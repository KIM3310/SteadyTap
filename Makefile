SHELL := /bin/sh

.PHONY: check-bootstrap-python generate-xcode-project verify verify-ios verify-app-store verify-backend verify-site deploy-pages

BOOTSTRAP_PYTHON ?= python3
BACKEND_VENV := backend/.venv
BACKEND_PYTHON := $(BACKEND_VENV)/bin/python
BACKEND_STAMP := $(BACKEND_VENV)/.installed-dev

verify: verify-ios verify-backend

verify-ios:
	swift build
	./scripts/verify_cli.sh

generate-xcode-project:
	@xcodegen_bin="$$(./scripts/install_xcodegen.sh)"; \
	"$$xcodegen_bin" generate

verify-app-store:
	python3 scripts/validate_app_store_readiness.py
	plutil -lint Resources/PrivacyInfo.xcprivacy
	plutil -lint Resources/AdditionalInfo.plist
	plutil -lint Resources/SteadyTap-Info.plist

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
	cd backend && .venv/bin/python -m pip check
	cd backend && .venv/bin/python -m compileall -q app tests
	cd backend && .venv/bin/python -m ruff check .
	cd backend && .venv/bin/python -m pytest -W error -q

verify-site:
	PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s scripts/tests -p "test_*.py"
	python3 scripts/validate_repository_surface.py
	python3 scripts/validate_architecture_blueprint.py
	python3 scripts/validate_app_store_readiness.py

deploy-pages: verify-site
	python3 scripts/pages_release.py prepare --revision "$$(git rev-parse HEAD)"
	npx --yes wrangler@4.114.0 pages deploy site --project-name steadytap --branch=main --commit-hash="$$(git rev-parse HEAD)"
	python3 scripts/pages_release.py verify --revision "$$(git rev-parse HEAD)" --origin https://steadytap.pages.dev
