.PHONY: frontend-check typecheck lint test

frontend-check: typecheck lint test
	@echo "✅ 前端全部检查通过"

typecheck:
	npx tsc --noEmit

lint:
	npx eslint src/ --max-warnings 0

test:
	npx vitest run --coverage
