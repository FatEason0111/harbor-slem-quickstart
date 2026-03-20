#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-vars.sh"

echo "[STEP 5] Generate harbor.yml from upstream template and override required values"

mkdir -p "${HARBOR_LINK}/common/config"
mkdir -p "${HARBOR_LINK}/common/data"
mkdir -p "${HARBOR_LINK}/common/config/shared/trust-certificates"

if [[ ! -f "${HARBOR_LINK}/harbor.yml.tmpl" ]]; then
  echo "[ERROR] Missing template: ${HARBOR_LINK}/harbor.yml.tmpl"
  exit 1
fi

cp -f "${HARBOR_LINK}/harbor.yml.tmpl" "${HARBOR_LINK}/harbor.yml"

TMP_PY="$(mktemp /tmp/harbor_patch_XXXXXX.py)"
trap 'rm -f "${TMP_PY}"' EXIT

cat > "${TMP_PY}" <<'PYEOF'
from pathlib import Path
import os
import re
import sys

harbor_link = os.environ["HARBOR_LINK"]
host = os.environ["HARBOR_HOSTNAME"]
cert_dir = os.environ["HARBOR_CERT_DIR"]
admin_pw = os.environ["HARBOR_ADMIN_PASSWORD"]
db_pw = os.environ["HARBOR_DB_PASSWORD"]
data_dir = os.environ["HARBOR_DATA"]

p = Path(harbor_link) / "harbor.yml"
text = p.read_text(encoding="utf-8")
lines = text.splitlines()

replaced = {
    "hostname": False,
    "harbor_admin_password": False,
    "data_volume": False,
    "https_certificate": False,
    "https_private_key": False,
    "database_password": False,
}

section = None
new_lines = []

top_level_section_re = re.compile(r'^([A-Za-z0-9_]+):\s*(?:#.*)?$')

for line in lines:
    stripped = line.strip()

    # detect current top-level section
    if line and not line.startswith((" ", "\t")):
        m = top_level_section_re.match(line)
        if m:
            section = m.group(1)
        else:
            section = None

    # top-level keys
    if not line.startswith((" ", "\t")):
        if re.match(r'^hostname:\s*', line):
            new_lines.append(f"hostname: {host}")
            replaced["hostname"] = True
            continue
        if re.match(r'^harbor_admin_password:\s*', line):
            new_lines.append(f"harbor_admin_password: {admin_pw}")
            replaced["harbor_admin_password"] = True
            continue
        if re.match(r'^data_volume:\s*', line):
            new_lines.append(f"data_volume: {data_dir}")
            replaced["data_volume"] = True
            continue

    # nested keys under https
    if section == "https":
        if re.match(r'^[ \t]+certificate:\s*', line):
            new_lines.append(f"  certificate: {cert_dir}/{host}.crt")
            replaced["https_certificate"] = True
            continue
        if re.match(r'^[ \t]+private_key:\s*', line):
            new_lines.append(f"  private_key: {cert_dir}/{host}.key")
            replaced["https_private_key"] = True
            continue

    # nested keys under database
    if section == "database":
        if re.match(r'^[ \t]+password:\s*', line):
            new_lines.append(f"  password: {db_pw}")
            replaced["database_password"] = True
            continue

    new_lines.append(line)

missing = [k for k, v in replaced.items() if not v]
if missing:
    print(f"[ERROR] Failed to patch required keys in harbor.yml: {', '.join(missing)}", file=sys.stderr)
    sys.exit(1)

p.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
print(f"[INFO] Patched {p}")
PYEOF

export HARBOR_LINK HARBOR_HOSTNAME HARBOR_CERT_DIR HARBOR_ADMIN_PASSWORD HARBOR_DB_PASSWORD HARBOR_DATA
python3 "${TMP_PY}"

echo "[INFO] Preview important harbor.yml fields:"
grep -nE '^hostname:|^harbor_admin_password:|^data_volume:|^database:|^[[:space:]]*password:|^[[:space:]]*certificate:|^[[:space:]]*private_key:' "${HARBOR_LINK}/harbor.yml" || true

echo "[OK] harbor.yml generated at ${HARBOR_LINK}/harbor.yml"
