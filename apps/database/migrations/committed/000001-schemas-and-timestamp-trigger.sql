--! Previous: -
--! Hash: sha1:de60470eae2711674026eea0ced5e4917011e6ea
--! Message: schemas-and-timestamp-trigger

--! split: 0001-reset.sql
/*
 * Graphile Migrate will run our `current/...` migrations in one batch. Since
 * this is our first migration it's defining the entire database, so we first
 * drop anything that may have previously been created
 * (app_public/app_hidden/app_private) so that we can start from scratch.
 */

DROP SCHEMA IF EXISTS app_public CASCADE;
DROP SCHEMA IF EXISTS app_hidden CASCADE;
DROP SCHEMA IF EXISTS app_private CASCADE;

--! split: 0010-public-permissions.sql
/*
 * The `public` *schema* contains things like PostgreSQL extensions. We
 * deliberately do not install application logic into the public schema
 * (instead storing it to app_public/app_hidden/app_private as appropriate),
 * but none the less we don't want untrusted roles to be able to install or
 * modify things into the public schema.
 *
 * The `public` *role* is automatically inherited by all other roles; we only
 * want specific roles to be able to access our database so we must revoke
 * access to the `public` role.
 */

REVOKE ALL ON SCHEMA public FROM PUBLIC;

ALTER DEFAULT PRIVILEGES REVOKE ALL ON SEQUENCES FROM PUBLIC;
ALTER DEFAULT PRIVILEGES REVOKE ALL ON FUNCTIONS FROM PUBLIC;

-- Of course we want our database owner to be able to do anything inside the
-- database, so we grant access to the `public` schema:
GRANT ALL ON SCHEMA public TO :DATABASE_OWNER;

--! split: 0020-schemas.sql
/*
 * Read about our app_public/app_hidden/app_private schemas here:
 * https://www.graphile.org/postgraphile/namespaces/#advice
 *
 * Note this pattern is not required to use PostGraphile, it's merely the
 * preference of the author of this package.
 */

CREATE SCHEMA app_public;
CREATE SCHEMA app_hidden;
CREATE SCHEMA app_private;

-- The 'visitor' role (used by PostGraphile to represent an end user) may
-- access the public, app_public and app_hidden schemas (but _NOT_ the
-- app_private schema).
GRANT USAGE ON SCHEMA public, app_public, app_hidden TO :DATABASE_VISITOR;

-- We want the `visitor` role to be able to insert rows (`serial` data type
-- creates sequences, so we need to grant access to that).
ALTER DEFAULT PRIVILEGES IN SCHEMA public, app_public, app_hidden
    GRANT USAGE, SELECT ON SEQUENCES TO :DATABASE_VISITOR;

-- And the `visitor` role should be able to call functions too.
ALTER DEFAULT PRIVILEGES IN SCHEMA public, app_public, app_hidden
    GRANT EXECUTE ON FUNCTIONS TO :DATABASE_VISITOR;

--! split: 0030-timestamp-trigger.sql
/*
 * This trigger is used on tables with created_at and updated_at to ensure that
 * these timestamps are kept valid (namely: `created_at` cannot be changed, and
 * `updated_at` must be monotonically increasing).
 */
CREATE FUNCTION app_private.tg__timestamps() RETURNS trigger AS
$$
BEGIN
    new.created_at = (CASE WHEN tg_op = 'INSERT' THEN NOW() ELSE old.created_at END);
    new.updated_at = (CASE
                          WHEN tg_op = 'UPDATE' AND old.updated_at >= NOW()
                              THEN old.updated_at + INTERVAL '1 millisecond'
                          ELSE NOW() END);
    RETURN new;
END;
$$ LANGUAGE plpgsql VOLATILE SET search_path TO pg_catalog, public, pg_temp;
COMMENT ON FUNCTION app_private.tg__timestamps() IS
    E'This trigger should be called on all tables with created_at, updated_at - it ensures that they cannot be manipulated and that updated_at will always be larger than the previous updated_at.';
