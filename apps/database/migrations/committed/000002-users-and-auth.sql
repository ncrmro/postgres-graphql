--! Previous: sha1:de60470eae2711674026eea0ced5e4917011e6ea
--! Hash: sha1:59b313c6c36382410785d19241393e8110c9b9af
--! Message: users-and-auth

--! split: 0001-jwt-token-type.sql
DROP TYPE IF EXISTS app_public.jwt_token CASCADE;
CREATE TYPE app_public.jwt_token AS
(
    role     text,
    user_id  uuid,
    username text,
    exp      bigint
);

--! split: 0002-viewer-id-function.sql
CREATE OR REPLACE FUNCTION app_public.viewer_id() RETURNS uuid AS
$$
SELECT nullif(current_setting('jwt.claims.user_id', TRUE), '')::uuid
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION app_public.viewer_id() IS 'Gets the id of the viewer who was identified by our JWT.';

--! split: 0010-user-table.sql
CREATE EXTENSION IF NOT EXISTS citext WITH SCHEMA public;

DROP TABLE IF EXISTS app_public.user CASCADE;
CREATE TABLE app_public.user
(
    id          uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    username    citext      NOT NULL UNIQUE CHECK (length(username) >= 2 AND length(username) <= 24 AND
                                                   username ~ '^[a-zA-Z]([_]?[a-zA-Z0-9])+$'),
    name        text,
    avatar_url  text CHECK (avatar_url ~ '^https?://[^/]+'),
    is_admin    boolean     NOT NULL DEFAULT FALSE,
    is_verified boolean     NOT NULL DEFAULT FALSE,
    created_at  timestamptz NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc'),
    updated_at  timestamptz NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc')
);

ALTER TABLE app_public.user
    ENABLE ROW LEVEL SECURITY;

-- Users are publicly visible, like on GitHub, Twitter, Facebook, Trello, etc.
CREATE POLICY select_all ON app_public.user FOR SELECT USING (TRUE);
-- You can only update yourself.
CREATE POLICY update_self ON app_public.user FOR UPDATE USING (id = app_public.viewer_id());
GRANT SELECT ON app_public.user TO :DATABASE_VISITOR;
-- NOTE: `insert` is not granted, because we'll handle that separately
GRANT UPDATE (username, name, avatar_url) ON app_public.user TO :DATABASE_VISITOR;
-- NOTE: `delete` is not granted, because we require confirmation via request_account_deletion/confirm_account_deletion

COMMENT ON TABLE app_public.user IS
    E'A user who can log in to the application.';

COMMENT ON COLUMN app_public.user.id IS
    E'Unique identifier for the user.';
COMMENT ON COLUMN app_public.user.username IS
    E'Public-facing username (or ''handle'') of the user.';
COMMENT ON COLUMN app_public.user.name IS
    E'Public-facing name (or pseudonym) of the user.';
COMMENT ON COLUMN app_public.user.avatar_url IS
    E'Optional avatar URL.';
COMMENT ON COLUMN app_public.user.is_admin IS
    E'If true, the user has elevated privileges.';

CREATE TRIGGER _100_timestamps
    BEFORE INSERT OR UPDATE
    ON app_public.user
    FOR EACH ROW
EXECUTE PROCEDURE app_private.tg__timestamps();

--! split: 0020-viewer-function.sql
-- Returns the current user; this is a "custom query" function; see:
-- https://www.graphile.org/postgraphile/custom-queries/
-- So this will be queryable via GraphQL as `{ viewer { ... } }`
CREATE FUNCTION app_public.viewer() RETURNS app_public.user AS
$$
SELECT *
FROM app_public.user
WHERE id = app_public.viewer_id();
$$ LANGUAGE sql STABLE;

COMMENT ON FUNCTION app_public.viewer() IS
    E'The currently logged in user (or null if not logged in).';

--! split: 0030-user-secrets-table.sql
-- The users table contains all the public information, but we need somewhere
-- to store private information. In fact, this data is so private that we don't
-- want the user themselves to be able to see it - things like the bcrypted
-- password hash, timestamps of recent login attempts (to allow us to
-- auto-protect user accounts that are under attack), etc.
DROP TABLE IF EXISTS app_private.user_secrets CASCADE;
CREATE TABLE app_private.user_secrets
(
    user_id                             uuid        NOT NULL PRIMARY KEY REFERENCES app_public.user ON DELETE CASCADE,
    password_hash                       text,
    last_login_at                       timestamptz NOT NULL DEFAULT now(),
    failed_password_attempts            int         NOT NULL DEFAULT 0,
    first_failed_password_attempt       timestamptz,
    reset_password_token                text,
    reset_password_token_generated      timestamptz,
    failed_reset_password_attempts      int         NOT NULL DEFAULT 0,
    first_failed_reset_password_attempt timestamptz,
    delete_account_token                text,
    delete_account_token_generated      timestamptz
);

ALTER TABLE app_private.user_secrets
    ENABLE ROW LEVEL SECURITY;

COMMENT ON TABLE app_private.user_secrets IS
    E'The contents of this table should never be visible to the user. Contains data mostly related to authentication.';

/*
 * When we insert into `users` we _always_ want there to be a matching
 * `user_secrets` entry, so we have a trigger to enforce this:
 */
CREATE OR REPLACE FUNCTION app_private.tg_user_secrets__insert_with_user() RETURNS trigger AS
$$
BEGIN
    INSERT INTO app_private.user_secrets(user_id) VALUES (new.id);
    RETURN new;
END;
$$ LANGUAGE plpgsql VOLATILE SET search_path TO pg_catalog, public, pg_temp;

CREATE TRIGGER _500_insert_secrets
    AFTER INSERT
    ON app_public.user
    FOR EACH ROW
EXECUTE PROCEDURE app_private.tg_user_secrets__insert_with_user();

COMMENT ON FUNCTION app_private.tg_user_secrets__insert_with_user() IS
    E'Ensures that every user record has an associated user_secret record.';

--! split: 0040-user-has-password.sql
/*
 * Because you can register with username/password or using OAuth (social
 * login), we need a way to tell the user whether or not they have a
 * password. This is to help the UI display the right interface: change
 * password or set password.
 */
CREATE FUNCTION app_public.users_has_password(u app_public.user) RETURNS boolean AS
$$
SELECT (password_hash IS NOT NULL)
FROM app_private.user_secrets
WHERE user_secrets.user_id = u.id
  AND u.id = app_public.viewer_id();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO pg_catalog, public, pg_temp;

--! split: 0050-user-emails.sql
DROP TABLE IF EXISTS app_public.user_emails CASCADE;
CREATE TABLE app_public.user_emails
(
    id          uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL DEFAULT app_public.viewer_id() REFERENCES app_public.user ON DELETE CASCADE,
    email       citext      NOT NULL CHECK (email ~ '[^@]+@[^@]+\.[^@]+'),
    is_verified boolean     NOT NULL DEFAULT FALSE,
    is_primary  boolean     NOT NULL DEFAULT FALSE,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now(),
    -- Each user can only have an email once.
    CONSTRAINT user_emails_user_id_email_key UNIQUE (user_id, email),
    -- An unverified email cannot be set as the primary email.
    CONSTRAINT user_emails_must_be_verified_to_be_primary CHECK (is_primary IS FALSE OR is_verified IS TRUE)
);
ALTER TABLE app_public.user_emails
    ENABLE ROW LEVEL SECURITY;

-- Once an email is verified, it may only be used by one user. (We can't
-- enforce this before an email is verified otherwise it could be used to
-- prevent a legitimate user from signing up.)
CREATE UNIQUE INDEX uniq_user_emails_verified_email ON app_public.user_emails (email) WHERE (is_verified IS TRUE);
-- Only one primary email per user.
CREATE UNIQUE INDEX uniq_user_emails_primary_email ON app_public.user_emails (user_id) WHERE (is_primary IS TRUE);
-- Allow efficient retrieval of all the emails owned by a particular user.
CREATE INDEX idx_user_emails_user ON app_public.user_emails (user_id);
-- For the user settings page sorting
CREATE INDEX idx_user_emails_primary ON app_public.user_emails (is_primary, user_id);

-- Keep created_at and updated_at up to date.
CREATE TRIGGER _100_timestamps
    BEFORE INSERT OR UPDATE
    ON app_public.user_emails
    FOR EACH ROW
EXECUTE PROCEDURE app_private.tg__timestamps();

--! split: 0060-authenticate-user.sql
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;

CREATE FUNCTION app_public.authenticate(username citext,
                                        password text) RETURNS app_public.jwt_token AS
$$
DECLARE account app_private.user_secrets;
BEGIN
    -- IF email
    IF username ~ '[^@]+@[^@]+\.[^@]+'
    THEN
        SELECT a.*
        INTO account
        FROM app_private.user_secrets AS a
                 INNER JOIN app_public.user_emails ue ON ue.user_id = a.user_id
        WHERE ue.email = authenticate.username;
    ELSE
        SELECT a.*
        INTO account
        FROM app_private.user_secrets AS a
                 INNER JOIN app_public.user u ON a.user_id = u.id
        WHERE u.username = authenticate.username;
    END IF;


--     SELECT u.username INTO username FROM app_public.user u WHERE id = account.user_id;

    IF account.password_hash = crypt(password, account.password_hash)
    THEN
        RETURN (':DATABASE_VISITOR', account.user_id, username,
                extract(EPOCH FROM (now() + INTERVAL '2 days')))::app_public.jwt_token;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql STRICT
                    SECURITY DEFINER;

COMMENT ON FUNCTION app_public.authenticate(citext, text) IS 'Creates a JWT token that will securely identify a user and give them certain permissions. This token expires in 2 days.';

--! split: 0070-register-user.sql
CREATE OR REPLACE FUNCTION app_public.register_user(username citext,
                                                    password text) RETURNS app_public.jwt_token AS
$$
DECLARE u app_public.user;
BEGIN
    INSERT INTO app_public.user (username)
    VALUES (username)
    RETURNING * INTO u;

    UPDATE app_private.user_secrets us
        SET password_hash = crypt(password, gen_salt('bf'))
    WHERE user_id = u.id;

    RETURN app_public.authenticate(u.username::citext, password);
END;
$$ LANGUAGE plpgsql STRICT
                    SECURITY DEFINER;
