/**
 * Format an ISO timestamp into a human-readable relative or absolute string.
 * - Within 60 s  → "just now"
 * - Within 1 h   → "X min ago"
 * - Within 24 h  → "X hr ago"
 * - Older        → locale date + time
 */
export function timeAgo(isoString) {
  const date = new Date(isoString);
  const diffMs = Date.now() - date.getTime();
  const diffS = Math.floor(diffMs / 1000);

  if (diffS < 60) return "just now";
  if (diffS < 3600) return `${Math.floor(diffS / 60)} min ago`;
  if (diffS < 86400) return `${Math.floor(diffS / 3600)} hr ago`;

  return date.toLocaleString(undefined, {
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

/**
 * Extract the primary label from an analysis string.
 * The backend returns free-form text; we take the first sentence or line.
 */
export function primaryLabel(analysis) {
  if (!analysis) return "Unknown";
  const first = analysis.split(/[\n.]/)[0].trim();
  return first || "Unknown";
}

/**
 * Return true if confidence is high enough to display prominently.
 * Confidence is expected as a 0–1 float or 0–100 integer.
 */
export function isHighConfidence(confidence) {
  if (confidence == null) return true;
  const val = confidence > 1 ? confidence : confidence * 100;
  return val >= 60;
}
