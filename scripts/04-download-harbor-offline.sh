#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00-vars.sh"

echo "[STEP 4] Download Harbor offline installer"

mkdir -p "${HARBOR_INSTALL_ROOT}"
cd "${HARBOR_INSTALL_ROOT}"

wget -O "harbor-offline-installer-v${HARBOR_VERSION}.tgz" "${HARBOR_RELEASE_URL}"
tar xzf "harbor-offline-installer-v${HARBOR_VERSION}.tgz"

rm -rf "${HARBOR_BASE}"
mv harbor "${HARBOR_BASE}"
ln -sfn "${HARBOR_BASE}" "${HARBOR_LINK}"

echo "[OK] Harbor installer prepared at ${HARBOR_LINK}"
ls -l "${HARBOR_LINK}"
