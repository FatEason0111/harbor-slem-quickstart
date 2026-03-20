#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00-vars.sh"

echo "[STEP 3] Enable Podman socket for docker-compose compatibility"

systemctl enable --now podman.socket
systemctl status podman.socket --no-pager || true

test -S /run/podman/podman.sock
docker info >/dev/null

echo "[OK] Podman API socket is ready at /run/podman/podman.sock"
