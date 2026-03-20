#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00-vars.sh"

echo "[STEP 2] Configure hostname mapping and certificates"

grep -qE "^[[:space:]]*${HARBOR_IP}[[:space:]]+${HARBOR_HOSTNAME}(\s|$)" /etc/hosts ||       echo "${HARBOR_IP} ${HARBOR_HOSTNAME} harbor" >> /etc/hosts

mkdir -p "${CERT_DIR}"
cd "${CERT_DIR}"

if [[ ! -f ca.key ]]; then
  openssl genrsa -out ca.key 4096
fi

if [[ ! -f ca.crt ]]; then
  openssl req -x509 -new -nodes -sha512 -days 3650         -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${ORG_UNIT}/CN=Harbor Local Root CA"         -key ca.key         -out ca.crt
fi

openssl genrsa -out "${HARBOR_HOSTNAME}.key" 4096
openssl req -sha512 -new       -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${ORG_UNIT}/CN=${HARBOR_HOSTNAME}"       -key "${HARBOR_HOSTNAME}.key"       -out "${HARBOR_HOSTNAME}.csr"

cat > v3.ext <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature,nonRepudiation,keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth
subjectAltName=@alt_names

[alt_names]
DNS.1=${HARBOR_HOSTNAME}
DNS.2=harbor
IP.1=${HARBOR_IP}
EOF

openssl x509 -req -sha512 -days 3650       -extfile v3.ext       -CA ca.crt -CAkey ca.key -CAcreateserial       -in "${HARBOR_HOSTNAME}.csr"       -out "${HARBOR_HOSTNAME}.crt"

openssl x509 -inform PEM -in "${HARBOR_HOSTNAME}.crt" -out "${HARBOR_HOSTNAME}.cert"

mkdir -p "${HARBOR_CERT_DIR}"
cp "${HARBOR_HOSTNAME}.crt" "${HARBOR_CERT_DIR}/"
cp "${HARBOR_HOSTNAME}.key" "${HARBOR_CERT_DIR}/"
chmod 600 "${HARBOR_CERT_DIR}/${HARBOR_HOSTNAME}.key"

cp ca.crt /etc/pki/trust/anchors/harbor-ca.crt
update-ca-certificates

echo "[OK] Certificates generated and trusted."
echo "[CHECK] openssl x509 -in ${HARBOR_HOSTNAME}.crt -noout -text | egrep -A2 'Subject:|Subject Alternative Name'"
