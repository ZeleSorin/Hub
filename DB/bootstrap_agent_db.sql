-- Bootstrap script for octo_agents database
-- Idempotent: safe to run multiple times
-- Usage: psql postgresql://postgres:postgres@localhost:5432/postgres -f bootstrap_agent_db.sql

-- Create the database if it does not exist
SELECT 'CREATE DATABASE octo_agents'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'octo_agents')\gexec

-- Connect to the new database
\c octo_agents

-- Create the agent_tasks table
CREATE TABLE IF NOT EXISTS agent_tasks (
    id          SERIAL PRIMARY KEY,
    agent_name  TEXT        NOT NULL,
    title       TEXT        NOT NULL,
    description TEXT,
    status      TEXT        NOT NULL DEFAULT 'todo'
                            CHECK (status IN ('todo', 'in_progress', 'done')),
    priority    INTEGER     NOT NULL DEFAULT 0,
    claimed_at  TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT agent_tasks_agent_name_title_key UNIQUE (agent_name, title)
);

-- Index for "next task" query: agent_name + status + priority
CREATE INDEX IF NOT EXISTS idx_agent_tasks_claim
    ON agent_tasks (agent_name, status, priority DESC, created_at ASC);

-- Index for "list my tasks" query
CREATE INDEX IF NOT EXISTS idx_agent_tasks_agent
    ON agent_tasks (agent_name);

-- Add unique constraint if table already existed without it
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'agent_tasks_agent_name_title_key'
    ) THEN
        ALTER TABLE agent_tasks ADD CONSTRAINT agent_tasks_agent_name_title_key UNIQUE (agent_name, title);
    END IF;
END $$;

-- Create the draft_tasks table (raw operator notes, not tracked work items)
CREATE TABLE IF NOT EXISTS draft_tasks (
    id          SERIAL PRIMARY KEY,
    agent_name  TEXT        NOT NULL,
    content     TEXT        NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for per-agent queries
CREATE INDEX IF NOT EXISTS idx_draft_tasks_agent
    ON draft_tasks (agent_name);
