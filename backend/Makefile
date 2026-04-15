.PHONY: check lint typecheck test install

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
	mypy src/ --strict

test:
	pytest tests/ -v --cov=src --cov-report=term-missing --cov-fail-under=80
