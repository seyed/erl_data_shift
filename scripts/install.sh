#!/usr/bin/env bash
set -e

REPO="https://github.com/seyed/erl_data_shift" 
INSTALL_DIR="${EDS_INSTALL_DIR:-$HOME/.local/bin}"

echo "🔍 Detecting platform..."

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
    Darwin)
        ASSET="eds-macos-arm64"
        ;;
    Linux)
        ASSET="eds-linux-x86_64"
        ;;
    *)
        echo "❌ Unsupported OS: $OS. Only macOS and Linux are supported."
        exit 1
        ;;
esac

echo "📦 Fetching latest release info..."
LATEST_URL=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep "browser_download_url.*${ASSET}" \
    | cut -d '"' -f 4)

if [ -z "$LATEST_URL" ]; then
    echo "❌ Could not find a release asset matching ${ASSET}."
    echo "   Check https://github.com/${REPO}/releases manually."
    exit 1
fi

mkdir -p "$INSTALL_DIR"
DEST="${INSTALL_DIR}/eds"

echo "⬇️  Downloading ${ASSET}..."
curl -fsSL "$LATEST_URL" -o "$DEST"
chmod +x "$DEST"

# macOS Gatekeeper blocks unsigned downloaded binaries by default — clear
# the quarantine flag so it runs without a manual right-click-Open step.
if [ "$OS" = "Darwin" ]; then
    xattr -d com.apple.quarantine "$DEST" 2>/dev/null || true
fi

echo "✅ Installed to ${DEST}"

case ":$PATH:" in
    *":${INSTALL_DIR}:"*)
        echo "🎉 Run 'eds --help' to get started."
        ;;
    *)
        echo "⚠️  ${INSTALL_DIR} is not on your PATH."
        echo "   Add this to your shell profile (~/.zshrc, ~/.bashrc, etc.):"
        echo "     export PATH=\"${INSTALL_DIR}:\$PATH\""
        ;;
esac