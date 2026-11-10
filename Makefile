.PHONY: dev prod down logs clean migrate backend-shell db-shell ps restart

# ============================================================
# InterConnect Burundi — Makefile
# ============================================================

## Start all services in development mode (foreground)
dev:
	docker-compose up --build

## Start all services in production mode (background)
prod:
	docker-compose -f docker-compose.yml up -d --build

## Stop all services
down:
	docker-compose down

## Stop services and remove volumes (⚠ DATA LOSS)
clean:
	docker-compose down -v --rmi local

## Follow logs of all services
logs:
	docker-compose logs -f

## Show running containers
ps:
	docker-compose ps

## Restart all services
restart:
	docker-compose restart

## Run initial DB migration manually (if auto-init didn't trigger)
migrate:
	docker-compose exec postgres psql -U $${POSTGRES_USER} -d $${POSTGRES_DB} -f /docker-entrypoint-initdb.d/001_initial_schema.sql

## Open a shell inside the backend container
backend-shell:
	docker-compose exec backend sh

## Open a psql shell in the postgres container
db-shell:
	docker-compose exec postgres psql -U $${POSTGRES_USER} -d $${POSTGRES_DB}

## Open a redis-cli shell
redis-shell:
	docker-compose exec redis redis-cli -a $${REDIS_PASSWORD}

## Pull latest images without rebuilding
pull:
	docker-compose pull
