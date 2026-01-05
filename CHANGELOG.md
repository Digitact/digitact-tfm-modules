# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- N/A

### Changed
- N/A

### Fixed
- N/A

---

## [1.0.0] - 2026-01-06

### Added
- Initial release of terraform labelling module
- Mandatory `repository` variable to track which git repository manages infrastructure
- Seven mandatory tags: Application, Environment, Criticality, Backup, ManagedBy, Layer, Repository
- Comprehensive validation for repository names (lowercase letters, numbers, hyphens, underscores, 2-100 characters)
- Support for 95+ AWS resource types with naming patterns
- Automated testing infrastructure (51 tests: 32 positive + 19 negative scenarios)
- Automated versioning and release workflow via GitHub Actions
- Git hooks for code quality (pre-commit formatting, pre-push validation)
- Comprehensive documentation with usage examples

### Configuration
- Terraform required version: >=1.14.0
- AWS provider version: >=6.0, <7.0 (enforces 6.x series with multi-region support)
- GitHub Actions use major version tags for automatic updates:
  - `aquasecurity/trivy-action@0.33.1` for security scanning
  - `softprops/action-gh-release@v2` for release automation

### Quality
- Zero tflint warnings (removed deprecated interpolation syntax and unused locals)
- All tests passing with latest Terraform 1.14.3
- Security scanning enabled with Trivy

---

## How to Maintain This Changelog

When making changes, update the **[Unreleased]** section above with your changes under the appropriate category:

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** in case of vulnerabilities

When creating a release, move the **[Unreleased]** changes to a new version section.

## Reference Links

- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- [VERSIONING.md](./VERSIONING.md) - Our versioning guide
