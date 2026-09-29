# Verification

Run these files after migrations, seed, promotion, and screening.

Run all verification files in order:

```text
docker compose run --rm runner verify
```

The runner starts the database dependency if needed and waits for its healthcheck.
Run `docker compose run --rm runner all` first when starting from an empty database;
that command rebuilds the IRIS schemas and also runs verification and existing tests.

GNU Make users can optionally run the equivalent shortcut:

```text
make verify
```

The order is `001_basic_checks.sql`, `002_spatial_checks.sql`, then
`003_index_usage.sql`. SQL is read from the read-only project mount inside the runner;
no host PostgreSQL client or host-side input redirection is required.

The verification queries demonstrate canonical fields, promotion, CRS
normalization, spatial round-trip behavior, index existence, and representative
query plans.
