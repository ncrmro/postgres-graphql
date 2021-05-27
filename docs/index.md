

## Temporarily Disabling Triggers

Let's say we would like to delete a user and all of their emails

```postgresql
ALTER TABLE app_public.user_emails DISABLE TRIGGER _500_prevent_delete_last;
DELETE from app_public.user_emails WHERE email='user1@test.com';
DELETE from app_public.user WHERE username='user1';
ALTER TABLE app_public.user_emails ENABLE TRIGGER _500_prevent_delete_last;
```
