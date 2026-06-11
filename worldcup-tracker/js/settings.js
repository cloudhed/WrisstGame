// Persistent user settings via localStorage. Single source of truth for UI state
// so filters, followed teams and preferences survive reloads.

const KEY = "wc2026.settings.v1";

const DEFAULTS = {
  followedTeams: [], // team names the user follows (drives notifications + "My matches")
  filters: {
    team: "", // "" = all; otherwise a single team name
    group: "", // "" = all; e.g. "Group F"
    stage: "", // "" = all; e.g. "group", "r16", "final"
    search: "",
    hidePast: false,
    myMatchesOnly: false, // show only followed-team matches
  },
  reminderLeadMinutes: null, // null => use config default
  theme: "auto", // "auto" | "light" | "dark"
  notificationsEnabled: false, // user opted in to reminders
};

function deepMerge(base, override) {
  const out = Array.isArray(base) ? [...base] : { ...base };
  for (const k of Object.keys(override || {})) {
    if (
      override[k] &&
      typeof override[k] === "object" &&
      !Array.isArray(override[k]) &&
      typeof base[k] === "object"
    ) {
      out[k] = deepMerge(base[k], override[k]);
    } else {
      out[k] = override[k];
    }
  }
  return out;
}

let state = load();
const listeners = new Set();

function load() {
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? deepMerge(DEFAULTS, JSON.parse(raw)) : deepMerge(DEFAULTS, {});
  } catch {
    return deepMerge(DEFAULTS, {});
  }
}

function persist() {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
  } catch {
    /* storage may be unavailable (private mode); ignore */
  }
}

export function getSettings() {
  return state;
}

// Apply a partial patch (deep-merged), persist, and notify listeners.
export function updateSettings(patch) {
  state = deepMerge(state, patch);
  persist();
  for (const fn of listeners) fn(state);
}

export function onSettingsChange(fn) {
  listeners.add(fn);
  return () => listeners.delete(fn);
}

// --- Followed teams helpers ---
export function isFollowed(team) {
  return state.followedTeams.includes(team);
}

export function toggleFollow(team) {
  const set = new Set(state.followedTeams);
  set.has(team) ? set.delete(team) : set.add(team);
  updateSettings({ followedTeams: [...set] });
}
