// Pure filtering + sorting logic. Given the full match list and the current
// filter state, return the matches to render (always chronological).

import { isPast, matchHasTeam } from "./data.js";

export function applyFilters(matches, settings, now = Date.now()) {
  const f = settings.filters;
  const followed = new Set(settings.followedTeams);
  const search = f.search.trim().toLowerCase();

  return matches
    .filter((m) => {
      if (f.myMatchesOnly) {
        if (!(followed.has(m.home.name) || followed.has(m.away.name)))
          return false;
      }
      if (f.team && !matchHasTeam(m, f.team)) return false;
      if (f.group && m.group !== f.group) return false;
      if (f.stage && m.stage !== f.stage) return false;
      if (f.hidePast && isPast(m, now)) return false;
      if (search) {
        const hay = `${m.home.name} ${m.away.name} ${m.group || ""} ${
          m.stageLabel
        } ${m.venue}`.toLowerCase();
        if (!hay.includes(search)) return false;
      }
      return true;
    })
    .sort((a, b) => a.kickoffMs - b.kickoffMs);
}

// The next upcoming followed match (for the countdown banner), or null.
export function nextFollowedMatch(matches, settings, now = Date.now()) {
  const followed = new Set(settings.followedTeams);
  if (followed.size === 0) return null;
  return (
    matches
      .filter(
        (m) =>
          m.kickoffMs > now &&
          (followed.has(m.home.name) || followed.has(m.away.name))
      )
      .sort((a, b) => a.kickoffMs - b.kickoffMs)[0] || null
  );
}
