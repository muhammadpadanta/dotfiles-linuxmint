#!/bin/bash

# Linux Mint Package Installer
# Based on macOS Brewfile conversion
# Includes VS Code extensions installation

set -e

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== Linux Mint Package Installer =====${NC}"
echo -e "${YELLOW}This script will install equivalent packages from your macOS Brewfile${NC}"
echo

# Function to check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# Function to install a package if not already installed
install_package() {
  if dpkg -l | grep -q "^ii  $1 "; then
    echo -e "${GREEN}✓${NC} $1 is already installed"
  else
    echo -e "${BLUE}Installing${NC} $1..."
    sudo apt-get install -y "$1"
  fi
}

# Function to install a deb package from URL
install_deb_from_url() {
  local package_name=$1
  local url=$2
  local filename=$(basename "$url")
  
  if command_exists "$package_name"; then
    echo -e "${GREEN}✓${NC} $package_name is already installed"
  else
    echo -e "${BLUE}Installing ${package_name}...${NC}"
    wget -O "$filename" "$url"
    sudo apt-get install -y "./$filename"
    rm "$filename"
  fi
}

# Function to add a PPA
add_ppa() {
  if ! grep -q "^deb .*$1" /etc/apt/sources.list /etc/apt/sources.list.d/*; then
    echo -e "${BLUE}Adding PPA${NC} $1..."
    sudo add-apt-repository -y "ppa:$1"
  else
    echo -e "${GREEN}✓${NC} PPA $1 is already added"
  fi
}

# Function to install VS Code extension
install_vscode_extension() {
  if code --list-extensions | grep -q "^$1$"; then
    echo -e "${GREEN}✓${NC} VS Code extension $1 is already installed"
  else
    echo -e "${BLUE}Installing VS Code extension${NC} $1..."
    code --install-extension "$1"
  fi
}

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}Please don't run this script as root. It will use sudo when needed.${NC}"
  exit 1
fi

# Update package lists
echo -e "${BLUE}Updating package lists...${NC}"
sudo apt-get update

# Install basic build tools and dependencies
echo -e "\n${YELLOW}Installing essential build tools and dependencies...${NC}"
sudo apt-get install -y build-essential curl wget software-properties-common apt-transport-https ca-certificates gnupg-agent

# Install JetBrains Mono Nerd Font
echo -e "\n${YELLOW}Installing JetBrains Mono Nerd Font...${NC}"
if [ ! -d "$HOME/.local/share/fonts/NerdFonts/JetBrainsMono" ]; then
  mkdir -p "$HOME/.local/share/fonts/NerdFonts/JetBrainsMono"
  echo -e "${BLUE}Installing JetBrains Mono Nerd Font...${NC}"
  wget -O jetbrainsmono.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
  unzip -o jetbrainsmono.zip -d "$HOME/.local/share/fonts/NerdFonts/JetBrainsMono"
  rm jetbrainsmono.zip
  
  fc-cache -fv
fi

# GUI Applications
echo -e "\n${YELLOW}Installing GUI Applications...${NC}"

# Discord
install_deb_from_url "discord" "https://discord.com/api/download?platform=linux&format=deb"

# Google Chrome
install_deb_from_url "google-chrome-stable" "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

# OBS Studio
install_package "obs-studio"

# Obsidian
install_deb_from_url "obsidian" "https://github.com/obsidianmd/obsidian-releases/releases/download/v1.4.13/obsidian_1.4.13_amd64.deb"

# Postman
if ! command_exists postman; then
  echo -e "${BLUE}Installing Postman...${NC}"
  wget -O postman.tar.gz https://dl.pstmn.io/download/latest/linux64
  sudo tar -xzf postman.tar.gz -C /opt
  sudo ln -s /opt/Postman/Postman /usr/bin/postman
  echo "[Desktop Entry]
Name=Postman
GenericName=API Client
X-GNOME-FullName=Postman API Client
Comment=Make and view REST API calls and responses
Keywords=api;
Exec=/opt/Postman/Postman
Terminal=false
Type=Application
Icon=/opt/Postman/app/resources/app/assets/icon.png
Categories=Development;Utility;" | sudo tee /usr/share/applications/postman.desktop
  rm postman.tar.gz
fi

# Spotify
if ! command_exists spotify; then
  echo -e "${BLUE}Installing Spotify...${NC}"
  curl -sS https://download.spotify.com/debian/pubkey_6224F9941A8AA6D1.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
  echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
  sudo apt-get update
  sudo apt-get install -y spotify-client
fi

# Steam
install_package "steam-installer"

# VS Code
if ! command_exists code; then
  echo -e "${BLUE}Installing Visual Studio Code...${NC}"
  wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
  sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/trusted.gpg.d/
  sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
  rm -f packages.microsoft.gpg
  sudo apt-get update
  sudo apt-get install -y code
fi

# VLC
install_package "vlc"

# VNC Viewer
install_package "tigervnc-viewer"

# Zoom
install_deb_from_url "zoom" "https://zoom.us/client/latest/zoom_amd64.deb"

# CLI tools
echo -e "\n${YELLOW}Installing CLI tools...${NC}"

# Define an array of simple packages to install
CLI_PACKAGES=(
  "aria2"
  "autoconf"
  "automake"
  "bash"
  "bc"
  "coreutils"
  "curl"
  "ffmpeg"
  "fish"
  "fzf"
  "gawk"
  "git"
  "jq"
  "make"
  "neovim"
  "nmap"
  "ripgrep"
  "smartmontools"
  "stow"
  "tldr"
  "unzip"
  "wget"
  "yt-dlp"
)

# Install simple packages
for package in "${CLI_PACKAGES[@]}"; do
  install_package "$package"
done

# Install bat (might be named differently)
install_package "bat" || install_package "batcat"

# Install btop (with htop fallback)
install_package "btop" || install_package "htop"

# Install fd-find
install_package "fd-find"

# Install neofetch
install_package "neofetch"

# Install dev libraries
DEV_LIBRARIES=(
  "libevent-dev"
  "libfftw3-dev"
  "libasound2-dev"
  "libncursesw5-dev"
  "libpulse-dev"
  "libtool"
  "ncurses-dev"
  "libtree-sitter-dev"
  "libutf8proc-dev"
)

# Install dev libraries
for package in "${DEV_LIBRARIES[@]}"; do
  install_package "$package"
done

# Install CAVA
if ! command_exists cava; then
  echo -e "${BLUE}Installing CAVA from source...${NC}"
  git clone https://github.com/karlstav/cava.git
  cd cava
  ./autogen.sh
  ./configure
  make
  sudo make install
  cd ..
  rm -rf cava
fi

# Install eza
if ! command_exists eza; then
  echo -e "${BLUE}Installing eza (modern ls replacement)...${NC}"
  sudo apt-get install -y gpg
  mkdir -p ~/.local/bin
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update
  sudo apt-get install -y eza
fi

# GitHub CLI
if ! command_exists gh; then
  echo -e "${BLUE}Installing GitHub CLI...${NC}"
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
  sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
  sudo apt-get update
  sudo apt-get install -y gh
fi

# GitLab CLI
if ! command_exists glab; then
  echo -e "${BLUE}Installing GitLab CLI...${NC}"
  sudo apt-get install -y golang-go
  go install gitlab.com/gitlab-org/cli/cmd/glab@latest
  if [[ ":$PATH:" != *":$HOME/go/bin:"* ]]; then
    echo 'export PATH="$PATH:$HOME/go/bin"' >> ~/.bashrc
    echo 'export PATH="$PATH:$HOME/go/bin"' >> ~/.profile
  fi
fi

# LazyGit
if ! command_exists lazygit; then
  echo -e "${BLUE}Installing LazyGit...${NC}"
  LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
  curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar xf lazygit.tar.gz lazygit
  sudo install lazygit /usr/local/bin
  rm lazygit lazygit.tar.gz
fi

# mise (replacement for asdf)
if ! command_exists mise; then
  echo -e "${BLUE}Installing mise...${NC}"
  curl https://mise.run | sh
fi

# Spicetify
if ! command_exists spicetify; then
  echo -e "${BLUE}Installing Spicetify...${NC}"
  curl -fsSL https://raw.githubusercontent.com/spicetify/spicetify-cli/master/install.sh | sh
  if [[ ":$PATH:" != *":$HOME/.spicetify:"* ]]; then
    echo 'export PATH="$PATH:$HOME/.spicetify"' >> ~/.bashrc
    echo 'export PATH="$PATH:$HOME/.spicetify"' >> ~/.profile
  fi
fi

# Starship prompt
if ! command_exists starship; then
  echo -e "${BLUE}Installing Starship prompt...${NC}"
  curl -sS https://starship.rs/install.sh | sh
fi

# Yarn
if ! command_exists yarn; then
  echo -e "${BLUE}Installing Yarn...${NC}"
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
  sudo apt-get update
  sudo apt-get install -y yarn
fi

# Zoxide (smart cd)
if ! command_exists zoxide; then
  echo -e "${BLUE}Installing zoxide...${NC}"
  curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

# Install VS Code Extensions
echo -e "\n${YELLOW}Installing Visual Studio Code Extensions...${NC}"
if command_exists code; then
  VSCODE_EXTENSIONS=(
    "aaron-bond.better-comments"
    "adpyke.codesnap"
    "akamud.vscode-theme-onedark"
    "alexisvt.flutter-snippets"
    "anseki.vscode-color"
    "be5invis.vscode-custom-css"
    "bradlc.vscode-tailwindcss"
    "catppuccin.catppuccin-vsc"
    "chadalen.vscode-jetbrains-icon-theme"
    "christian-kohler.npm-intellisense"
    "christian-kohler.path-intellisense"
    "dart-code.dart-code"
    "dart-code.flutter"
    "dbaeumer.vscode-eslint"
    "donjayamanne.githistory"
    "dracula-theme.theme-dracula"
    "eamodio.gitlens"
    "ecmel.vscode-html-css"
    "enkia.tokyo-night"
    "esbenp.prettier-vscode"
    "formulahendry.auto-close-tag"
    "formulahendry.auto-complete-tag"
    "formulahendry.auto-rename-tag"
    "formulahendry.code-runner"
    "github.copilot"
    "github.copilot-chat"
    "github.github-vscode-theme"
    "github.remotehub"
    "golang.go"
    "hzgood.dart-data-class-generator"
    "illixion.vscode-vibrancy-continued"
    "inferrinizzard.prettier-sql-vscode"
    "jdinhlife.gruvbox"
    "jeroen-meijer.pubspec-assist"
    "marcelovelasquez.flutter-tree"
    "mhutchie.git-graph"
    "miguelsolorio.fluent-icons"
    "mikaelkristiansson87.react-theme-vscode"
    "ms-azuretools.vscode-docker"
    "ms-python.debugpy"
    "ms-python.python"
    "ms-python.vscode-pylance"
    "ms-vscode.azure-repos"
    "ms-vscode.remote-repositories"
    "mvllow.rose-pine"
    "pflannery.vscode-versionlens"
    "pkief.material-icon-theme"
    "postman.postman-for-vscode"
    "pranaygp.vscode-css-peek"
    "robbowen.synthwave-vscode"
    "rvest.vs-code-prettier-eslint"
    "shd101wyy.markdown-preview-enhanced"
    "sporiley.css-auto-prefix"
    "steoates.autoimport"
    "teabyii.ayu"
    "tonybaloney.vscode-pets"
    "usernamehw.errorlens"
    "vscjava.vscode-gradle"
    "wix.vscode-import-cost"
    "yandeu.five-server"
    "zignd.html-css-class-completion"
  )

  for extension in "${VSCODE_EXTENSIONS[@]}"; do
    install_vscode_extension "$extension"
  done
else
  echo -e "${YELLOW}VS Code is not installed. Skipping extensions installation.${NC}"
fi

echo -e "\n${GREEN}All Done!${NC}"
echo -e "${BLUE}Linux Mint Package Installation Complete${NC}"
echo -e "${YELLOW}You may need to log out and log back in for some changes to take effect.${NC}"