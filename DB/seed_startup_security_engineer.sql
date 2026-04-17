INSERT INTO agent_tasks (agent_name, title, description, status, priority)
VALUES (
  'startup-security-engineer',
  'TASK 1 - Security review of all current project components',
  E'Perform a security review across all currently defined project components. Read each agent_init.md and available design/architecture documents, then produce a consolidated security report.\n\nComponents to review:\n- server/MASTER_ARCHITECTURE.md (Pi infrastructure: Docker, Caddy, PostgreSQL, n8n)\n- backlog/git-push-deploy-builder/agent_init.md (webhook + shell execution)\n- backlog/rpi-server-programmer/agent_init.md (Go API server)\n- backlog/pi-setup/agent_init.md (OS setup)\n- backlog/pi-deploy/agent_init.md (Docker Compose deployment)\n\nFor each component, produce:\n# Security Issues — actual risks found\n# Severity — Low / Medium / High with justification\n# Fixes — concrete steps\n# Safer Pattern — what to do going forward\n\nThen produce a cross-cutting section:\n# Minimal Rules — reusable rules that apply across all components\n# Quick Checklist — things to verify before deploying anything in this project\n\nConstraints:\n- Focus on realistic threats (automated scanners, webhook replay, command injection, secret leakage, exposed ports)\n- No enterprise tooling recommendations\n- Every finding must include the attack scenario\n- Prioritize by severity, High items first\n\nDone criteria: Report written to backlog/startup-security-engineer/security_review.md',
  'todo', 100
)
ON CONFLICT (agent_name, title) DO NOTHING
RETURNING id, agent_name, title, status, priority;
