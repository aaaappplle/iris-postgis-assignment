BEGIN;

-- Register one minimal logical source run per country/source/date represented
-- by the staging fixtures.
-- Use the earliest staging creation timestamp for each logical run.
\echo '--> Register source provenance in iris_core.source_run'
INSERT INTO iris_core.source_run (
    country_code,
    source_id,
    source_date,
    created_at
)
SELECT
    s.country_code,
    s.source_id,
    s.source_date,
    MIN(s.created_at)
FROM (
    SELECT country_code, source_id, source_date, created_at
    FROM iris_staging.parcel

    UNION ALL

    SELECT country_code, source_id, source_date, created_at
    FROM iris_staging.substation

    UNION ALL

    SELECT country_code, source_id, source_date, created_at
    FROM iris_staging.peatland

    UNION ALL

    SELECT country_code, source_id, source_date, created_at
    FROM iris_staging.screening_layer
) AS s
GROUP BY s.country_code, s.source_id, s.source_date
ORDER BY s.country_code, s.source_id, s.source_date
ON CONFLICT (country_code, source_id, source_date) DO NOTHING;

-- Parcel: normalize to MultiPolygon/4326.
\echo '--> Promote iris_staging.parcel into iris_core.parcel'
INSERT INTO iris_core.parcel (
    country_code,
    region_code,
    source_id,
    source_date,
    parcel_ref,
    geom,
    source_run_id,
    created_at
)
SELECT
    s.country_code,
    s.region_code,
    s.source_id,
    s.source_date,
    s.external_id,
    ST_Multi(
        CASE
            WHEN ST_SRID(s.geom) = 4326 THEN s.geom
            ELSE ST_Transform(s.geom, 4326)
        END
    )::geometry(MultiPolygon, 4326),
    r.id,
    s.created_at
FROM iris_staging.parcel AS s
JOIN iris_core.source_run AS r
  ON r.country_code = s.country_code
 AND r.source_id = s.source_id
 AND r.source_date = s.source_date
ON CONFLICT (country_code, source_id, parcel_ref) DO NOTHING;

-- Substation: the committed fixture is EPSG:25832, so this path explicitly
-- demonstrates CRS transformation to canonical EPSG:4326.
\echo '--> Promote iris_staging.substation into iris_core.substation'
INSERT INTO iris_core.substation (
    country_code,
    region_code,
    source_id,
    source_date,
    substation_ref,
    name,
    geom,
    source_run_id,
    created_at
)
SELECT
    s.country_code,
    s.region_code,
    s.source_id,
    s.source_date,
    s.external_id,
    s.name,
    (
        CASE
            WHEN ST_SRID(s.geom) = 4326 THEN s.geom
            ELSE ST_Transform(s.geom, 4326)
        END
    )::geometry(Point, 4326),
    r.id,
    s.created_at
FROM iris_staging.substation AS s
JOIN iris_core.source_run AS r
  ON r.country_code = s.country_code
 AND r.source_id = s.source_id
 AND r.source_date = s.source_date
ON CONFLICT (country_code, source_id, substation_ref) DO NOTHING;

-- Peatland: normalize to MultiPolygon/4326.
\echo '--> Promote iris_staging.peatland into iris_core.peatland'
INSERT INTO iris_core.peatland (
    country_code,
    region_code,
    source_id,
    source_date,
    peatland_ref,
    geom,
    source_run_id,
    created_at
)
SELECT
    s.country_code,
    s.region_code,
    s.source_id,
    s.source_date,
    s.external_id,
    ST_Multi(
        CASE
            WHEN ST_SRID(s.geom) = 4326 THEN s.geom
            ELSE ST_Transform(s.geom, 4326)
        END
    )::geometry(MultiPolygon, 4326),
    r.id,
    s.created_at
FROM iris_staging.peatland AS s
JOIN iris_core.source_run AS r
  ON r.country_code = s.country_code
 AND r.source_id = s.source_id
 AND r.source_date = s.source_date
ON CONFLICT (country_code, source_id, peatland_ref) DO NOTHING;

-- Screening layer: normalize to MultiPolygon/4326.
\echo '--> Promote iris_staging.screening_layer into iris_core.screening_layer'
INSERT INTO iris_core.screening_layer (
    country_code,
    region_code,
    source_id,
    source_date,
    layer_ref,
    layer_type,
    geom,
    source_run_id,
    created_at
)
SELECT
    s.country_code,
    s.region_code,
    s.source_id,
    s.source_date,
    s.external_id,
    s.layer_type,
    ST_Multi(
        CASE
            WHEN ST_SRID(s.geom) = 4326 THEN s.geom
            ELSE ST_Transform(s.geom, 4326)
        END
    )::geometry(MultiPolygon, 4326),
    r.id,
    s.created_at
FROM iris_staging.screening_layer AS s
JOIN iris_core.source_run AS r
  ON r.country_code = s.country_code
 AND r.source_id = s.source_id
 AND r.source_date = s.source_date
ON CONFLICT (country_code, source_id, layer_ref) DO NOTHING;

COMMIT;
