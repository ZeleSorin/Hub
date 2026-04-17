-- Seed agent tasks for octo_agents
-- All tasks are sourced from each agent's backlog TODO.txt
-- Idempotent: uses ON CONFLICT (agent_name, title) DO NOTHING
-- Usage: psql postgresql://postgres:postgres@localhost:5432/octo_agents -f seed_agent_tasks.sql

\c octo_agents

INSERT INTO agent_tasks (agent_name, title, description, status, priority, completed_at) VALUES

-- ============================================================
-- dashboard-ui-expert
-- ============================================================

('dashboard-ui-expert', 'TASK 1 - Scaffold Phoenix project',
 'Create a new Phoenix LiveView project with PostgreSQL adapter and Tailwind CSS configured.',
 'done', 160, now()),

('dashboard-ui-expert', 'TASK 2 - Agent schema and migration',
 'Define Agent schema and Ecto migration with fields: id, name, folder_path, description, inserted_at.',
 'done', 150, now()),

('dashboard-ui-expert', 'TASK 3 - Task schema and migration',
 'Define Task schema and migration with fields: id, agent_id, title, status, position, inserted_at.',
 'done', 140, now()),

('dashboard-ui-expert', 'TASK 4 - Agent loader',
 'Build module that scans backlog/, parses each agent_init.md and TODO.txt, and upserts records into the DB.',
 'done', 130, now()),

('dashboard-ui-expert', 'TASK 5 - AgentList LiveView',
 'Build LiveView listing all agents with streams, showing name, task count, and a status badge per agent.',
 'done', 120, now()),

('dashboard-ui-expert', 'TASK 6 - AgentDetail LiveView',
 'Build LiveView showing agent info and task list with checkboxes to mark tasks as in_progress or done.',
 'done', 110, now()),

('dashboard-ui-expert', 'TASK 7 - InteractionPanel LiveComponent',
 'Build live component with a prompt text input, run button, and scrollable output display area.',
 'done', 100, now()),

('dashboard-ui-expert', 'UI-008 - AgentRunner module',
 E'Scope: Create lib/octo_dashboard/agent_runner.ex and lib/octo_dashboard/runner_supervisor.ex. Add RunnerSupervisor to application.ex children if missing.\n\nDone when:\n- AgentRunner.start_run(%Agent{}, prompt) starts a temporary GenServer under RunnerSupervisor\n- Port opens with {:spawn_executable, claude_path} and options [:binary, :exit_status, {:line, 4096}]\n- Each {:eol, line} is broadcast to "agent:<id>:runner" via OctoDashboard.PubSub\n- {:exit_status, code} stops the GenServer with :normal\n- claude_path read from Application.fetch_env!(:octo_dashboard, :claude_path) — never hardcoded\n- RunnerSupervisor is a DynamicSupervisor with restart: :temporary per child\n\nCommit: feat: add AgentRunner GenServer with port-based claude CLI streaming',
 'done', 90, now()),

('dashboard-ui-expert', 'UI-009 - Wire DashboardLive to AgentRunner',
 E'Scope: Modify lib/octo_dashboard_web/live/dashboard_live.ex only.\n\nDone when:\n- handle_info({:interaction_prompt_submitted, prompt}) calls AgentRunner.start_run/2 for selected agent\n- Selecting an agent subscribes socket to "agent:<id>:runner" via Phoenix.PubSub.subscribe\n- handle_info({:runner_chunk, interaction_id, line}) appends line to output_lines, capped at 300\n- handle_info({:runner_finished, interaction_id, exit_code, _}) sets runner_state to "idle" and puts flash\n- Switching agents unsubscribes previous topic before subscribing new one\n- runner_state assign is "idle" | "running" and controls submit button disabled state\n\nCommit: feat: wire DashboardLive to AgentRunner via PubSub for real-time output streaming',
 'done', 80, now()),

('dashboard-ui-expert', 'UI-010 - Persist interaction history',
 E'Scope: Create lib/octo_dashboard/dashboard/interaction.ex and one migration file. Add create_interaction/1, complete_interaction/2, list_interactions/2, get_interaction/1 to dashboard.ex.\n\nDone when:\n- Migration creates interactions table with: id, agent_id (FK, on_delete: :delete_all), prompt (text not null), full_response (text default ""), exit_code (integer), started_at (utc_datetime_usec not null), completed_at (utc_datetime_usec), inserted_at\n- Index on agent_id and inserted_at\n- Dashboard.create_interaction/1 inserts on run start\n- Dashboard.complete_interaction/2 updates full_response, exit_code, completed_at on exit\n- InteractionPanel displays last 10 interactions for selected agent\n- mix ecto.migrate applies cleanly\n\nCommit: feat: add Interaction schema and persist agent run history to PostgreSQL',
 'done', 70, now()),

('dashboard-ui-expert', 'UI-011 - Tailwind layout',
 E'Scope: Modify dashboard_live.ex and interaction_panel_component.ex only.\n\nDone when:\n- Three-column layout on xl+: agent sidebar (~340px), detail (flex-1), interaction panel (~540px)\n- Single column on mobile\n- Agent sidebar: bg-white/85 backdrop-blur rounded-[1.75rem] border border-white/70 shadow-xl\n- Interaction panel: bg-slate-950 text-slate-100 rounded-[1.75rem] shadow-2xl\n- Stats row: Agents (sky), Queued Tasks (amber), Active Tasks (emerald)\n- Task badges: todo=slate, in_progress=amber, done=emerald\n- Agent badges: idle=slate, queued=sky, active=amber, done=emerald\n- Sync Backlog button in header\n- Empty state when no agent selected\n\nCommit: style: apply three-column operator layout with glass cards and dark interaction panel',
 'done', 60, now()),

('dashboard-ui-expert', 'UI-012 - Boot test',
 E'Scope: No code changes unless broken. Fix only the single file that is wrong.\n\nDone when:\n- docker compose up --build starts app and db with no blocking errors\n- Migrations apply on boot\n- localhost:4000 loads without crash\n- Sync Backlog loads agents from filesystem\n- Selecting agent shows its tasks\n- No compile warnings about missing modules\n\nNotes: Fixed boot issues in dev.sh, core_components.ex, dashboard_live.ex, agent_runner.ex, dev.exs, docker-compose.yml. watchman missing is non-fatal.\n\nCommit: fix: <describe what was broken> (only if code changes needed)',
 'done', 50, now()),

('dashboard-ui-expert', 'UI-013 - Validate claude CLI invocation',
 E'Scope: Modify lib/octo_dashboard/agent_runner.ex only (args list and Port options).\n\nDone when:\n- claude --help run on dev machine to confirm available flags and argument format\n- Prompt passing method confirmed (positional arg, flag value, or stdin)\n- Current impl ["--print", prompt] verified or corrected\n- Real test run via dashboard UI produces visible streamed output in interaction panel\n- Output arrives line by line, not buffered until exit\n\nStatus: claude --help confirmed -p/--print flag. Remaining gap: end-to-end test inside Docker requires claude CLI binary mounted or installed in the container.\n\nCommit: fix: correct claude CLI args for port-based invocation (only if args were wrong)',
 'todo', 40, NULL),

('dashboard-ui-expert', 'UI-014 - Fix stream_count helper',
 E'Scope: Modify lib/octo_dashboard_web/live/dashboard_live.ex only.\n\nDone when:\n- stream_count(@streams.tasks) replaced with @task_count (integer assign)\n- task_count set in load_dashboard as length(selected_agent.tasks), 0 when no agent selected\n- Private stream_count/1 function removed if no longer used\n- agent_count already uses this pattern; identical pattern applied to task_count\n- Displayed task count updates correctly when switching agents\n\nCommit: fix: replace stream_count/1 with tracked task_count assign',
 'done', 35, now()),

('dashboard-ui-expert', 'UI-015 - DONE.txt support in Loader',
 E'Scope: Modify lib/octo_dashboard/dashboard/loader.ex only, specifically parse_tasks/1.\n\nDone when:\n- Loader reads Tasks/DONE.txt if it exists, using same [x]/[ ] pattern\n- DONE.txt tasks appended after TODO.txt tasks with continuing positions\n- k3s-setup-expert and usb-drive-setup-expert show completed tasks after sync\n- Missing DONE.txt handled gracefully (no crash)\n- Position-based upsert prevents duplicate rows\n\nCommit: feat: include DONE.txt tasks in agent task loader',
 'done', 30, now()),

('dashboard-ui-expert', 'UI-016 - Task status sync safety',
 E'Scope: Modify lib/octo_dashboard/dashboard/loader.ex only, specifically sync_tasks/2.\n\nDone when:\n- Existing DB tasks with status in_progress or done are NOT reset to todo on sync\n- File marker [x] with DB status todo updates DB to done\n- File marker [ ] with DB status in_progress or done preserves DB status\n- New tasks get status from file marker\n- Logic in private merged_status(existing_task, parsed_status)\n\nCommit: fix: preserve in_progress and done task statuses across backlog syncs',
 'done', 25, now()),

-- ============================================================
-- local-db-expert
-- ============================================================

('local-db-expert', 'DB-001 - Verify PostgreSQL is accessible',
 E'Scope: No code changes. Verification only.\n\nDone when:\n- docker compose up db (from Dashboard/) starts cleanly with no errors\n- docker exec octo_dashboard_db pg_isready -U postgres returns "accepting connections"\n- psql postgresql://postgres:postgres@localhost:5432/octo_dashboard_dev -c "SELECT 1" succeeds from host machine\n- Host port 5432 is not blocked\n- PostgreSQL version and database existence confirmed\n\nCommit: none (verification only)',
 'todo', 70, NULL),

('local-db-expert', 'DB-002 - Run dashboard migrations',
 E'Scope: No migration files to create. Run existing migrations inside app container.\n\nDone when:\n- All three migrations applied: create_agents, create_tasks, create_interactions\n- \\dt on octo_dashboard_dev shows: schema_migrations, agents, tasks, interactions\n- \\d agents, \\d tasks, \\d interactions show correct columns and constraints\n- All three migration timestamps recorded in schema_migrations\n- If migration fails: report exact error, do not fix files without user approval\n\nCommit: none (no files changed)',
 'todo', 60, NULL),

('local-db-expert', 'DB-003 - Design agent task-pull schema',
 E'Scope: Write DB/SCHEMA_DESIGN.md only. No SQL yet.\n\nDone when:\n- SCHEMA_DESIGN.md documents the octo_agents database schema\n- Table: agent_tasks (id, agent_name, title, description, status, priority, claimed_at, completed_at, created_at)\n- Status values and transitions defined: todo -> in_progress -> done\n- Indexes specified alongside query patterns they support\n- Atomic claim strategy addressed (SKIP LOCKED)\n- Unique constraint on (agent_name, title) for idempotent seeding\n\nCommit: docs: add agent task-pull schema design',
 'todo', 50, NULL),

('local-db-expert', 'DB-004 - Create bootstrap SQL',
 E'Scope: Write DB/bootstrap_agent_db.sql only. Must be idempotent (safe to run multiple times).\n\nDone when:\n- File creates octo_agents database if not exists\n- All tables with CREATE TABLE IF NOT EXISTS including UNIQUE (agent_name, title)\n- All indexes with CREATE INDEX IF NOT EXISTS\n- Idempotent unique constraint migration via DO $$ block\n- Runs with: psql postgresql://postgres:postgres@localhost:5432/postgres -f bootstrap_agent_db.sql\n- Running twice produces no errors\n- No DROP statements\n\nCommit: feat: add bootstrap SQL for octo_agents database and agent task schema',
 'todo', 40, NULL),

('local-db-expert', 'DB-005 - Apply agent task-pull schema',
 E'Scope: No file changes. Run bootstrap_agent_db.sql and verify result.\n\nDone when:\n- bootstrap_agent_db.sql runs with no errors\n- \\dt on octo_agents shows agent_tasks table\n- \\d agent_tasks shows correct column types, NOT NULL constraints, unique constraint\n- \\di shows expected indexes present\n- If file had errors: fix bootstrap_agent_db.sql and include fix in commit\n\nCommit: none if no changes needed; fix: correct bootstrap SQL errors if file needed fixing',
 'todo', 30, NULL),

('local-db-expert', 'DB-006 - Document agent query interface',
 E'Scope: Write DB/AGENT_QUERIES.md only.\n\nDone when:\n- Documents DATABASE_URL: postgresql://postgres:postgres@localhost:5432/octo_agents\n- Exact SQL with placeholders for: claim next task (SKIP LOCKED), mark done, list my tasks, add a task\n- Explains agent_name convention (folder name slug, e.g. "dashboard-ui-expert")\n- Short enough to read in under two minutes\n\nCommit: docs: add AGENT_QUERIES.md with agent task SQL interface',
 'todo', 20, NULL),

('local-db-expert', 'DB-007 - Seed agent task data',
 E'Scope: Write DB/seed_agent_tasks.sql only. Run and verify.\n\nDone when:\n- seed_agent_tasks.sql contains all real tasks from each agent backlog\n- Uses ON CONFLICT (agent_name, title) DO NOTHING for idempotency\n- Correct statuses: done for completed tasks, todo for pending\n- Claim next task query returns correct highest-priority todo row per agent\n- SELECT count(*) FROM agent_tasks WHERE status = ''todo'' matches expected count\n\nCommit: feat: add seed SQL with real agent task data',
 'todo', 10, NULL),

-- ============================================================
-- k3s-setup-expert (all done)
-- ============================================================

('k3s-setup-expert', 'TASK 1 - Enable cgroup memory',
 'Update active boot cmdline on Raspberry Pi to enable memory cgroup support required by K3s.',
 'done', 70, now()),

('k3s-setup-expert', 'TASK 2 - Reboot Pi',
 'Reboot after kernel command line change so memory cgroup settings take effect.',
 'done', 60, now()),

('k3s-setup-expert', 'TASK 3 - Install K3s',
 'Install K3s using the official install script for a single-node server with --disable traefik.',
 'done', 50, now()),

('k3s-setup-expert', 'TASK 4 - Enable and start K3s service',
 'Enable and start the k3s systemd service, verify it is active via systemctl status.',
 'done', 40, now()),

('k3s-setup-expert', 'TASK 5 - Verify K3s is running',
 'Check service state and confirm k3s version v1.34.6+k3s1.',
 'done', 30, now()),

('k3s-setup-expert', 'TASK 6 - Configure kubeconfig for SSH user',
 'Copy admin kubeconfig to SSH user home directory, set KUBECONFIG=$HOME/.kube/config.',
 'done', 20, now()),

('k3s-setup-expert', 'TASK 7 - Verify cluster health',
 'Confirm node mob is Ready and core system pods are Running.',
 'done', 10, now()),

-- ============================================================
-- usb-drive-setup-expert (all done)
-- ============================================================

('usb-drive-setup-expert', 'STEP 1 - Discover attached block devices',
 'Run lsblk, identify USB vs SD card, confirm device with user if multiple USB drives detected.',
 'done', 100, now()),

('usb-drive-setup-expert', 'STEP 2 - Inspect the target device',
 'Run blkid and fdisk -l, report filesystem type, label, UUID, partition status.',
 'done', 90, now()),

('usb-drive-setup-expert', 'STEP 3 - Confirm intent with the user',
 'Show device path, current contents, planned action, data loss warning. Wait for explicit yes before proceeding.',
 'done', 80, now()),

('usb-drive-setup-expert', 'STEP 4 - Partition and/or format',
 'Only if needed: create GPT partition table and ext4 filesystem. Skip if already compatible.',
 'done', 70, now()),

('usb-drive-setup-expert', 'STEP 5 - Create the mount point',
 'mkdir -p /mnt/usb-data.',
 'done', 60, now()),

('usb-drive-setup-expert', 'STEP 6 - Mount the device temporarily',
 'Mount device to /mnt/usb-data, verify with df -h and findmnt.',
 'done', 50, now()),

('usb-drive-setup-expert', 'STEP 7 - Add to /etc/fstab using UUID',
 'Retrieve UUID via blkid, add fstab entry with nofail, validate with mount -a.',
 'done', 40, now()),

('usb-drive-setup-expert', 'STEP 8 - Create service-specific directory structure',
 'mkdir -p /mnt/usb-data/postgresql/data.',
 'done', 30, now()),

('usb-drive-setup-expert', 'STEP 9 - Validate and apply ownership/permissions',
 'postgres user not found at setup time. Directories left with root ownership. Must re-run chown/chmod after PostgreSQL is installed.',
 'done', 20, now()),

('usb-drive-setup-expert', 'STEP 10 - Final verification',
 'Run ls -la, stat, df -h. Report results and confirm USB is ready.',
 'done', 10, now())

ON CONFLICT (agent_name, title) DO NOTHING;
