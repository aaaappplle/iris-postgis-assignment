# Data Contracts

The pilot treats completeness, CRS, units, source date, and uncertainty as explicit
data contracts.

## Completeness

Every persisted business entity must have a non-null `country_code`.

Records missing `country_code` are rejected by staging `NOT NULL` constraints during
insertion.

Core required fields include, where applicable:

- `country_code`
- `source_id`
- `source_date`
- canonical business reference
- `geom`
- `source_run_id`
- `created_at`

Optional attributes such as `region_code` or descriptive names may remain nullable
if not guaranteed by the source.

## Canonical Field Names

The canonical names used by the pilot include:

```text
geom
country_code
region_code
source_id
source_date
created_at
```

The core geometry column is named `geom`.

## Geometry Contracts

| Entity | Geometry Type | Core CRS |
|---|---|---|
| parcel | MultiPolygon | EPSG:4326 |
| substation | Point | EPSG:4326 |
| peatland | MultiPolygon | EPSG:4326 |
| screening_layer | MultiPolygon | EPSG:4326 |

Core geometry must have the declared type and SRID, be valid, and be non-empty.
Constraint violations abort promotion; geometry is not silently repaired.

## CRS

Staging geometry may preserve the incoming source CRS.

Core geometry is normalized to EPSG:4326.

One deterministic substation fixture uses EPSG:25832 and is transformed during promotion:

```sql
ST_Transform(geom, 4326)
```

`ST_SetSRID` declares a geometry's CRS metadata.

`ST_Transform` converts coordinate values between CRSs.

These operations are not interchangeable.

## Units

Derived numeric evidence carries an explicit unit.

The persisted `substation_distance` evidence uses `m`. Intersection evidence is
represented by its evidence type and related feature reference, so its numeric value
and unit remain null.

Examples:

```text
pilot substation distance:
numeric_value = 143.38
unit = m

illustrative area evidence:
numeric_value = 1200
unit = m2

illustrative overlap evidence:
numeric_value = 23.4
unit = percent
```

Metric distance calculations do not use EPSG:4326 degrees directly.

## Source Date

`source_date` represents the date or version of the source dataset.

For the deterministic fixtures, `created_at` is supplied by staging and preserved on
the promoted core feature. It therefore represents the fixture/source record timestamp,
not the wall-clock time when the rebuild runs.

They intentionally represent different concepts.

A logical source run uses the earliest staging creation timestamp represented by
its country/source/date group when first promoted. Spatial entities must match their
source run's country, source ID, and source date.

Evidence `created_at` is the later of the screened parcel timestamp and the matched
feature timestamp. This keeps regenerated fixture evidence deterministic.

## Uncertainty

Spatial screening results are preliminary evidence. Every persisted pilot evidence row
uses:

```text
uncertainty_note = Preliminary screening result; requires project-specific verification.
```

to record relevant assumptions or limitations.

Evidence `text_value` stores the related feature reference. Its `source_run_id` points
to that feature's country-scoped source run, while `parcel_id` identifies the screened
parcel.

The pilot does not claim authoritative confirmation of permitting, ownership,
grid capacity, planning eligibility, or construction readiness.
