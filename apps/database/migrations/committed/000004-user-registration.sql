--! Previous: sha1:2874c961801a9d6832bd9442d92795af2ee6048b
--! Hash: sha1:ab7772c2fb1a26725a0f3802bdb273a470e77191
--! Message: user registration

-- Enter migration here

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DROP TYPE IF EXISTS public.jwt_token CASCADE;

CREATE TYPE public.jwt_token AS
(
    role     text,
    user_id  uuid,
    username text,
    email    text,
    exp      bigint
);

CREATE OR REPLACE FUNCTION public.register_user(email text,
                                     password text) RETURNS public.jwt_token AS
$$
DECLARE "user" public.user;
BEGIN
    INSERT INTO public.user (username)
    VALUES (email)
    RETURNING * INTO "user";

    INSERT INTO private.user_account (user_id, email, password_hash)
    VALUES ("user".id, email, crypt(password, gen_salt('bf')));

    RETURN public.authenticate(email, password);
END;
$$ LANGUAGE plpgsql STRICT
                    SECURITY DEFINER;

COMMENT ON FUNCTION public.register_user(text, text) IS 'Registers a single user and creates an account in our forum.';
