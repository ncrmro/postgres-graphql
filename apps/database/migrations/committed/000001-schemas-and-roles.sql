--! Previous: -
--! Hash: sha1:417a071b3828db454e480480b1f48ba490dcf60e
--! Message: schemas and roles

-- Enter migration here

CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS private;

DO
$$
    BEGIN
        CREATE ROLE myapp_anonymous;
    EXCEPTION
        WHEN DUPLICATE_OBJECT THEN
            RAISE NOTICE 'not creating anonymous role -- it already exists';
    END
$$;

DO
$$
    BEGIN
        CREATE ROLE myapp_viewer;
    EXCEPTION
        WHEN DUPLICATE_OBJECT THEN
            RAISE NOTICE 'not creating viewer role -- it already exists';
    END
$$;

ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM myapp_anonymous;
ALTER DEFAULT PRIVILEGES REVOKE EXECUTE ON FUNCTIONS FROM myapp_viewer;
