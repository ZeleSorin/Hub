# Setup Instructions

## Prerequisites

- n8n running in Docker on the Raspberry Pi
- The n8n container has `git` installed, or git is on the Pi host and mounted into the container
- The n8n process user has write access to `LOCAL_PATH` (and its parent for first-run clone)
- For private repos: a GitHub Personal Access Token with `Contents: read` scope

---

## Step 1 — Configure environment variables

n8n reads environment variables from its Docker configuration. Add these to your `docker-compose.yml` under the n8n service's `environment` block:

```yaml
services:
  n8n:
    image: n8nio/n8n
    environment:
      - WEBHOOK_SECRET=your-generated-secret
      - DEPLOY_BRANCH=main
      - LOCAL_PATH=/opt/myapp
      # For public repos or SSH:
      - REPO_URL=https://github.com/your-user/your-repo.git
      # For private repos via HTTPS — token embedded in URL:
      # - REPO_URL=https://YOUR_GIT_TOKEN@github.com/your-user/your-repo.git
    volumes:
      - n8n_data:/home/node/.n8n
      - /opt/myapp:/opt/myapp   # mount the deploy target so n8n can write to it
      - /var/log:/var/log        # mount log dir so deploy.log is accessible on the Pi
```

Generate a webhook secret:
```bash
openssl rand -hex 32
```

Restart n8n after editing the compose file:
```bash
docker compose up -d n8n
```

---

## Step 2 — Import the workflow

1. Open n8n in your browser
2. Go to **Workflows → Import from file**
3. Select `workflow.json` from this directory
4. The workflow imports as inactive — do not activate yet

---

## Step 3 — Verify the Webhook node

1. Open the imported workflow
2. Click the **Git Push Webhook** node
3. Confirm:
   - HTTP Method: `POST`
   - Path: `git-deploy`
   - Response Mode: `On Received`
   - **Raw Body: enabled** (under Options)
4. Copy the **Production URL** shown at the bottom of the node — it looks like:
   `https://your-n8n-domain/webhook/git-deploy`

---

## Step 4 — Register the webhook on GitHub

1. Go to your GitHub repo → **Settings → Webhooks → Add webhook**
2. Fill in:
   - **Payload URL**: the URL you copied in Step 3
   - **Content type**: `application/json`
   - **Secret**: the same value as `WEBHOOK_SECRET`
   - **Which events**: `Just the push event`
3. Save. GitHub will send a ping — it will return 200 (the workflow will fail the branch check on a ping, which is fine).

---

## Step 5 — Activate the workflow

Back in n8n, toggle the workflow to **Active**.

---

## Step 6 — Test

**Test 1 — Real push:**
Push a commit to your deploy branch. Then on the Pi:
```bash
tail -f /var/log/deploy.log
```
You should see `Pull complete.` or `Clone complete.`

**Test 2 — Wrong branch:**
Push to a different branch. The workflow should complete with no log entry.

**Test 3 — Bad signature (tamper test):**
Send a POST to the webhook URL with a wrong or missing `X-Hub-Signature-256` header. The workflow should return 200 and stop — check n8n execution history for a failed execution.

---

## SSH Authentication (alternative to token)

If you prefer SSH over HTTPS tokens:

1. Generate a deploy key on the Pi:
   ```bash
   ssh-keygen -t ed25519 -C "deploy@pi" -f ~/.ssh/deploy_key -N ""
   ```
2. Add the public key (`~/.ssh/deploy_key.pub`) to GitHub repo → **Settings → Deploy keys**
3. Mount the key into the n8n container:
   ```yaml
   volumes:
     - ~/.ssh:/home/node/.ssh:ro
   ```
4. Set `REPO_URL` to the SSH format: `git@github.com:your-user/your-repo.git`
5. Leave `GIT_TOKEN` unset

---

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| n8n execution fails with "Signature mismatch" | `WEBHOOK_SECRET` in n8n doesn't match the secret set in GitHub |
| `git: command not found` in Execute Command output | `git` not installed in the n8n container — install it or use a custom image |
| Permission denied on `LOCAL_PATH` | The n8n container user (uid 1000) doesn't own the mounted directory |
| Workflow triggers but no log file appears | `/var/log` not mounted into the n8n container |
| GitHub shows webhook delivery failed | n8n is not publicly reachable — use Cloudflare Tunnel or ngrok |
