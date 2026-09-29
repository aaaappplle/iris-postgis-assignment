# Automated Tests

The automated SQL tests are split by responsibility:

- `001_constraints.sql` validates fixture promotion, required country codes,
  country-scoped uniqueness, and country-scoped foreign keys.
- `002_geometry.sql` validates canonical geometry types, SRID 4326, and the
  EPSG:25832 to EPSG:4326 transformation.
- `003_screening.sql` validates intersections, substation proximity, and the three
  deterministic evidence rows for `PARCEL-001`, including provenance and the absence
  of evidence for `PARCEL-002`.

Run the complete suite in numeric order:

```text
docker compose run --rm runner test
```

Run an individual file after a completed rebuild:

```text
docker compose run --rm --entrypoint psql runner -X -v ON_ERROR_STOP=1 -f tests/001_constraints.sql
```

Replace the filename with `002_geometry.sql` or `003_screening.sql` as needed.

Every file uses its own transaction and finishes with `ROLLBACK`, so test-only changes
do not alter fixture state. `ON_ERROR_STOP=1` makes any failed assertion return a
non-zero exit code.
