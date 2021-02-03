--! Previous: sha1:ab7772c2fb1a26725a0f3802bdb273a470e77191
--! Hash: sha1:f74433c99ebe55a2175d99c75f8a77cad78222c4
--! Message: user authentication

-- Enter migration here

CREATE OR REPLACE FUNCTION public.authenticate(email text,
                                    password text) RETURNS public.jwt_token AS
$$
DECLARE account  private.user_account;
        username text;
BEGIN
    SELECT a.*
    INTO account
    FROM private.user_account AS a
    WHERE a.email = authenticate.email;

    SELECT u.username INTO username FROM public.user u WHERE id = account.user_id;

    IF account.password_hash = crypt(password, account.password_hash)
    THEN
        RETURN ('jtx_viewer', account.user_id, username, account.email,
                extract(EPOCH FROM (now() + INTERVAL '2 days')))::public.jwt_token;
    ELSE
        RETURN NULL;
    END IF;
END;
$$ LANGUAGE plpgsql STRICT
                    SECURITY DEFINER;

COMMENT ON FUNCTION public.authenticate(text, text) IS 'Creates a JWT token that will securely identify a user and give them certain permissions. This token expires in 2 days.';
