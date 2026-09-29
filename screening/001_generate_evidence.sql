BEGIN;

-- Positive parcel / peatland intersections.
\echo '--> Upsert peatland_intersection rows into iris_core.evidence'
INSERT INTO iris_core.evidence (
    country_code,
    parcel_id,
    source_run_id,
    evidence_type,
    text_value,
    uncertainty_note,
    created_at
)
SELECT
    p.country_code,
    p.id,
    pt.source_run_id,
    'peatland_intersection',
    pt.peatland_ref,
    'Preliminary screening result; requires project-specific verification.',
    GREATEST(p.created_at, pt.created_at)
FROM iris_core.parcel AS p
JOIN iris_core.peatland AS pt
  ON pt.country_code = p.country_code
 AND ST_Intersects(p.geom, pt.geom)
ON CONFLICT (
    country_code,
    parcel_id,
    source_run_id,
    evidence_type,
    text_value
)
DO UPDATE SET
    numeric_value = EXCLUDED.numeric_value,
    unit = EXCLUDED.unit,
    uncertainty_note = EXCLUDED.uncertainty_note,
    created_at = EXCLUDED.created_at;

-- Positive parcel / generic screening-layer intersections.
\echo '--> Upsert screening_layer_intersection rows into iris_core.evidence'
INSERT INTO iris_core.evidence (
    country_code,
    parcel_id,
    source_run_id,
    evidence_type,
    text_value,
    uncertainty_note,
    created_at
)
SELECT
    p.country_code,
    p.id,
    sl.source_run_id,
    'screening_layer_intersection',
    sl.layer_ref,
    'Preliminary screening result; requires project-specific verification.',
    GREATEST(p.created_at, sl.created_at)
FROM iris_core.parcel AS p
JOIN iris_core.screening_layer AS sl
  ON sl.country_code = p.country_code
 AND ST_Intersects(p.geom, sl.geom)
ON CONFLICT (
    country_code,
    parcel_id,
    source_run_id,
    evidence_type,
    text_value
)
DO UPDATE SET
    numeric_value = EXCLUDED.numeric_value,
    unit = EXCLUDED.unit,
    uncertainty_note = EXCLUDED.uncertainty_note,
    created_at = EXCLUDED.created_at;

-- Substations within the deterministic 500 m demonstration threshold.
\echo '--> Upsert substation_distance rows into iris_core.evidence'
INSERT INTO iris_core.evidence (
    country_code,
    parcel_id,
    source_run_id,
    evidence_type,
    numeric_value,
    unit,
    text_value,
    uncertainty_note,
    created_at
)
SELECT
    p.country_code,
    p.id,
    s.source_run_id,
    'substation_distance',
    ROUND(ST_Distance(p.geom::geography, s.geom::geography)::numeric, 2),
    'm',
    s.substation_ref,
    'Preliminary screening result; requires project-specific verification.',
    GREATEST(p.created_at, s.created_at)
FROM iris_core.parcel AS p
JOIN iris_core.substation AS s
  ON s.country_code = p.country_code
 AND ST_DWithin(p.geom::geography, s.geom::geography, 500)
ON CONFLICT (
    country_code,
    parcel_id,
    source_run_id,
    evidence_type,
    text_value
)
DO UPDATE SET
    numeric_value = EXCLUDED.numeric_value,
    unit = EXCLUDED.unit,
    uncertainty_note = EXCLUDED.uncertainty_note,
    created_at = EXCLUDED.created_at;

COMMIT;
