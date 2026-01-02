# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive testing infrastructure (51 tests: 32 positive + 19 negative)
- Automated versioning and release workflow
- Git hooks for code quality
- Support for 95+ AWS resource types

### Changed
- N/A

### Deprecated
- N/A

### Removed
- N/A

### Fixed
- N/A

### Security
- N/A

---

## How to Maintain This Changelog

When making changes, update the **[Unreleased]** section above with your changes under the appropriate category:

- **Added** for new features
- **Changed** for changes in existing functionality
- **Deprecated** for soon-to-be removed features
- **Removed** for now removed features
- **Fixed** for any bug fixes
- **Security** in case of vulnerabilities

When creating a release, the GitHub Actions workflow will automatically generate release notes from commits. However, you can also manually maintain this changelog for additional context.

### Example Entry Format

```markdown
## [1.0.0] - 2025-01-02

### Added
- Initial release of labelling module
- Support for 95+ AWS resource types
- Automated testing with 51 test scenarios
- Comprehensive documentation

### Fixed
- Fixed S3 naming validation for lowercase requirements
```

## Reference Links

- [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
- [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
- [VERSIONING.md](./VERSIONING.md) - Our versioning guide
