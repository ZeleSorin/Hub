import { feedComponent } from "./components/feed.js";
import { detailComponent } from "./components/detail.js";
import { statusComponent } from "./components/status.js";

document.addEventListener("alpine:init", () => {
  Alpine.data("feed", feedComponent);
  Alpine.data("detail", detailComponent);
  Alpine.data("status", statusComponent);
});
