// Entry point: loads data, wires the UI to settings, renders, and starts the
// optional live-score + notification subsystems. Kept thin — feature logic
// lives in the dedicated modules.

import { loadFixtures, teamList, groupList, STAGES } from "./data.js";
import { applyFilters, nextFollowedMatch } from "./filters.js";
import { renderSchedule } from "./render.js";
import { getSettings, updateSettings, toggleFollow } from "./settings.js";
import { formatTime, formatDayHeading, localTimeZoneLabel, countdownTo } from "./time.js";
import * as notify from "./notifications.js";
import { startLive } from "./live.js";

const cfg = window.WC_CONFIG;
let allMatches = [];

const $ = (id) => document.getElementById(id);

async function init() {
  $("tz-label").textContent = `Times shown in your local timezone (${localTimeZoneLabel()}, 24h)`;

  try {
    allMatches = await loadFixtures();
  } catch (e) {
    $("schedule").innerHTML = `<p class="empty">Couldn't load the schedule. ${e.message}</p>`;
    return;
  }

  buildFilterControls();
  applyThemeFromSettings();
  wireControls();
  registerServiceWorker();
  initNotificationsUI();

  render();
  startLive(() => allMatches, render, cfg.live);

  // Keep "live"/"past" states and countdown fresh.
  setInterval(render, 30000);
}

function buildFilterControls() {
  const s = getSettings();

  const teamSel = $("f-team");
  teamSel.innerHTML = `<option value="">All teams</option>` +
    teamList(allMatches).map((t) => `<option value="${t}">${t}</option>`).join("");
  teamSel.value = s.filters.team;

  const groupSel = $("f-group");
  groupSel.innerHTML = `<option value="">All groups</option>` +
    groupList(allMatches).map((g) => `<option value="${g}">${g}</option>`).join("");
  groupSel.value = s.filters.group;

  const stageSel = $("f-stage");
  stageSel.innerHTML = `<option value="">All stages</option>` +
    STAGES.map((st) => `<option value="${st.id}">${st.label}</option>`).join("");
  stageSel.value = s.filters.stage;

  $("f-search").value = s.filters.search;
  $("f-hidepast").checked = s.filters.hidePast;
  $("f-mymatches").checked = s.filters.myMatchesOnly;

  $("quick-team-btn").textContent = `🇸🇪 ${cfg.defaultTeam} only`;
  syncQuickTeamButton();
}

function wireControls() {
  $("f-team").addEventListener("change", (e) => {
    updateSettings({ filters: { team: e.target.value } });
    syncQuickTeamButton();
    render();
  });
  $("f-group").addEventListener("change", (e) => {
    updateSettings({ filters: { group: e.target.value } });
    render();
  });
  $("f-stage").addEventListener("change", (e) => {
    updateSettings({ filters: { stage: e.target.value } });
    render();
  });
  $("f-search").addEventListener("input", (e) => {
    updateSettings({ filters: { search: e.target.value } });
    render();
  });
  $("f-hidepast").addEventListener("change", (e) => {
    updateSettings({ filters: { hidePast: e.target.checked } });
    render();
  });
  $("f-mymatches").addEventListener("change", (e) => {
    updateSettings({ filters: { myMatchesOnly: e.target.checked } });
    render();
  });

  // Quick "<team> only" toggle.
  $("quick-team-btn").addEventListener("click", () => {
    const cur = getSettings().filters.team;
    const next = cur === cfg.defaultTeam ? "" : cfg.defaultTeam;
    updateSettings({ filters: { team: next } });
    $("f-team").value = next;
    syncQuickTeamButton();
    render();
  });

  $("theme-btn").addEventListener("click", cycleTheme);
}

function syncQuickTeamButton() {
  const on = getSettings().filters.team === cfg.defaultTeam;
  $("quick-team-btn").classList.toggle("chip--on", on);
}

function render() {
  const s = getSettings();
  const matches = applyFilters(allMatches, s);
  renderSchedule($("schedule"), matches, s, {
    onFollow: (team) => {
      toggleFollow(team);
      rescheduleReminders();
      render();
    },
  });
  renderCountdown();
}

function renderCountdown() {
  const s = getSettings();
  const banner = $("countdown");
  const m = nextFollowedMatch(allMatches, s);
  if (!m) {
    banner.hidden = true;
    return;
  }
  const cd = countdownTo(m.utcKickoff);
  banner.hidden = false;
  banner.innerHTML = `Next: <strong>${m.home.flag} ${m.home.name} vs ${m.away.name} ${m.away.flag}</strong>
    — ${formatDayHeading(m.utcKickoff)} ${formatTime(m.utcKickoff)} <em>${cd || "now"}</em>`;
}

// --- Notifications UI ---
function initNotificationsUI() {
  const btn = $("notif-btn");
  if (!notify.isSupported()) {
    btn.textContent = "🔕 Notifications unsupported";
    btn.disabled = true;
    return;
  }
  updateNotifButton();
  btn.addEventListener("click", async () => {
    const perm = await notify.requestPermission();
    updateSettings({ notificationsEnabled: perm === "granted" });
    if (perm === "granted") rescheduleReminders();
    updateNotifButton();
  });
}

function updateNotifButton() {
  const btn = $("notif-btn");
  const perm = notify.permission();
  if (perm === "granted") {
    btn.textContent = "🔔 Reminders on";
    btn.classList.add("chip--on");
  } else if (perm === "denied") {
    btn.textContent = "🔕 Blocked in browser";
    btn.classList.remove("chip--on");
  } else {
    btn.textContent = "🔔 Enable reminders";
    btn.classList.remove("chip--on");
  }
}

function rescheduleReminders() {
  const s = getSettings();
  const lead = s.reminderLeadMinutes ?? cfg.notifications.defaultLeadMinutes;
  const followed = new Set(s.followedTeams);
  const mine = allMatches.filter(
    (m) => followed.has(m.home.name) || followed.has(m.away.name)
  );
  notify.scheduleReminders(mine, lead);
}

// --- Theme ---
function applyThemeFromSettings() {
  const t = getSettings().theme;
  document.documentElement.dataset.theme = t;
  $("theme-btn").textContent = themeIcon(t);
}
function cycleTheme() {
  const order = ["auto", "light", "dark"];
  const cur = getSettings().theme;
  const next = order[(order.indexOf(cur) + 1) % order.length];
  updateSettings({ theme: next });
  applyThemeFromSettings();
  $("theme-btn").textContent = themeIcon(next);
}
function themeIcon(t) {
  return t === "light" ? "☀️" : t === "dark" ? "🌙" : "🌗";
}

function registerServiceWorker() {
  if (!("serviceWorker" in navigator)) return;
  navigator.serviceWorker.register("./sw.js").catch(() => {
    /* offline/PWA features unavailable; app still works */
  });
}

init();
