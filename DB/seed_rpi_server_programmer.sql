INSERT INTO agent_tasks (agent_name, title, description, status, priority)
VALUES (
  'rpi-server-programmer',
  'TASK 1 - Design and document server architecture',
  E'Produce the full architecture design document for the Raspberry Pi server application.\n\nOutput must cover:\n1. Stack Choice — language, framework, and justification for Raspberry Pi constraints\n2. Repo Structure — full suggested folder/file layout\n3. Server Architecture — key modules and responsibilities\n4. API Skeleton — initial endpoints and purpose\n5. Configuration Strategy — env vars, secrets handling\n6. Docker Setup — Dockerfile approach, compose integration notes\n7. First Build Tasks — exact ordered list of implementation tasks\n\nConstraints:\n- Stack must be appropriate for linux/arm64, low RAM usage\n- No heavy frameworks, no microservice complexity\n- Local dev and Pi deployment must use the same Dockerfile and compose file\n- Output must be practical and implementation-focused, not theoretical\n\nDone criteria: Document written to backlog/rpi-server-programmer/server_architecture.md',
  'todo', 100
),
(
  'rpi-server-programmer',
  'TASK 2 - Scaffold server repo and implement working entrypoint',
  E'Create the actual server repository with a working entrypoint, health check endpoint, config loading, logging, and Dockerfile.\n\nDeliverables (all files must compile and run):\n- cmd/server/main.go — entrypoint, wires config + server + routes\n- internal/config/config.go — env loading with defaults and required var validation\n- internal/server/server.go — http.Server setup with graceful shutdown on SIGTERM\n- internal/handler/health.go — GET /health returns {"status":"ok"}\n- internal/handler/routes.go — route registration\n- internal/middleware/logging.go — request logging middleware\n- Dockerfile — multi-stage build, final image linux/arm64\n- docker-compose.yml — single service, env_file, volume mount placeholder\n- .env.example — all supported env vars documented\n- .gitignore — Go standard ignores\n- go.mod — module name rpi-server, Go 1.22+\n- README.md — how to run locally and on Pi\n\nVerification:\n- docker build succeeds\n- curl http://localhost:<PORT>/health returns {"status":"ok"}\n- Server handles SIGTERM without dropping in-flight requests\n\nDone criteria: All files written to server/rpi-server/ directory. Docker build passes. Health check responds.',
  'todo', 90
)
ON CONFLICT (agent_name, title) DO NOTHING
RETURNING id, agent_name, title, status, priority;
