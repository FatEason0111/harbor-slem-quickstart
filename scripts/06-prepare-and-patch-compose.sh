#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00-vars.sh"

echo "[STEP 6] Load offline images, run prepare, and patch compose for Podman"

cd "${HARBOR_LINK}"

IMAGE_TAR="$(find . -maxdepth 1 -type f -name 'harbor*.tar.gz' | head -n1)"
if [[ -z "${IMAGE_TAR}" ]]; then
  echo "[ERROR] Harbor offline image tarball not found under ${HARBOR_LINK}"
  exit 1
fi

docker load -i "${IMAGE_TAR}"
./prepare

cp docker-compose.yml docker-compose.yml.bak

python3 - <<'PY'
from pathlib import Path
p = Path("docker-compose.yml")
text = p.read_text(encoding="utf-8")
lines = text.splitlines()
out = []
skip = False
indent = None

for line in lines:
    stripped = line.lstrip()
    current_indent = len(line) - len(stripped)

    if not skip and stripped.startswith("logging:"):
        skip = True
        indent = current_indent
        continue

    if skip:
        if stripped == "":
            continue
        if current_indent > indent:
            continue
        skip = False

    out.append(line)

p.write_text("\n".join(out) + "\n", encoding="utf-8")
PY

echo "[OK] docker-compose.yml generated and patched for Podman log-driver compatibility"
grep -n 'logging:\|syslog-address\|driver:' docker-compose.yml || true
