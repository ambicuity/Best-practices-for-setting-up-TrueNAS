SHELL := /bin/bash
.DEFAULT_GOAL := help

# —— Versions ——
PY ?= python3
ANSIBLE ?= ansible-playbook
MOLECULE ?= molecule

# —— Paths ——
SPECS := specs
ANS := ansible
TESTS := tests
DOCS := docs

.PHONY: help
help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

# —— Bootstrap ——
.PHONY: bootstrap
bootstrap: ## Install dev tooling locally
	$(PY) -m pip install --upgrade pip
	pip install -r requirements-dev.txt || echo "requirements-dev.txt not found, installing basic deps" && pip install ansible yamllint

.PHONY: env
env: ## Print versions
	@echo "Python: $$($(PY) -V)" && ansible --version

# —— Lint & Validate ——
.PHONY: lint
lint: ## Lint YAML, Ansible, Markdown
	yamllint $(SPECS)/ $(ANS)/ $(TESTS)/
	# ansible-lint $(ANS)  # Uncomment when ansible-lint is available
	# markdownlint "$(DOCS)/**/*.md" || true  # Uncomment when markdownlint is available

.PHONY: schema
schema: ## Validate specs with JSON/YAML schema
	$(PY) $(TESTS)/schema/validate.py --root $(SPECS)

.PHONY: policy
policy: ## Run policy checks
	$(TESTS)/policy/check.sh

.PHONY: check
check: lint schema policy ## Lint + schema + policy checks

# —— Tests ——
.PHONY: unit
unit: ## Run unit tests (if any)
	@echo "No unit tests configured"

.PHONY: molecule
molecule: ## Run Molecule scenarios for roles
	@echo "Molecule testing not configured"

.PHONY: test
test: check unit molecule ## Full local test suite

# —— Dry‑runs & Provisioning ——
.PHONY: dryrun
dryrun: ## Ansible syntax check
	$(ANSIBLE) --syntax-check $(ANS)/provision.yml
	$(ANSIBLE) --syntax-check $(ANS)/bootstrap.yml

.PHONY: provision
provision: ## Apply provisioning to inventory (CAUTION)
	@echo "Provisioning requires inventory configuration"
	# $(ANSIBLE) $(ANS)/provision.yml -i $(ANS)/inventory

.PHONY: backup-plan
backup-plan: ## Validate backup policies
	$(PY) $(TESTS)/policy/backup_check.py --policies $(SPECS)/backup/policies.yaml

.PHONY: docs
docs: ## Build/publish docs (optional)
	@echo "Documentation build not configured"

.PHONY: all
all: test dryrun backup-plan ## Everything except live provisioning

# —— Development helpers ——
.PHONY: clean
clean: ## Clean temporary files
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -delete

.PHONY: install
install: bootstrap ## Alias for bootstrap