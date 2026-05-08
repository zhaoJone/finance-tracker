.PHONY: docker-build docker-up docker-down docker-logs docker-clean

docker-build:
	docker compose build --no-cache

docker-up:
	docker compose up -d
	@echo "Running database migrations..."
	@docker compose exec -T backend alembic upgrade head && echo " - Migrations OK" || echo " - Migrations FAILED"
	@echo "Services started. Waiting for health checks..."
	@sleep 10
	@curl -f http://localhost/api/health && echo " - Backend health OK" || echo " - Backend health FAILED"
	@curl -f http://localhost/ && echo " - Frontend OK" || echo " - Frontend FAILED"

docker-down:
	docker compose down

docker-logs:
	docker compose logs -f

docker-clean:
	docker compose down -v --rmi local
	rm -rf ./data
