# Contributing to ShellOps

Thank you for your interest in contributing to the ShellOps Educational Toolkit! This document guides contributors through the process of adding features, fixing bugs, or improving documentation.

## Philosophy

ShellOps is designed for educational purposes. All contributions should:
- **Teach good practices** — Demonstrate shell scripting best practices
- **Stay maintainable** — Keep code simple, well-documented, and modular
- **Prioritize clarity** — Favor readability over cleverness
- **Include documentation** — Every feature needs docs and examples
- **Be testable** — Changes should include test cases

## Getting Started

1. **Fork or clone** the repository
2. **Create a feature branch**: `git checkout -b feature/your-feature-name`
3. **Make your changes** following the guidelines below
4. **Test thoroughly** using `test.sh`
5. **Submit a pull request** with a clear description

## Code Style & Best Practices

### Bash Guidelines

- **Shellcheck**: Run `shellcheck lib/*.sh shellops setup_wizard.sh` before submitting
- **Error handling**: Always use `set -e` and check exit codes
- **Comments**: Explain *why*, not *what* (code shows what it does)
- **Indentation**: Use 2 spaces, no tabs
- **Quoting**: Quote all variables: `"$var"` not `$var`
- **Avoid**:
  - Exotic shells (bash, not zsh/ksh-only features)
  - External dependencies beyond POSIX tools
  - Hard-coded paths (prefer configurable paths)

### Example Function Structure

```bash
# Clear, descriptive function names with underscore separation
validate_user_input() {
    local input="$1"
    local expected_pattern="$2"
    
    # Check parameters
    if [[ -z "$input" ]]; then
        log_error "validate_user_input: input required"
        return 1
    fi
    
    # Perform validation
    if [[ $input =~ $expected_pattern ]]; then
        log_info "Input validated: $input"
        return 0
    else
        log_error "Input validation failed: $input"
        return 1
    fi
}
```

## Project Structure

When adding features:

- **Core logic** → `lib/your_feature.sh`
- **Shared utilities** → Add functions to `lib/common.sh`
- **Configuration** → Add keys to `config/shellops.conf.example`
- **Documentation** → Create or update relevant docs in `docs/`
- **Integration** → Add command routing in main `shellops` script

## Adding a New Feature

### 1. Create the Module

Create `/lib/your_feature.sh`:

```bash
#!/bin/bash
# Module description and purpose

# Source common utilities
source "$(dirname "$0")/common.sh" || exit 1
source "$(dirname "$0")/config.sh" || { log_error "Failed to source config.sh"; exit 1; }

# Feature-specific functions
your_feature_main() {
    log_info "Starting your feature..."
    # Implementation
}

# Export for use by main script
export -f your_feature_main
```

### 2. Update Main Script

Add to `shellops`:

```bash
your-feature)
    source lib/your_feature.sh || exit 1
    your_feature_main "$@"
    ;;
```

### 3. Update Configuration

Add to `config/shellops.conf.example`:

```bash
# Your Feature Configuration
FEATURE_ENABLED=true
FEATURE_OPTION="value"
```

### 4. Add Documentation

Create `docs/feature_name.md` with:
- What it does
- Usage examples
- Configuration options
- Troubleshooting tips
- Educational notes

### 5. Test

Run the test script:

```bash
./test.sh
```

Write a simple test in `test.sh`:

```bash
# Test your_feature
echo "Testing your_feature..."
./shellops your-feature || { echo "Feature test failed"; exit 1; }
```

## Documentation Standards

All documentation should:
- Use clear, simple language (educational audience)
- Include examples for all features
- Explain *why* not just *how*
- Link to related features/config
- Include troubleshooting section

Template for feature documentation:

```markdown
# Feature Name

## Overview
Brief description and use case.

## Usage
```bash
shellops feature-name [options]
```

## Options
- `--option1` — Description
- `--option2` — Description

## Examples
```bash
# Example 1: Basic usage
shellops feature-name

# Example 2: With options
shellops feature-name --option1 value

# Example 3: With dry-run
shellops feature-name --dry-run
```

## Configuration
### Config File Settings
- `FEATURE_VAR` — Description (default: value)

## Educational Notes
Insights about the feature, shell techniques, or system admin concepts.

## Troubleshooting
Common issues and solutions.
```

## Testing Requirements

Before submitting, verify:

- ✅ **Shellcheck passes**: `shellcheck lib/*.sh shellops`
- ✅ **test.sh runs successfully**: `./test.sh`
- ✅ **Help system works**: `shellops help your-feature`
- ✅ **Dry-run mode works**: `shellops your-feature --dry-run`
- ✅ **Config loading works**: Verify config file parsing
- ✅ **Error handling**: Test with invalid inputs, missing deps, permission issues
- ✅ **Documentation**: Docs created and links updated

## Commit Messages

Use clear, descriptive commit messages:

**Good:**
```
Add user_monitor feature with idle time detection

- Implement user activity tracking
- Add suspicious activity alerts
- Include configuration options
- Add comprehensive documentation
- Passes shellcheck and test suite
```

**Avoid:**
```
Fix stuff
Update code
Working version
```

## Pull Request Checklist

Before submitting:
- [ ] Feature is complete and tested
- [ ] All documentation is written
- [ ] Code follows style guidelines
- [ ] Shellcheck passes with no warnings
- [ ] test.sh passes completely
- [ ] Commit messages are clear
- [ ] PR description explains intent
- [ ] No breaking changes to existing features

## Documentation Updates

If your changes affect existing documentation:
- Update relevant `.md` files in `/docs/`
- Update `README.md` if changing structure/usage
- Update configuration examples
- Update help text in main script

## Questions & Discussions

- Check existing issues/documentation first
- Ask in comments when clarification needed
- Propose substantial changes before implementing

---

**Thank you for contributing to ShellOps!** Your work helps teach excellent shell scripting and system administration practices.
