// Data layer: loads the bundled schedule and exposes derived metadata.
// Live scores are merged in separately (see live.js) so the schedule works
// with zero network/API.

// A match is considered "in play / recently finished" for this many minutes
// after kickoff (covers 90' + stoppage + half-time + extra time/pens).
export const MATCH_DURATION_MIN = 150;

let cache = null;

export async function loadFixtures() {
  if (cache) return cache;
  const res = await fetch("./data/fixtures.json", { cache: "no-cache" });
  if (!res.ok) throw new Error(`Failed to load fixtures: ${res.status}`);
  const doc = await res.json();
  cache = doc.matches.map((m) => ({
    ...m,
    kickoffMs: new Date(m.utcKickoff).getTime(),
    // live fields, populated later by mergeLive()
    live: null, // { status, minute, homeScore, awayScore }
  }));
  return cache;
}

// Distinct real (non-TBD) team names, sorted, for the team dropdown.
export function teamList(matches) {
  const set = new Set();
  for (const m of matches) {
    if (!m.home.tbd) set.add(m.home.name);
    if (!m.away.tbd) set.add(m.away.name);
  }
  return [...set].sort((a, b) => a.localeCompare(b));
}

export function groupList(matches) {
  const set = new Set();
  for (const m of matches) if (m.group) set.add(m.group);
  return [...set].sort();
}

export const STAGES = [
  { id: "group", label: "Group Stage" },
  { id: "r32", label: "Round of 32" },
  { id: "r16", label: "Round of 16" },
  { id: "qf", label: "Quarter-final" },
  { id: "sf", label: "Semi-final" },
  { id: "third", label: "Third place" },
  { id: "final", label: "Final" },
];

export function matchHasTeam(m, team) {
  return m.home.name === team || m.away.name === team;
}

// Has the match finished (by clock; live status can override in render)?
export function isPast(m, now = Date.now()) {
  return m.kickoffMs + MATCH_DURATION_MIN * 60000 < now;
}

// Is the match currently within its live window?
export function inLiveWindow(m, now = Date.now()) {
  return (
    now >= m.kickoffMs - 5 * 60000 &&
    now <= m.kickoffMs + MATCH_DURATION_MIN * 60000
  );
}

// Merge normalized live results (from the proxy) onto our matches.
// `liveItems`: [{ utcDate, home, away, homeScore, awayScore, status, minute }]
// Matching is best-effort: same calendar day + fuzzy team-name match.
export function mergeLive(matches, liveItems) {
  if (!Array.isArray(liveItems)) return;
  const norm = (s) =>
    (s || "")
      .toLowerCase()
      .normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "")
      .replace(/[^a-z]/g, "");
  // Common name aliases between fixtures and football APIs.
  const ALIAS = {
    southkorea: "koreare", // some APIs use "Korea Republic"
    koreare: "southkorea",
    usa: "unitedstates",
    unitedstates: "usa",
    ivorycoast: "cotedivoire",
    cotedivoire: "ivorycoast",
  };
  const sameTeam = (a, b) => {
    const na = norm(a),
      nb = norm(b);
    return na === nb || ALIAS[na] === nb || ALIAS[nb] === na;
  };

  for (const item of liveItems) {
    const day = (item.utcDate || "").slice(0, 10);
    const m = matches.find(
      (mm) =>
        mm.utcKickoff.slice(0, 10) === day &&
        sameTeam(mm.home.name, item.home) &&
        sameTeam(mm.away.name, item.away)
    );
    if (!m) continue;
    m.live = {
      status: item.status || null,
      minute: item.minute ?? null,
      homeScore: item.homeScore ?? null,
      awayScore: item.awayScore ?? null,
    };
  }
}
