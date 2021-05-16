-- Manually create the test user so JWT works across database resets
INSERT INTO app_public.user (id, username, name, is_verified)
VALUES ('da221b05-a99c-485d-a278-015e7baaeda2', 'testuser1', 'Test User', TRUE);
UPDATE app_private.user_secrets us
        SET password_hash = crypt('test123', gen_salt('bf'))
    WHERE user_id = 'da221b05-a99c-485d-a278-015e7baaeda2';

INSERT INTO app_public.user (id, username, name, is_verified)
VALUES ('23e675b1-d581-4d84-96a9-8f73dbee72ad', 'ncrmro', 'Nicholas Romero', TRUE);
UPDATE app_private.user_secrets us
        SET password_hash = crypt('test123', gen_salt('bf'))
    WHERE user_id = '23e675b1-d581-4d84-96a9-8f73dbee72ad';

SELECT *
FROM app_public.register_user(
        username := 'testuser2', password := 'test123'
    );

SELECT *
FROM app_public.register_user(
        username := 'nopartorsystemuser', password := 'test123'
    );

SELECT *
FROM app_public.register_user(
        username := 'noemailuser', password := 'test123'
    );
