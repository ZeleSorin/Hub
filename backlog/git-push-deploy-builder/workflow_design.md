# Git-Push Deploy Workflow — Design Document

## 1. Workflow Goal

When a developer pushes to the configured branch of a Git repository, a webhook fires and triggers an n8n workflow running on a Raspberry Pi. The workflow validates the request's authenticity, confirms the push is to the correct branch, then runs a `git pull` (or `git clone` on first run) to bring the local directory on the Pi into sync with the remote branch. The result is a directory on the Pi that always reflects the latest commit on the configured branch, updated automatically within seconds of every push.

---

## 2. Trigger Design

**Webhook receipt:**
- n8n exposes a public HTTPS endpoint via its built-in Webhook node.
- The Git provider is configured to POST to this URL on every push event.
- The Webhook node is set to return the raw body (required for HMAC signature validation).

**Signature validation:**
- The Git provider sends a shared secret in a request header:
  - GitHub: `X-Hub-Signature-256` (format: `sha256=<hex>`)
  - Gitea: `X-Gitea-Signature` (format: `sha256=<hex>`)
  - GitLab: `X-Gitlab-Token` (raw secret string, not HMAC)
- A Code node computes `HMAC-SHA256(WEBHOOK_SECRET, rawBody)` and compares it to the header value.
- If validation fails: return HTTP 200, stop workflow, log nothing. Never return 401/403.

**Branch filter:**
- After signature validation, an IF node checks whether `body.ref` equals `refs/heads/<DEPLOY_BRANCH>`.
- If the branch does not match: end workflow silently. No error, no log entry — off-branch pushes are high-volume and irrelevant.

---

## 3. Execution Logic

After validation and branch check pass:

1. A Set node reads the operator-configured constants (branch, repo URL, local path) from environment variables and makes them available as named fields.
2. An Execute Command node runs the clone-or-pull shell script using only those constants — no webhook payload data enters the command.
3. On success: workflow ends. Output is written to the Pi's log file.
4. On non-zero exit code: a Stop and Error node halts the workflow and surfaces the error in n8n's execution history.

---

## 4. Required Inputs

All inputs are operator-configured constants. None come from the webhook payload at runtime.

| Variable | Purpose | Where set |
|---|---|---|
| `WEBHOOK_SECRET` | Shared secret for HMAC signature validation | n8n environment variable |
| `DEPLOY_BRANCH` | Branch to deploy (e.g. `main`) | n8n environment variable |
| `REPO_URL` | Full HTTPS or SSH URL of the repository | n8n environment variable |
| `LOCAL_PATH` | Absolute path on the Pi where code is deployed | n8n environment variable |
| `GIT_TOKEN` | Personal access token for private HTTPS repos | n8n environment variable (omit for SSH) |

For private repos via HTTPS, the repo URL is constructed as:
```
https://<GIT_TOKEN>@github.com/user/repo.git
```

For SSH, no token is needed — the n8n process user's `~/.ssh` key must be authorized on the Git provider.

---

## 5. n8n Node Plan

| # | Node Type | Name | Purpose |
|---|---|---|---|
| 1 | Webhook | `Git Push Webhook` | Receives POST from Git provider. Raw body enabled. Method: POST. |
| 2 | Code (JS) | `Validate Signature` | Computes HMAC-SHA256 of raw body using `WEBHOOK_SECRET`. Compares to header. Throws on mismatch (triggers error branch). Returns 200 silently on failure. |
| 3 | IF | `Branch Filter` | Checks `{{ $json.body.ref }}` equals `refs/heads/{{ $env.DEPLOY_BRANCH }}`. True → continue. False → stop (no error). |
| 4 | Set | `Deploy Constants` | Extracts `DEPLOY_BRANCH`, `REPO_URL`, `LOCAL_PATH` from env vars into named fields for downstream nodes. |
| 5 | Execute Command | `Git Pull` | Runs the clone-or-pull shell command using Set node values. |
| 6 | Stop and Error | `Pull Failed` | Connected to Execute Command error output. Surfaces failure in n8n execution history. |

---

## 6. Shell Command Strategy

**The command pattern (idempotent — handles first run and all subsequent runs):**

```bash
if [ -d "$LOCAL_PATH/.git" ]; then
  git -C "$LOCAL_PATH" pull origin "$DEPLOY_BRANCH" >> /var/log/deploy.log 2>&1
else
  git clone --branch "$DEPLOY_BRANCH" --single-branch "$REPO_URL" "$LOCAL_PATH" >> /var/log/deploy.log 2>&1
fi
```

In the Execute Command node, `$LOCAL_PATH`, `$DEPLOY_BRANCH`, and `$REPO_URL` are references to n8n expressions pulling from the Set node — they are operator constants resolved at design time, never webhook payload fields.

**First run:** No `.git` directory exists → `git clone` creates the repo.  
**Subsequent runs:** `.git` exists → `git pull` updates it.  
**Both paths** log to `/var/log/deploy.log` with stdout and stderr merged.

The n8n process user must have:
- Write access to `$LOCAL_PATH` (and its parent if cloning)
- `git` installed and on PATH
- Network access to the Git provider

---

## 7. Security Rules

**Signature verification is mandatory and first.**
The Code node runs before any branch check or command execution. If the signature is absent or incorrect, the workflow responds with HTTP 200 and stops. No information is leaked about what validation exists or what failed.

**No webhook payload data enters shell commands.**
`REPO_URL`, `DEPLOY_BRANCH`, and `LOCAL_PATH` are set by the operator in environment variables and copied into the Set node at design time. The `body.ref` field from the webhook payload is only used in the IF node comparison — it never touches the Execute Command node.

**Credentials in environment variables only.**
`WEBHOOK_SECRET` and `GIT_TOKEN` are loaded from n8n's environment at startup. They are never written into workflow JSON, node parameters, or shell command strings. n8n workflow exports are plain JSON and may be committed or shared — they must contain no secrets.

**Branch filter rejects off-target pushes silently.**
The IF node false branch terminates the workflow with no response body change and no log entry. This prevents volume and avoids leaking branch names.

---

## 8. Failure Handling

**Signature mismatch:**
- Code node throws → workflow error path
- HTTP 200 returned to caller (no information leak)
- n8n execution logged as failed — visible in n8n UI execution history

**Wrong branch:**
- IF node false path → workflow ends normally
- No log entry, no error — this is expected high-volume traffic

**Git command failure (non-zero exit):**
- Execute Command node routes to Stop and Error node
- Error message (stderr from git) surfaces in n8n execution history
- `/var/log/deploy.log` contains the full output for diagnosis

**Common failure causes:**
- SSH key not authorized / token expired → `git pull` exits non-zero
- Local path permissions wrong → `git clone` fails
- Network unreachable → git times out

No retry logic in MVP. Failures are visible in n8n UI and in the log file. The next push will trigger a fresh attempt.

---

## 9. Future Extension — Docker Rebuild

After a successful `git pull`, a Docker rebuild/restart can be added by extending the Execute Command node's shell script:

```bash
# After successful pull:
docker compose -f "$LOCAL_PATH/docker-compose.yml" up -d --build >> /var/log/deploy.log 2>&1
```

**Requirements to add this:**
- The n8n process user must be in the `docker` group (or have sudo for docker commands)
- `docker` and `docker compose` must be installed on the Pi
- A second Execute Command node should handle this separately so git pull failures don't mask docker failures

**Do not implement this until the basic git pull workflow is stable and tested.**

---

## 10. Build Tasks

These are the exact implementation steps in order:

1. Confirm n8n is running on the Pi and accessible (HTTPS or via Cloudflare Tunnel / ngrok for webhook reachability)
2. Set environment variables in n8n: `WEBHOOK_SECRET`, `DEPLOY_BRANCH`, `REPO_URL`, `LOCAL_PATH`, and optionally `GIT_TOKEN`
3. Create the workflow in n8n UI:
   a. Add Webhook node — method POST, response mode "On Received", enable "Return Raw Body"
   b. Add Code node — HMAC-SHA256 validation (JavaScript, see Task 2 for exact code)
   c. Add IF node — branch filter on `body.ref`
   d. Add Set node — map env vars to named fields
   e. Add Execute Command node — clone-or-pull command
   f. Add Stop and Error node — connected to Execute Command error output
4. Activate the workflow and copy the webhook URL
5. Register the webhook URL in the Git provider (GitHub/Gitea/GitLab) with the shared secret
6. Test with a push to the deploy branch — verify pull succeeds and log file is written
7. Test with a push to a non-deploy branch — verify workflow stops silently
8. Test with a tampered signature — verify workflow returns 200 and stops
