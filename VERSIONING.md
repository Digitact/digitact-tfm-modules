# Versioning Guide

This repository uses **Semantic Versioning** with git tags to manage releases of Terraform modules.

## Quick Reference

```bash
# Check current version
make version-current

# See what the next version would be
make version-next

# Create a new release (runs all quality checks first)
make release VERSION=v1.0.0

# Auto-increment versions
make release-patch    # v1.0.0 → v1.0.1 (bug fixes)
make release-minor    # v1.0.0 → v1.1.0 (new features)
make release-major    # v1.0.0 → v2.0.0 (breaking changes)
```

## Semantic Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/):

**Given a version number `MAJOR.MINOR.PATCH` (e.g., `v1.2.3`):**

- **MAJOR** version when you make incompatible API changes
  - Breaking changes to module interfaces
  - Removed or renamed input variables
  - Changed output values that break downstream dependencies
  - Example: `v1.5.2` → `v2.0.0`

- **MINOR** version when you add functionality in a backwards compatible manner
  - New input variables (with defaults)
  - New output values
  - New resource types supported
  - Example: `v1.5.2` → `v1.6.0`

- **PATCH** version when you make backwards compatible bug fixes
  - Bug fixes
  - Documentation updates
  - Internal refactoring (no interface changes)
  - Example: `v1.5.2` → `v1.5.3`

## Release Workflows

### Option 1: Manual Release via Makefile (Recommended for Development)

This creates a local tag that you can push when ready:

```bash
# 1. Ensure all changes are committed
git status

# 2. Run quality checks and create release
make release VERSION=v1.0.0

# 3. Push the tag to trigger automated release
git push origin v1.0.0
```

**Auto-increment helpers:**

```bash
# Bug fix release (recommended for most changes)
make release-patch

# New feature release
make release-minor

# Breaking change release (use cautiously!)
make release-major
```

### Option 2: Automated Release via GitHub Actions (Recommended for Production)

Trigger the release workflow from GitHub Actions:

1. Navigate to **Actions** → **Release** workflow
2. Click **Run workflow**
3. Enter version (e.g., `v1.0.0`)
4. Optionally check "Update latest tag" (⚠️ see warnings below)
5. Click **Run workflow**

**The workflow will:**
- ✅ Validate version format
- ✅ Run all quality checks (format, validate, lint, security, tests)
- ✅ Create annotated git tag
- ✅ Generate changelog from commits
- ✅ Create GitHub Release with notes
- ✅ Optionally update "latest" tag

## Using Released Versions in Terraform

### Recommended: Pin to Specific Version

**Best practice for production:**

```hcl
module "naming" {
  source = "github.com/digitact/digitact-tfm-modules//labelling?ref=v1.0.0"

  product     = "whub"
  environment = "prd"
  application = "api"
  criticality = "critical"
  backup      = "tier-1"
  layer       = "application"
}
```

✅ **Benefits:**
- Predictable behavior
- No unexpected changes
- Easy rollback
- Clear dependency tracking

### Development: Use Latest Tag

**⚠️ NOT recommended for production:**

```hcl
module "naming" {
  source = "github.com/digitact/digitact-tfm-modules//labelling?ref=latest"

  # ... configuration ...
}
```

❌ **Risks:**
- Unpredictable behavior (tag moves)
- Breaking changes without notice
- Difficult to debug issues
- No version audit trail

**When to use `latest`:**
- ✓ Local development/experimentation
- ✓ Testing new features
- ✓ Proof of concept projects
- ✗ Production environments
- ✗ Shared infrastructure
- ✗ Long-lived projects

## The "latest" Tag Controversy

The `latest` tag is a **moving tag** - it gets updated to point to the newest release.

**Arguments AGAINST moving tags:**
- Git tags are meant to be immutable pointers
- Can cause confusion and unexpected behavior
- Terraform may cache the old version
- Violates git best practices

**Arguments FOR moving tags (our use case):**
- Convenient for development workflows
- Similar to Docker's `latest` tag pattern
- Used by GitHub Actions themselves
- Clearly documented as development-only

**Our Stance:**
- ✅ We provide `latest` tag as an **optional convenience** for development
- ⚠️ Clearly document it's NOT for production use
- ✅ Default behavior: Do NOT update `latest` automatically
- ✅ Manual opt-in required via GitHub Actions checkbox

## Release Checklist

Before creating a release:

- [ ] All changes committed and pushed to `main`
- [ ] All tests passing (`make tf-test`)
- [ ] Documentation updated (`make tf-docs`)
- [ ] CHANGELOG.md updated (if you maintain one)
- [ ] Version follows semantic versioning
- [ ] No breaking changes in MINOR/PATCH releases
- [ ] Breaking changes documented in MAJOR releases

## Version History

View all releases:
- **GitHub**: https://github.com/digitact/digitact-tfm-modules/releases
- **Git tags**: `git tag --list --sort=-version:refname`
- **Latest**: `git describe --tags --abbrev=0`

## Troubleshooting

### "Tag already exists"

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin :refs/tags/v1.0.0

# Recreate
make release VERSION=v1.0.0
```

### "Quality checks failed"

The release process runs all quality gates:

```bash
# Run checks manually to see failures
make ci-check

# Common issues:
make tf-fmt          # Fix formatting
make tf-docs         # Update documentation
make tf-test         # Fix failing tests
```

### "How do I rollback a release?"

Git tags are permanent markers. To "rollback":

1. **Don't delete the bad tag** (breaks anyone using it)
2. **Create a new patch release** with fixes
3. **Update documentation** noting the issue

```bash
# Fix the issue in code, then:
make release-patch
```

## Migration from Old Versioning

If you previously used branch names or commit SHAs:

**Before:**
```hcl
source = "github.com/digitact/digitact-tfm-modules//labelling"  # ❌ Always uses main
source = "github.com/digitact/digitact-tfm-modules//labelling?ref=abc123"  # ❌ Commit SHA
```

**After:**
```hcl
source = "github.com/digitact/digitact-tfm-modules//labelling?ref=v1.0.0"  # ✅ Semantic version
```

## Best Practices Summary

1. ✅ **Always use semantic versioning** (v1.0.0, v1.2.3)
2. ✅ **Pin to specific versions** in production
3. ✅ **Run quality checks** before release (`make release` does this)
4. ✅ **Document breaking changes** in release notes
5. ✅ **Never force-push over tags** (create new version instead)
6. ✅ **Use auto-increment helpers** (`make release-patch`)
7. ⚠️ **Use "latest" only for development**
8. ❌ **Don't delete released tags**
9. ❌ **Don't skip versions** (no jumping from v1.0.0 to v3.0.0)
10. ❌ **Don't use vague version constraints** in production (no `~>`, `>=`)

## References

- [Semantic Versioning 2.0.0](https://semver.org/)
- [Terraform Module Versioning Best Practices](https://devtodevops.com/blog/terraform-module-versioning-best-practices/)
- [Git Tagging Best Practices](https://www.atlassian.com/git/tutorials/inspecting-a-repository/git-tag)
- [GitHub Actions Semantic Versioning](https://medium.com/@swastikaaryal/automating-semantic-versioning-with-github-actions-33e9fa23d912)
