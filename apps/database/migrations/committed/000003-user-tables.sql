--! Previous: sha1:2d6741b787f0894efd5bbb849d19df6eed3d1839
--! Hash: sha1:2874c961801a9d6832bd9442d92795af2ee6048b
--! Message: user tables

-- Enter migration here

DROP TABLE IF EXISTS public.user;

CREATE TABLE public.user
(
    id         uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    username   text CHECK (char_length(username) < 32) UNIQUE,
    created_at timestamptz NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc'),
    updated_at timestamptz NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc')
);

COMMENT ON TABLE public.user IS 'Public information about a user';
COMMENT ON COLUMN public.user.username IS 'This publicly viewable username';

CREATE TRIGGER user_updated_at
    BEFORE UPDATE
    ON public.user
    FOR EACH ROW
EXECUTE PROCEDURE private.set_updated_at();

CREATE POLICY select_user ON public.user FOR SELECT
    USING (id = current_setting('jwt.claims.user_id', TRUE)::uuid);

CREATE POLICY update_user ON public.user FOR UPDATE TO myapp_viewer
    USING (id = current_setting('jwt.claims.person_id', TRUE)::uuid);

COMMENT ON TABLE public.user IS E'@omit delete';

DROP TABLE IF EXISTS private.user_account;

CREATE TABLE private.user_account
(
    user_id       uuid PRIMARY KEY REFERENCES public.user (id) ON DELETE CASCADE,
    email         text        NOT NULL UNIQUE CHECK (email ~* '^.+@.+\..+$'),
    active        bool                 DEFAULT FALSE,
    password_hash text,
    created_at    timestamptz NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc'),
    updated_at    timestamptz NOT NULL DEFAULT (NOW() AT TIME ZONE 'utc')
);

COMMENT ON TABLE private.user_account IS 'Private information about a person’s account.';
COMMENT ON COLUMN private.user_account.user_id IS 'The id of the person associated with this account.';
COMMENT ON COLUMN private.user_account.email IS 'The email address of the person.';
COMMENT ON COLUMN private.user_account.password_hash IS 'An opaque hash of the person’s password.';

CREATE TRIGGER user_account_updated_at
    BEFORE UPDATE
    ON private.user_account
    FOR EACH ROW
EXECUTE PROCEDURE private.set_updated_at();

CREATE POLICY select_private_user ON private.user_account FOR SELECT
    USING (user_id = current_setting('jwt.claims.user_id', TRUE)::uuid);

CREATE POLICY update_private_user ON private.user_account FOR UPDATE TO myapp_viewer
    USING (user_id = current_setting('jwt.claims.person_id', TRUE)::uuid);
