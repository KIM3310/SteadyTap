SHELL := /bin/sh

.PHONY: verify verify-ios verify-backend

verify: verify-ios verify-backend

verify-ios:
	swift build
	./scripts/verify_cli.sh

verify-backend:
	cd backend && . .venv/bin/activate && python -m py_compile app/main.py && pytest -q tests/test_api.py tests/test_cors.py
