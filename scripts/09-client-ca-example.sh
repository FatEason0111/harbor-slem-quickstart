#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00-vars.sh"

echo "[STEP 9] Example: trust Harbor CA on another Linux client"

echo "Create the CA trust path for your registry client, then copy:"
echo "  ${CERT_DIR}/ca.crt"
echo
echo "Example for Podman client:"
echo "  mkdir -p /etc/containers/certs.d/${HARBOR_HOSTNAME}"
echo "  cp ca.crt /etc/containers/certs.d/${HARBOR_HOSTNAME}/ca.crt"
echo
echo "Example for Docker client:"
echo "  mkdir -p /etc/docker/certs.d/${HARBOR_HOSTNAME}"
echo "  cp ca.crt /etc/docker/certs.d/${HARBOR_HOSTNAME}/ca.crt"
