Harbor on SLE Micro 6.2 - Step-by-step install kit
================================================

Purpose
-------
This kit packages the field-tested procedure used in the current conversation:
self-signed Harbor deployment on SLE Micro 6.2 using podman-docker + docker-compose
compatibility.

Important
---------
1. This is a practical workaround for SLE Micro 6.2.
2. Harbor standalone installer officially expects Docker Engine. On SLE Micro 6.2,
   we use Podman compatibility mode and patch the generated compose file for log-driver
   compatibility.
3. Use /var/lib/harbor instead of /data because SLE Micro root filesystem is read-only.

Execution order
---------------
1. Edit scripts/00-vars.sh
2. Run scripts/01-install-prereqs.sh
3. Reboot
4. source ./scripts/00-vars.sh
5. Run:
   ./scripts/02-configure-host-and-certs.sh
   ./scripts/03-enable-podman-socket.sh
   ./scripts/04-download-harbor-offline.sh
   ./scripts/05-write-harbor-yml.sh
   ./scripts/06-prepare-and-patch-compose.sh
   ./scripts/07-start-harbor.sh
   ./scripts/08-post-check.sh

Expected access
---------------
URL:      https://<your-harbor-hostname>
Username: admin
Password: value from scripts/00-vars.sh

Common issues fixed by this kit
-------------------------------
- /data read-only on SLE Micro
- docker version gate in Harbor installer
- registry source drift
- Podman bind mount requires pre-created host directories
- Missing /run/podman/podman.sock
- Podman does not support syslog log driver in Harbor compose

Recommended artifact to read first
----------------------------------
Open the companion DOCX:
harbor_slem62_self_signed_harbor_guide.docx
