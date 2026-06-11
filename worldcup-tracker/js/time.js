// Time helpers. All kickoffs are stored as UTC ISO 8601 in fixtures.json and
// rendered in the *viewer's* local timezone on a 24-hour clock.

const timeFmt = new Intl.DateTimeFormat([], {
  hour: "2-digit",
  minute: "2-digit",
  hour12: false,
});

const dayFmt = new Intl.DateTimeFormat([], {
  weekday: "long",
  day: "numeric",
  month: "long",
});

const tzFmt = new Intl.DateTimeFormat([], { timeZoneName: "short" });

// "14:00" (local, 24h)
export function formatTime(iso) {
  return timeFmt.format(new Date(iso));
}

// "Sunday, 14 June" (local)
export function formatDayHeading(iso) {
  return dayFmt.format(new Date(iso));
}

// Stable per-local-day key for grouping, e.g. "2026-06-14".
export function localDateKey(iso) {
  const d = new Date(iso);
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

// Short local timezone label, e.g. "GMT+2".
export function localTimeZoneLabel() {
  const parts = tzFmt.formatToParts(new Date());
  const tz = parts.find((p) => p.type === "timeZoneName");
  return tz ? tz.value : "";
}

// Human countdown to a future time, e.g. "in 2d 4h", "in 18 min", or null if past.
export function countdownTo(iso, now = Date.now()) {
  let ms = new Date(iso).getTime() - now;
  if (ms <= 0) return null;
  const min = Math.floor(ms / 60000);
  if (min < 60) return `in ${min} min`;
  const h = Math.floor(min / 60);
  if (h < 24) return `in ${h}h ${min % 60}m`;
  const d = Math.floor(h / 24);
  return `in ${d}d ${h % 24}h`;
}
