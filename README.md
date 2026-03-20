# Harbor on SUSE Linux Micro Quickstart

Harbor offline install kit for **SUSE Linux Micro 6.2**, with a practical Podman-based workflow.

这是一个面向实际落地的脚本集合，目标是：
**快速在 SUSE Linux Micro 上把 Harbor 镜像仓库搭起来**。

It is optimized for **SUSE Linux Micro 6.2**, but the overall workflow can also be reused on **other Linux distributions** with a few script adjustments.

## Why This Project / 为什么要做这个项目

官方 Harbor standalone installer 更偏向于 Docker Engine 的标准环境，而 **SUSE Linux Micro** 有几个比较现实的差异：

- root filesystem behavior is different, so `/data` is often not the best choice
- Podman is the more natural runtime on this platform
- `docker-compose` compatibility needs extra handling
- some generated Harbor files need patching to run cleanly in this environment

所以这个项目的目的不是“演示 Harbor 如何安装”，而是把一套已经验证过的流程沉淀成脚本，方便你：

- 快速搭建一个私有镜像仓库 / quickly bootstrap a private image registry
- 在实验室、内网、POC、边缘环境中快速复用
- 在 SUSE Linux Micro 上少踩坑

如果你使用的是其他 Linux，比如 openSUSE、SLES、Rocky Linux、Ubuntu、Debian，也可以复用这套思路。
You will usually only need to adjust package installation, CA trust commands, and maybe a few service paths.

## What This Kit Does / 项目做了什么

This repo automates a self-signed HTTPS Harbor deployment with:

- Harbor offline installer
- Podman + podman-docker compatibility
- `docker-compose` workflow
- self-signed CA and server certificates
- Harbor config generation and compose patching

重点适配点包括：

- 使用 `/var/lib/harbor` 而不是 `/data`
- 启用 `/run/podman/podman.sock`
- 修补 Harbor 生成的 `docker-compose.yml`
- 处理自签名证书和本机信任

## Repository Layout / 仓库结构

```text
README.md
scripts/
  00-vars.sh
  01-install-prereqs.sh
  02-configure-host-and-certs.sh
  03-enable-podman-socket.sh
  04-download-harbor-offline.sh
  05-write-harbor-yml.sh
  06-prepare-and-patch-compose.sh
  07-start-harbor.sh
  08-post-check.sh
  09-client-ca-example.sh
```

## Before You Start / 开始前准备

建议以 `root` 或具备等效权限的用户执行，因为脚本会修改：

- `/etc/hosts`
- systemd service state
- CA trust store
- `/opt`
- `/var/lib/harbor`

You also need:

- internet access for downloading the Harbor offline package
- a hostname and IP for Harbor
- basic shell tools available on the target host

## Name Resolution / 域名解析要求

在浏览器、本地终端或者其他客户端访问 Harbor 之前，必须先保证：

- `HARBOR_HOSTNAME` can be resolved to `HARBOR_IP`
- the machine accessing Harbor knows how to reach that hostname

推荐方式：

- 如果你的环境里有 DNS 服务器，直接为 Harbor 配置一条 DNS 解析记录
- 如果没有 DNS，也可以在访问端机器上配置静态 `hosts`

Example / 示例:

```text
192.168.202.140 harbortest.lab.local harbor
```

说明：

- [`scripts/02-configure-host-and-certs.sh`](./scripts/02-configure-host-and-certs.sh) 会在 Harbor 服务器本机写入 `/etc/hosts`
- 但如果你要从你自己的电脑、跳板机或其他 Linux client 访问 Harbor，这些客户端也需要能解析这个主机名
- 如果客户端没有 DNS 解析能力，请手动在客户端的 `hosts` 文件里添加同样的映射

## Configuration / 配置说明

First, edit:

```bash
scripts/00-vars.sh
```

你至少需要确认这些变量：

```bash
export HARBOR_VERSION="2.14.3"
export HARBOR_HOSTNAME="harbortest.lab.local"
export HARBOR_IP="192.168.202.140"

export HARBOR_ADMIN_PASSWORD="Harbor12345!"
export HARBOR_DB_PASSWORD="HarborDB12345!"
```

建议按你的实际环境修改：

- `HARBOR_HOSTNAME`
- `HARBOR_IP`
- `HARBOR_ADMIN_PASSWORD`
- `HARBOR_DB_PASSWORD`
- certificate subject fields such as `COUNTRY`, `STATE`, `CITY`, `ORG`

## Usage / 使用步骤

### Step 0. Edit variables / 先改变量

```bash
vi scripts/00-vars.sh
```

确认主机名、IP、密码和证书信息都符合你的环境。
同时确认 `HARBOR_HOSTNAME` 在你的访问环境里可以解析到 `HARBOR_IP`。

### Step 1. Install prerequisites / 安装依赖

```bash
./scripts/01-install-prereqs.sh
```

This installs required packages on **SLE Micro 6.2**:

- `podman`
- `podman-docker`
- `docker-compose`
- `openssl`
- `ca-certificates`
- `wget`
- `tar`
- `curl`
- `python3`

Then reboot:

```bash
reboot
```

### Step 2. Reload variables / 重载环境变量

After reboot, go back to the repo and run:

```bash
source ./scripts/00-vars.sh
```

### Step 3. Configure host mapping and certificates / 配置 hosts 与证书

```bash
./scripts/02-configure-host-and-certs.sh
```

This step will:

- append Harbor hostname mapping to `/etc/hosts`
- create a local CA
- generate server certificate and key for Harbor
- copy the certs into Harbor data paths
- trust the generated CA on the local host

注意：
这个步骤只保证 Harbor 服务器本机能解析该主机名。
If you access Harbor from another machine, make sure DNS or static `hosts` is configured there as well.

### Step 4. Enable Podman socket / 启用 Podman socket

```bash
./scripts/03-enable-podman-socket.sh
```

This is required so `docker-compose` can talk to Podman through:

```text
/run/podman/podman.sock
```

### Step 5. Download Harbor offline installer / 下载 Harbor 离线安装包

```bash
./scripts/04-download-harbor-offline.sh
```

This step downloads the Harbor offline bundle and prepares:

```text
/opt/harbor-<version>
/opt/harbor
```

### Step 6. Generate `harbor.yml` / 生成 Harbor 配置

```bash
./scripts/05-write-harbor-yml.sh
```

This script copies `harbor.yml.tmpl` and rewrites important values such as:

- `hostname`
- `harbor_admin_password`
- `data_volume`
- HTTPS certificate path
- database password

### Step 7. Prepare images and patch compose / 预处理镜像并修补 compose

```bash
./scripts/06-prepare-and-patch-compose.sh
```

This step will:

- load the offline image tarball
- run Harbor `prepare`
- remove incompatible logging sections from generated `docker-compose.yml`

这一步是整个项目适配 SUSE Linux Micro / Podman 的关键之一。

### Step 8. Start Harbor / 启动 Harbor

```bash
./scripts/07-start-harbor.sh
```

After startup, open:

```text
https://<your-harbor-hostname>
```

Default login:

- Username: `admin`
- Password: value of `HARBOR_ADMIN_PASSWORD`

### Step 9. Verify deployment / 验证服务

```bash
./scripts/08-post-check.sh
```

Useful checks:

```bash
docker compose ps
podman ps -a
podman logs harbor-core
podman logs nginx
curl -kI https://<your-harbor-hostname>
```

### Step 10. Trust the CA on another client (optional) / 其他客户端信任 CA（可选）

```bash
./scripts/09-client-ca-example.sh
```

If you want another Linux client to pull/push images from this Harbor instance, you should trust the generated CA there as well.

## Quick Start / 快速执行顺序

```bash
vi scripts/00-vars.sh
./scripts/01-install-prereqs.sh
reboot

source ./scripts/00-vars.sh
./scripts/02-configure-host-and-certs.sh
./scripts/03-enable-podman-socket.sh
./scripts/04-download-harbor-offline.sh
./scripts/05-write-harbor-yml.sh
./scripts/06-prepare-and-patch-compose.sh
./scripts/07-start-harbor.sh
./scripts/08-post-check.sh
```

## Adapting to Other Linux Distributions / 迁移到其他 Linux

This repo is tuned for **SUSE Linux Micro 6.2**, but the scripts are intentionally simple and easy to modify.

如果你要迁移到其他 Linux，通常只需要改这些地方：

### 1. Package installation / 软件包安装方式

[`scripts/01-install-prereqs.sh`](./scripts/01-install-prereqs.sh) currently uses:

```bash
transactional-update pkg install ...
```

On other systems, replace it with the native package manager, for example:

- `zypper install`
- `apt install`
- `dnf install`

### 2. CA trust update command / 证书信任刷新命令

[`scripts/02-configure-host-and-certs.sh`](./scripts/02-configure-host-and-certs.sh) uses:

```bash
update-ca-certificates
```

Different distros may use a different trust path or refresh command.

### 3. Container runtime details / 容器运行时差异

This project assumes:

- Podman is installed
- Docker-compatible CLI is available
- `podman.socket` is enabled

If you use Docker Engine directly, some compatibility steps may no longer be necessary.

### 4. Filesystem paths / 文件路径

The scripts default to:

- `/opt`
- `/var/lib/harbor`
- `/root/certs`

You can change these in [`scripts/00-vars.sh`](./scripts/00-vars.sh) if your host layout is different.

## Notes / 说明

- This project uses **self-signed certificates** by default.
- The current variables file contains example passwords; change them before production use.
- `./scripts/07-start-harbor.sh` runs `docker compose down -v || true` before startup, so be careful when rerunning it on a live environment.
- `./scripts/04-download-harbor-offline.sh` recreates the Harbor install directory when needed.

## Typical Use Cases / 适用场景

- lab environment / 实验环境
- internal image registry / 内部镜像仓库
- edge or offline-friendly deployment / 边缘或离线友好环境
- fast PoC on SUSE Linux Micro / 在 SUSE Linux Micro 上快速验证方案

## License

See [`LICENSE`](./LICENSE).
