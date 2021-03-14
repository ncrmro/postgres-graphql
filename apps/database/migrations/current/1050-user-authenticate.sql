CREATE FUNCTION app_public.authenticate(username text,
                                        password text) RETURNS app_public.jwt_token AS
$$
DECLARE v_user        app_public.users;
        v_user_secret app_private.user_secrets;

BEGIN
    IF username LIKE '%@%'
    THEN
        -- It's an email
        SELECT users.*
        INTO v_user
        FROM app_public.users
                 INNER JOIN app_public.user_emails
                            ON (user_emails.user_id = users.id)
        WHERE user_emails.email = authenticate.username
        ORDER BY user_emails.is_verified DESC, -- Prefer verified email
                 user_emails.created_at ASC    -- Failing that, prefer the first registered (unverified users _should_ verify before logging in)
        LIMIT 1;
    ELSE
        -- It's a username
        SELECT users.*
        INTO v_user
        FROM app_public.users
        WHERE users.username = authenticate.username;
    END IF;

    IF NOT (v_user IS NULL)
    THEN
        -- Load their secrets
        SELECT *
        INTO v_user_secret
        FROM app_private.user_secrets
        WHERE user_secrets.user_id = v_user.id;

        -- Have there been too many login attempts?
--         IF (
--                 v_user_secret.first_failed_password_attempt IS NOT NULL
--                 AND
--                 v_user_secret.first_failed_password_attempt > NOW() - v_login_attempt_window_duration
--                 AND
--                 v_user_secret.failed_password_attempts >= 3
--             )
--         THEN
--             RAISE EXCEPTION 'User account locked - too many login attempts. Try again after 5 minutes.' USING ERRCODE = 'LOCKD';
--         END IF;

        -- Not too many login attempts, let's check the password.
        -- NOTE: `password_hash` could be null, this is fine since `NULL = NULL` is null, and null is falsy.
        IF v_user_secret.password_hash = crypt(password, v_user_secret.password_hash)
        THEN
            -- Excellent - they're logged in! Let's reset the attempt tracking
--             UPDATE app_private.user_secrets
--             SET failed_password_attempts      = 0,
--                 first_failed_password_attempt = NULL,
--                 last_login_at                 = NOW()
--             WHERE user_id = v_user.id;
--             -- Create a session for the user
--             INSERT INTO app_private.sessions (user_id) VALUES (v_user.id) RETURNING * INTO v_session;
            -- And finally return the session
            RETURN ('jtx_viewer', v_user_secret.user_id, username,
                    EXTRACT(EPOCH FROM (NOW() + INTERVAL '2 days')))::app_public.jwt_token;
            --         ELSE
--             -- Wrong password, bump all the attempt tracking figures
--             UPDATE app_private.user_secrets
--             SET failed_password_attempts      = (CASE
--                                                      WHEN first_failed_password_attempt IS NULL OR
--                                                           first_failed_password_attempt < NOW() - v_login_attempt_window_duration
--                                                          THEN 1
--                                                      ELSE failed_password_attempts + 1 END),
--                 first_failed_password_attempt = (CASE
--                                                      WHEN first_failed_password_attempt IS NULL OR
--                                                           first_failed_password_attempt < NOW() - v_login_attempt_window_duration
--                                                          THEN NOW()
--                                                      ELSE first_failed_password_attempt END)
--             WHERE user_id = v_user.id;
--             RETURN NULL; -- Must not throw otherwise transaction will be aborted and attempts won't be recorded
        END IF;
    ELSE
        -- No user with that email/username was found
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql STRICT
                    SECURITY DEFINER SET search_path TO pg_catalog, public, pg_temp;

COMMENT ON FUNCTION app_public.authenticate(text, text) IS 'Creates a JWT token that will securely identify a user and give them certain permissions. This token expires in 2 days.';

GRANT EXECUTE ON FUNCTION app_public.authenticate(text, text) TO :DATABASE_VISITOR;
