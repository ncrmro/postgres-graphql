--! Previous: sha1:417a071b3828db454e480480b1f48ba490dcf60e
--! Hash: sha1:2d6741b787f0894efd5bbb849d19df6eed3d1839
--! Message: updated at trigger

-- Enter migration here

CREATE OR REPLACE FUNCTION private.set_updated_at() RETURNS trigger AS
$$
BEGIN
    new.updated_at := current_timestamp;
    RETURN new;
END;
$$ LANGUAGE plpgsql;
