import { describe, it, expect, vi, beforeEach } from "vitest";
import { getEvents, getEvent, getCameras, getStatus, photoUrl } from "../js/api.js";

function mockFetch(data, ok = true) {
  global.fetch = vi.fn().mockResolvedValue({
    ok,
    status: ok ? 200 : 404,
    statusText: ok ? "OK" : "Not Found",
    json: () => Promise.resolve(data),
  });
}

beforeEach(() => {
  vi.restoreAllMocks();
});

describe("getEvents", () => {
  it("calls /api/events with default limit and offset", async () => {
    mockFetch({ events: [] });
    await getEvents();
    expect(fetch).toHaveBeenCalledWith("/api/events?limit=20&offset=0");
  });

  it("respects custom limit and offset", async () => {
    mockFetch({ events: [] });
    await getEvents({ limit: 5, offset: 10 });
    expect(fetch).toHaveBeenCalledWith("/api/events?limit=5&offset=10");
  });

  it("returns the parsed JSON body", async () => {
    const payload = { events: [{ id: 1 }] };
    mockFetch(payload);
    const result = await getEvents();
    expect(result).toEqual(payload);
  });

  it("throws when the server responds with an error", async () => {
    mockFetch({}, false);
    await expect(getEvents()).rejects.toThrow("404");
  });
});

describe("getEvent", () => {
  it("calls /api/events/:id", async () => {
    mockFetch({ id: 42 });
    await getEvent(42);
    expect(fetch).toHaveBeenCalledWith("/api/events/42");
  });
});

describe("getCameras", () => {
  it("calls /api/cameras", async () => {
    mockFetch({ cameras: [] });
    await getCameras();
    expect(fetch).toHaveBeenCalledWith("/api/cameras");
  });
});

describe("getStatus", () => {
  it("calls /api/status", async () => {
    mockFetch({ server_uptime_seconds: 3600 });
    await getStatus();
    expect(fetch).toHaveBeenCalledWith("/api/status");
  });
});

describe("photoUrl", () => {
  it("returns null for falsy input", () => {
    expect(photoUrl(null)).toBe(null);
    expect(photoUrl("")).toBe(null);
  });

  it("passes through absolute http URLs unchanged", () => {
    expect(photoUrl("http://192.168.1.50/photos/img.jpg")).toBe(
      "http://192.168.1.50/photos/img.jpg"
    );
  });

  it("prepends BASE (empty by default) to relative paths", () => {
    expect(photoUrl("/photos/img.jpg")).toBe("/photos/img.jpg");
  });
});
