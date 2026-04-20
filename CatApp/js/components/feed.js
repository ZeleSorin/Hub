import { getEvents, photoUrl } from "../api.js";
import { timeAgo, primaryLabel, isHighConfidence } from "../utils.js";

export function feedComponent() {
  return {
    events: [],
    loading: true,
    error: null,
    lastUpdated: null,
    _pollTimer: null,

    async init() {
      await this.load();
      this._pollTimer = setInterval(() => this.load(), 30_000);
    },

    destroy() {
      clearInterval(this._pollTimer);
    },

    async load() {
      try {
        const data = await getEvents({ limit: 20 });
        this.events = data.events ?? [];
        this.error = null;
        this.lastUpdated = new Date();
      } catch (err) {
        this.error = "Could not reach server. Retrying in 30s.";
      } finally {
        this.loading = false;
      }
    },

    get statusText() {
      if (this.error) return this.error;
      if (this.lastUpdated) return `Updated ${timeAgo(this.lastUpdated.toISOString())}`;
      return "";
    },

    label(event) {
      return primaryLabel(event.analysis);
    },

    confident(event) {
      return isHighConfidence(event.analysis?.confidence);
    },

    timestamp(event) {
      return timeAgo(event.captured_at);
    },

    imgSrc(event) {
      return photoUrl(event.photo_url) ?? "";
    },

    openDetail(event) {
      this.$dispatch("open-detail", { event });
    },
  };
}
