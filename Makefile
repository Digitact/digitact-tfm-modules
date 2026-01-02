.PHONY: help tf-fmt tf-fmt-check tf-validate tf-validate-all tf-lint tf-security tf-security-full tf-check tf-docs tf-test tf-test-naming tf-test-staging tf-test-production tf-test-failures install-hooks clean test-examples version-check version-current version-next release-check release release-major release-minor release-patch

# ============================================================================
# DIGITACT TERRAFORM MODULES - MAKEFILE
# ============================================================================
#
# This Makefile provides targets for developing, testing, and validating
# Terraform modules in the digitact-tfm-modules repository.
#
# Quick Start:
#   make install-hooks  - Install git hooks (pre-commit, pre-push)
#   make tf-check       - Run all quality checks
#   make tf-fmt         - Format all module files
#
# ============================================================================

# Terraform tool versions (Docker images) - all use latest stable
TERRAFORM_VERSION := latest
TFLINT_VERSION := latest
TRIVY_VERSION := latest
TFDOCS_VERSION := latest

# Terraform execution - set USE_DOCKER_TERRAFORM=1 to use Docker
# Default: use local terraform binary (faster for development)
# Docker: ensures version consistency and no local install required
ifdef USE_DOCKER_TERRAFORM
	TERRAFORM := docker run --rm -v $(PWD):/workspace -w /workspace hashicorp/terraform:$(TERRAFORM_VERSION)
else
	TERRAFORM := terraform
endif

# Module directories (automatically detected)
MODULE_DIRS := $(shell find . -maxdepth 2 -name "*.tf" -not -path "./.terraform/*" -not -path "./examples/*" -exec dirname {} \; | sort -u)

help: ## Show this help message
	@echo ''
	@echo 'Digitact Terraform Modules - Available targets:'
	@echo ''
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ''
	@echo 'Examples:'
	@echo '  make install-hooks   # Install git hooks for auto-formatting and validation'
	@echo '  make tf-check        # Run all quality checks'
	@echo '  make tf-fmt          # Format all Terraform files'
	@echo ''

# ============================================================================
# TERRAFORM FORMATTING
# ============================================================================

tf-fmt: ## Format all Terraform module files
	@echo "Formatting Terraform files..."
	@$(TERRAFORM) fmt -recursive .
	@echo "✅ All Terraform files formatted"

tf-fmt-check: ## Check Terraform formatting (no changes)
	@echo "Checking Terraform formatting..."
	@$(TERRAFORM) fmt -check -recursive .
	@echo "✅ Terraform formatting OK"

# ============================================================================
# TERRAFORM VALIDATION
# ============================================================================

tf-validate: ## Validate Terraform configuration (requires terraform init first)
	@echo "Validating Terraform modules..."
	@for module in $(MODULE_DIRS); do \
		echo "  Validating module: $$(basename $$module)"; \
		if [ ! -d "$$module/.terraform" ]; then \
			echo "    ⚠️  Module not initialized, running terraform init..."; \
			(cd $$module && $(TERRAFORM) init -backend=false >/dev/null 2>&1) || { echo "    ❌ Failed to initialize"; exit 1; }; \
		fi; \
		(cd $$module && $(TERRAFORM) validate >/dev/null 2>&1) || { echo "    ❌ Validation failed"; cd $$module && $(TERRAFORM) validate; exit 1; }; \
		echo "    ✅ Valid"; \
	done
	@echo "✅ All modules validated successfully"

tf-validate-all: ## Initialize and validate all modules from scratch
	@echo "Initializing and validating all Terraform modules..."
	@for module in $(MODULE_DIRS); do \
		echo "  Processing module: $$(basename $$module)"; \
		echo "    - Cleaning previous state..."; \
		rm -rf "$$module/.terraform" "$$module/.terraform.lock.hcl"; \
		echo "    - Initializing..."; \
		(cd $$module && $(TERRAFORM) init -backend=false >/dev/null 2>&1) || { echo "    ❌ Failed to initialize"; exit 1; }; \
		echo "    - Validating..."; \
		(cd $$module && $(TERRAFORM) validate >/dev/null 2>&1) || { echo "    ❌ Validation failed"; cd $$module && $(TERRAFORM) validate; exit 1; }; \
		echo "    ✅ Valid"; \
	done
	@echo "✅ All modules initialized and validated successfully"

# ============================================================================
# TERRAFORM LINTING
# ============================================================================

tf-lint: ## Run tflint on all modules (via Docker)
	@echo "Running tflint via Docker..."
	@if [ ! -f ".tflint.hcl" ]; then \
		echo "⚠️  .tflint.hcl not found"; \
		echo "   Creating basic .tflint.hcl configuration..."; \
		echo 'plugin "terraform" {\n  enabled = true\n  preset  = "recommended"\n}\n\nplugin "aws" {\n  enabled = true\n  version = "0.35.0"\n  source  = "github.com/terraform-linters/tflint-ruleset-aws"\n}' > .tflint.hcl; \
	fi
	@mkdir -p $(HOME)/.cache/tflint-docker
	@docker run --rm \
		-v $(PWD):/workspace \
		-v $(HOME)/.cache/tflint-docker:/root/.tflint.d \
		-w /workspace \
		ghcr.io/terraform-linters/tflint:$(TFLINT_VERSION) \
		--init
	@docker run --rm \
		-v $(PWD):/workspace \
		-v $(HOME)/.cache/tflint-docker:/root/.tflint.d \
		-w /workspace \
		ghcr.io/terraform-linters/tflint:$(TFLINT_VERSION) \
		--recursive --format=compact --minimum-failure-severity=error
	@echo "✅ tflint checks passed"

# ============================================================================
# SECURITY SCANNING
# ============================================================================

tf-security: ## Run Trivy security scan (HIGH/CRITICAL only, via Docker)
	@echo "Running Trivy security scan via Docker..."
	@docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		aquasec/trivy:$(TRIVY_VERSION) \
		config . \
		--severity HIGH,CRITICAL \
		--tf-exclude-downloaded-modules
	@echo "✅ Trivy security checks passed"

tf-security-full: ## Run Trivy with all severity levels (via Docker)
	@echo "Running Trivy full security scan via Docker..."
	@docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		aquasec/trivy:$(TRIVY_VERSION) \
		config . \
		--tf-exclude-downloaded-modules
	@echo "✅ Trivy full scan complete"

# ============================================================================
# COMPREHENSIVE CHECKS
# ============================================================================

tf-check: tf-fmt-check tf-validate tf-security ## Run all Terraform checks (format, validate, security)
	@echo ""
	@echo "✅ All Terraform module checks passed!"
	@echo ""
	@echo "Checks completed:"
	@echo "  ✅ Formatting (terraform fmt)"
	@echo "  ✅ Validation (terraform validate)"
	@echo "  ✅ Security (Trivy HIGH/CRITICAL)"
	@echo ""
	@echo "Optional: Run 'make tf-lint' for additional linting"

# ============================================================================
# DOCUMENTATION
# ============================================================================

tf-docs: ## Generate README.md for all modules and main repo (via Docker)
	@echo "Generating module documentation via terraform-docs (Docker)..."
	@echo ""
	@echo "Updating main README.md..."
	@docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		quay.io/terraform-docs/terraform-docs:$(TFDOCS_VERSION) \
		markdown table \
		--output-file README.md \
		--output-mode inject \
		--hide-empty \
		.
	@echo "  ✅ Main README.md updated"
	@echo ""
	@echo "Updating module READMEs..."
	@for module in $(MODULE_DIRS); do \
		echo "  Generating docs for: $$(basename $$module)"; \
		docker run --rm \
			-v $(PWD):/workspace \
			-w /workspace \
			quay.io/terraform-docs/terraform-docs:$(TFDOCS_VERSION) \
			markdown table \
			--output-file README.md \
			--output-mode inject \
			--hide-empty \
			$$module; \
		echo "    ✅ $$(basename $$module)/README.md updated"; \
	done
	@echo ""
	@echo "✅ All documentation generated successfully"
	@echo ""
	@echo "Note: Ensure your README.md files have terraform-docs markers:"
	@echo "  <!-- BEGIN_TF_DOCS -->"
	@echo "  <!-- END_TF_DOCS -->"

tf-docs-check: ## Check if documentation is up to date
	@echo "Checking if documentation is up to date..."
	@docker run --rm \
		-v $(PWD):/workspace \
		-w /workspace \
		quay.io/terraform-docs/terraform-docs:$(TFDOCS_VERSION) \
		markdown table \
		--output-check \
		.
	@echo "✅ Documentation is up to date"

# ============================================================================
# GIT HOOKS
# ============================================================================

install-hooks: ## Install Git hooks (pre-commit, pre-push)
	@if [ ! -d .git ]; then \
		echo "⚠️  Not a git repository - skipping hook installation"; \
		exit 0; \
	fi
	@echo "Installing Git hooks..."
	@if [ -f .git/hooks/pre-commit ] && cmp -s scripts/pre-commit.template .git/hooks/pre-commit; then \
		echo "✅ Pre-commit hook already installed"; \
	else \
		cp scripts/pre-commit.template .git/hooks/pre-commit; \
		chmod +x .git/hooks/pre-commit; \
		echo "✅ Pre-commit hook installed (auto-formats Terraform)"; \
	fi
	@if [ -f .git/hooks/pre-push ] && cmp -s scripts/pre-push.template .git/hooks/pre-push; then \
		echo "✅ Pre-push hook already installed"; \
	else \
		cp scripts/pre-push.template .git/hooks/pre-push; \
		chmod +x .git/hooks/pre-push; \
		echo "✅ Pre-push hook installed (runs quality checks)"; \
	fi
	@echo ""
	@echo "Hooks installed:"
	@echo "  pre-commit: Auto-formats Terraform module files"
	@echo "  pre-push:   Runs validation, linting, and security scans"
	@echo ""
	@echo "To skip hooks: git commit/push --no-verify"

# ============================================================================
# CLEANUP
# ============================================================================

clean: ## Clean Terraform cache and lock files from all modules
	@echo "Cleaning Terraform cache files..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@echo "✅ Clean complete"

# ============================================================================
# TERRAFORM TESTING
# ============================================================================

tf-test: ## Run all Terraform tests (naming, staging, production, failures)
	@echo "Running all Terraform tests..."
	@echo ""
	@$(MAKE) tf-test-naming
	@echo ""
	@$(MAKE) tf-test-staging
	@echo ""
	@$(MAKE) tf-test-production
	@echo ""
	@$(MAKE) tf-test-failures
	@echo ""
	@echo "✅ All Terraform tests passed!"
	@echo ""
	@echo "Test suites completed:"
	@echo "  ✅ Naming validation (10 tests)"
	@echo "  ✅ Staging environment (9 scenarios)"
	@echo "  ✅ Production environment (13 scenarios)"
	@echo "  ✅ Failure scenarios (19 negative tests)"
	@echo ""
	@echo "Total: 51 tests (32 positive + 19 negative)"
	@echo ""

tf-test-naming: ## Run naming validation tests
	@echo "Running naming validation tests..."
	@if [ ! -d "labelling/tests" ]; then \
		echo "❌ Test directory not found: labelling/tests"; \
		exit 1; \
	fi
	@cd labelling && $(TERRAFORM) init -backend=false >/dev/null 2>&1 || { echo "❌ Failed to initialize module"; exit 1; }
	@cd labelling && $(TERRAFORM) test -filter=tests/naming_validation.tftest.hcl -verbose
	@echo "✅ Naming validation tests passed"

tf-test-staging: ## Run staging environment tests
	@echo "Running staging environment tests..."
	@if [ ! -d "labelling/tests" ]; then \
		echo "❌ Test directory not found: labelling/tests"; \
		exit 1; \
	fi
	@cd labelling && $(TERRAFORM) init -backend=false >/dev/null 2>&1 || { echo "❌ Failed to initialize module"; exit 1; }
	@cd labelling && $(TERRAFORM) test -filter=tests/staging_environment.tftest.hcl -verbose
	@echo "✅ Staging environment tests passed"

tf-test-production: ## Run production environment tests
	@echo "Running production environment tests..."
	@if [ ! -d "labelling/tests" ]; then \
		echo "❌ Test directory not found: labelling/tests"; \
		exit 1; \
	fi
	@cd labelling && $(TERRAFORM) init -backend=false >/dev/null 2>&1 || { echo "❌ Failed to initialize module"; exit 1; }
	@cd labelling && $(TERRAFORM) test -filter=tests/production_environment.tftest.hcl -verbose
	@echo "✅ Production environment tests passed"

tf-test-failures: ## Run failure scenarios (negative) tests
	@echo "Running failure scenarios tests..."
	@if [ ! -d "labelling/tests" ]; then \
		echo "❌ Test directory not found: labelling/tests"; \
		exit 1; \
	fi
	@cd labelling && $(TERRAFORM) init -backend=false >/dev/null 2>&1 || { echo "❌ Failed to initialize module"; exit 1; }
	@cd labelling && $(TERRAFORM) test -filter=tests/failure_scenarios.tftest.hcl -verbose
	@echo "✅ Failure scenarios tests passed (19 negative tests)"

test-examples: ## Test all example configurations (if examples/ directory exists)
	@echo "Testing example configurations..."
	@if [ ! -d "examples" ]; then \
		echo "⚠️  No examples/ directory found"; \
		echo "   Create examples/ directory with test configurations"; \
		exit 0; \
	fi
	@for example in $$(find examples -maxdepth 1 -type d -not -path examples); do \
		if [ -f "$$example/main.tf" ]; then \
			echo "  Testing: $$(basename $$example)"; \
			echo "    - Initializing..."; \
			(cd $$example && $(TERRAFORM) init -backend=false >/dev/null 2>&1) || { echo "    ❌ Init failed"; exit 1; }; \
			echo "    - Validating..."; \
			(cd $$example && $(TERRAFORM) validate >/dev/null 2>&1) || { echo "    ❌ Validation failed"; exit 1; }; \
			echo "    ✅ Valid"; \
		fi; \
	done
	@echo "✅ All examples validated successfully"

# ============================================================================
# MODULE RELEASE & VERSIONING
# ============================================================================
# This repository uses semantic versioning with git tags.
# See VERSIONING.md for detailed documentation.
#
# Quick Start:
#   make release VERSION=v1.0.0        # Create a new release
#   make release-minor                  # Auto-increment minor version
#   make release-patch                  # Auto-increment patch version
# ============================================================================

version-check: ## Check that all modules have valid version constraints
	@echo "Checking module version constraints..."
	@for module in $(MODULE_DIRS); do \
		if [ -f "$$module/versions.tf" ]; then \
			echo "  ✅ $$(basename $$module) has versions.tf"; \
		else \
			echo "  ⚠️  $$(basename $$module) missing versions.tf"; \
		fi; \
	done

version-current: ## Show current version (latest git tag)
	@CURRENT_VERSION=$$(git describe --tags --abbrev=0 2>/dev/null || echo "none"); \
	if [ "$$CURRENT_VERSION" = "none" ]; then \
		echo "📦 No releases yet - this will be the first release"; \
		echo "   Recommended: make release VERSION=v1.0.0"; \
	else \
		echo "📦 Current version: $$CURRENT_VERSION"; \
		echo "   Created: $$(git log -1 --format=%ai $$CURRENT_VERSION)"; \
		echo "   Commits since: $$(git rev-list $$CURRENT_VERSION..HEAD --count)"; \
	fi

version-next: ## Calculate next semantic version
	@CURRENT=$$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"); \
	echo "Current version: $$CURRENT"; \
	CURRENT_NO_V=$${CURRENT#v}; \
	MAJOR=$$(echo $$CURRENT_NO_V | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT_NO_V | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT_NO_V | cut -d. -f3 | cut -d- -f1); \
	NEXT_MAJOR=$$((MAJOR + 1)); \
	NEXT_MINOR=$$((MINOR + 1)); \
	NEXT_PATCH=$$((PATCH + 1)); \
	echo ""; \
	echo "Next versions:"; \
	echo "  Major (breaking changes): v$$NEXT_MAJOR.0.0"; \
	echo "  Minor (new features):     v$$MAJOR.$$NEXT_MINOR.0"; \
	echo "  Patch (bug fixes):        v$$MAJOR.$$MINOR.$$NEXT_PATCH"

release-check: ## Pre-release validation (run all quality checks)
	@echo "Running pre-release validation..."
	@$(MAKE) ci-check
	@echo ""
	@echo "✅ All quality checks passed - ready for release!"

release: release-check ## Create a new release (usage: make release VERSION=v1.0.0)
	@if [ -z "$(VERSION)" ]; then \
		echo "❌ VERSION is required"; \
		echo ""; \
		echo "Usage:"; \
		echo "  make release VERSION=v1.0.0      # Explicit version"; \
		echo "  make release-major               # Auto-increment major"; \
		echo "  make release-minor               # Auto-increment minor"; \
		echo "  make release-patch               # Auto-increment patch"; \
		echo ""; \
		exit 1; \
	fi
	@if ! echo "$(VERSION)" | grep -qE "^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.-]+)?$$"; then \
		echo "❌ Invalid version format: $(VERSION)"; \
		echo "   Expected: v<major>.<minor>.<patch> (e.g., v1.0.0, v1.2.3-beta.1)"; \
		exit 1; \
	fi
	@if git rev-parse "$(VERSION)" >/dev/null 2>&1; then \
		echo "❌ Tag $(VERSION) already exists!"; \
		echo "   Use: git tag -d $(VERSION) to delete locally"; \
		echo "   Use: git push origin :refs/tags/$(VERSION) to delete remotely"; \
		exit 1; \
	fi
	@echo "Creating release: $(VERSION)"
	@echo ""
	@git tag -a "$(VERSION)" -m "Release $(VERSION)"
	@echo "✅ Tag created: $(VERSION)"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Push tag:    git push origin $(VERSION)"
	@echo "  2. Or trigger GitHub Actions release workflow for automated release"
	@echo ""
	@echo "To use this version in Terraform:"
	@echo '  source = "github.com/$${ORG}/$${REPO}//labelling?ref=$(VERSION)"'

release-major: ## Auto-increment major version (breaking changes)
	@CURRENT=$$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"); \
	CURRENT_NO_V=$${CURRENT#v}; \
	MAJOR=$$(echo $$CURRENT_NO_V | cut -d. -f1); \
	NEXT_MAJOR=$$((MAJOR + 1)); \
	NEW_VERSION="v$$NEXT_MAJOR.0.0"; \
	echo "Incrementing major version: $$CURRENT → $$NEW_VERSION"; \
	$(MAKE) release VERSION=$$NEW_VERSION

release-minor: ## Auto-increment minor version (new features)
	@CURRENT=$$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"); \
	CURRENT_NO_V=$${CURRENT#v}; \
	MAJOR=$$(echo $$CURRENT_NO_V | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT_NO_V | cut -d. -f2); \
	NEXT_MINOR=$$((MINOR + 1)); \
	NEW_VERSION="v$$MAJOR.$$NEXT_MINOR.0"; \
	echo "Incrementing minor version: $$CURRENT → $$NEW_VERSION"; \
	$(MAKE) release VERSION=$$NEW_VERSION

release-patch: ## Auto-increment patch version (bug fixes)
	@CURRENT=$$(git describe --tags --abbrev=0 2>/dev/null || echo "v0.0.0"); \
	CURRENT_NO_V=$${CURRENT#v}; \
	MAJOR=$$(echo $$CURRENT_NO_V | cut -d. -f1); \
	MINOR=$$(echo $$CURRENT_NO_V | cut -d. -f2); \
	PATCH=$$(echo $$CURRENT_NO_V | cut -d. -f3 | cut -d- -f1); \
	NEXT_PATCH=$$((PATCH + 1)); \
	NEW_VERSION="v$$MAJOR.$$MINOR.$$NEXT_PATCH"; \
	echo "Incrementing patch version: $$CURRENT → $$NEW_VERSION"; \
	$(MAKE) release VERSION=$$NEW_VERSION

# ============================================================================
# DEVELOPMENT WORKFLOW
# ============================================================================

dev-setup: install-hooks ## Set up development environment
	@echo "Setting up development environment..."
	@echo "✅ Development environment ready"
	@echo ""
	@echo "Next steps:"
	@echo "  1. Create a new module in a subdirectory"
	@echo "  2. Run 'make tf-check' to validate"
	@echo "  3. Commit your changes (pre-commit will auto-format)"
	@echo "  4. Push your changes (pre-push will run quality checks)"

ci-check: tf-fmt-check tf-validate-all tf-security tf-test ## Run all checks suitable for CI/CD
	@echo ""
	@echo "✅ All CI checks passed!"
	@echo ""
	@echo "Checks completed:"
	@echo "  ✅ Formatting (terraform fmt)"
	@echo "  ✅ Validation (terraform validate)"
	@echo "  ✅ Security (Trivy HIGH/CRITICAL)"
	@echo "  ✅ Tests (51 total: 32 positive + 19 negative tests)"
	@echo ""

# ============================================================================
# MODULE LIST
# ============================================================================

list-modules: ## List all modules in the repository
	@echo "Modules in this repository:"
	@for module in $(MODULE_DIRS); do \
		echo "  - $$(basename $$module)"; \
	done
