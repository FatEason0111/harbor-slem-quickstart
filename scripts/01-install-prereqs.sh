#!/usr/bin/env bash
set -euo pipefail

echo "[STEP 1] Install required packages on SLE Micro 6.2"
transactional-update pkg install podman podman-docker docker-compose openssl ca-certificates wget tar curl python3

cat <<'EOF'

[NEXT ACTION REQUIRED]
1) Reboot the host:
   reboot
2) After reboot, continue with:
   source ./scripts/00-vars.sh
   ./scripts/02-configure-host-and-certs.sh

EOF
