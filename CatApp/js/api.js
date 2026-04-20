const BASE = import.meta.env?.VITE_API_BASE ?? "";

async function request(path) {
  const res = await fetch(`${BASE}${path}`);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json();
}

/**
 * @param {{ limit?: number, offset?: number }} opts
 * @returns {Promise<{ events: Event[] }>}
 */
export function getEvents({ limit = 20, offset = 0 } = {}) {
  return request(`/api/events?limit=${limit}&offset=${offset}`);
}

/**
 * @param {string|number} id
 * @returns {Promise<Event>}
 */
export function getEvent(id) {
  return request(`/api/events/${id}`);
}

/**
 * @returns {Promise<{ cameras: Camera[] }>}
 */
export function getCameras() {
  return request("/api/cameras");
}

/**
 * @returns {Promise<Status>}
 */
export function getStatus() {
  return request("/api/status");
}

/**
 * Resolve a photo URL. photo_path may be absolute (/photos/…) or relative.
 */
export function photoUrl(photoPath) {
  if (!photoPath) return null;
  if (photoPath.startsWith("http")) return photoPath;
  return `${BASE}${photoPath}`;
}
