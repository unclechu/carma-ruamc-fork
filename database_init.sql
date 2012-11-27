BEGIN;

CREATE EXTENSION hstore;
CREATE EXTENSION postgis;

CREATE ROLE carma_search PASSWORD 'md568023aeacae5a76b23b958eb5da1a994' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO carma_search;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO carma_search;

CREATE ROLE carma_db_sync PASSWORD 'md556d33ece5e1452257fa0a086e7945c0b' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO carma_db_sync; -- FIXME:

CREATE ROLE carma_geo PASSWORD 'md5a73940ffdfdd8d8b9ecfbfba6cc3e2ab' NOSUPERUSER NOCREATEDB NOCREATEROLE INHERIT LOGIN;
CREATE TABLE geo_partners (id INTEGER PRIMARY KEY, name TEXT, city TEXT, address TEXT);
SELECT AddGeometryColumn ('geo_partners', 'coords', 4326, 'POINT', 2);
GRANT SELECT, UPDATE ON geo_partners TO carma_geo;
GRANT SELECT ON partnerMessageTbl TO carma_geo;

COMMIT;
