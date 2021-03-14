SELECT *
FROM app_public.register_user(email := 'test@test.com', password := 'test123');
SELECT *
FROM app_public.register_user(email := 'test2@test.com', password := 'test123');
SELECT *
FROM app_public.register_user(email := 'no_part_or_system_user@test.com', password := 'test123');
