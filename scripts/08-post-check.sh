#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00-vars.sh"

echo "[STEP 8] Post-check"

cd "${HARBOR_LINK}"
docker compose ps
curl -kI "https://${HARBOR_HOSTNAME}" || true

echo
echo "[DEBUG] Useful commands:"
echo "  docker compose logs --tail=100"
echo "  podman ps -a"
echo "  podman logs harbor-core"
echo "  podman logs nginx"
