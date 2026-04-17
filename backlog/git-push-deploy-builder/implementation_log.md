# Implementation Log

## Status: In Progress

---

## What Was Built

### Files Created

| File | Repo | Purpose |
|---|---|---|
| `workflow_design.md` | backlog/git-push-deploy-builder | Full design document |
| `workflow.json` | pi-cloud/apps | n8n workflow (importable) |
| `deploy.sh` | backlog/git-push-deploy-builder | Standalone shell script for manual use |
| `.env.example` | backlog/git-push-deploy-builder | Env var reference |
| `SETUP.md` | backlog/git-push-deploy-builder | Setup instructions |
| `apps/Dockerfile` | pi-cloud/apps | Custom n8n image with git installed |

### Changes to pi-cloud

- `apps/compose.yml` — switched n8n from `image:` to `build:`, added deploy env vars, mounted `/mnt/usb/apps` and `/var/log`
- `apps/Dockerfile` — multi-stage build: copies git binary from `alpine:3.22` into the hardened n8n image (n8n uses Docker Hardened Images which have no package manager)
- Added env vars to n8n container:
  - `N8N_BLOCK_ENV_ACCESS_IN_NODE=false` — allows `$env.*` in node expressions
  - `NODE_FUNCTION_ALLOW_BUILTIN=crypto` — allows `require('crypto')` in Code nodes

### Pi .env (~/pi-cloud/.env)

Added to existing file:
```
WEBHOOK_SECRET=<generated>
DEPLOY_BRANCH=release
REPO_URL=https://github.com/ZeleSorin/pi-cloud.git
LOCAL_PATH=/mnt/usb/app/pi-cloud
```

---

## n8n Workflow State

Workflow imported manually into n8n UI. Current node configuration:

### 1. Git Push Webhook
- Type: Webhook
- Method: POST
- Path: `git-deploy`
- Raw Body: enabled

### 2. Validate Signature
- Type: Code (JavaScript)
- Uses `$env.WEBHOOK_SECRET` and `require('crypto')`
- Computes HMAC-SHA256 and compares to `X-Hub-Signature-256` header
- Current issue: signature mismatch when testing with curl (re-stringified body bytes may differ from original)

### 3. Branch Filter
- Type: IF
- Checks `body.ref` equals `refs/heads/release`

### 4. Deploy Constants
- Type: Set
- Hardcoded values (env var expressions didn't work in Set node):
  - branch: `release`
  - repoUrl: `https://github.com/ZeleSorin/pi-cloud.git`
  - localPath: `/mnt/usb/app/pi-cloud`

### 5. Git Pull
- Type: SSH
- Host: `172.18.0.1` (Pi host gateway from n8n container)
- Credential: SSH Password (user: mob)
- Command: clone-or-pull bash one-liner

### 6. Pull Failed
- Type: Stop and Error

---

## Known Issues / Discoveries

### Execute Command node removed
n8n v1.x removed the Execute Command node. Replaced with SSH node connecting to `172.18.0.1` (Pi host) via SSH password auth.

### n8n uses Docker Hardened Images
`n8nio/n8n:latest` uses Docker Hardened Images (Alpine 3.22) with no package manager. Used multi-stage build to copy git binary from standard Alpine 3.22.

### env vars in Set node
`$env.VARIABLE` expressions in Set node values showed "[ERROR: access to env vars denied]" even after setting `N8N_BLOCK_ENV_ACCESS_IN_NODE=false`. Worked around by hardcoding values directly.

### Raw body for HMAC validation
n8n parses the JSON body before the Code node runs. Re-stringifying with `JSON.stringify` may produce different bytes than GitHub's original payload, causing signature mismatch. Needs investigation with a real GitHub push.

---

## Next Steps

1. **Set up public webhook URL** — ngrok installed on Pi, needs authtoken from ngrok.com account
2. **Run ngrok** — `ngrok http 5678` to expose n8n directly (or proxy through Caddy)
3. **Register webhook on GitHub** — repo Settings → Webhooks, paste ngrok URL + WEBHOOK_SECRET
4. **Test with real push** — push to `release` branch, verify pull lands at `/mnt/usb/app/pi-cloud`
5. **Fix signature validation** — if mismatch persists with real push, investigate raw body handling in n8n webhook node
6. **Activate workflow** — switch from Test URL to Production URL, activate in n8n

---

## Pi Infrastructure

- n8n running in Docker, accessible at `http://n8n.local` via Caddy reverse proxy
- n8n data persisted at `/mnt/usb/n8n`
- Deploy target: `/mnt/usb/app/pi-cloud`
- Public IP: `178.225.231.147` (no domain confirmed, no port forwarding confirmed)
- SSH accessible from n8n container via `172.18.0.1:22`
