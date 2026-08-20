// In-app notifications: schedule a reminder before kickoff for every followed
// match. Reminders fire while the page is open OR while it's installed as a PWA
// (the service worker displays them). This module is intentionally small and
// self-contained so future channels (calendar .ics export, webhook/Tasker push)
// can be added alongside without touching the rest of the app.

import { formatTime } from "./time.js";

// setTimeout caps out around ~24.8 days; only arm reminders within this horizon.
const MAX_HORIZON_MS = 20 * 24 * 60 * 60 * 1000;

let timers = [];

export function isSupported() {
  return "Notification" in window;
}

export function permission() {
  return isSupported() ? Notification.permission : "denied";
}

export async function requestPermission() {
  if (!isSupported()) return "denied";
  if (Notification.permission !== "default") return Notification.permission;
  try {
    return await Notification.requestPermission();
  } catch {
    return Notification.permission;
  }
}

// Clear and re-arm all reminders for the followed matches.
// `matches` should already be filtered to the user's followed teams.
export function scheduleReminders(matches, leadMinutes) {
  clearReminders();
  if (permission() !== "granted") return 0;

  const now = Date.now();
  const leadMs = Math.max(0, leadMinutes) * 60000;
  let armed = 0;

  for (const m of matches) {
    const fireAt = m.kickoffMs - leadMs;
    const delay = fireAt - now;
    if (delay <= 0 || delay > MAX_HORIZON_MS) continue;

    const title = `${m.home.flag} ${m.home.name} vs ${m.away.name} ${m.away.flag}`;
    const body = `Kicks off at ${formatTime(m.utcKickoff)} · ${
      m.group || m.stageLabel
    } · ${m.venue}`;

    const id = setTimeout(() => showNotification(title, body), delay);
    timers.push(id);
    armed++;
  }
  return armed;
}

export function clearReminders() {
  for (const t of timers) clearTimeout(t);
  timers = [];
}

// Prefer the service worker (works when installed/backgrounded); fall back to a
// page Notification when there's no active SW registration.
export async function showNotification(title, body) {
  const options = {
    body,
    tag: title, // collapse duplicates
    icon: "./icons/icon-192.png",
    badge: "./icons/icon-192.png",
  };
  try {
    const reg = await navigator.serviceWorker?.getRegistration();
    if (reg) {
      await reg.showNotification(title, options);
      return;
    }
  } catch {
    /* fall through to page notification */
  }
  if (permission() === "granted") new Notification(title, options);
}
