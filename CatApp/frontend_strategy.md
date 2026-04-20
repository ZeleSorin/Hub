# Frontend Strategy — Cat Monitoring App

## Chosen Approach

**Mobile-first web app, no PWA for now.**

A plain web app served over the local network (or a simple tunnel like Tailscale/ngrok for remote access) is the right starting point. It runs on iPhone Safari without any App Store involvement, requires no build pipeline beyond a single HTML file + optional bundler, and can be iterated on immediately.

PWA features (manifest, service worker, offline cache) are not added until they are specifically needed. The first version does not need offline support. Add the manifest when the user wants "Add to Home Screen" — that is a five-minute addition, not an architecture decision.

No native iOS. The app does not need push notifications or background refresh in V1. Web is sufficient.

---

## Stack Choice

**No framework. Vanilla JS with Alpine.js for reactivity.**

Alpine.js is a 15kb script tag. It handles reactive state, DOM updates, and event handling without a build step. The developer can read and understand every line. There is no Webpack, no Vite, no node_modules to maintain. A `.html` file with a `<script src="alpine.min.js">` and a `<link rel="stylesheet" href="style.css">` is the entire project scaffold.

**Styling: plain CSS with CSS custom properties.**

No Tailwind, no CSS-in-JS. A single `style.css` with CSS variables for colors and spacing. Mobile-first media queries. The stylesheet should be under 200 lines for V1.

**State/data: Alpine.js component state + fetch + setInterval.**

Each screen manages its own state as an Alpine component. Data is fetched with the native `fetch()` API. No Redux, no Zustand, no SWR. State lives in the component that needs it — not in a global store.

This stack fits a solo developer building a personal Pi-backed app because there is nothing to break, nothing to upgrade, and nothing to learn beyond what the developer already knows. The entire app can be understood by reading three files.

---

## App Structure

**Three screens:**

### 1. Feed (default / home screen)
- Shows the last 20 events, newest first
- Each event: thumbnail photo + analysis label + timestamp
- Tapping an event opens the Detail screen
- Polling refreshes the list every 30 seconds

### 2. Event Detail
- Full-size photo
- Full analysis result text
- Camera name + exact timestamp
- Back button returns to Feed

### 3. System Status
- Camera list with last-seen timestamp per camera
- Server uptime / last ping
- Accessible via a single status icon in the top bar

**Navigation model:** No router. Three Alpine components, toggled with `x-show`. No URL changes, no history stack. The app is too small to justify a router. If the developer wants deep-linking later, it can be added with 20 lines of code.

---

## UX Priorities

**iPhone Safari constraints drive every decision:**

- **Touch targets:** All interactive elements are minimum 44×44px. No small icon-only buttons. Labels next to icons on the main feed.
- **Typography:** System font stack (`-apple-system, BlinkMacSystemFont, sans-serif`). 16px base size minimum — never smaller. Line height 1.5 for readability.
- **Scroll behavior:** Feed is a single vertically scrolling list. No horizontal scroll. `overflow-x: hidden` on body. `-webkit-overflow-scrolling: touch` on scroll containers.
- **Image display:** Photos fill the card width with a fixed aspect ratio (16:9 or 4:3 depending on camera). `object-fit: cover` prevents distortion. Images load lazily. Placeholder shown while loading.
- **Status feedback:** A subtle spinner or "Refreshing…" label during polls. Never a blank screen — always show stale data while fetching new data.
- **No modals.** Detail view replaces the feed, not a modal overlay. Modals are hard to dismiss reliably on iOS Safari.

---

## Backend Integration

**Communication: HTTP REST, JSON responses, fetch() from the browser.**

No WebSockets, no SSE for V1. The data changes at most every few minutes (camera capture frequency). Polling is simpler, easier to debug, and sufficient.

**Proposed API endpoints:**

```
GET /api/events?limit=20&offset=0
  → { events: [{ id, camera_id, captured_at, photo_url, analysis: { label, confidence, raw } }] }

GET /api/events/:id
  → { id, camera_id, captured_at, photo_url, analysis: { label, confidence, raw } }

GET /api/cameras
  → { cameras: [{ id, name, last_seen_at, status }] }

GET /api/status
  → { server_uptime_seconds, camera_count, last_event_at }

GET /photos/:filename
  → binary image (JPEG), served directly by the Go server
```

Photos are served as static files by the Go server — no base64 in JSON, no presigned URLs. The `photo_url` field in the event response is a relative path like `/photos/2024-01-15_143022_cam1.jpg`.

**Polling strategy:**
- Feed polls `GET /api/events?limit=20` every 30 seconds via `setInterval`
- Status screen polls `GET /api/cameras` and `GET /api/status` every 60 seconds
- Detail view does not poll — it shows a point-in-time snapshot

**Error and loading states:**
- **Loading:** Show last known data immediately; display a small "Updating…" indicator during fetch. Never block the UI.
- **Empty state:** If no events exist yet, show "No events yet. Cameras will appear here once they capture activity." — not a blank screen.
- **Error:** If fetch fails, show a small banner: "Could not reach server. Retrying in 30s." Do not crash the UI or clear existing data. Retry automatically on the next poll cycle.

---

## Media Handling

**Photos are loaded as standard `<img>` tags pointing to `/photos/:filename`.**

No base64 encoding. No blob URLs. No image proxy. The Go server serves the JPEG files directly from disk. This is the simplest approach and works fine on a local network.

**Lazy loading:** Add `loading="lazy"` to all `<img>` tags in the feed list. The browser handles the rest. No Intersection Observer needed in V1.

**Thumbnail vs full size:** The Go server serves one size — the original capture. If the originals are large (>1MB), the Go server should resize them to ~800px wide on disk before storing, or serve a resized version via a query param (`/photos/:filename?w=400`). Do not implement client-side resizing.

**Analysis results alongside photos:**
- In the feed card: one-line label below the image (e.g. "Luna — sleeping", "Max — eating")
- In the detail view: full analysis block — label, confidence percentage, and any raw description from the model
- Confidence below 60% gets a muted color (gray) to signal uncertainty

---

## Build Plan

**Step 1 — Static scaffold (Day 1)**
Create `index.html` with Alpine.js via CDN, `style.css`, and a hardcoded mock event object. Render one card with a placeholder image. Get it looking right on iPhone Safari before touching the backend.

**Step 2 — Feed screen with real data (Day 2)**
Wire `GET /api/events?limit=20` to the feed component. Replace mock data with live data. Confirm images load from `/photos/:filename`. Add the 30-second poll with `setInterval`.

**Step 3 — Detail screen (Day 3)**
Add the detail view as a second Alpine component toggled with `x-show`. Tap a feed card → detail appears. Back button returns to feed. Show full photo + full analysis text.

**Step 4 — Empty and error states (Day 3–4)**
Handle the three states for the feed: loading (spinner), empty (message), error (banner + retry). Do not skip this — it is what makes the app feel finished.

**Step 5 — Status screen (Day 4–5)**
Add the status screen with camera list and last-seen timestamps. Toggle via an icon in the top bar.

**Step 6 — Polish for iPhone (Day 5–6)**
Test on real iPhone Safari. Fix touch target sizes, scroll jank, font sizes. Add `<meta name="viewport" content="width=device-width, initial-scale=1">` if not already present. Add `<meta name="apple-mobile-web-app-capable" content="yes">`.

**Step 7 — PWA manifest (optional, Day 6+)**
Add `manifest.json` and a basic service worker only if the user wants "Add to Home Screen" with an icon. This is a cosmetic improvement, not a functional one.

---

## Things To Avoid

**React / Vue / Svelte.** None of these are justified for a three-screen personal tool. They add build steps, node_modules, and concepts (virtual DOM, component lifecycle, JSX) that a learning developer does not need to debug at 11pm.

**WebSockets.** The data changes every few minutes. Polling is simpler, easier to debug, and sufficient. WebSockets add server-side complexity (goroutine management, connection state) for no real benefit here.

**A state management library.** No Redux, no Zustand, no Pinia. Each screen owns its own state. There is no shared state complex enough to warrant a store.

**Base64-encoding images in API responses.** This inflates JSON payloads by ~33%, kills response times, and prevents browser caching. Serve images as static files.

**CSS frameworks.** Tailwind requires a build step and a learning curve. Bootstrap adds 200kb and generic-looking components. Write 150 lines of plain CSS instead.

**Abstracting the API client.** Do not create a `api.js` module with a class and methods. Call `fetch()` directly in the component. When the app has three endpoints, abstraction is overhead, not help.

**Over-planning the backend API.** Propose the endpoints above, build the frontend against them, adjust as needed. Do not spend a week designing a perfect API contract before writing a single line of UI.

**Targeting anything other than iPhone Safari.** This is a personal app. It needs to work on one device. Do not test in Chrome and call it done — test on the actual phone.
