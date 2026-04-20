import { getCameras, getStatus } from "../api.js";
import { timeAgo } from "../utils.js";

export function statusComponent() {
  return {
    cameras: [],
    uptime: null,
    lastEvent: null,
    loading: true,
    error: null,
    _pollTimer: null,

    async init() {
      await this.load();
      this._pollTimer = setInterval(() => this.load(), 60_000);
    },

    destroy() {
      clearInterval(this._pollTimer);
    },

    async load() {
      try {
        const [camData, statusData] = await Promise.all([getCameras(), getStatus()]);
        this.cameras = camData.cameras ?? [];
        this.uptime = statusData.server_uptime_seconds ?? null;
        this.lastEvent = statusData.last_event_at ?? null;
        this.error = null;
      } catch {
        this.error = "Could not load status.";
      } finally {
        this.loading = false;
      }
    },

    get uptimeText() {
      if (this.uptime == null) return "—";
      const h = Math.floor(this.uptime / 3600);
      const m = Math.floor((this.uptime % 3600) / 60);
      return h > 0 ? `${h}h ${m}m` : `${m}m`;
    },

    get lastEventText() {
      return this.lastEvent ? timeAgo(this.lastEvent) : "—";
    },

    cameraLastSeen(camera) {
      return camera.last_seen_at ? timeAgo(camera.last_seen_at) : "Never";
    },

    isOnline(camera) {
      if (!camera.last_seen_at) return false;
      const diffMs = Date.now() - new Date(camera.last_seen_at).getTime();
      return diffMs < 5 * 60 * 1000;
    },
  };
}
