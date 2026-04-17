INSERT INTO agent_tasks (agent_name, title, description, status, priority) VALUES

('pi-setup', 'TASK 1 - Mount USB drive',
'Mount the 64GB USB drive at /mnt/usb and make it persistent across reboots.

Steps:
1. Run lsblk — identify the USB device (confirm with user if ambiguous)
2. Format as ext4: sudo mkfs.ext4 /dev/sdX1
3. Create mount point: sudo mkdir -p /mnt/usb
4. Get UUID: sudo blkid /dev/sdX1
5. Add to /etc/fstab: UUID=<uuid> /mnt/usb ext4 defaults,noatime 0 2
6. Mount now: sudo mount -a
7. Verify: df -h /mnt/usb

Done criteria: /mnt/usb is mounted, writable, and survives a reboot.',
'todo', 100),

('pi-setup', 'TASK 2 - Install Docker',
'Install Docker and Docker Compose on the Raspberry Pi using the official install script.

Steps:
1. Run: curl -fsSL https://get.docker.com | sh
2. Add user to docker group: sudo usermod -aG docker $USER
3. Apply group without logout: newgrp docker
4. Verify: docker version && docker compose version
5. Check cgroup memory: cat /proc/cgroups | grep memory
   - If enabled column is 0: add cgroup_enable=memory cgroup_memory=1 to /boot/cmdline.txt, reboot
   - If enabled column is 1: proceed

Done criteria: docker version and docker compose version both return without error. cgroup memory is enabled.',
'todo', 90),

('pi-setup', 'TASK 3 - Verify arm64 image availability',
'Confirm that all three stack images publish a linux/arm64 layer before deployment begins.

Commands:
  docker buildx imagetools inspect caddy:2-alpine
  docker buildx imagetools inspect postgres:16-alpine
  docker buildx imagetools inspect n8nio/n8n:latest

For each image, confirm linux/arm64 appears in the platform list.

Done criteria: All three images confirmed arm64. Record the exact tags verified.',
'todo', 80),

('pi-deploy', 'TASK 1 - Create folder structure and USB directories',
'Create the project folder structure on the Pi and the USB volume directories.

Commands:
  mkdir -p ~/pi-cloud/{infra,data,apps}
  mkdir -p /mnt/usb/caddy/{data,config}
  mkdir -p /mnt/usb/postgres
  mkdir -p /mnt/usb/n8n

Verify:
  ls ~/pi-cloud/
  ls /mnt/usb/

Done criteria: All directories exist. /mnt/usb directories are writable by the current user.',
'todo', 100),

('pi-deploy', 'TASK 2 - Write and deploy infra layer (Caddy)',
E'Write the Caddyfile and infra/compose.yml, then deploy Caddy.\n\nFile: ~/pi-cloud/infra/Caddyfile\n---\nn8n.local {\n    reverse_proxy n8n:5678\n}\n---\n\nFile: ~/pi-cloud/infra/compose.yml\n---\nservices:\n  caddy:\n    image: caddy:2-alpine\n    container_name: caddy\n    restart: unless-stopped\n    ports:\n      - "80:80"\n      - "443:443"\n    volumes:\n      - ./Caddyfile:/etc/caddy/Caddyfile:ro\n      - /mnt/usb/caddy/data:/data\n      - /mnt/usb/caddy/config:/config\n    mem_limit: 64m\n    cpus: "0.25"\n    networks:\n      - proxy\n\nnetworks:\n  proxy:\n    name: proxy\n    driver: bridge\n---\n\nDeploy: docker compose -f ~/pi-cloud/infra/compose.yml up -d\nVerify: docker ps | grep caddy && docker logs caddy\n\nDone criteria: caddy container running, no errors in logs, proxy network exists (docker network ls).',
'todo', 90),

('pi-deploy', 'TASK 3 - Write and deploy data layer (PostgreSQL)',
E'Write data/compose.yml and deploy PostgreSQL.\n\nFile: ~/pi-cloud/data/compose.yml\n---\nservices:\n  postgres:\n    image: postgres:16-alpine\n    container_name: postgres\n    restart: unless-stopped\n    environment:\n      POSTGRES_USER: ${POSTGRES_USER:-admin}\n      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}\n      POSTGRES_DB: ${POSTGRES_DB:-picloud}\n    volumes:\n      - /mnt/usb/postgres:/var/lib/postgresql/data\n    mem_limit: 256m\n    cpus: "0.5"\n    networks:\n      - internal\n\nnetworks:\n  internal:\n    name: internal\n    driver: bridge\n---\n\nBefore deploying, ensure ~/pi-cloud/.env exists with at minimum:\n  POSTGRES_PASSWORD=<strong_password>\n  POSTGRES_DB=picloud\n\nDeploy: docker compose -f ~/pi-cloud/data/compose.yml up -d\nVerify: docker ps | grep postgres && docker logs postgres\n\nDone criteria: postgres container running, DB initialized (logs show "database system is ready to accept connections"), data visible at /mnt/usb/postgres.',
'todo', 80),

('pi-deploy', 'TASK 4 - Write and deploy apps layer (n8n)',
E'Write apps/compose.yml and .env, then deploy n8n.\n\nFile: ~/pi-cloud/.env (append if exists)\n---\nPOSTGRES_USER=admin\nPOSTGRES_PASSWORD=<same_as_task_3>\nPOSTGRES_DB=picloud\nN8N_ENCRYPTION_KEY=<random_32char_string>\n---\n\nFile: ~/pi-cloud/apps/compose.yml\n---\nservices:\n  n8n:\n    image: n8nio/n8n:latest\n    container_name: n8n\n    restart: unless-stopped\n    environment:\n      - N8N_HOST=n8n.local\n      - N8N_PORT=5678\n      - N8N_PROTOCOL=http\n      - DB_TYPE=postgresdb\n      - DB_POSTGRESDB_HOST=postgres\n      - DB_POSTGRESDB_PORT=5432\n      - DB_POSTGRESDB_DATABASE=${POSTGRES_DB}\n      - DB_POSTGRESDB_USER=${POSTGRES_USER}\n      - DB_POSTGRESDB_PASSWORD=${POSTGRES_PASSWORD}\n      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}\n    volumes:\n      - /mnt/usb/n8n:/home/node/.n8n\n    mem_limit: 512m\n    cpus: "1.0"\n    networks:\n      - proxy\n      - internal\n\nnetworks:\n  proxy:\n    external: true\n  internal:\n    external: true\n---\n\nDeploy: docker compose -f ~/pi-cloud/apps/compose.yml --env-file ~/pi-cloud/.env up -d\nVerify: docker ps | grep n8n && docker logs n8n\n\nDone criteria: n8n container running, logs show "Editor is now accessible", curl http://localhost:5678 returns HTTP 200.',
'todo', 70)

ON CONFLICT (agent_name, title) DO NOTHING
RETURNING id, agent_name, title, status, priority;
