-- Enter migration here

CREATE SCHEMA IF NOT EXISTS myapp;
CREATE SCHEMA IF NOT EXISTS myapp_private;

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
