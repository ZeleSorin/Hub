# Pi Cloud Runbook

## Stack Overview

| Service    | Image              | Network(s)        | Data                  |
|------------|--------------------|-------------------|-----------------------|
| Caddy      | caddy:2-alpine     | proxy             | /mnt/usb/caddy/       |
| PostgreSQL | postgres:16-alpine | internal          | /mnt/usb/postgres/    |
| n8n        | n8nio/n8n:latest   | proxy + internal  | /mnt/usb/n8n/         |

**Pi IP:** 192.168.1.162  
**User:** mob  
**Project dir:** ~/pi-cloud/  
**Secrets:** ~/pi-cloud/.env (never commit this)  
**Access:** https://n8n.local (add `192.168.1.162 n8n.local` to your PC's hosts file)

---

## File Structure

```
~/pi-cloud/
├── .env                  # secrets (POSTGRES_PASSWORD, POSTGRES_DB, POSTGRES_USER, N8N_ENCRYPTION_KEY)
├── infra/
│   ├── Caddyfile
│   └── compose.yml       # Caddy
├── data/
│   └── compose.yml       # PostgreSQL
└── apps/
    └── compose.yml       # n8n
```

---

## Start / Stop / Restart

### Start all services (in order)
```bash
docker compose -f ~/pi-cloud/infra/compose.yml up -d
docker compose -f ~/pi-cloud/data/compose.yml --env-file ~/pi-cloud/.env up -d
docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env up -d
```

### Stop all services
```bash
docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env down
docker compose -f ~/pi-cloud/data/compose.yml --env-file ~/pi-cloud/.env down
docker compose -f ~/pi-cloud/infra/compose.yml down
```

### Restart a single service
```bash
docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env restart n8n
docker compose -f ~/pi-cloud/data/compose.yml --env-file ~/pi-cloud/.env restart postgres
docker compose -f ~/pi-cloud/infra/compose.yml restart caddy
```

---

## Status & Logs

### Check all containers are running
```bash
docker ps
```

### View logs
```bash
docker logs caddy
docker logs postgres
docker logs n8n
docker logs n8n --follow   # live tail
```

### Resource usage
```bash
docker stats
```

---

## Redeploy (after image update)

Pull new image and recreate the container — data is safe on /mnt/usb:

```bash
# n8n
docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env pull
docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env up -d

# postgres
docker compose -f ~/pi-cloud/data/compose.yml --env-file ~/pi-cloud/.env pull
docker compose -f ~/pi-cloud/data/compose.yml --env-file ~/pi-cloud/.env up -d

# caddy
docker compose -f ~/pi-cloud/infra/compose.yml pull
docker compose -f ~/pi-cloud/infra/compose.yml up -d
```

---

## Full Redeploy from Scratch

> WARNING: This destroys all data. Only use if starting fresh.

```bash
# Stop everything
docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env down
docker compose -f ~/pi-cloud/data/compose.yml --env-file ~/pi-cloud/.env down
docker compose -f ~/pi-cloud/infra/compose.yml down

# Wipe data
sudo rm -rf /mnt/usb/postgres
sudo rm -rf /mnt/usb/n8n
sudo rm -rf /mnt/usb/caddy

# Recreate directories
sudo mkdir -p /mnt/usb/{caddy/data,caddy/config,postgres,n8n}
sudo chown -R mob:mob /mnt/usb

# Redeploy
docker compose -f ~/pi-cloud/infra/compose.yml up -d
docker compose -f ~/pi-cloud/data/compose.yml --env-file ~/pi-cloud/.env up -d
docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env up -d
```

---

## Backup

All data lives on the USB drive. To back up:

```bash
# Stop n8n and postgres first to ensure consistent state
docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env down
docker compose -f ~/pi-cloud/data/compose.yml --env-file ~/pi-cloud/.env down

# Copy data to backup location
cp -r /mnt/usb/postgres ~/backups/postgres-$(date +%Y%m%d)
cp -r /mnt/usb/n8n ~/backups/n8n-$(date +%Y%m%d)

# Restart
docker compose -f ~/pi-cloud/data/compose.yml --env-file ~/pi-cloud/.env up -d
docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env up -d
```

---

## Troubleshooting

### Container won't start
```bash
docker logs <name>   # read the actual error, don't restart blindly
```

### n8n can't connect to PostgreSQL
- Check postgres is running: `docker ps | grep postgres`
- Check both are on the internal network: `docker network inspect internal`
- Verify .env has correct POSTGRES_PASSWORD

### Can't reach https://n8n.local from browser
- Check `192.168.1.162 n8n.local` is in your PC's hosts file
- Check Caddy is running: `docker ps | grep caddy`
- Check Caddy logs: `docker logs caddy`
- Test from the Pi: `curl -sk -o /dev/null -w "%{http_code}" --resolve n8n.local:443:127.0.0.1 https://n8n.local`

### USB not mounted after reboot
```bash
mountpoint /mnt/usb   # check if mounted
lsblk                 # find the USB device
sudo mount /dev/sdX1 /mnt/usb   # mount manually (replace sdX1 with actual device)
```
If this happens after every reboot, the USB is not in `/etc/fstab` — contact pi-setup agent.

### Reset n8n user password
```bash
docker exec -it postgres psql -U admin -d picloud -c \
  "UPDATE public.user SET password = '\$2a\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi' WHERE 1=1;"
```
This sets the password to `password`. Log in and change it immediately.

---

## Network Layout

```
Browser (PC)
    │ https://n8n.local
    ▼
[Caddy :443]  ── proxy network ──▶  [n8n :5678]
                                         │
                                   internal network
                                         │
                                    [PostgreSQL :5432]
```

- PostgreSQL is NOT reachable from outside the internal network
- n8n is NOT exposed on the host — only reachable through Caddy
- Caddy handles TLS termination using its local CA

---

## .env Reference

| Variable           | Required | Description                        |
|--------------------|----------|------------------------------------|
| POSTGRES_PASSWORD  | yes      | PostgreSQL password for admin user |
| POSTGRES_DB        | yes      | Database name (picloud)            |
| POSTGRES_USER      | yes      | Database user (admin)              |
| N8N_ENCRYPTION_KEY | yes      | n8n credential encryption key      |
