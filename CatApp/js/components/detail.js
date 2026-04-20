import { photoUrl } from "../api.js";
import { timeAgo, primaryLabel, isHighConfidence } from "../utils.js";

export function detailComponent() {
  return {
    event: null,

    get label() {
      return primaryLabel(this.event?.analysis);
    },

    get confident() {
      return isHighConfidence(this.event?.analysis?.confidence);
    },

    get imgSrc() {
      return photoUrl(this.event?.photo_url) ?? "";
    },

    get timestamp() {
      return this.event ? timeAgo(this.event.captured_at) : "";
    },

    get analysisText() {
      return this.event?.analysis?.raw ?? this.event?.analysis ?? "";
    },

    get cameraName() {
      return this.event?.camera_id ?? "Unknown camera";
    },

    open(event) {
      this.event = event;
    },

    close() {
      this.event = null;
      this.$dispatch("close-detail");
    },
  };
}
