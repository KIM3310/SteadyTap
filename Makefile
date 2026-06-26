SHELL := /bin/sh

.PHONY: check-bootstrap-python verify verify-ios verify-backend

BOOTSTRAP_PYTHON ?= python3
BACKEND_VENV := backend/.venv
BACKEND_PYTHON := $(BACKEND_VENV)/bin/python
BACKEND_STAMP := $(BACKEND_VENV)/.installed-dev

verify: verify-ios verify-backend

verify-ios:
	swift build
	./scripts/verify_cli.sh

check-bootstrap-python:
	@$(BOOTSTRAP_PYTHON) -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)" >/dev/null 2>&1 || { \
		echo "Python 3.11+ is required to create $(BACKEND_VENV)."; \
		echo "Set BOOTSTRAP_PYTHON=/path/to/python3.11, for example: make BOOTSTRAP_PYTHON=/opt/homebrew/bin/python3.11 verify-backend"; \
		exit 1; \
	}

$(BACKEND_STAMP): backend/pyproject.toml backend/requirements.txt backend/requirements-dev.txt | check-bootstrap-python
	@if [ ! -x "$(BACKEND_PYTHON)" ] || ! $(BACKEND_PYTHON) -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 11) else 1)" >/dev/null 2>&1; then \
		rm -rf $(BACKEND_VENV); \
		$(BOOTSTRAP_PYTHON) -m venv $(BACKEND_VENV); \
	fi
	@if ! $(BACKEND_PYTHON) -m pip --version >/dev/null 2>&1; then \
		$(BACKEND_PYTHON) -m ensurepip --upgrade; \
	fi
	cd backend && .venv/bin/python -m pip install --upgrade pip && .venv/bin/python -m pip install -e ".[dev]"
	touch $(BACKEND_STAMP)

verify-backend: $(BACKEND_STAMP)
	cd backend && .venv/bin/python -m py_compile app/main.py && .venv/bin/python -m pytest -q tests/test_api.py tests/test_cors.py
