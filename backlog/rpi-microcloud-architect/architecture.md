# Raspberry Pi Micro-Cloud Architecture

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Raspberry Pi 4 (4GB)               │
│                                                     │
│  ┌──────────────────────────────────────────────┐   │
│  │              Caddy (Reverse Proxy)           │   │
│  │         Port 80/443 → hostname routing       │   │
│  └──────────────┬───────────┬──────────────────┘   │
│                 │           │                        │
│         ┌───────▼──┐  ┌────▼──────┐                │
│         │ Postgres │  │   n8n     │                │
│         │ (data)   │  │ (automate)│                │
│         └──────────┘  └───────────┘                │
│                                                     │
│  SD card: OS + Docker daemon only                   │
│  USB drive (/mnt/usb): ALL persistent data          │
└─────────────────────────────────────────────────────┘
```

**Components and roles:**

| Layer | Component | Role |
|---|---|---|
| Host OS | Raspberry Pi OS 64-bit (or Ubuntu Server ARM) | Kernel + Docker daemon |
| Reverse proxy | Caddy | TLS termination, hostname routing, HTTP → HTTPS |
| Database | PostgreSQL 16 | Relational storage for apps |
| Automation | n8n | Workflow automation, webhooks, scheduled jobs |
| Storage | USB drive at `/mnt/usb` | All Docker volumes — nothing persistent on SD |

---

## 2. Technology Choices

### Docker Compose over k3s

k3s adds ~500MB baseline RAM (etcd, control plane, kubelet). On a 4GB Pi with ~600MB consumed by OS + Docker daemon, that leaves only ~2.9GB for workloads before adding k3s overhead. Docker Compose has no control plane — it costs nothing beyond the containers themselves.

Use k3s only if: you add a second Pi and need multi-node scheduling, or a specific tool requires the Kubernetes API. Neither applies here.

### Caddy over Traefik

Both are valid. Caddy wins here because:
- The Caddyfile is human-readable with no label gymnastics
- Automatic HTTPS with ACME works out of the box
- arm64 image is official and multi-arch: `caddy:2-alpine` publishes `linux/arm64`
- Simpler to debug when routes misbehave — the config is static and visible

Use Traefik if you prefer auto-discovery via Docker labels and want to add services without touching the proxy config.

### Three Initial Services

**Networking/Exposure — Caddy**
- arm64: `caddy:2-alpine` — verified multi-arch (linux/amd64, linux/arm64, linux/arm/v7)
- Idle RAM: ~15–20MB
- Role: single entry point for all HTTP/S traffic

**Storage/Database — PostgreSQL 16**
- arm64: `postgres:16-alpine` — official image, verified linux/arm64
- Idle RAM: ~30–50MB
- Role: relational database for n8n and future services

**Automation/Scripting — n8n**
- arm64: `n8nio/n8n:latest` — official image, publishes linux/arm64
- Idle RAM: ~150–250MB
- Role: visual workflow automation, webhooks, scheduled tasks

**RAM budget (conservative):**
```
OS + Docker daemon:   ~600MB
Caddy:                 ~20MB
PostgreSQL:            ~50MB
n8n:                  ~250MB
──────────────────────────────
Total committed:      ~920MB
Headroom:           ~3,080MB  (plenty for growth)
```

---

## 3. Folder Structure

```
~/pi-cloud/
├── infra/
│   ├── compose.yml          # Caddy
│   └── Caddyfile
├── data/
│   ├── compose.yml          # PostgreSQL
├── apps/
│   ├── compose.yml          # n8n
└── .env                     # shared env vars (USB path, domain)
```

One compose file per logical group. This means `docker compose -f apps/compose.yml restart n8n` restarts only n8n without touching the proxy or database.

The USB drive is mounted at `/mnt/usb` on the host. All volume bind mounts target subdirectories there.

---

## 4. Step-by-Step Setup Guide

### 4.1 Prepare the USB drive

```bash
# Find the USB device (usually /dev/sda on Pi with no other USB storage)
lsblk

# Format as ext4 (do this once — destroys existing data)
sudo mkfs.ext4 /dev/sda1

# Create mount point
sudo mkdir -p /mnt/usb

# Get the UUID for stable mounting
sudo blkid /dev/sda1
# Copy the UUID value

# Add to /etc/fstab for auto-mount on boot
echo 'UUID=<your-uuid> /mnt/usb ext4 defaults,noatime 0 2' | sudo tee -a /etc/fstab

# Mount now without rebooting
sudo mount -a

# Verify
df -h /mnt/usb
```

### 4.2 Install Docker

```bash
# Official install script — works on Raspberry Pi OS and Ubuntu ARM
curl -fsSL https://get.docker.com | sh

# Add your user to the docker group (avoid sudo on every command)
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker version
docker compose version
```

### 4.3 Create the directory structure

```bash
mkdir -p ~/pi-cloud/{infra,data,apps}
mkdir -p /mnt/usb/{caddy,postgres,n8n}
```

### 4.4 Deploy the stack

```bash
# Start infra first (proxy must be up before services)
docker compose -f ~/pi-cloud/infra/compose.yml up -d

# Then data layer
docker compose -f ~/pi-cloud/data/compose.yml up -d

# Then apps
docker compose -f ~/pi-cloud/apps/compose.yml up -d
```

### 4.5 Verify

```bash
# All containers running
docker ps

# Caddy logs (check for TLS errors)
docker logs caddy

# n8n reachable
curl -I http://n8n.local  # or your configured hostname
```

---

## 5. Docker Compose Files

### `infra/Caddyfile`

```caddyfile
# Replace .local hostnames with your actual domain or local DNS entries
n8n.local {
    reverse_proxy n8n:5678
}

# Add more services here as you expand
```

### `infra/compose.yml`

```yaml
services:
  caddy:
    image: caddy:2-alpine          # linux/arm64 verified
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - /mnt/usb/caddy/data:/data          # TLS certs on USB
      - /mnt/usb/caddy/config:/config
    mem_limit: 64m
    cpus: "0.25"
    networks:
      - proxy

networks:
  proxy:
    name: proxy
    driver: bridge
```

### `data/compose.yml`

```yaml
services:
  postgres:
    image: postgres:16-alpine      # linux/arm64 verified
    container_name: postgres
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-admin}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?required}
      POSTGRES_DB: ${POSTGRES_DB:-picloud}
    volumes:
      - /mnt/usb/postgres:/var/lib/postgresql/data  # USB, not SD card
    mem_limit: 256m
    cpus: "0.5"
    networks:
      - internal

networks:
  internal:
    name: internal
    driver: bridge
```

### `apps/compose.yml`

```yaml
services:
  n8n:
    image: n8nio/n8n:latest        # linux/arm64 verified
    container_name: n8n
    restart: unless-stopped
    environment:
      - N8N_HOST=n8n.local
      - N8N_PORT=5678
      - N8N_PROTOCOL=https
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=n8n
      - DB_POSTGRESDB_USER=${POSTGRES_USER:-admin}
      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD:?required}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY:?required}
    volumes:
      - /mnt/usb/n8n:/home/node/.n8n  # workflows and credentials on USB
    mem_limit: 512m
    cpus: "1.0"
    networks:
      - proxy      # reachable by Caddy
      - internal   # can reach Postgres
    depends_on:
      - postgres   # note: start order only, not health; add healthcheck if needed

networks:
  proxy:
    external: true   # defined in infra/compose.yml
  internal:
    external: true   # defined in data/compose.yml
```

### `.env` (at `~/pi-cloud/.env`)

```dotenv
POSTGRES_USER=admin
POSTGRES_PASSWORD=changeme_strong_password
POSTGRES_DB=picloud
N8N_ENCRYPTION_KEY=changeme_32char_random_string
```

> **Never commit `.env` to git.** Add it to `.gitignore` immediately.

---

## 6. How to Extend the System Later

### Adding a new service

1. **Check arm64 availability first:**
   ```bash
   docker buildx imagetools inspect <image>:<tag> | grep -A2 "Platform"
   ```
2. **Decide which network group it belongs to** — `proxy` if Caddy needs to route to it, `internal` if it only talks to other backend services.
3. **Add a new service block** to the appropriate compose file (or create a new one under `~/pi-cloud/`).
4. **Add a Caddyfile entry** with the hostname route.
5. **Create its USB volume directory:** `mkdir -p /mnt/usb/<service>`
6. **Set `mem_limit`** — check the image's documentation or run `docker stats` after a few minutes of idle to calibrate.

### Upgrade path to k3s (when you actually need it)

Trigger: you add a second Pi, or you need a Kubernetes operator that has no Docker Compose equivalent.

Steps at that point:
- Install k3s on the primary Pi as control plane
- Join the second Pi as a worker node
- Migrate compose files to Helm charts or raw manifests
- Move USB mounts to PersistentVolumeClaims backed by `local-path-provisioner` (k3s includes this by default)

### Services worth adding next (in order of usefulness)

| Service | Image | Purpose | Idle RAM |
|---|---|---|---|
| Gitea | `gitea/gitea:latest` | Self-hosted git | ~80MB |
| Woodpecker CI | `woodpeckerci/woodpecker-server` | CI/CD tied to Gitea | ~50MB |
| MinIO | `minio/minio` | S3-compatible object storage | ~100MB |
| Uptime Kuma | `louislam/uptime-kuma:1` | Service health monitoring | ~60MB |

Add Uptime Kuma last — monitoring before there's something stable to monitor is premature. Add it once you have two or three services running reliably.
