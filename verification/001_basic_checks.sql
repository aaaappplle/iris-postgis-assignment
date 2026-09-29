-- Basic verification for the IRIS pilot.
-- Run after migrations, seed, promotion, and screening.

\pset pager off

\echo '=== PostGIS version ==='
SELECT PostGIS_Version();

\echo '=== Core row counts ==='
SELECT 'source_run' AS table_name, COUNT(*) AS row_count
FROM iris_core.source_run
UNION ALL
SELECT 'parcel', COUNT(*) FROM iris_core.parcel
UNION ALL
SELECT 'substation', COUNT(*) FROM iris_core.substation
UNION ALL
SELECT 'peatland', COUNT(*) FROM iris_core.peatland
UNION ALL
SELECT 'screening_layer', COUNT(*) FROM iris_core.screening_layer
UNION ALL
SELECT 'evidence', COUNT(*) FROM iris_core.evidence
ORDER BY table_name;

\echo '=== Staging / core row counts ==='
SELECT 'parcel' AS entity,
       (SELECT COUNT(*) FROM iris_staging.parcel) AS staging_rows,
       (SELECT COUNT(*) FROM iris_core.parcel) AS core_rows
UNION ALL
SELECT 'substation',
       (SELECT COUNT(*) FROM iris_staging.substation),
       (SELECT COUNT(*) FROM iris_core.substation)
UNION ALL
SELECT 'peatland',
       (SELECT COUNT(*) FROM iris_staging.peatland),
       (SELECT COUNT(*) FROM iris_core.peatland)
UNION ALL
SELECT 'screening_layer',
       (SELECT COUNT(*) FROM iris_staging.screening_layer),
       (SELECT COUNT(*) FROM iris_core.screening_layer);

\echo '=== Required canonical columns in core business tables ==='
SELECT
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'iris_core'
  AND table_name IN ('parcel', 'substation', 'peatland', 'screening_layer')
  AND column_name IN (
      'geom',
      'country_code',
      'region_code',
      'source_id',
      'source_date',
      'created_at'
  )
ORDER BY table_name, ordinal_position;

\echo '=== No NULL country_code values ==='
SELECT 'parcel' AS table_name, COUNT(*) AS null_country_codes
FROM iris_core.parcel
WHERE country_code IS NULL
UNION ALL
SELECT 'substation', COUNT(*)
FROM iris_core.substation
WHERE country_code IS NULL
UNION ALL
SELECT 'peatland', COUNT(*)
FROM iris_core.peatland
WHERE country_code IS NULL
UNION ALL
SELECT 'screening_layer', COUNT(*)
FROM iris_core.screening_layer
WHERE country_code IS NULL
UNION ALL
SELECT 'source_run', COUNT(*)
FROM iris_core.source_run
WHERE country_code IS NULL;

\echo '=== Geometry type and SRID contracts ==='
SELECT
    'parcel' AS entity,
    parcel_ref AS ref,
    GeometryType(geom) AS geometry_type,
    ST_SRID(geom) AS srid
FROM iris_core.parcel

UNION ALL

SELECT
    'substation',
    substation_ref,
    GeometryType(geom),
    ST_SRID(geom)
FROM iris_core.substation

UNION ALL

SELECT
    'peatland',
    peatland_ref,
    GeometryType(geom),
    ST_SRID(geom)
FROM iris_core.peatland

UNION ALL

SELECT
    'screening_layer',
    layer_ref,
    GeometryType(geom),
    ST_SRID(geom)
FROM iris_core.screening_layer
ORDER BY entity, ref;

\echo '=== CRS transformation demonstration ==='
SELECT s.external_id,
       ST_SRID(s.geom) AS staging_srid,
       ST_SRID(c.geom) AS core_srid,
       ST_AsText(s.geom) AS staging_geometry,
       ST_AsText(c.geom) AS core_geometry,
       ST_Equals(ST_Transform(s.geom, 4326), c.geom)
           AS transformation_matches
FROM iris_staging.substation AS s
JOIN iris_core.substation AS c
  ON c.country_code = s.country_code
 AND c.source_id = s.source_id
 AND c.substation_ref = s.external_id
WHERE s.country_code = 'DE'
  AND s.source_id = 'demo_grid_utm32'
  AND s.external_id = 'SUB-001';

\echo '=== EWKB geometry round trip ==='
WITH geometries AS (
    SELECT 'parcel' AS entity, parcel_ref AS ref, geom
    FROM iris_core.parcel
    UNION ALL
    SELECT 'substation', substation_ref, geom
    FROM iris_core.substation
    UNION ALL
    SELECT 'peatland', peatland_ref, geom
    FROM iris_core.peatland
    UNION ALL
    SELECT 'screening_layer', layer_ref, geom
    FROM iris_core.screening_layer
),
round_trips AS (
    SELECT *,
           ST_GeomFromEWKB(ST_AsEWKB(geom)) AS restored_geom
    FROM geometries
)
SELECT entity,
       ref,
       ST_Equals(geom, restored_geom) AS geometry_equal,
       ST_SRID(geom) = ST_SRID(restored_geom) AS srid_equal,
       GeometryType(geom) = GeometryType(restored_geom) AS type_equal
FROM round_trips
ORDER BY entity, ref;

\echo '=== Source lineage ==='
SELECT
    p.parcel_ref,
    p.country_code,
    p.source_id,
    p.source_date,
    p.source_run_id,
    r.source_id AS run_source_id,
    r.source_date AS run_source_date,
    p.source_id = r.source_id
        AND p.source_date = r.source_date AS provenance_matches,
    r.created_at AS source_run_created_at
FROM iris_core.parcel AS p
JOIN iris_core.source_run AS r
  ON r.country_code = p.country_code
 AND r.id = p.source_run_id
ORDER BY p.parcel_ref;

\echo '=== Persisted screening evidence ==='
SELECT
    e.id AS evidence_id,
    p.parcel_ref,
    e.evidence_type,
    e.text_value AS related_feature_ref,
    e.numeric_value,
    e.unit,
    e.uncertainty_note,
    r.source_id AS evidence_source_id,
    r.source_date AS evidence_source_date,
    e.created_at
FROM iris_core.evidence AS e
JOIN iris_core.parcel AS p
  ON p.country_code = e.country_code
 AND p.id = e.parcel_id
JOIN iris_core.source_run AS r
  ON r.country_code = e.country_code
 AND r.id = e.source_run_id
ORDER BY p.parcel_ref, e.evidence_type;
