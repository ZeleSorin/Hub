INSERT INTO agent_tasks (agent_name, title, description, status, priority)
VALUES (
  'git-push-deploy-builder',
  'TASK 1 - Design and document git-push deploy workflow',
  E'Produce a complete design document for the n8n git-push-to-deploy automation.\n\nOutput must cover:\n1. Workflow Goal — one-paragraph summary of what the automation does\n2. Trigger Design — how the Git push webhook is received, what is checked, how branch is validated\n3. Execution Logic — exact steps the workflow performs after validation\n4. Required Inputs — branch name, repo URL, local target path, credentials/secrets\n5. n8n Node Plan — ordered list of nodes with purpose of each\n6. Shell Command Strategy — exact clone-or-pull command pattern, first run vs later runs\n7. Security Rules — webhook signature verification, credential handling, command safety\n8. Failure Handling — what happens on pull failure, what gets logged, how errors surface\n9. Future Extension — how to add Docker rebuild/restart after successful pull (document only, do not implement)\n10. Build Tasks — exact ordered implementation steps\n\nConstraints:\n- Git provider should be treated as configurable (GitHub/Gitea/GitLab)\n- No CI/CD complexity\n- No Kubernetes\n- Secrets via env vars only, never in workflow JSON\n- Commands must be safe (no webhook payload interpolation)\n\nDone criteria: Document written to backlog/git-push-deploy-builder/workflow_design.md',
  'todo', 100
),
(
  'git-push-deploy-builder',
  'TASK 2 - Implement n8n workflow and shell script',
  E'Build the actual n8n workflow and supporting shell script for git-push deploy.\n\nDeliverables:\n1. n8n workflow JSON export — importable workflow with all nodes configured:\n   - Webhook node (raw body, POST)\n   - Code node: HMAC-SHA256 signature validation\n   - IF node: branch filter\n   - Set node: constants (branch, repo URL, local path)\n   - Execute Command node: clone-or-pull shell command\n   - Stop and Error node: failure path\n2. deploy.sh — standalone shell script version of the clone-or-pull logic (for manual use or debugging)\n3. .env.example — all required env vars documented (WEBHOOK_SECRET, GIT_TOKEN or SSH setup instructions)\n4. Setup instructions — how to import the workflow into n8n, configure env vars, register the webhook URL with the Git provider\n\nShell command must:\n- Be idempotent (clone if not exists, pull if exists)\n- Never interpolate webhook payload data\n- Log output to /var/log/deploy.log\n- Return non-zero exit code on failure\n\nDone criteria: Workflow JSON written to backlog/git-push-deploy-builder/workflow.json, script to backlog/git-push-deploy-builder/deploy.sh, env example to backlog/git-push-deploy-builder/.env.example',
  'todo', 90
)
ON CONFLICT (agent_name, title) DO NOTHING
RETURNING id, agent_name, title, status, priority;
