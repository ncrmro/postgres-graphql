CREATE FUNCTION app_public.register_user(email citext,
                                         password citext) RETURNS app_public.jwt_token AS
$$
DECLARE "user" app_public.users;
BEGIN
    INSERT INTO app_public.users (username)
    VALUES ((SELECT SPLIT_PART(email, '@', 1) AS username))
    RETURNING * INTO "user";

    INSERT INTO app_public.user_emails (user_id, email)
    VALUES ("user".id, email);

    UPDATE app_private.user_secrets
    SET password_hash = crypt(password, gen_salt('bf'))
    WHERE user_id = "user".id;

    RETURN app_public.authenticate(email, password);
END;
$$ LANGUAGE plpgsql STRICT
                    SECURITY DEFINER SET search_path TO pg_catalog, public, pg_temp;

COMMENT ON FUNCTION app_public.register_user(citext, citext) IS 'Registers a single user and creates an account in our forum.';

