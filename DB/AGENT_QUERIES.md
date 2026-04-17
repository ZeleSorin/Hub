# Agent Query Reference

Connection string (from host machine):
```
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/octo_agents
```

---

## 1. Claim next task

Returns the highest-priority unclaimed task for this agent. Safe for concurrent agents — uses `SKIP LOCKED` to prevent double-claiming.

```sql
BEGIN;

SELECT id, title, description
FROM agent_tasks
WHERE agent_name = '<your-agent-name>' AND status = 'todo'
ORDER BY priority DESC, created_at ASC
LIMIT 1
FOR UPDATE SKIP LOCKED;

-- If a row was returned, mark it in_progress (use the id from above):
UPDATE agent_tasks
SET status = 'in_progress', claimed_at = now()
WHERE id = <id>;

COMMIT;
```

---

## 2. Mark task done

```sql
UPDATE agent_tasks
SET status = 'done', completed_at = now()
WHERE id = <id>;
```

---

## 3. List my tasks

```sql
SELECT id, title, status, priority, claimed_at, completed_at
FROM agent_tasks
WHERE agent_name = '<your-agent-name>'
ORDER BY priority DESC, created_at ASC;
```

---

## 4. Add a task (for seeding or manual insertion)

```sql
INSERT INTO agent_tasks (agent_name, title, description, priority)
VALUES ('<your-agent-name>', '<title>', '<description>', <priority>);
```

Priority convention: higher integer = pulled first. Use `0` for normal, `10` for high, `100` for urgent.
