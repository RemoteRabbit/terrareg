# Contributing to terrareg

Thank you for your interest in contributing to terrareg! We welcome contributions of all kinds.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/terrareg.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`

## Development Setup

### Prerequisites

- [Neovim](https://neovim.io/) (latest stable version recommended)
- [Python](https://python.org/) (for pre-commit)
- [Git](https://git-scm.com/)

### Setup

1. Install pre-commit:
   ```bash
   pip install pre-commit
   pre-commit install
   ```

2. The pre-commit hooks will automatically:
   - Format Lua code with StyLua
   - Lint code with Luacheck
   - Check for trailing whitespace and other issues
   - Validate commit messages

## Making Changes

### Code Style

- We use [StyLua](https://github.com/JohnnyMorganz/StyLua) for Lua formatting
- Follow existing code patterns and conventions
- Write clear, descriptive variable and function names
- Add type annotations where helpful

### Commit Messages

We use [Conventional Commits](https://conventionalcommits.org/) format:

```
type(scope): description

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
- `feat: add telescope integration`
- `fix: handle empty buffer correctly`
- `docs: update installation instructions`

### Testing

Before submitting a PR:
1. Test your changes manually in Neovim
2. Ensure all pre-commit hooks pass
3. Test with different plugin managers if applicable

## Pull Request Process

1. **Create a descriptive PR title** following conventional commit format
2. **Fill out the PR template** with details about your changes
3. **Link any related issues** in the PR description
4. **Ensure CI passes** - all checks must be green
5. **Be responsive to feedback** and make requested changes promptly

## Beta Testing

For testing new features:
1. Push changes to the `beta` branch
2. Beta releases are automatically created
3. Users can test with `branch = "beta"` in their plugin manager
4. Once stable, merge to `main` for full release

## Types of Contributions

### Bug Reports
- Use the bug report template
- Include Neovim version, OS, and reproduction steps
- Provide minimal configuration to reproduce the issue

### Feature Requests
- Use the feature request template
- Explain the use case and expected behavior
- Consider if it fits the plugin's scope

### Documentation
- Fix typos, improve clarity
- Add examples and use cases
- Keep documentation up to date with code changes

### Code Contributions
- Bug fixes
- New features (discuss in an issue first for large features)
- Performance improvements
- Code refactoring

## Code Review

All submissions require review. We aim to:
- Be constructive and helpful
- Focus on code quality and maintainability
- Ensure consistency with project goals
- Provide timely feedback

## Getting Help

- Open an issue for questions
- Check existing issues and discussions
- Review the documentation

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
