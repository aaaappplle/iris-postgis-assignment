SHELL := /bin/sh

DB_SERVICE := db
DB_USER := iris
DB_NAME := iris

.PHONY: help up down status psql wait-db reset migrate seed promote screening rebuild verify test all

help:
	@echo "IRIS PostGIS Pilot (optional Make shortcuts)"
	@echo "Docker-only workflow: docker compose run --rm runner all"
	@echo ""
	@echo "Available commands:"
	@echo "  make up       Start PostgreSQL/PostGIS and wait for readiness"
	@echo "  make down     Stop Docker Compose services"
	@echo "  make status   Show Docker Compose service status"
	@echo "  make psql     Open an interactive psql session"
	@echo "  make wait-db  Start the database if needed and wait for readiness"
	@echo "  make reset    Drop iris_core and iris_staging"
	@echo "  make migrate  Run all SQL migrations"
	@echo "  make seed     Load deterministic staging fixtures"
	@echo "  make promote  Promote staging data into iris_core"
	@echo "  make screening Persist deterministic spatial evidence"
	@echo "  make rebuild  Reset, migrate, seed, promote, and screen"
	@echo "  make verify   Run verification queries"
	@echo "  make test     Run existing automated correctness tests"
	@echo "  make all      Rebuild, verify, and test"

up: wait-db

wait-db:
	docker compose up -d --wait --wait-timeout 60 $(DB_SERVICE)

down:
	docker compose down

status:
	docker compose ps

psql: wait-db
	docker compose exec $(DB_SERVICE) psql -X -U $(DB_USER) -d $(DB_NAME)

reset migrate seed promote screening rebuild verify test all:
	docker compose run --rm runner $@
