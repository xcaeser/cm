#!/bin/sh

# This script downloads and installs the latest binary release of 'cumul'
# from GitHub for your OS and architecture.
#
# Usage: ./install.sh
#    or: curl -sSfL https://raw.githubusercontent.com/YOUR_USERNAME/cumul/main/install.sh | sh

set -e

# Function to print colored output
colored_echo() {
    local color=$1
    local text=$2
    case $color in
        "red")    printf "\033[31m%s\033[0m\n" "$text" ;;
        "green")  printf "\033[32m%s\033[0m\n" "$text" ;;
        "yellow") printf "\033[33m%s\033[0m\n" "$text" ;;
        "blue")   printf "\033[34m%s\033[0m\n" "$text" ;;
        *)        echo "$text" ;;
    esac
}

# Check for necessary tools
for tool in curl grep sed cut; do
    if ! command -v $tool >/dev/null 2>&1; then
        colored_echo "red" "Error: '$tool' is not installed. Please install it first."
        exit 1
    fi
done

# --- Configuration ---
GITHUB_REPO="xcaeser/cm"
INSTALL_DIR="/usr/local/bin"
BINARY_NAME="cm"

# --- Detect OS and Architecture ---
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH_TYPE=$(uname -m)

case $OS_TYPE in
    linux)
        OS="linux"
        ;;
    darwin)
        OS="macos"
        ;;
    *)
        colored_echo "red" "Unsupported OS: $OS_TYPE"
        exit 1
        ;;
esac

case $ARCH_TYPE in
    x86_64 | amd64)
        ARCH="amd64"
        ;;
    aarch64 | arm64)
        ARCH="arm64"
        ;;
    *)
        colored_echo "red" "Unsupported architecture: $ARCH_TYPE"
        exit 1
        ;;
esac

# --- Get Latest Release URL ---
colored_echo "blue" "Fetching the latest release information from GitHub..."
API_URL="https://api.github.com/repos/$GITHUB_REPO/releases/latest"

# Use curl to get the latest release data and grep for the download URL
# that matches the OS and architecture.
DOWNLOAD_URL=$(curl -sSL "$API_URL" | grep "browser_download_url" | grep "$OS" | grep "$ARCH" | cut -d '"' -f 4 | head -n 1)

if [ -z "$DOWNLOAD_URL" ]; then
    colored_echo "red" "Error: Could not find a release asset for your system ($OS-$ARCH)."
    colored_echo "yellow" "Please check the releases page: https://github.com/$GITHUB_REPO/releases"
    exit 1
fi

colored_echo "green" "Found download URL: $DOWNLOAD_URL"

# --- Download and Install ---
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT # Cleanup on exit

# Assuming the downloaded file is a compressed tarball (e.g., .tar.gz)
# If it's just the binary, you can simplify this.
TARBALL_PATH="$TMP_DIR/${BINARY_NAME}.tar.gz"
colored_echo "blue" "Downloading to $TARBALL_PATH..."

curl -L --progress-bar "$DOWNLOAD_URL" -o "$TARBALL_PATH"

colored_echo "blue" "Extracting the binary..."
tar -xzf "$TARBALL_PATH" -C "$TMP_DIR"

# Find the binary in the extracted files (can be adapted if the name differs)
EXTRACTED_BINARY=$(find "$TMP_DIR" -type f -name "$BINARY_NAME")

if [ ! -f "$EXTRACTED_BINARY" ]; then
    colored_echo "red" "Error: Binary '$BINARY_NAME' not found in the downloaded archive."
    exit 1
fi

colored_echo "blue" "Installing the binary to $INSTALL_DIR..."

# Move the binary to the installation directory. May require sudo.
if [ -w "$INSTALL_DIR" ]; then
    mv "$EXTRACTED_BINARY" "$INSTALL_DIR/$BINARY_NAME"
    chmod +x "$INSTALL_DIR/$BINARY_NAME"
else
    colored_echo "yellow" "Write permission to $INSTALL_DIR is required. Using sudo..."
    sudo mv "$EXTRACTED_BINARY" "$INSTALL_DIR/$BINARY_NAME"
    sudo chmod +x "$INSTALL_DIR/$BINARY_NAME"
fi

# --- Verification ---
if command -v $BINARY_NAME >/dev/null 2>&1; then
    INSTALLED_PATH=$(command -v $BINARY_NAME)
    colored_echo "green" "Installation successful!"
    colored_echo "blue" "'$BINARY_NAME' is now available at: $INSTALLED_PATH"
    colored_echo "blue" "You can now run '$BINARY_NAME --version' to test it."
else
    colored_echo "red" "Installation failed. Please check your PATH or try again."
    exit 1
fi