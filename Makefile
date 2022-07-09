#* Variables
SHELL := /usr/bin/env bash
PYTHON := python
PYTHONPATH := `pwd`
POETRY := $(if $([[ -x "$(command -v poetry)" ]]),poetry,"${HOME}/.local/bin/poetry")

#* Docker variables
IMAGE := antispoofnet
VERSION := latest

#* Poetry
.PHONY: poetry-download
poetry-download:
	curl -sSL https://install.python-poetry.org/ | $(PYTHON) -

.PHONY: poetry-remove
poetry-remove:
	curl -sSL https://install.python-poetry.org/ | $(PYTHON) - --uninstall

#* Installation
.PHONY: install
install:
	$(POETRY) lock -n && $(POETRY) export --without-hashes > requirements.txt
	$(POETRY) install -n
	-$(POETRY) run mypy --install-types --non-interactive ./

.PHONY: pre-commit-install
pre-commit-install:
	$(POETRY) run pre-commit install

#* Formatters
.PHONY: codestyle
codestyle:
	$(POETRY) run pyupgrade --exit-zero-even-if-changed --py39-plus **/*.py
	$(POETRY) run isort --settings-path pyproject.toml ./
	$(POETRY) run black --config pyproject.toml ./

.PHONY: formatting
formatting: codestyle

#* Linting
.PHONY: test
test:
	PYTHONPATH=$(PYTHONPATH) $(POETRY) run pytest -c pyproject.toml --cov-report=html --cov=antispoofnet tests/
	$(POETRY) run coverage-badge -o assets/images/coverage.svg -f

.PHONY: check-codestyle
check-codestyle:
	$(POETRY) run isort --diff --check-only --settings-path pyproject.toml ./
	$(POETRY) run black --diff --check --config pyproject.toml ./
	$(POETRY) run darglint --verbosity 2 antispoofnet tests

.PHONY: mypy
mypy:
	$(POETRY) run mypy --config-file pyproject.toml ./

.PHONY: lint
lint: test check-codestyle mypy

.PHONY: update-dev-deps
update-dev-deps:
	$(POETRY) add -D darglint@latest "isort[colors]@latest" mypy@latest pre-commit@latest pydocstyle@latest pylint@latest pytest@latest pyupgrade@latest coverage@latest coverage-badge@latest pytest-html@latest pytest-cov@latest
	$(POETRY) add -D --allow-prereleases black@latest

#* Docker
# Example: make docker-build VERSION=latest
# Example: make docker-build IMAGE=some_name VERSION=0.1.0
.PHONY: docker-build
docker-build:
	@echo Building docker $(IMAGE):$(VERSION) ...
	docker build \
		-t $(IMAGE):$(VERSION) . \
		-f ./docker/Dockerfile --no-cache

# Example: make docker-remove VERSION=latest
# Example: make docker-remove IMAGE=some_name VERSION=0.1.0
.PHONY: docker-remove
docker-remove:
	@echo Removing docker $(IMAGE):$(VERSION) ...
	docker rmi -f $(IMAGE):$(VERSION)

#* Cleaning
.PHONY: pycache-remove
pycache-remove:
	find . | grep -E "(__pycache__|\.pyc|\.pyo$$)" | xargs rm -rf

.PHONY: dsstore-remove
dsstore-remove:
	find . | grep -E ".DS_Store" | xargs rm -rf

.PHONY: mypycache-remove
mypycache-remove:
	find . | grep -E ".mypy_cache" | xargs rm -rf

.PHONY: ipynbcheckpoints-remove
ipynbcheckpoints-remove:
	find . | grep -E ".ipynb_checkpoints" | xargs rm -rf

.PHONY: pytestcache-remove
pytestcache-remove:
	find . | grep -E ".pytest_cache" | xargs rm -rf

.PHONY: build-remove
build-remove:
	rm -rf build/

.PHONY: coverage-remove
coverage-remove:
	rm -rf htmlcov/ .coverage

.PHONY: cleanup
cleanup: pycache-remove dsstore-remove mypycache-remove ipynbcheckpoints-remove pytestcache-remove coverage-remove
