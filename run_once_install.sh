#!/usr/bin/env bash
# install.sh — Interactive development environment setup for Linux (Debian/Ubuntu)
#
# Usage:
#   bash install.sh
#
# Run once via chezmoi (run_once_install.sh) after the first `chezmoi apply`.

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
step()  { echo -e "\n${CYAN}▶ $*${NC}"; }

confirm() {
  local prompt="${1:-Continue?}"
  local default="${2:-n}"
  local yn
  if [[ "$default" == "y" ]]; then
    read -r -p "  ${prompt} [Y/n] " yn
    [[ -z "$yn" || "$yn" =~ ^[Yy]$ ]]
  else
    read -r -p "  ${prompt} [y/N] " yn
    [[ "$yn" =~ ^[Yy]$ ]]
  fi
}

require_linux() {
  [[ "$(uname -s)" == "Linux" ]] || { error "This script supports Linux only."; exit 1; }
}

require_debian() {
  command -v apt-get &>/dev/null || {
    error "apt-get not found. This script requires a Debian/Ubuntu-based system."
    exit 1
  }
}

apt_install() {
  info "Installing: $*"
  sudo apt-get install -y "$@"
}

# ── Installers ────────────────────────────────────────────────────────────────

setup_base_tools() {
  step "Base tools"
  sudo apt-get update -qq
  apt_install \
    curl wget git vim \
    net-tools nmap iputils-ping dnsutils \
    build-essential ca-certificates gnupg lsb-release \
    unzip zip htop jq tree
}

setup_zsh() {
  step "zsh"
  if command -v zsh &>/dev/null; then
    info "zsh is already installed: $(zsh --version)"
  else
    apt_install zsh
  fi

  if confirm "Set zsh as the default shell for $USER?" y; then
    sudo chsh -s "$(command -v zsh)" "$USER"
    info "Default shell changed to zsh. Log out and back in to take effect."
  fi
}

setup_omz() {
  step "oh-my-zsh + Powerlevel10k + plugins"

  if [[ -d "$HOME/.oh-my-zsh" ]]; then
    info "oh-my-zsh is already installed."
  else
    info "Installing oh-my-zsh..."
    RUNZSH=no CHSH=no \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    info "Installing zsh-autosuggestions..."
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
  else
    info "zsh-autosuggestions already installed."
  fi

  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    info "Installing zsh-syntax-highlighting..."
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
  else
    info "zsh-syntax-highlighting already installed."
  fi

  if [[ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    info "Installing Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
      "$ZSH_CUSTOM/themes/powerlevel10k"
    info "Run 'p10k configure' after your first zsh login to set up the prompt."
  else
    info "Powerlevel10k already installed."
  fi
}

setup_chezmoi() {
  step "chezmoi"
  if command -v chezmoi &>/dev/null; then
    info "chezmoi is already installed: $(chezmoi --version)"
  else
    info "Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    info "Make sure \$HOME/.local/bin is on your PATH."
  fi
}

setup_gh() {
  step "GitHub CLI (gh)"
  if command -v gh &>/dev/null; then
    info "GitHub CLI is already installed: $(gh --version | head -1)"
    return
  fi
  info "Installing GitHub CLI..."
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list
  sudo apt-get update -qq
  apt_install gh
  info "Authenticate with: gh auth login"
}

setup_opencode() {
  step "opencode"
  if command -v opencode &>/dev/null; then
    info "opencode is already installed."
    return
  fi
  info "Installing opencode AI coding assistant..."
  warn "The following command pipes a remote script to bash."
  warn "Review it first: curl -fsSL https://opencode.ai/install"
  if confirm "Proceed with curl | bash install?"; then
    curl -fsSL https://opencode.ai/install | bash \
      || warn "Could not install opencode. Check https://opencode.ai for manual install instructions."
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
  require_linux
  require_debian

  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║   Development Environment Setup              ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
  echo ""
  echo "Select what to install (press Enter to accept the default):"
  echo ""

  local want_base=false
  local want_zsh=false
  local want_omz=false
  local want_chezmoi=false
  local want_gh=false
  local want_opencode=false

  echo "── Core ──────────────────────────────────────────"
  confirm "Base tools  (vim, curl, wget, git, net-tools, nmap, jq, htop...)" y \
    && want_base=true
  confirm "zsh shell + set as default"                                       y \
    && want_zsh=true
  confirm "oh-my-zsh + Powerlevel10k + zsh plugins"                         y \
    && want_omz=true
  confirm "chezmoi  (dotfiles manager)"                                      y \
    && want_chezmoi=true

  echo ""
  echo "── Developer tools ───────────────────────────────"
  confirm "GitHub CLI  (gh)"     && want_gh=true
  confirm "opencode  (AI coding assistant)" && want_opencode=true

  echo ""

  [[ "$want_base"     == true ]] && setup_base_tools
  [[ "$want_zsh"      == true ]] && setup_zsh
  [[ "$want_omz"      == true ]] && setup_omz
  [[ "$want_chezmoi"  == true ]] && setup_chezmoi
  [[ "$want_gh"       == true ]] && setup_gh
  [[ "$want_opencode" == true ]] && setup_opencode

  echo ""
  step "Done! Next steps"
  echo "  1. Apply dotfiles:       ~/.local/bin/chezmoi init --apply https://github.com/lab86-work/dotfiles.git"
  echo "  2. Configure prompt:     p10k configure"
  echo "  3. Restart your shell or run: exec zsh"
  echo ""
}

main "$@"
