#!/bin/sh
set -eu

help() {
    cat <<'EOF'
IRIS PostGIS Pilot
Usage: docker compose run --rm runner [command]

Commands:
  help      Show this help (default)
  reset     Drop iris_core and iris_staging
  migrate   Run schema migrations
  seed      Load staging fixtures
  promote   Promote staging data into core
  screening Persist deterministic spatial evidence
  rebuild   Reset, migrate, seed, promote, and screen
  verify    Run read-only verification queries
  test      Run the existing automated correctness tests
  all       Rebuild, verify, and test

WARNING: reset, rebuild, and all delete existing IRIS schema data.
EOF
}

run_sql() {
    description=$1
    file=$2
    printf '\n==> %s\n' "$description"
    psql -X -v ON_ERROR_STOP=1 -f "$file"
}

run() {
    case "$1" in
        reset)
            run_sql \
                'Reset: drop iris_core and iris_staging schemas' \
                scripts/reset.sql
            ;;
        migrate)
            run_sql \
                'Migration: enable the PostGIS extension' \
                migrations/001_extensions.sql
            run_sql \
                'Migration: create iris_staging and iris_core schemas' \
                migrations/002_schemas.sql
            run_sql \
                'Migration: create source-run provenance table' \
                migrations/003_source_run.sql
            run_sql \
                'Migration: create iris_staging tables' \
                migrations/004_staging_tables.sql
            run_sql \
                'Migration: create iris_core tables and geometry constraints' \
                migrations/005_core_tables.sql
            run_sql \
                'Migration: create spatial and evidence indexes' \
                migrations/006_indexes.sql
            ;;
        seed)
            run_sql \
                'Seed: load deterministic fixtures into iris_staging' \
                fixtures/001_seed_staging.sql
            ;;
        promote)
            run_sql \
                'Promotion: copy normalized records into iris_core' \
                fixtures/002_promote_to_core.sql
            ;;
        screening)
            run_sql \
                'Screening: persist deterministic spatial evidence' \
                screening/001_generate_evidence.sql
            ;;
        rebuild)
            printf '\n==> Rebuilding IRIS schemas (existing IRIS data will be deleted)\n'
            run reset
            run migrate
            run seed
            run promote
            run screening
            ;;
        verify)
            run_sql \
                'Verification: inspect schemas, rows, CRS, lineage, and evidence' \
                verification/001_basic_checks.sql
            run_sql \
                'Verification: validate spatial results and persisted evidence' \
                verification/002_spatial_checks.sql
            run_sql \
                'Verification: inspect indexes and representative query plans' \
                verification/003_index_usage.sql
            ;;
        test)
            run_sql \
                'Tests: validate database constraints' \
                tests/001_constraints.sql
            run_sql \
                'Tests: validate geometry and CRS contracts' \
                tests/002_geometry.sql
            run_sql \
                'Tests: validate spatial screening and evidence' \
                tests/003_screening.sql
            ;;
        all)
            run rebuild
            run verify
            run test
            ;;
        help)
            help
            ;;
        *)
            printf 'Unknown command: %s\n' "$1" >&2
            help >&2
            exit 2
            ;;
    esac
}

if [ "$#" -gt 1 ]; then
    help >&2
    exit 2
fi

command=${1:-help}
run "$command"
if [ "$command" != help ]; then
    printf '\n==> %s completed successfully\n' "$command"
fi
