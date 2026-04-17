# Database Connection Guide

Two PostgreSQL databases run in a single Docker container (`octo_dashboard_db`, postgres:17, host port 5432):

| Database | Owner | Purpose |
|---|---|---|
| `octo_dashboard_dev` | Phoenix app | Cached index of agents, tasks, and interaction history |
| `octo_agents` | Agents | Authoritative task queue and operator draft notes |

Credentials (dev only): `postgres` / `postgres`

---

## 1. Operator (you, the human)

### Connect from the host machine

**Via docker exec (no local psql needed):**
```bash
# octo_agents
docker exec -it octo_dashboard_db psql -U postgres -d octo_agents

# octo_dashboard_dev
docker exec -it octo_dashboard_db psql -U postgres -d octo_dashboard_dev
```

**Via GUI client (SQLTools, DBeaver, TablePlus, etc.):**

| Field | Value |
|---|---|
| Host | `localhost` |
| Port | `5432` |
| Username | `postgres` |
| Password | `postgres` |
| Database | `octo_agents` or `octo_dashboard_dev` |

### Run SQL files
```bash
# Bootstrap schema (idempotent — safe to re-run)
docker exec -i octo_dashboard_db psql -U postgres -f - < DB/bootstrap_agent_db.sql

# Any ad-hoc SQL file
docker exec -i octo_dashboard_db psql -U postgres -d octo_agents -f - < DB/your_file.sql
```

### Tables in octo_agents

| Table | Purpose |
|---|---|
| `agent_tasks` | Structured tasks agents claim and complete |
| `draft_tasks` | Free-form operator notes, written from the dashboard |

### Useful inspection queries
```sql
-- List all tables
SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Task summary per agent
SELECT agent_name,
       COUNT(*) AS total,
       COUNT(*) FILTER (WHERE status = 'done') AS done,
       COUNT(*) FILTER (WHERE status = 'todo') AS todo
FROM agent_tasks
GROUP BY agent_name
ORDER BY agent_name;

-- Manually update a task
UPDATE agent_tasks SET status = 'done', completed_at = now() WHERE id = <id>;
```

---

## 2. Agents (Claude CLI processes)

### Connection string
```
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/octo_agents
```

Set this as an environment variable. Connect with `psql $DATABASE_URL` or any PostgreSQL client.

### Your agent_name
Use your folder slug exactly as it appears in `backlog/`. Examples:
- `dashboard-ui-expert`
- `k3s-setup-expert`
- `usb-drive-setup-expert`
- `local-db-expert`

### Claim your next task (atomic — safe for concurrent agents)
```sql
BEGIN;

SELECT id, title, description
FROM agent_tasks
WHERE agent_name = '<your-agent-name>' AND status = 'todo'
ORDER BY priority DESC, created_at ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- If a row was returned, mark it in_progress:
UPDATE agent_tasks SET status = 'in_progress', claimed_at = now() WHERE id = <id>;

COMMIT;
```

### Mark task done
```sql
UPDATE agent_tasks SET status = 'done', completed_at = now() WHERE id = <id>;
```

### List your tasks
```sql
SELECT id, title, status, priority, claimed_at, completed_at
FROM agent_tasks
WHERE agent_name = '<your-agent-name>'
ORDER BY priority DESC, created_at ASC;
```

### If the DB is unreachable
- Confirm the `octo_dashboard_db` container is running: `docker ps`
- Start it if needed: `docker compose up db` from `Dashboard/`
- Do not proceed with work that requires task tracking until the connection is restored
- Never write task state to files as a substitute for the DB

---

## 3. Applications (Phoenix dashboard)

### octo_dashboard_dev — primary Repo
The Phoenix app owns this database exclusively. Connection is configured via environment variable:

```
DATABASE_URL=ecto://postgres:postgres@db/octo_dashboard_dev
```

Inside Docker, `db` resolves to the `octo_dashboard_db` container via the Docker Compose network. This maps to `OctoDashboard.Repo` in `runtime.exs`:

```elixir
config :octo_dashboard, OctoDashboard.Repo,
  url: System.get_env("DATABASE_URL") || "ecto://postgres:postgres@db/octo_dashboard_dev",
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
```

**The Phoenix app has full read/write access to `octo_dashboard_dev`. It must never write to `octo_agents`.**

### octo_agents — read-only from the dashboard
The dashboard may query `octo_agents` to display agent task status (see `UI-017`). This connection must be:
- Read-only (SELECT only — no INSERT, UPDATE, DELETE)
- Configured as a separate Repo or via raw SQL with a dedicated connection string
- Connection string from inside Docker: `postgresql://postgres:postgres@db:5432/octo_agents`

Note: `db` is the Docker Compose service name, reachable inside the container network. `localhost` from inside a container points to the container itself, not the host.

### Ownership summary

| Database | Phoenix writes | Agents write |
|---|---|---|
| `octo_dashboard_dev` | Yes | No |
| `octo_agents` | No (read-only) | Yes |
