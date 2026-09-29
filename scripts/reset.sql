-- Reset only the IRIS application schemas.
-- PostgreSQL, PostGIS, and the Docker volume are preserved.
-- This script is intended to be followed by the migrations.

BEGIN;

\echo '--> Drop schema iris_core and its objects'
DROP SCHEMA IF EXISTS iris_core CASCADE;

\echo '--> Drop schema iris_staging and its objects'
DROP SCHEMA IF EXISTS iris_staging CASCADE;

COMMIT;
