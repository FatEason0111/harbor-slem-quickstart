#!/usr/bin/env bash
set -euo pipefail

# ===== Basic variables (edit before use) =====
export HARBOR_VERSION="2.14.3"
export HARBOR_HOSTNAME="harbortest.lab.local"
export HARBOR_IP="192.168.202.140"

export HARBOR_ADMIN_PASSWORD="Harbor12345!"
export HARBOR_DB_PASSWORD="HarborDB12345!"

export COUNTRY="CN"
export STATE="Shanghai"
export CITY="Shanghai"
export ORG="Lab"
export ORG_UNIT="IT"

# ===== Derived variables =====
export CERT_DIR="/root/certs"
export HARBOR_DATA="/var/lib/harbor"
export HARBOR_CERT_DIR="${HARBOR_DATA}/cert"
export HARBOR_INSTALL_ROOT="/opt"
export HARBOR_BASE="${HARBOR_INSTALL_ROOT}/harbor-${HARBOR_VERSION}"
export HARBOR_LINK="${HARBOR_INSTALL_ROOT}/harbor"
export HARBOR_RELEASE_URL="https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/harbor-offline-installer-v${HARBOR_VERSION}.tgz"

echo "[INFO] Loaded variables:"
echo "       HARBOR_VERSION=${HARBOR_VERSION}"
echo "       HARBOR_HOSTNAME=${HARBOR_HOSTNAME}"
echo "       HARBOR_IP=${HARBOR_IP}"
echo "       HARBOR_BASE=${HARBOR_BASE}"
