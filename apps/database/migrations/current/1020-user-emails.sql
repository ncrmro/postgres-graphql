DROP TABLE IF EXISTS app_public.user_emails CASCADE;
/*
 * A user may have more than one email address; this is useful when letting the
 * user change their email so that they can verify the new one before deleting
 * the old one, but is also generally useful as they might want to use
 * different emails to log in versus where to send notifications. Therefore we
 * track user emails in a separate table.
 */
CREATE TABLE app_public.user_emails
(
    id          uuid PRIMARY KEY     DEFAULT gen_random_uuid(),
    user_id     uuid        NOT NULL DEFAULT app_public.viewer_id() REFERENCES app_public.users ON DELETE CASCADE,
    email       citext      NOT NULL CHECK (email ~ '[^@]+@[^@]+\.[^@]+'),
    is_verified boolean     NOT NULL DEFAULT FALSE,
    is_primary  boolean     NOT NULL DEFAULT FALSE,
    created_at  timestamptz NOT NULL DEFAULT NOW(),
    updated_at  timestamptz NOT NULL DEFAULT NOW(),
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

-- You can't verify an email address that someone else has already verified. (Email is taken.)
CREATE OR REPLACE FUNCTION app_public.tg_user_emails__forbid_if_verified() RETURNS trigger AS
$$
BEGIN
    IF EXISTS(SELECT 1 FROM app_public.user_emails WHERE email = new.email AND is_verified IS TRUE)
    THEN
        RAISE EXCEPTION 'An account using that email address has already been created.' USING ERRCODE = 'EMTKN';
    END IF;
    RETURN new;
END;
$$ LANGUAGE plpgsql VOLATILE SECURITY DEFINER SET search_path TO pg_catalog, public, pg_temp;
CREATE TRIGGER _200_forbid_existing_email
    BEFORE INSERT
    ON app_public.user_emails
    FOR EACH ROW
EXECUTE PROCEDURE app_public.tg_user_emails__forbid_if_verified();

COMMENT ON TABLE app_public.user_emails IS
    E'Information about a user''s email address.';
COMMENT ON COLUMN app_public.user_emails.email IS
    E'The users email address, in `a@b.c` format.';
COMMENT ON COLUMN app_public.user_emails.is_verified IS
    E'True if the user has is_verified their email address (by clicking the link in the email we sent them, or logging in with a social login provider), false otherwise.';

-- Users may only manage their own emails.
CREATE POLICY select_own ON app_public.user_emails FOR SELECT USING (user_id = app_public.viewer_id());
CREATE POLICY insert_own ON app_public.user_emails FOR INSERT WITH CHECK (user_id = app_public.viewer_id());
-- NOTE: we don't allow emails to be updated, instead add a new email and delete the old one.
CREATE POLICY delete_own ON app_public.user_emails FOR DELETE USING (user_id = app_public.viewer_id());
