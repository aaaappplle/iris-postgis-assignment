-- Index existence and representative query-plan verification.
--
-- The fixture set is intentionally tiny. PostgreSQL may legitimately prefer a
-- sequential scan, so this file demonstrates index existence and representative
-- EXPLAIN plans without asserting a specific planner choice.

\pset pager off

\echo '=== IRIS indexes ==='
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'iris_core'
  AND tablename IN (
      'parcel',
      'substation',
      'peatland',
      'screening_layer',
      'evidence'
  )
ORDER BY tablename, indexname;

\echo '=== EXPLAIN: parcel / peatland intersection ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    p.parcel_ref,
    pt.peatland_ref
FROM iris_core.parcel AS p
JOIN iris_core.peatland AS pt
  ON p.country_code = pt.country_code
 AND ST_Intersects(p.geom, pt.geom);

\echo '=== EXPLAIN: parcel / screening-layer intersection ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    p.parcel_ref,
    sl.layer_ref
FROM iris_core.parcel AS p
JOIN iris_core.screening_layer AS sl
  ON p.country_code = sl.country_code
 AND ST_Intersects(p.geom, sl.geom);

\echo '=== EXPLAIN: parcel / substation proximity ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT
    p.parcel_ref,
    s.substation_ref
FROM iris_core.parcel AS p
JOIN iris_core.substation AS s
  ON p.country_code = s.country_code
 AND ST_DWithin(
        p.geom::geography,
        s.geom::geography,
        500
    );
