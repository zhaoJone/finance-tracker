.PHONY: check lint typecheck test install migrate migrate-new migrate-down migrate-history

install:
	pip install -e ".[dev]"

check: lint typecheck test
	@echo "✅ 后端全部检查通过"

lint:
	@echo "--- 层级检查 ---"
	cd lints && python check_layers.py
	@echo "--- 响应格式检查 ---"
	cd lints && python check_response_format.py
	@echo "--- Ruff ---"
	ruff check src/

typecheck:
	python -m mypy src/ --strict

test:
	pytest tests/ -v --cov=src --cov-report=term-missing --cov-fail-under=80

migrate:
	alembic upgrade head

migrate-new:
	@if [ -z "$(msg)" ]; then echo "Usage: make migrate-new msg='description'"; exit 1; fi
	alembic revision --autogenerate -m "$(msg)"

migrate-down:
	alembic downgrade -1

migrate-history:
	alembic history
