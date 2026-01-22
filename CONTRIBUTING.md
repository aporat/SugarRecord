# Contributing to SugarRecord

Thank you for your interest in contributing to SugarRecord! This document provides guidelines for contributing to the project.

## Code of Conduct

Be respectful and constructive in all interactions with the community.

## How to Contribute

### Reporting Issues

- Search existing issues before creating a new one
- Provide clear reproduction steps
- Include relevant environment details (Xcode version, iOS/macOS version, etc.)
- Share minimal code examples that demonstrate the issue

### Pull Requests

1. **Fork the repository** and create a feature branch from `main`
2. **Follow the coding style** already present in the codebase
3. **Write tests** for new features or bug fixes
4. **Run tests** locally before submitting: `swift test` or use Xcode
5. **Lint your code** using SwiftLint: configuration is in `.swiftlint.yml`
6. **Use Conventional Commits** for commit messages (see below)
7. **Submit your PR** with a clear description of the changes

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org) format:

```
<type>: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc.)
- `refactor`: Code refactoring without changing functionality
- `perf`: Performance improvements
- `test`: Adding or updating tests
- `chore`: Maintenance tasks, dependency updates, etc.
- `ci`: CI/CD changes

**Examples:**
```
feat: add batch insert operation for bulk data imports
fix: resolve race condition in background context merging
docs: update README with performBackgroundTask examples
test: add unit tests for FetchRequest filtering
```

## Development Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/aporat/SugarRecord.git
   cd SugarRecord
   ```

2. Open the package in Xcode:
   ```bash
   open Package.swift
   ```

3. Build and run tests:
   - Press `Cmd+U` in Xcode, or
   - Run `swift test` from the command line

## Code Style

- Follow Swift API Design Guidelines
- Use SwiftFormat configuration (`.swiftformat`) for consistent formatting
- Respect SwiftLint rules (`.swiftlint.yml`)
- Keep line length under 110 characters
- Use meaningful variable and function names
- Add documentation comments for public APIs

## Testing

- All new features must include unit tests
- All bug fixes should include regression tests
- Tests should use in-memory stores for speed and isolation
- Aim for high code coverage, especially for critical paths

## CI Requirements

All pull requests must pass:
- ✅ Build successfully on iOS simulator
- ✅ All unit tests pass
- ✅ SwiftLint checks pass
- ✅ No compiler warnings

## Questions?

If you have questions about contributing, feel free to:
- Open an issue for discussion
- Reach out to the maintainers

Thank you for contributing! 🎉
