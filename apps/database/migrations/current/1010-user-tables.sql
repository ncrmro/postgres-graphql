DROP TYPE IF EXISTS app_public.jwt_token CASCADE;
CREATE TYPE app_public.jwt_token AS
(
    role     text,
    user_id  uuid,
    username text,
    exp      bigint
);

CREATE OR REPLACE FUNCTION app_public.viewer_id() RETURNS uuid AS
$$
SELECT NULLIF(CURRENT_SETTING('jwt.claims.user_id', TRUE), '')::uuid
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO pg_catalog, public, pg_temp;
COMMENT ON FUNCTION app_public.viewer_id() IS
    E'Handy method to get the current user ID for use in RLS policies, etc; in GraphQL, use `currentUser{id}` instead.';


/*
 * The users table stores (unsurprisingly) the users of our application. You'll
 * notice that it does NOT contain private information such as the user's
 * password or their email address; that's because the users table is seen as
 * public - anyone who can "see" the user can see this information.
 *
 * The author sees `is_admin` and `is_verified` as public information; if you
 * disagree then you should relocate these attributes to another table, such as
 * `user_secrets`.
 */
DROP TABLE IF EXISTS app_public.users CASCADE;
CREATE TABLE app_public.users
(
    id          uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    username    citext      NOT NULL UNIQUE CHECK (LENGTH(username) >= 2 AND LENGTH(username) <= 24 AND
                                                   username ~ '^[a-zA-Z]([_]?[a-zA-Z0-9])+$'),
    name        text,
    avatar_url  text CHECK (avatar_url ~ '^https?://[^/]+'),
    is_admin    boolean     NOT NULL DEFAULT FALSE,
    is_verified boolean     NOT NULL DEFAULT FALSE,
    created_at  timestamptz NOT NULL DEFAULT NOW(),
    updated_at  timestamptz NOT NULL DEFAULT NOW()
);
ALTER TABLE app_public.users
    ENABLE ROW LEVEL SECURITY;

-- Users are publicly visible, like on GitHub, Twitter, Facebook, Trello, etc.
CREATE POLICY select_all ON app_public.users FOR SELECT USING (TRUE);
-- You can only update yourself.
CREATE POLICY update_self ON app_public.users FOR UPDATE USING (id = app_public.viewer_id());
GRANT SELECT ON app_public.users TO :DATABASE_VISITOR;
-- NOTE: `insert` is not granted, because we'll handle that separately
GRANT UPDATE (username, name, avatar_url) ON app_public.users TO :DATABASE_VISITOR;
-- NOTE: `delete` is not granted, because we require confirmation via request_account_deletion/confirm_account_deletion

COMMENT ON TABLE app_public.users IS
    E'A user who can log in to the application.';

COMMENT ON COLUMN app_public.users.id IS
    E'Unique identifier for the user.';
COMMENT ON COLUMN app_public.users.username IS
    E'Public-facing username (or ''handle'') of the user.';
COMMENT ON COLUMN app_public.users.name IS
    E'Public-facing name (or pseudonym) of the user.';
COMMENT ON COLUMN app_public.users.avatar_url IS
    E'Optional avatar URL.';
COMMENT ON COLUMN app_public.users.is_admin IS
    E'If true, the user has elevated privileges.';

CREATE TRIGGER _100_timestamps
    BEFORE INSERT OR UPDATE
    ON app_public.users
    FOR EACH ROW
EXECUTE PROCEDURE app_private.tg__timestamps();


/**********/

-- Returns the current user; this is a "custom query" function; see:
-- https://www.graphile.org/postgraphile/custom-queries/
-- So this will be queryable via GraphQL as `{ currentUser { ... } }`
CREATE OR REPLACE FUNCTION app_public.viewer() RETURNS app_public.users AS
$$
SELECT users.*
FROM app_public.users
WHERE id = app_public.viewer_id();
$$ LANGUAGE sql STABLE;
COMMENT ON FUNCTION app_public.viewer() IS
    E'The currently logged in user (or null if not logged in).';

GRANT EXECUTE ON FUNCTION app_public.viewer() TO :DATABASE_VISITOR;

/**********/

-- The users table contains all the public information, but we need somewhere
-- to store private information. In fact, this data is so private that we don't
-- want the user themselves to be able to see it - things like the bcrypted
-- password hash, timestamps of recent login attempts (to allow us to
-- auto-protect user accounts that are under attack), etc.
DROP TABLE IF EXISTS app_private.user_secrets CASCADE;
CREATE TABLE app_private.user_secrets
(
    user_id       uuid PRIMARY KEY REFERENCES app_public.users (id) ON DELETE CASCADE,
    active        bool                 DEFAULT FALSE,
    password_hash text
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
    ON app_public.users
    FOR EACH ROW
EXECUTE PROCEDURE app_private.tg_user_secrets__insert_with_user();
COMMENT ON FUNCTION app_private.tg_user_secrets__insert_with_user() IS
    E'Ensures that every user record has an associated user_secret record.';

/*
 * Because you can register with username/password or using OAuth (social
 * login), we need a way to tell the user whether or not they have a
 * password. This is to help the UI display the right interface: change
 * password or set password.
 */
CREATE OR REPLACE FUNCTION app_public.users_has_password(u app_public.users) RETURNS boolean AS
$$
SELECT (password_hash IS NOT NULL)
FROM app_private.user_secrets
WHERE user_secrets.user_id = u.id
  AND u.id = app_public.viewer_id();
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path TO pg_catalog, public, pg_temp;

