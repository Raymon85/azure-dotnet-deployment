#!/bin/bash
# ============================================================================
# .NET Runtime Installation Script for Ubuntu 22.04
# Project: Rayan - Azure Cloud Deployment
# Usage: sudo bash setup-dotnet.sh
# ============================================================================

set -euo pipefail

DOTNET_VERSION="8.0"
APP_USER="azureuser"
APP_DIR="/opt/webapp"

echo "========================================"
echo "  Rayan - .NET Runtime Setup"
echo "========================================"
echo ""

# -------------------------------------------
# Step 1: Update system packages
# -------------------------------------------
echo "[1/5] Updating system packages..."
apt-get update -y
apt-get upgrade -y

# -------------------------------------------
# Step 2: Install prerequisites
# -------------------------------------------
echo "[2/5] Installing prerequisites..."
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    unzip \
    wget

# -------------------------------------------
# Step 3: Install .NET Runtime
# -------------------------------------------
echo "[3/5] Installing .NET ${DOTNET_VERSION} Runtime..."

# Add Microsoft package repository
wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
dpkg -i /tmp/packages-microsoft-prod.deb
rm /tmp/packages-microsoft-prod.deb

apt-get update -y
apt-get install -y aspnetcore-runtime-${DOTNET_VERSION}

echo "  .NET Runtime version:"
dotnet --list-runtimes

# -------------------------------------------
# Step 4: Create application directory
# -------------------------------------------
echo "[4/5] Creating application directory..."
mkdir -p ${APP_DIR}
chown ${APP_USER}:${APP_USER} ${APP_DIR}

# -------------------------------------------
# Step 5: Configure firewall (if ufw is active)
# -------------------------------------------
echo "[5/5] Configuring firewall..."
if command -v ufw &> /dev/null; then
    ufw allow 22/tcp   # SSH
    ufw allow 80/tcp   # HTTP
    ufw allow 5000/tcp # App direct access
    echo "  Firewall rules added."
else
    echo "  UFW not found, skipping firewall configuration."
fi

echo ""
echo "========================================"
echo "  Setup complete!"
echo "  .NET Runtime ${DOTNET_VERSION} is installed."
echo "  Application directory: ${APP_DIR}"
echo "========================================"
