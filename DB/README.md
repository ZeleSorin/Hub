# Octo Agent Database — Usage Guide

## Connection

```
postgresql://postgres:postgres@localhost:5432/octo_agents
```

Set this as your `DATABASE_URL` environment variable. No config files, no framework — just this string and raw SQL.

---

## Rules

- **Do NOT alter the schema.** No CREATE, DROP, ALTER, or any DDL statements. The schema is owned by the DB expert. If you need a change, request it.
- **Do NOT write to `octo_dashboard_dev`.** That database belongs to the Phoenix app.
- **Read and write `agent_tasks` only.** Do not write to `draft_tasks` — that table is operator-managed.

---

## Your table: `agent_tasks`

| Column | Description |
|---|---|
| `id` | Task identifier |
| `agent_name` | Your agent name (e.g. `dashboard-ui-expert`) |
| `title` | What the task is |
| `description` | Optional detail |
| `status` | `todo` → `in_progress` → `done` |
| `priority` | Higher integer = pulled first |
| `claimed_at` | Set automatically when you claim a task |
| `completed_at` | Set automatically when you mark done |
| `created_at` | Set automatically on insert |

## Read-only: `draft_tasks`

Raw task notes written by the operator from the dashboard. You may read these for context but must not write to them.

| Column | Description |
|---|---|
| `id` | Row identifier |
| `agent_name` | Which agent the note is for |
| `content` | Free-form text |
| `created_at` | When it was written |

---

## Queries

### Get your next task

```sql
BEGIN;

SELECT id, title, description
FROM agent_tasks
WHERE agent_name = '<your-agent-name>' AND status = 'todo'
ORDER BY priority DESC, created_at ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;

UPDATE agent_tasks
SET status = 'in_progress', claimed_at = now()
WHERE id = <id from above>;

COMMIT;
```

### Mark task done

```sql
UPDATE agent_tasks
SET status = 'done', completed_at = now()
WHERE id = <id>;
```

### List your tasks

```sql
SELECT id, title, status, priority, claimed_at, completed_at
FROM agent_tasks
WHERE agent_name = '<your-agent-name>'
ORDER BY priority DESC, created_at ASC;
```

---

## What you must NOT do

- `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE` — forbidden
- `CREATE INDEX`, `DROP INDEX` — forbidden
- `INSERT` or `DELETE` on rows that belong to another agent
- Write anything to `octo_dashboard_dev`

If the schema does not fit your needs, talk to the DB expert.
