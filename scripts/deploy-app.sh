#!/bin/bash
# ============================================================================
# Deployment Script - Transfer and deploy .NET application to Azure VM
# Project: Rayan - Azure Cloud Deployment
# Usage: bash deploy-app.sh <VM_IP_OR_FQDN> [SSH_KEY_PATH]
# ============================================================================

set -euo pipefail

# -------------------------------------------
# Configuration
# -------------------------------------------
VM_HOST="${1:?Usage: deploy-app.sh <VM_IP_OR_FQDN> [SSH_KEY_PATH]}"
SSH_KEY="${2:-~/.ssh/id_rsa}"
VM_USER="azureuser"
REMOTE_APP_DIR="/opt/webapp"
LOCAL_PROJECT_DIR="$(cd "$(dirname "$0")/../src/WebApp" && pwd)"
PUBLISH_DIR="/tmp/webapp-publish"

echo "========================================"
echo "  Rayan - Application Deployment"
echo "========================================"
echo ""
echo "  Target: ${VM_USER}@${VM_HOST}"
echo "  Source:  ${LOCAL_PROJECT_DIR}"
echo ""

# -------------------------------------------
# Step 1: Build and publish the application
# -------------------------------------------
echo "[1/5] Building and publishing application..."
rm -rf "${PUBLISH_DIR}"
dotnet publish "${LOCAL_PROJECT_DIR}" \
    --configuration Release \
    --output "${PUBLISH_DIR}" \
    --runtime linux-x64 \
    --self-contained false

echo "  Published $(find "${PUBLISH_DIR}" -type f | wc -l) files."

# -------------------------------------------
# Step 2: Transfer files to VM
# -------------------------------------------
echo "[2/5] Transferring files to VM..."
ssh -i "${SSH_KEY}" -o StrictHostKeyChecking=accept-new "${VM_USER}@${VM_HOST}" \
    "sudo mkdir -p ${REMOTE_APP_DIR} && sudo chown ${VM_USER}:${VM_USER} ${REMOTE_APP_DIR}"

scp -i "${SSH_KEY}" -r "${PUBLISH_DIR}/"* "${VM_USER}@${VM_HOST}:${REMOTE_APP_DIR}/"

echo "  Files transferred."

# -------------------------------------------
# Step 3: Transfer and install systemd service
# -------------------------------------------
echo "[3/5] Installing systemd service..."
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
scp -i "${SSH_KEY}" "${SCRIPT_DIR}/config/webapp.service" "${VM_USER}@${VM_HOST}:/tmp/webapp.service"

ssh -i "${SSH_KEY}" "${VM_USER}@${VM_HOST}" << 'REMOTE_COMMANDS'
    sudo mv /tmp/webapp.service /etc/systemd/system/webapp.service
    sudo systemctl daemon-reload
REMOTE_COMMANDS

echo "  Systemd service installed."

# -------------------------------------------
# Step 4: Start/restart the application
# -------------------------------------------
echo "[4/5] Starting application..."
ssh -i "${SSH_KEY}" "${VM_USER}@${VM_HOST}" << 'REMOTE_COMMANDS'
    sudo systemctl enable webapp
    sudo systemctl restart webapp
    sleep 3
    sudo systemctl status webapp --no-pager
REMOTE_COMMANDS

# -------------------------------------------
# Step 5: Verify deployment
# -------------------------------------------
echo "[5/5] Verifying deployment..."
sleep 2

HTTP_STATUS=$(ssh -i "${SSH_KEY}" "${VM_USER}@${VM_HOST}" \
    "curl -s -o /dev/null -w '%{http_code}' http://localhost:5000" 2>/dev/null || echo "000")

if [ "${HTTP_STATUS}" = "200" ]; then
    echo ""
    echo "========================================"
    echo "  Deployment successful!"
    echo "  Application is running on port 5000."
    echo "  URL: http://${VM_HOST}:5000"
    echo "  URL: http://${VM_HOST} (if reverse proxy configured)"
    echo "========================================"
else
    echo ""
    echo "========================================"
    echo "  WARNING: Application may not be responding."
    echo "  HTTP Status: ${HTTP_STATUS}"
    echo "  Check logs: ssh ${VM_USER}@${VM_HOST} 'journalctl -u webapp -f'"
    echo "========================================"
    exit 1
fi

# Cleanup
rm -rf "${PUBLISH_DIR}"
