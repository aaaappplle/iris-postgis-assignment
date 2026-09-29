# Deliberate Simplifications and Production Evolution

The assignment intentionally implements a small, reproducible pilot rather than a
complete production ingestion and screening platform.

## Synthetic Fixtures

### Pilot

The repository uses small deterministic synthetic fixtures.

Fixtures are treated as immutable. Promotion is insert-only: conflicts retain the
existing core business record. Repeating promotion does not refresh changed source
data; rebuild after changing fixtures.

### Production evolution

Production would use source-specific adapters for real cadastral, grid,
environmental, peatland, and screening datasets.

Incremental ingestion would need an explicit update/versioning policy.

---

## Minimal Staging Model

### Pilot

Staging includes only the fields needed to demonstrate the required data flow.

### Production evolution

Production staging could preserve:

- raw payloads
- source filenames or URIs
- original source identifiers
- original CRS metadata
- validation status
- error/rejection reasons
- ingestion diagnostics
- source-specific attributes

A dedicated reject/dead-letter store could capture records that fail mandatory
validation such as missing `country_code`.

---

## Minimal Source-Run Metadata

### Pilot

`source_run` stores only minimal provenance.

One country/source/date group represents one logical run. Its timestamp is the earliest
staging creation time in that group when first promoted, rather than an execution time
for each ingestion attempt. Spatial entity foreign keys enforce matching country,
source ID, and source date.

### Production evolution

A production model could add:

- independent run UUID
- run status
- started/finished timestamps
- row counts
- rejected-row counts
- source URI
- checksum
- loader version
- error diagnostics

It could also support multiple ingestion attempts for the same source/date.

---

## Simplified CRS Strategy

### Pilot

Core geometry is normalized to EPSG:4326.

### Production evolution

Production metric analysis could select projected CRSs dynamically based on country,
region, geometry extent, and operation type.

---

## Demonstration Screening Rules

### Pilot

The repository demonstrates spatial predicates and deterministic thresholds.

### Production evolution

Production rules would likely be:

- configurable
- versioned
- auditable
- tied to explicit commercial, environmental, or regulatory assumptions

---

## Minimal Evidence Model

### Pilot

The pilot persists a compact deterministic set of positive screening results for the
fixture parcel. Screening uses an idempotent upsert keyed by parcel, related source run,
evidence type, and related feature reference. It does not remove stale results during
a standalone rerun; fixture changes require a rebuild.

### Production evolution

Production evidence could add:

- rule/version provenance
- related source-feature references
- confidence level
- severity
- structured calculation metadata
- richer uncertainty representation

---

## Small Test Dataset

### Pilot

The committed dataset prioritizes determinism and readability.

Automated tests are split by database constraints, geometry/CRS behavior, and spatial
screening/evidence. Automated rejection coverage for the geometry validity/non-empty
checks and same-country provenance constraints is deferred; these changes do not claim
that additional coverage.

### Production evolution

Production validation would additionally cover:

- invalid geometry
- empty geometry
- mixed CRS inputs
- topology edge cases
- multiple countries
- very large geometries
- bulk ingestion
- performance/load testing

---

## Pilot-Focused Indexing

### Pilot

Indexes support the demonstrated query paths.

### Production evolution

Production indexing would be tuned using:

- real data volumes
- real query plans
- actual access patterns
- partitioning strategy
- materialized results where justified

---

## SQL-First Scope

### Pilot

The solution stays SQL-first and avoids unnecessary application layers.

### Production evolution

A production system might add ingestion services, orchestration, APIs, monitoring,
and operational tooling only when justified by actual system requirements.
