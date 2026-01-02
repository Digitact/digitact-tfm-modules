# Git Hooks for Digitact Terraform Modules

This directory contains git hook templates that automate code quality checks for the Terraform modules repository.

## Installation

```bash
make install-hooks
```

This will copy the hook templates to `.git/hooks/` and make them executable.

## Available Hooks

### Pre-Commit Hook (`pre-commit.template`)

**Purpose:** Auto-format Terraform code before each commit

**What it does:**
- Runs `terraform fmt -recursive` on all staged `.tf` files
- Automatically stages the formatted files
- Ensures all commits have properly formatted code

**Duration:** ~2 seconds

**Skip:** Not recommended, but you can skip with `git commit --no-verify`

**Example output:**
```
Pre-commit: Auto-formatting staged Terraform module files
  Terraform Modules:
    ✓ terraform fmt applied to all modules
✓ Pre-commit fixes applied and staged
```

### Pre-Push Hook (`pre-push.template`)

**Purpose:** Run quality checks before pushing to remote

**What it does:**
1. **Format Check** - Validates Terraform formatting (should be handled by pre-commit)
2. **Validation** - Runs `terraform validate` on all modules
3. **Linting** - Runs `tflint` via Docker (no local install required)
4. **Security Scan** - Runs `trivy` for HIGH/CRITICAL vulnerabilities
5. **Secrets Detection** - Checks for accidentally committed AWS keys or private keys

**Duration:** ~20 seconds

**Skip:** Use `git push --no-verify` for emergency pushes (not recommended)

**Example output:**
```
╔════════════════════════════════════════════════════════════╗
║      Digitact Terraform Modules - Pre-Push Checks        ║
╚════════════════════════════════════════════════════════════╝

Changes detected:
  ▸ Terraform module files

▶ Running Terraform module pre-push checks...

  1/5 Checking Terraform formatting...
  ✓ Terraform formatting OK
  2/5 Validating Terraform modules...
  ✓ All modules validated successfully
  3/5 Running tflint via Docker...
  ✓ tflint checks passed
  4/5 Running Trivy security scan via Docker...
  ✓ Trivy security checks passed
  5/5 Checking for exposed secrets...
  ✓ No secrets detected

✅ Terraform module pre-push checks passed!

✅ All pre-push checks passed! (18s)

Validated:
  ✓ Terraform modules (fmt, validate, tflint, trivy)
```

## Hook Workflow

### Development Workflow with Hooks

```bash
# 1. Make changes to module files
vim labelling/main.tf

# 2. Stage changes
git add labelling/main.tf

# 3. Commit (pre-commit hook auto-formats)
git commit -m "feat: add new resource names"
# → Pre-commit runs terraform fmt automatically
# → Formatted files are staged and included in commit

# 4. Push (pre-push hook validates)
git push origin main
# → Pre-push runs all quality checks
# → Push proceeds only if all checks pass
```

## Troubleshooting

### Pre-Commit Hook Issues

**Problem:** "terraform: command not found"
```bash
# Install Terraform
brew install terraform
```

**Problem:** Hook doesn't run
```bash
# Check hook is executable
ls -la .git/hooks/pre-commit

# Reinstall hooks
make install-hooks
```

### Pre-Push Hook Issues

**Problem:** "Docker: command not found"
```bash
# Install Docker Desktop
# https://www.docker.com/products/docker-desktop
```

**Problem:** Validation fails for modules
```bash
# Initialize modules first
make tf-validate-all

# Or manually:
cd labelling && terraform init -backend=false
```

**Problem:** tflint not configured
```bash
# .tflint.hcl is auto-created if missing
# Or manually:
cp .tflint.hcl.example .tflint.hcl
```

**Problem:** Trivy finds security issues
```bash
# Review the issues reported
# Fix the security problems
# Or temporarily bypass (not recommended):
git push --no-verify
```

### Skipping Hooks (Emergency Use Only)

```bash
# Skip pre-commit hook
git commit --no-verify -m "emergency fix"

# Skip pre-push hook
git push --no-verify

# ⚠️  WARNING: Bypassing hooks can introduce:
#   - Unformatted code
#   - Invalid Terraform configurations
#   - Security vulnerabilities
#   - Secrets exposure
```

## Manual Execution

You can run the hook checks manually without committing/pushing:

### Test Pre-Commit Hook
```bash
# Run formatting check
terraform fmt -check -recursive .

# Auto-format
terraform fmt -recursive .
```

### Test Pre-Push Hook
```bash
# Run all checks via Makefile
make tf-check

# Or individual checks:
make tf-fmt-check      # Format validation
make tf-validate       # Terraform validate
make tf-lint           # tflint
make tf-security       # Trivy scan
```

## CI/CD Integration

These hooks mirror the checks run in CI/CD pipelines. Passing the pre-push hook locally means your changes are highly likely to pass CI/CD.

**GitHub Actions equivalent:**
```yaml
- name: Terraform Format
  run: terraform fmt -check -recursive .

- name: Terraform Validate
  run: |
    for module in $(find . -name "*.tf" -exec dirname {} \; | sort -u); do
      terraform -chdir=$module init -backend=false
      terraform -chdir=$module validate
    done

- name: TFLint
  run: |
    docker run --rm -v $(pwd):/workspace -w /workspace \
      ghcr.io/terraform-linters/tflint:v0.60.0 \
      sh -c "tflint --init && tflint --recursive"

- name: Trivy
  run: |
    docker run --rm -v $(pwd):/workspace -w /workspace \
      aquasec/trivy:0.68.1 config . --severity HIGH,CRITICAL
```

## Hook Customization

To customize hooks for your needs:

1. Edit `scripts/pre-commit.template` or `scripts/pre-push.template`
2. Run `make install-hooks` to update installed hooks
3. Commit the template changes to share with team

**Example customizations:**
- Add additional validation tools
- Change tflint severity threshold
- Add custom naming checks
- Enable/disable specific checks

## Dependencies

### Pre-Commit Hook
- **Terraform CLI** (required)
  - Install: `brew install terraform`
  - Version: 1.5+

### Pre-Push Hook
- **Terraform CLI** (required)
  - Install: `brew install terraform`
  - Version: 1.5+

- **Docker** (required for tflint and trivy)
  - Install: [Docker Desktop](https://www.docker.com/products/docker-desktop)
  - Version: 20.10+

- **tflint** (via Docker, no local install needed)
  - Image: `ghcr.io/terraform-linters/tflint:v0.60.0`

- **trivy** (via Docker, no local install needed)
  - Image: `aquasec/trivy:0.68.1`

## Best Practices

1. **Always install hooks** when cloning the repository
   ```bash
   make install-hooks
   ```

2. **Don't skip hooks** unless absolutely necessary
   - They catch issues early
   - Prevent CI/CD failures
   - Maintain code quality

3. **Fix issues, don't bypass**
   - If pre-push fails, fix the underlying issue
   - `--no-verify` should be rare emergency use only

4. **Keep tools updated**
   - Update `TFLINT_VERSION` and `TRIVY_VERSION` in Makefile
   - Run `make install-hooks` after updates

5. **Run checks locally before pushing**
   ```bash
   make tf-check  # Runs all quality checks
   ```

## Support

For issues with git hooks:
1. Check this README for troubleshooting
2. Run `make help` to see available targets
3. Check Makefile for detailed implementation
4. Review hook templates in `scripts/`
