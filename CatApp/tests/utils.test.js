import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { timeAgo, primaryLabel, isHighConfidence } from "../js/utils.js";

describe("timeAgo", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(new Date("2024-06-01T12:00:00Z"));
  });
  afterEach(() => vi.useRealTimers());

  it("returns 'just now' for timestamps within 60 seconds", () => {
    expect(timeAgo("2024-06-01T11:59:30Z")).toBe("just now");
    expect(timeAgo("2024-06-01T12:00:00Z")).toBe("just now");
  });

  it("returns minutes for timestamps within 1 hour", () => {
    expect(timeAgo("2024-06-01T11:45:00Z")).toBe("15 min ago");
    expect(timeAgo("2024-06-01T11:01:00Z")).toBe("59 min ago");
  });

  it("returns hours for timestamps within 24 hours", () => {
    expect(timeAgo("2024-06-01T10:00:00Z")).toBe("2 hr ago");
    expect(timeAgo("2024-06-01T00:00:00Z")).toBe("12 hr ago");
  });

  it("returns a locale date string for timestamps older than 24 hours", () => {
    const result = timeAgo("2024-05-30T12:00:00Z");
    expect(result).toMatch(/May/);
  });
});

describe("primaryLabel", () => {
  it("returns the first sentence", () => {
    expect(primaryLabel("Cat sleeping. Confidence high.")).toBe("Cat sleeping");
  });

  it("returns the first line when no period", () => {
    expect(primaryLabel("Luna eating\nSome other detail")).toBe("Luna eating");
  });

  it("returns 'Unknown' for empty or null input", () => {
    expect(primaryLabel(null)).toBe("Unknown");
    expect(primaryLabel("")).toBe("Unknown");
  });
});

describe("isHighConfidence", () => {
  it("returns true for confidence >= 60 (0–100 scale)", () => {
    expect(isHighConfidence(60)).toBe(true);
    expect(isHighConfidence(95)).toBe(true);
  });

  it("returns false for confidence < 60 (0–100 scale)", () => {
    expect(isHighConfidence(59)).toBe(false);
    expect(isHighConfidence(0)).toBe(false);
  });

  it("handles 0–1 float scale", () => {
    expect(isHighConfidence(0.75)).toBe(true);
    expect(isHighConfidence(0.5)).toBe(false);
  });

  it("returns true when confidence is null (benefit of the doubt)", () => {
    expect(isHighConfidence(null)).toBe(true);
    expect(isHighConfidence(undefined)).toBe(true);
  });
});
