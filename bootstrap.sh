#!/usr/bin/env bash
#
# dotfiles-bootstrap - Set up a fresh Linux install with your preferred
# packages, config files, and desktop tweaks. Fedora/KDE focus, but
# extensible to other distros and desktops.
#
# Usage: ./bootstrap.sh [options]
#   --dry-run    Print what would happen without doing it
#   --packages   Only install packages
#   --config     Only deploy config files
#   --services   Only enable systemd services
#   --all        Do everything (default)
#   --help       Show this message
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
RUN_PACKAGES=true
RUN_CONFIG=true
RUN_SERVICES=true

# ── Colors ───────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { printf "${CYAN}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[ OK ]${NC}  %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
err()   { printf "${RED}[ERR]${NC}  %s\n" "$*" >&2; }

# ── Argument parsing ─────────────────────────────────────────────────
parse_args() {
    case "${1:---all}" in
        --dry-run)  DRY_RUN=true; shift; parse_args "$@" ;;
        --packages) RUN_PACKAGES=true;  RUN_CONFIG=false; RUN_SERVICES=false ;;
        --config)   RUN_PACKAGES=false; RUN_CONFIG=true;  RUN_SERVICES=false ;;
        --services) RUN_PACKAGES=false; RUN_CONFIG=false; RUN_SERVICES=true  ;;
        --all)      RUN_PACKAGES=true;  RUN_CONFIG=true;   RUN_SERVICES=true  ;;
        --help|-h)
            head -12 "$0" | tail -8
            exit 0
            ;;
        *)
            err "Unknown option: $1"
            head -12 "$0" | tail -8
            exit 1
            ;;
    esac
}

# ── Helpers ──────────────────────────────────────────────────────────
run() {
    if $DRY_RUN; then
        printf "  ${YELLOW}DRY${NC} %s\n" "$*"
    else
        "$@"
    fi
}

detect_distro() {
    if [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

has_command() {
    command -v "$1" &>/dev/null
}

# ── Package lists ────────────────────────────────────────────────────
FEDORA_PACKAGES=(
    # Desktop / KDE
    kde-plasma-desktop
    konsole
    dolphin
    kate
    gwenview
    okular
    ark
    spectacle
    # Browser
    firefox
    # Terminal utilities
    git
    vim-enhanced
    neovim
    tmux
    fzf
    ripgrep
    fd-find
    bat
    eza
    htop
    btop
    curl
    wget
    rsync
    unzip
    p7zip
    # Development
    gcc
    gcc-c++
    make
    cmake
    python3
    python3-pip
    go
    rust
    cargo
    # System tools
    util-linux-user
    passwd
    firewalld
)

DEBIAN_PACKAGES=(
    # Desktop
    kde-plasma-desktop
    konsole
    dolphin
    kate
    gwenview
    okular
    ark
    spectacle
    # Browser
    firefox-esr
    # Terminal utilities
    git
    vim
    neovim
    tmux
    fzf
    ripgrep
    fd-find
    bat
    btop
    curl
    wget
    rsync
    unzip
    p7zip-full
    # Development
    gcc
    g++
    make
    cmake
    python3
    python3-pip
    golang-go
    # System tools
    ufw
)

ARCH_PACKAGES=(
    # Desktop / KDE
    plasma-meta
    konsole
    dolphin
    kate
    gwenview
    okular
    ark
    spectacle
    # Browser
    firefox
    # Terminal utilities
    git
    vim
    neovim
    tmux
    fzf
    ripgrep
    fd
    bat
    eza
    btop
    curl
    wget
    rsync
    unzip
    p7zip
    # Development
    gcc
    make
    cmake
    python
    python-pip
    go
    rust
    # System tools
    ufw
)

SYSTEMD_SERVICES=(
    firewalld
    NetworkManager
)

# ── Package installation ──────────────────────────────────────────────
install_packages_fedora() {
    info "Installing Fedora packages..."
    run sudo dnf upgrade -yq
    run sudo dnf install -yq "${FEDORA_PACKAGES[@]}"
    # Fedora: enable RPM Fusion free for multimedia codecs
    if ! dnf repolist | grep -q rpmfusion-free; then
        info "Enabling RPM Fusion free repository..."
        run sudo dnf install -yq "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    fi
    ok "Fedora packages installed"
}

install_packages_debian() {
    info "Installing Debian/Ubuntu packages..."
    run sudo apt-get update -qq
    run sudo apt-get upgrade -yqq
    run sudo apt-get install -yqq "${DEBIAN_PACKAGES[@]}"
    ok "Debian packages installed"
}

install_packages_arch() {
    info "Installing Arch packages..."
    run sudo pacman -Syu --noconfirm
    run sudo pacman -S --noconfirm "${ARCH_PACKAGES[@]}"
    ok "Arch packages installed"
}

install_packages() {
    local distro
    distro="$(detect_distro)"

    case "$distro" in
        fedora) install_packages_fedora ;;
        debian) install_packages_debian ;;
        arch)   install_packages_arch   ;;
        *)
            err "Unsupported distro. Add your package list to the script."
            exit 1
            ;;
    esac
}

# ── Config deployment ────────────────────────────────────────────────
ensure_dir() {
    local dest="$1"
    if $DRY_RUN; then
        printf "  ${YELLOW}DRY${NC} mkdir -p %s\n" "$dest"
    else
        mkdir -p "$dest"
    fi
}

deploy_file() {
    local src="$1"
    local dest="$2"

    if [[ ! -f "$src" ]]; then
        warn "Source file missing, skipping: $src"
        return
    fi

    if [[ -f "$dest" ]] && diff -q "$src" "$dest" &>/dev/null; then
        info "Already in place: $dest"
        return
    fi

    # Back up existing file
    if [[ -f "$dest" ]]; then
        run cp "$dest" "${dest}.bak.$(date +%s)"
    fi

    run cp "$src" "$dest"
    ok "Deployed: $dest"
}

deploy_configs() {
    info "Deploying dotfiles..."

    local DOTFILE_DIR="${SCRIPT_DIR}/dotfiles"

    if [[ ! -d "$DOTFILE_DIR" ]]; then
        warn "No dotfiles/ directory found at $DOTFILE_DIR"
        warn "Create dotfiles/ with your preferred structure (e.g. dotfiles/bashrc, dotfiles/tmux.conf)"
        return
    fi

    # Walk dotfiles/ and mirror structure into $HOME
    while IFS= read -r -d '' relpath; do
        local dest="${HOME}/${relpath#${DOTFILE_DIR}/}"
        ensure_dir "$(dirname "$dest")"
        deploy_file "$relpath" "$dest"
    done < <(find "$DOTFILE_DIR" -type f -print0 | sort -z)

    # Special: bashrc sourcing
    if [[ -f "${HOME}/.bashrc" ]] && ! grep -q 'dotfiles-bootstrap' "${HOME}/.bashrc"; then
        info "Appending bashrc source hook..."
        if ! $DRY_RUN; then
            cat >> "${HOME}/.bashrc" <<'BASHRC_HOOK'

# Added by dotfiles-bootstrap - source custom bashrc if present
if [[ -f "${HOME}/.bashrc.custom" ]]; then
    source "${HOME}/.bashrc.custom"
fi
BASHRC_HOOK
        fi
    fi

    # Set default editor to vim
    if ! $DRY_RUN; then
        if grep -q 'EDITOR=' "${HOME}/.bashrc" 2>/dev/null; then
            info "EDITOR already set in .bashrc, not overriding"
        else
            echo 'export EDITOR=vim' >> "${HOME}/.bashrc"
            ok "Set EDITOR=vim in .bashrc"
        fi
    fi

    # KDE: set dark mode via plasma config if available
    if has_command plasma-apply-lookandfeeltheme 2>/dev/null; then
        info "Setting KDE dark theme..."
        if ! $DRY_RUN; then
            run plasma-apply-lookandfeeltheme --apply org.kde.breezedark.desktop 2>/dev/null || \
                warn "Could not apply KDE dark theme (may need to log in first)"
        fi
    fi

    ok "Config deployment complete"
}

# ── Service management ───────────────────────────────────────────────
enable_services() {
    local distro
    distro="$(detect_distro)"

    info "Enabling systemd services..."

    case "$distro" in
        fedora)
            for svc in "${SYSTEMD_SERVICES[@]}"; do
                if systemctl is-enabled "$svc" &>/dev/null; then
                    info "Already enabled: $svc"
                else
                    run sudo systemctl enable --now "$svc"
                    ok "Enabled: $svc"
                fi
            done
            ;;
        debian)
            run sudo ufw enable 2>/dev/null || true
            for svc in NetworkManager; do
                if systemctl is-enabled "$svc" &>/dev/null; then
                    info "Already enabled: $svc"
                else
                    run sudo systemctl enable --now "$svc"
                    ok "Enabled: $svc"
                fi
            done
            ;;
        arch)
            for svc in NetworkManager; do
                if systemctl is-enabled "$svc" &>/dev/null; then
                    info "Already enabled: $svc"
                else
                    run sudo systemctl enable --now "$svc"
                    ok "Enabled: $svc"
                fi
            done
            ;;
    esac

    ok "Services configured"
}

# ── Main ─────────────────────────────────────────────────────────────
main() {
    parse_args "$@"

    local distro
    distro="$(detect_distro)"

    printf "\n"
    info "dotfiles-bootstrap"
    info "Distribution: $distro"
    info "Dry run: $DRY_RUN"
    info "Run packages: $RUN_PACKAGES"
    info "Run config:   $RUN_CONFIG"
    info "Run services:  $RUN_SERVICES"
    printf "\n"

    if [[ "$distro" == "unknown" ]]; then
        err "Could not detect Linux distribution."
        err "Supported: Fedora, Debian/Ubuntu, Arch"
        exit 1
    fi

    if $RUN_PACKAGES; then
        install_packages
    fi

    if $RUN_CONFIG; then
        deploy_configs
    fi

    if $RUN_SERVICES; then
        enable_services
    fi

    printf "\n"
    ok "Bootstrap complete! You may want to log out and back in for all changes to take effect."
}

main "$@"
