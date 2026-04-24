# Status — Cat Monitoring Frontend

## Done

### Task 148 — Frontend strategy (complete)
- `CatApp/frontend_strategy.md` — full architecture document covering stack, screens, UX, API contract, build plan

### Implementation — Step 1 scaffold (committed, tests passing)
Files in `CatApp/`:
- `index.html` — Alpine.js, 3 screens (Feed / Detail / Status), toggled with x-show
- `css/style.css` — dark theme, mobile-first, 44px touch targets
- `js/api.js` — all fetch calls (getEvents, getEvent, getCameras, getStatus, photoUrl)
- `js/utils.js` — timeAgo, primaryLabel, isHighConfidence
- `js/app.js` — registers Alpine components
- `js/components/feed.js` — 30s polling, loading/error/empty states
- `js/components/detail.js` — full photo + analysis view
- `js/components/status.js` — camera list + server uptime, 60s polling
- `tests/api.test.js` + `tests/utils.test.js` — 21 unit tests
- `Dockerfile` — multi-stage: node runs tests, nginx:alpine serves the app
- `nginx.conf` — proxies /api/ and /photos/ → server:8080
- `docker-compose.yml` — joins external proxy network, same pattern as server

### Infra (committed in pi-cloud submodule)
- `pi-cloud/infra/Caddyfile` — added `http://cats.local { reverse_proxy cat-monitor-ui:80 }`

## Pending commit
- `CatApp/docker-compose.yml` — staged but not committed in Octo root (user interrupted)

## Blocked on backend
The frontend calls these endpoints that the Go server does not expose yet:
- `GET /api/events?limit=20&offset=0` → `{ events: [{ id, camera_id, captured_at, photo_url, analysis }] }`
- `GET /api/events/:id` → single event
- `GET /api/cameras` → `{ cameras: [{ id, name, last_seen_at, status }] }`
- `GET /api/status` → `{ server_uptime_seconds, last_event_at }`
- `GET /photos/:filename` → binary JPEG served from disk

Backend source: `observations` table has `id, photo_path, analysis, created_at`. No camera table yet.

## Next steps (frontend)
1. Commit pending docker-compose.yml
2. Add mock data mode so UI can be previewed without a live backend
3. Polish pass on iPhone once real data is flowing
