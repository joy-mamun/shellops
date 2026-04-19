#!/bin/bash
# install.sh — Installation helper for ShellOps
# Copies files to appropriate locations and sets permissions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.shellops}"
INSTALL_USER="${INSTALL_USER:-$USER}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RESET='\033[0m'

# ============================================================================
# Helper Functions
# ============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${RESET} $1"
}

log_success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${RESET} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $1"
}

# ============================================================================
# Installation Logic
# ============================================================================

show_header() {
    cat << 'EOF'
╔════════════════════════════════════════════════════════════════════════════╗
║                   ShellOps Installation Helper                             ║
║             Educational Linux System Administration Toolkit                ║
└════════════════════════════════════════════════════════════════════════════╝

EOF
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check bash version
    local bash_version
    bash_version=$(bash --version | head -1 | grep -oP '\d+\.\d+')
    log_success "Bash version: $bash_version"
    
    # Check required commands
    for cmd in awk grep tar find; do
        if command -v "$cmd" &>/dev/null; then
            log_success "Command available: $cmd"
        else
            log_error "Command not found: $cmd (required)"
            return 1
        fi
    done
    
    return 0
}

install_files() {
    log_info "Installing ShellOps to: $INSTALL_DIR"
    
    # Create directories
    mkdir -p "$INSTALL_DIR"/{bin,lib,config,docs,logs} || {
        log_error "Cannot create installation directories"
        return 1
    }
    log_success "Created directories"
    
    # Copy main script
    cp "$SCRIPT_DIR/shellops" "$INSTALL_DIR/bin/shellops" || {
        log_error "Failed to copy main script"
        return 1
    }
    chmod 755 "$INSTALL_DIR/bin/shellops"
    log_success "Installed: bin/shellops"
    
    # Copy lib files
    cp "$SCRIPT_DIR/lib/"*.sh "$INSTALL_DIR/lib/" || {
        log_error "Failed to copy library files"
        return 1
    }
    chmod 755 "$INSTALL_DIR/lib/"*.sh
    log_success "Installed: lib/*.sh"
    
    # Copy setup wizard
    cp "$SCRIPT_DIR/setup_wizard.sh" "$INSTALL_DIR/setup_wizard.sh" || {
        log_error "Failed to copy setup wizard"
        return 1
    }
    chmod 755 "$INSTALL_DIR/setup_wizard.sh"
    log_success "Installed: setup_wizard.sh"
    
    # Copy documentation
    cp "$SCRIPT_DIR/docs/"*.md "$INSTALL_DIR/docs/" || {
        log_error "Failed to copy documentation"
        return 1
    }
    log_success "Installed: docs/*.md"
    
    # Copy configs
    cp "$SCRIPT_DIR/config/shellops.conf.example" "$INSTALL_DIR/config/" || {
        log_error "Failed to copy config example"
        return 1
    }
    cp "$SCRIPT_DIR/config/backup.exclude" "$INSTALL_DIR/config/" || {
        log_error "Failed to copy backup exclude patterns"
        return 1
    }
    log_success "Installed: config files"
    
    # Copy README and CONTRIBUTING
    cp "$SCRIPT_DIR/README.md" "$INSTALL_DIR/README.md" || {
        log_error "Failed to copy README"
        return 1
    }
    cp "$SCRIPT_DIR/CONTRIBUTING.md" "$INSTALL_DIR/CONTRIBUTING.md" || {
        log_error "Failed to copy CONTRIBUTING"
        return 1
    }
    log_success "Installed: README.md, CONTRIBUTING.md"
    
    return 0
}

set_permissions() {
    log_info "Setting permissions..."
    
    # Set directory permissions
    chmod 755 "$INSTALL_DIR" "$INSTALL_DIR"/{bin,lib,config,docs,logs}
    
    # Set file permissions
    chmod 755 "$INSTALL_DIR/bin/shellops"
    chmod 755 "$INSTALL_DIR/lib/"*.sh
    chmod 755 "$INSTALL_DIR/setup_wizard.sh"
    chmod 644 "$INSTALL_DIR/config/"*
    chmod 644 "$INSTALL_DIR/docs/"*.md
    chmod 644 "$INSTALL_DIR/"*.md
    
    log_success "Permissions set correctly"
    return 0
}

create_symlink() {
    local bin_path="/usr/local/bin/shellops"
    
    log_info "Creating system-wide symlink..."
    
    # Check if we can install to /usr/local
    if [[ ! -w "/usr/local/bin" ]]; then
        log_warn "Cannot write to /usr/local/bin (not root?)"
        log_info "ShellOps will be available as: $INSTALL_DIR/bin/shellops"
        log_info "Or add to PATH: export PATH=\"\$PATH:$INSTALL_DIR/bin\""
        return 0
    fi
    
    # Create symlink
    if [[ -e "$bin_path" ]]; then
        log_warn "Symlink already exists at: $bin_path"
        read -p "Overwrite? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
        sudo rm -f "$bin_path" || return 1
    fi
    
    sudo ln -s "$INSTALL_DIR/bin/shellops" "$bin_path" || {
        log_error "Failed to create symlink"
        return 1
    }
    
    log_success "Created symlink: /usr/local/bin/shellops"
    return 0
}

update_shell_config() {
    log_info "Updating shell configuration..."
    
    local shell_config=""
    local add_path="export PATH=\"\$PATH:$INSTALL_DIR/bin\""
    
    # Find appropriate shell config file
    if [[ -f "$HOME/.bashrc" ]]; then
        shell_config="$HOME/.bashrc"
    elif [[ -f "$HOME/.bash_profile" ]]; then
        shell_config="$HOME/.bash_profile"
    elif [[ -f "$HOME/.zshrc" ]]; then
        shell_config="$HOME/.zshrc"
    fi
    
    if [[ -z "$shell_config" ]]; then
        log_warn "Could not find shell configuration file"
        return 0
    fi
    
    # Check if already added
    if grep -q "ShellOps" "$shell_config" 2>/dev/null; then
        log_info "PATH already configured in: $shell_config"
        return 0
    fi
    
    # Add PATH entry
    {
        echo ""
        echo "# ShellOps installation"
        echo "$add_path"
    } >> "$shell_config"
    
    log_success "Updated: $shell_config"
    return 0
}

validate_installation() {
    log_info "Validating installation..."
    
    # Check files exist
    for file in bin/shellops lib/common.sh setup_wizard.sh; do
        if [[ ! -f "$INSTALL_DIR/$file" ]]; then
            log_error "File not found: $file"
            return 1
        fi
    done
    
    # Check executables
    for file in bin/shellops lib/*.sh setup_wizard.sh; do
        if [[ ! -x "$INSTALL_DIR/$file" ]]; then
            log_error "File not executable: $file"
            return 1
        fi
    done
    
    # Test basic functionality
    if "$INSTALL_DIR/bin/shellops" help &>/dev/null; then
        log_success "Executable test passed"
    else
        log_error "Executable test failed"
        return 1
    fi
    
    return 0
}

show_completion() {
    cat << EOF

╔════════════════════════════════════════════════════════════════════════════╗
║                    Installation Complete! ✓                               ║
╚════════════════════════════════════════════════════════════════════════════╝

ShellOps has been installed to: $INSTALL_DIR

Next steps:

1. Reload your shell configuration:
   source ~/.bashrc            (or ~/.bash_profile, ~/.zshrc)

2. Run the setup wizard:
   shellops init
   or
   $INSTALL_DIR/bin/shellops init

3. Try basic commands:
   shellops health
   shellops help

4. Read the documentation:
   shellops help               (command reference)
   cat $INSTALL_DIR/docs/quick-start.md   (quick start guide)

5. Configure automated tasks (optional):
   shellops backup schedule    (enable automated backups)

For more information:
   shellops help [command]
   cat $INSTALL_DIR/README.md

EOF
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    show_header
    
    # Check prerequisites
    check_prerequisites || {
        log_error "Prerequisites check failed"
        exit 1
    }
    
    echo ""
    
    # Install files
    install_files || {
        log_error "Installation failed"
        exit 1
    }
    
    echo ""
    
    # Set permissions
    set_permissions || {
        log_error "Permission setup failed"
        exit 1
    }
    
    echo ""
    
    # Create symlink (optional, try but don't fail)
    create_symlink || true
    
    echo ""
    
    # Update shell config
    update_shell_config || true
    
    echo ""
    
    # Validate installation
    validate_installation || {
        log_error "Installation validation failed"
        exit 1
    }
    
    echo ""
    
    # Show completion message
    show_completion
    
    log_success "Installation successful!"
    exit 0
}

# ============================================================================
# Entry Point
# ============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
