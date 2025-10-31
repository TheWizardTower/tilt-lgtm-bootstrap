#!/bin/bash
set -euo pipefail

# Use this script if flox/nix isn't a reasonable choice for your environment.
echo "Installing tools..."

# Detect OS
OS="unknown"
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if [ -f /etc/fedora-release ]; then
        OS="fedora"
    elif [ -f /etc/debian_version ]; then
        OS="debian"
    fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS="macos"
fi

# Install Tilt
if ! command -v tilt &>/dev/null; then
    echo "Installing Tilt..."
    curl -fsSL https://raw.githubusercontent.com/tilt-dev/tilt/master/scripts/install.sh | bash
else
    echo "✅ Tilt already installed: $(tilt version)"
fi

# Install k9s
if ! command -v k9s &>/dev/null; then
    echo "Installing k9s..."
    case $OS in
    fedora)
        sudo dnf install -y k9s
        ;;
    debian)
        # Install from GitHub releases
        K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest | grep tag_name | cut -d '"' -f 4)
        wget https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz
        tar -xzf k9s_Linux_amd64.tar.gz
        sudo mv k9s /usr/local/bin/
        rm k9s_Linux_amd64.tar.gz
        ;;
    macos)
        brew install k9s
        ;;
    *)
        echo "⚠️  Please install k9s manually: https://k9scli.io/topics/install/"
        ;;
    esac
else
    echo "✅ k9s already installed"
fi

# Install helm
if ! command -v helm &>/dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "✅ Helm already installed: $(helm version --short)"
fi

echo ""
echo "✅ All tools installed!"
