#!/bin/bash
# test.sh — Test suite for ShellOps
# Validates installation, module loading, and basic functionality

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# ============================================================================
# Test Utilities
# ============================================================================

test_start() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "▶ TEST: $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

test_pass() {
    log_success "✓ $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    log_error "✗ $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

# ============================================================================
# Phase 1: Dependency Checks
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║            ShellOps Test Suite — Starting                     ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

test_start "Required Commands"

# Check for required utilities
for cmd in bash awk grep tar find; do
    if command -v "$cmd" &>/dev/null; then
        test_pass "Command available: $cmd"
    else
        test_fail "Command missing: $cmd"
    fi
done

# Optional but helpful
for cmd in gzip bzip2 xz cron; do
    if command -v "$cmd" &>/dev/null; then
        log_info "Optional available: $cmd"
    else
        log_warn "Optional missing: $cmd"
    fi
done

# ============================================================================
# Phase 2: File Structure
# ============================================================================

test_start "Project Structure"

# Check directories
for dir in bin lib config docs; do
    if [[ -d "$SCRIPT_DIR/$dir" ]]; then
        test_pass "Directory exists: $dir/"
    else
        test_fail "Directory missing: $dir/"
    fi
done

# Check key files
for file in shellops setup_wizard.sh README.md CONTRIBUTING.md; do
    if [[ -f "$SCRIPT_DIR/$file" ]]; then
        test_pass "File exists: $file"
    else
        test_fail "File missing: $file"
    fi
done

# Check lib files
for lib in common.sh config.sh user_monitor.sh disk_cleanup.sh backup_schedule.sh health_check.sh; do
    if [[ -f "$SCRIPT_DIR/lib/$lib" ]]; then
        test_pass "Module exists: lib/$lib"
    else
        test_fail "Module missing: lib/$lib"
    fi
done

# ============================================================================
# Phase 3: File Permissions
# ============================================================================

test_start "File Permissions"

for file in shellops setup_wizard.sh lib/*.sh; do
    if [[ -x "$SCRIPT_DIR/$file" ]]; then
        test_pass "Executable: $(basename $file)"
    else
        test_fail "Not executable: $(basename $file)"
    fi
done

# ============================================================================
# Phase 4: Syntax Validation
# ============================================================================

test_start "Bash Syntax Validation"

for script in shellops setup_wizard.sh lib/*.sh; do
    if bash -n "$SCRIPT_DIR/$script" 2>/dev/null; then
        test_pass "Syntax OK: $(basename $script)"
    else
        test_fail "Syntax error: $(basename $script)"
    fi
done

# ============================================================================
# Phase 5: Module Loading
# ============================================================================

test_start "Module Loading"

# Test sourcing each module
if source "$SCRIPT_DIR/lib/common.sh" 2>/dev/null; then
    test_pass "Module loadable: lib/common.sh"
else
    test_fail "Module error: lib/common.sh"
fi

if source "$SCRIPT_DIR/lib/config.sh" 2>/dev/null; then
    test_pass "Module loadable: lib/config.sh"
else
    test_fail "Module error: lib/config.sh"
fi

if source "$SCRIPT_DIR/lib/user_monitor.sh" 2>/dev/null; then
    test_pass "Module loadable: lib/user_monitor.sh"
else
    test_fail "Module error: lib/user_monitor.sh"
fi

if source "$SCRIPT_DIR/lib/disk_cleanup.sh" 2>/dev/null; then
    test_pass "Module loadable: lib/disk_cleanup.sh"
else
    test_fail "Module error: lib/disk_cleanup.sh"
fi

if source "$SCRIPT_DIR/lib/backup_schedule.sh" 2>/dev/null; then
    test_pass "Module loadable: lib/backup_schedule.sh"
else
    test_fail "Module error: lib/backup_schedule.sh"
fi

if source "$SCRIPT_DIR/lib/health_check.sh" 2>/dev/null; then
    test_pass "Module loadable: lib/health_check.sh"
else
    test_fail "Module error: lib/health_check.sh"
fi

# ============================================================================
# Phase 6: Help System
# ============================================================================

test_start "Help System"

# Test main help
if "$SCRIPT_DIR/shellops" help | grep -q "USAGE"; then
    test_pass "Help system works"
else
    test_fail "Help system broken"
fi

# Test command-specific help
for cmd in monitor cleanup backup health; do
    if "$SCRIPT_DIR/shellops" help "$cmd" &>/dev/null; then
        test_pass "Help for: $cmd"
    else
        test_fail "Help missing: $cmd"
    fi
done

# ============================================================================
# Phase 7: Configuration
# ============================================================================

test_start "Configuration Validation"

if [[ -f "$SCRIPT_DIR/config/shellops.conf.example" ]]; then
    test_pass "Example config exists"
else
    test_fail "Example config missing"
fi

if [[ -f "$SCRIPT_DIR/config/backup.exclude" ]]; then
    test_pass "Backup exclude patterns exist"
else
    test_fail "Backup exclude patterns missing"
fi

# ============================================================================
# Phase 8: Basic Functionality (read-only)
# ============================================================================

test_start "Basic Functionality (Read-Only)"

# Test health quick (should always work)
if "$SCRIPT_DIR/shellops" health quick &>/dev/null 2>&1; then
    test_pass "Health check works"
else
    test_fail "Health check failed"
fi

# Test version
if "$SCRIPT_DIR/shellops" version | grep -q "ShellOps"; then
    test_pass "Version display works"
else
    test_fail "Version display broken"
fi

# ============================================================================
# Phase 9: Documentation
# ============================================================================

test_start "Documentation"

for doc in quick-start features configuration cron-setup troubleshooting; do
    if [[ -f "$SCRIPT_DIR/docs/${doc}.md" ]]; then
        test_pass "Doc exists: docs/${doc}.md"
    else
        test_fail "Doc missing: docs/${doc}.md"
    fi
done

# ============================================================================
# Phase 10: Function Export Check
# ============================================================================

test_start "Function Exports"

# Load common.sh and check if functions are exported
if bash -c "source '$SCRIPT_DIR/lib/common.sh' && compgen -p | grep -q 'log_info'" 2>/dev/null; then
    test_pass "Functions exported: common.sh"
else
    test_fail "Function export issue: common.sh"
fi

# ============================================================================
# Results Summary
# ============================================================================

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Test Results Summary                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Tests Passed:  $TESTS_PASSED ✓"
echo "Tests Failed:  $TESTS_FAILED ✗"
echo ""

if [[ $TESTS_FAILED -eq 0 ]]; then
    log_success "All tests passed! ✓"
    echo ""
    echo "Next steps:"
    echo "  1. Run setup wizard:    sudo ./setup_wizard.sh"
    echo "  2. Try commands:        ./shellops health"
    echo "  3. Read documentation: cat docs/quick-start.md"
    echo ""
    exit 0
else
    log_error "$TESTS_FAILED test(s) failed ✗"
    echo ""
    echo "Troubleshooting:"
    echo "  • Check file permissions: chmod +x shellops lib/*.sh"
    echo "  • Verify bash version: bash --version (need 4.0+)"
    echo "  • Review docs/troubleshooting.md"
    echo ""
    exit 1
fi
