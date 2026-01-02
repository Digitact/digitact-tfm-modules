# Digitact Terraform Modules

Shared Terraform modules for Digitact infrastructure across all products, enforcing consistent naming conventions, tagging standards, and infrastructure patterns.

## Overview

This repository contains reusable Terraform modules used across Digitact's product portfolio, including Winehub, Perkrunner, and future products. These modules enforce:

- **Consistent naming conventions** following `{product}-{env}-{app}-{resource}` pattern
- **Mandatory tagging** for governance and cost allocation (6 required tags)
- **Security best practices** validated by automated scans
- **Quality gates** enforced through git hooks and CI/CD

## Available Modules

### labelling

**Path:** `labelling/`

Generates compliant resource names and mandatory tags according to Digitact's NEW_ACCOUNT_STANDARDS.md.

**Features:**
- Standardized resource naming for 95+ AWS resource types across 11 categories
- Automatic generation of 6 mandatory tags (Application, Environment, Criticality, Backup, ManagedBy, Layer)
- Special handling for resources requiring `Name` tag (VPC, subnets, security groups, etc.)
- Environment-specific configurations
- Support for additional custom tags
- Comprehensive coverage including compute, networking, database, storage, messaging (SQS), security, and more

**Usage:**
```hcl
module "naming" {
  source = "github.com/digitact/digitact-tfm-modules//labelling?ref=v1.0.0"

  product     = "whub"        # or "prkr" for Perkrunner
  environment = "stg"         # prd, nprd, dev, stg
  application = "zoho-crm"
  criticality = "medium"      # critical, high, medium, low
  backup      = "tier-1"      # none, tier-1, tier-2, tier-3
  layer       = "application" # governance, shared-infrastructure, application
}

# Use for resources with 'name' argument
resource "aws_lambda_function" "api" {
  function_name = module.naming.name.lambda
  tags          = module.naming.mandatory_tags
  # ...
}

# Use for resources requiring 'Name' tag
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags       = module.naming.tags_with_name.vpc
  # Includes: Name + all 6 mandatory tags
}
```

**Documentation:**
- [USAGE_EXAMPLES.md](./labelling/USAGE_EXAMPLES.md) - Comprehensive usage examples for all resource types
- [NAMING_CONSTRAINTS.md](./labelling/NAMING_CONSTRAINTS.md) - AWS naming limits, validations, and best practices

## Quick Start

### 1. Install Development Tools

```bash
# Install git hooks for auto-formatting and validation
make install-hooks

# View all available commands
make help
```

### 2. Run Quality Checks

```bash
# Format all Terraform files
make tf-fmt

# Run all checks (format, validate, lint, security)
make tf-check

# Generate documentation
make tf-docs
```

### 3. Using Modules in Your Infrastructure

```hcl
# Reference specific version (recommended for production)
module "naming" {
  source = "github.com/digitact/digitact-tfm-modules//labelling?ref=v1.0.0"

  product     = "whub"
  environment = "prd"
  application = "api"
  criticality = "critical"
  backup      = "tier-1"
  layer       = "application"
}

# Or reference latest (for development)
module "naming" {
  source = "github.com/digitact/digitact-tfm-modules//labelling"

  environment = "stg"
  application = "analytics"
  # ...
}
```

## Products Using This Repository

- **Winehub** (`whub`) - Wine industry platform
- **Perkrunner** (`prkr`) - Perks and benefits platform
- Additional products as the portfolio grows

## Development

### Adding a New Module

1. Create a new directory for your module
2. Add standard files:
   ```
   my-module/
   ├── main.tf          # Main module logic
   ├── variables.tf     # Input variables (with descriptions)
   ├── outputs.tf       # Output values (with descriptions)
   ├── versions.tf      # Terraform/provider version constraints
   └── README.md        # Module documentation
   ```

3. Add terraform-docs markers to README.md:
   ```markdown
   ## Requirements

   <!-- BEGIN_TF_DOCS -->

<!-- END_TF_DOCS -->
   ```

4. Generate documentation:
   ```bash
   make tf-docs
   ```

5. Validate your module:
   ```bash
   make tf-check
   ```

### Running Tests

This repository includes comprehensive Terraform tests that validate naming logic, constraints, and real-world usage scenarios **without deploying actual AWS infrastructure**.

#### Test Suites

- **Naming Validation** (10 tests) - Core naming validation logic
- **Staging Environment** (9 scenarios) - Simulates staging environment usage
- **Production Environment** (13 scenarios) - Validates production-specific configurations
- **Failure Scenarios** (19 negative tests) - Validates that invalid configurations are correctly rejected

**Total: 51 tests** (32 positive + 19 negative tests) covering all major resource types and scenarios.

#### Running Tests Locally

```bash
# Run all tests (naming, staging, production, failures)
make tf-test

# Run specific test suites
make tf-test-naming       # Naming validation only
make tf-test-staging      # Staging environment scenarios
make tf-test-production   # Production environment scenarios
make tf-test-failures     # Failure scenarios (negative tests)

# Run all CI checks (includes tests)
make ci-check
```

#### Test Implementation

Tests use Terraform's native testing framework:
- **Mock provider** - No AWS credentials required
- **Plan-only execution** - No infrastructure deployed
- **Comprehensive assertions** - Validates naming, tagging, and constraints

See test files in `labelling/tests/`:
- `naming_validation.tftest.hcl` - Unit tests for naming validation
- `staging_environment.tftest.hcl` - Staging environment scenarios
- `production_environment.tftest.hcl` - Production environment scenarios
- `failure_scenarios.tftest.hcl` - Negative tests validating error conditions

### Git Hooks

This repository uses automated git hooks to maintain code quality:

**Pre-commit Hook:**
- Auto-formats all Terraform files using `terraform fmt`
- Automatically stages formatted files
- Runs on every `git commit`

**Pre-push Hook:**
- Validates Terraform formatting
- Runs `terraform validate` on all modules
- **Executes all Terraform tests** (51 tests: 32 positive + 19 negative)
- **Checks documentation is up-to-date** (terraform-docs via Docker)
- Executes `tflint` for linting (via Docker)
- Performs `trivy` security scan for HIGH/CRITICAL issues (via Docker)
- Checks for exposed secrets (AWS keys, private keys)
- Runs on every `git push`

See [scripts/README.md](./scripts/README.md) for detailed hook documentation.

### CI/CD Pipeline

This repository includes a comprehensive GitHub Actions workflow that runs on all pushes and pull requests to `main`:

**Automated CI/CD Checks:**
1. **Format Check** - Validates Terraform formatting
2. **Validate** - Initializes and validates all modules
3. **Lint** - Runs TFLint with AWS plugin
4. **Security** - Trivy scan for HIGH/CRITICAL vulnerabilities
5. **Tests** - Executes all 51 Terraform tests in parallel:
   - Naming validation tests (10 tests)
   - Staging environment scenarios (9 tests)
   - Production environment scenarios (13 tests)
   - Failure scenarios / negative tests (19 tests)

**Pipeline Features:**
- Parallel execution of independent jobs for speed
- Terraform plugin caching for performance
- SARIF upload to GitHub Security tab for vulnerability tracking
- Comprehensive status checks ensuring all quality gates pass

See `.github/workflows/terraform-ci.yml` for implementation details.

### Skipping Hooks (Emergency Use Only)

```bash
# Skip pre-commit
git commit --no-verify -m "emergency fix"

# Skip pre-push
git push --no-verify

# ⚠️  WARNING: Only use in emergencies - bypassing hooks can introduce:
#   - Unformatted code
#   - Invalid configurations
#   - Security vulnerabilities
```

## Module Standards

All modules in this repository must:

1. **Follow naming conventions**
   - Use snake_case for variables, locals, outputs
   - Use descriptive names (e.g., `vpc_id` not `id`)

2. **Include comprehensive documentation**
   - All variables must have `description`
   - All outputs must have `description`
   - README must include usage examples

3. **Specify version constraints**
   - Include `versions.tf` with minimum Terraform version
   - Specify required provider versions

4. **Pass quality gates**
   - ✅ terraform fmt
   - ✅ terraform validate
   - ✅ tflint (no errors)
   - ✅ trivy (no HIGH/CRITICAL issues)

5. **Be product-agnostic**
   - Design modules to work across all Digitact products
   - Use `var.product` for product-specific naming

## Quality Gates

### Automated Checks

All code must pass:

- ✅ **Formatting** - `terraform fmt -check -recursive`
- ✅ **Validation** - `terraform validate` for all modules
- ✅ **Tests** - 51 Terraform tests (32 positive + 19 negative tests)
- ✅ **Linting** - `tflint` with recommended rules
- ✅ **Security** - `trivy` scan for HIGH/CRITICAL vulnerabilities
- ✅ **Secrets** - No exposed AWS keys or private keys

### Make Targets

| Target | Description |
|--------|-------------|
| `make tf-fmt` | Format all Terraform files |
| `make tf-fmt-check` | Check formatting (no changes) |
| `make tf-validate` | Validate all modules |
| `make tf-test` | Run all Terraform tests (51 tests) |
| `make tf-test-naming` | Run naming validation tests |
| `make tf-test-staging` | Run staging environment tests |
| `make tf-test-production` | Run production environment tests |
| `make tf-test-failures` | Run failure scenarios (negative tests) |
| `make tf-lint` | Run tflint via Docker |
| `make tf-security` | Run Trivy security scan |
| `make tf-check` | Run all quality checks |
| `make tf-docs` | Generate documentation |
| `make install-hooks` | Install git hooks |
| `make ci-check` | Run all CI/CD checks (includes tests) |
| `make version-current` | Show current version |
| `make version-next` | Calculate next semantic version |
| `make release VERSION=v1.0.0` | Create new release with validation |
| `make release-patch` | Auto-increment patch version |
| `make release-minor` | Auto-increment minor version |
| `make release-major` | Auto-increment major version |
| `make help` | Show all available targets |

## Versioning

This repository uses **Semantic Versioning** with automated git tags and GitHub releases.

### Quick Start

```bash
# Check current version
make version-current

# Create a new release (auto-increments)
make release-patch    # Bug fixes: v1.0.0 → v1.0.1
make release-minor    # New features: v1.0.0 → v1.1.0
make release-major    # Breaking changes: v1.0.0 → v2.0.0

# Or specify exact version
make release VERSION=v1.0.0
```

### Using Versioned Modules in Terraform

**Recommended for production** - pin to specific version:

```hcl
module "naming" {
  source = "github.com/digitact/digitact-tfm-modules//labelling?ref=v1.0.0"

  product     = "whub"
  environment = "prd"
  application = "api"
  # ...
}
```

### Automated Releases

The repository includes GitHub Actions workflow for automated releases:
- Validates version format
- Runs all quality checks
- Creates git tags
- Generates changelogs
- Creates GitHub releases

**See [VERSIONING.md](./VERSIONING.md) for complete documentation.**

## Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Ensure all tests pass (`make ci-check`)
4. Generate documentation (`make tf-docs`)
5. Commit changes (pre-commit hook will auto-format)
6. Push changes (pre-push hook will validate)
7. Create a pull request

## Tools

### Docker-Based Execution (Recommended)

All tools can run via Docker with **no local installation required**:

| Tool | Version | Purpose | Docker Image |
|------|---------|---------|--------------|
| [terraform](https://www.terraform.io/) | latest | Infrastructure as Code | `hashicorp/terraform` |
| [tflint](https://github.com/terraform-linters/tflint) | latest | Terraform linting | `ghcr.io/terraform-linters/tflint` |
| [trivy](https://github.com/aquasecurity/trivy) | latest | Security scanning | `aquasec/trivy` |
| [terraform-docs](https://github.com/terraform-docs/terraform-docs) | latest | Documentation generation | `quay.io/terraform-docs/terraform-docs` |

### Using Docker for Terraform

By default, the Makefile uses local `terraform` binary for faster performance during development. To use Docker-based terraform for consistency:

```bash
# Use Docker terraform for all operations
USE_DOCKER_TERRAFORM=1 make tf-fmt
USE_DOCKER_TERRAFORM=1 make tf-test
USE_DOCKER_TERRAFORM=1 make ci-check

# Set as environment variable for session
export USE_DOCKER_TERRAFORM=1
make tf-fmt    # Now uses Docker
make tf-test   # Now uses Docker
```

**Benefits of Docker terraform:**
- ✅ No local Terraform installation required
- ✅ Always uses latest stable version
- ✅ Same environment as CI/CD
- ✅ Reproducible results across team

**Local terraform benefits:**
- ⚡ Faster execution (no container overhead)
- ⚡ Better developer experience (tab completion, etc.)
- ⚡ Easier debugging

## Repository Structure

```
digitact-tfm-modules/
├── .github/                        # GitHub-specific files
│   └── workflows/
│       ├── terraform-ci.yml        # CI/CD pipeline
│       └── release.yml             # Automated release workflow
├── .tflint.hcl                     # TFLint configuration
├── VERSIONING.md                   # Versioning guide and best practices
├── labelling/                      # Labelling module
│   ├── main.tf                     # Main module logic
│   ├── locals.tf                   # Naming constraints & validations
│   ├── variables.tf                # Input variables
│   ├── outputs.tf                  # Output values (95+ resource types)
│   ├── README.md                   # Module documentation
│   ├── USAGE_EXAMPLES.md          # Comprehensive examples
│   ├── NAMING_CONSTRAINTS.md      # AWS naming limits & validations
│   └── tests/                      # Terraform tests (51 tests)
│       ├── naming_validation.tftest.hcl      # Unit tests (10 tests)
│       ├── staging_environment.tftest.hcl    # Staging scenarios (9 tests)
│       ├── production_environment.tftest.hcl # Production scenarios (13 tests)
│       └── failure_scenarios.tftest.hcl      # Negative tests (19 tests)
├── scripts/                        # Git hook templates
│   ├── pre-commit.template         # Auto-format hook
│   ├── pre-push.template           # Quality gate hook (includes tests)
│   └── README.md                   # Hook documentation
├── Makefile                        # Development automation
└── README.md                       # This file
```

## License

Copyright © 2024 Digitact. All rights reserved.

## Support

For issues or questions:
- Review module documentation in module directories
- Check [scripts/README.md](./scripts/README.md) for git hook help
- Run `make help` for available commands
- Contact the Digitact infrastructure team

---

<!-- BEGIN_TF_DOCS -->
<!-- END_TF_DOCS -->
