// Live scores: polls the PHP proxy while any match is in its live window and
// merges normalized results onto the schedule. Entirely optional — if disabled
// or unreachable, it no-ops and the schedule keeps working.

import { mergeLive, inLiveWindow } from "./data.js";

let intervalId = null;

// `getMatches`: () => match[]   `onUpdate`: () => void (re-render)
export function startLive(getMatches, onUpdate, cfg) {
  if (!cfg || !cfg.enabled) return; // opt-in via config.js
  stopLive();

  const tick = async () => {
    const matches = getMatches();
    const now = Date.now();
    // Only spend a request when something is actually live.
    if (!matches.some((m) => inLiveWindow(m, now))) return;

    try {
      const res = await fetch(cfg.proxyUrl, { cache: "no-cache" });
      if (!res.ok) return;
      const data = await res.json();
      const items = Array.isArray(data) ? data : data.matches;
      mergeLive(matches, items);
      onUpdate();
    } catch {
      /* proxy down / offline — ignore, schedule still renders */
    }
  };

  tick();
  intervalId = setInterval(tick, cfg.pollMs || 45000);
}

export function stopLive() {
  if (intervalId) clearInterval(intervalId);
  intervalId = null;
}
