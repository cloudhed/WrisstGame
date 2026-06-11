// DOM rendering. Builds the date-grouped schedule and individual match cards.
// Stateless: hand it matches + settings, it paints the container.

import { formatTime, formatDayHeading, localDateKey } from "./time.js";
import { isPast, inLiveWindow } from "./data.js";
import { isFollowed } from "./settings.js";

function teamRow(team, score, opts = {}) {
  const el = document.createElement("div");
  el.className = "team" + (opts.winner ? " team--winner" : "");
  el.innerHTML = `
    <span class="team__flag">${team.flag}</span>
    <span class="team__name">${escapeHtml(team.name)}</span>
    <span class="team__score">${score ?? ""}</span>`;
  return el;
}

function liveBadge(m, now) {
  const live = m.live;
  if (live && (live.status === "IN_PLAY" || live.status === "PAUSED")) {
    const label =
      live.status === "PAUSED"
        ? "HT"
        : live.minute != null
        ? `${live.minute}'`
        : "LIVE";
    return `<span class="badge badge--live">● ${label}</span>`;
  }
  if (live && live.status === "FINISHED")
    return `<span class="badge badge--ft">FT</span>`;
  if (inLiveWindow(m, now) && !live)
    return `<span class="badge badge--live">● LIVE</span>`;
  if (isPast(m, now)) return `<span class="badge badge--ft">FT</span>`;
  return "";
}

function matchCard(m, now, onFollow) {
  const card = document.createElement("article");
  card.className = "match";
  if (isPast(m, now)) card.classList.add("match--past");
  if (inLiveWindow(m, now)) card.classList.add("match--live");

  const home = isFollowed(m.home.name);
  const away = isFollowed(m.away.name);

  const meta = document.createElement("div");
  meta.className = "match__meta";
  meta.innerHTML = `
    <span class="match__time">${formatTime(m.utcKickoff)}</span>
    <span class="match__tag">${m.group || m.stageLabel}</span>
    ${liveBadge(m, now)}
  `;

  const teams = document.createElement("div");
  teams.className = "match__teams";
  const hs = m.live ? m.live.homeScore : null;
  const as = m.live ? m.live.awayScore : null;
  teams.appendChild(teamRow(m.home, hs, { winner: hs != null && as != null && hs > as }));
  teams.appendChild(teamRow(m.away, as, { winner: hs != null && as != null && as > hs }));

  const foot = document.createElement("div");
  foot.className = "match__foot";
  foot.innerHTML = `<span class="match__venue">📍 ${escapeHtml(m.venue)}</span>`;

  const follow = document.createElement("div");
  follow.className = "match__follow";
  if (!m.home.tbd)
    follow.appendChild(followBtn(m.home, home, onFollow));
  if (!m.away.tbd)
    follow.appendChild(followBtn(m.away, away, onFollow));
  foot.appendChild(follow);

  card.append(meta, teams, foot);
  return card;
}

function followBtn(team, active, onFollow) {
  const b = document.createElement("button");
  b.className = "followbtn" + (active ? " followbtn--on" : "");
  b.type = "button";
  b.textContent = `${active ? "★" : "☆"} ${team.code}`;
  b.title = `${active ? "Unfollow" : "Follow"} ${team.name} (notify before kickoff)`;
  b.addEventListener("click", () => onFollow(team.name));
  return b;
}

export function renderSchedule(container, matches, settings, handlers) {
  const now = Date.now();
  container.innerHTML = "";

  if (matches.length === 0) {
    container.innerHTML = `<p class="empty">No matches match your filters.</p>`;
    return;
  }

  let lastKey = null;
  let section = null;
  for (const m of matches) {
    const key = localDateKey(m.utcKickoff);
    if (key !== lastKey) {
      lastKey = key;
      const h = document.createElement("h2");
      h.className = "dayhead";
      h.textContent = formatDayHeading(m.utcKickoff);
      container.appendChild(h);
      section = document.createElement("div");
      section.className = "daygroup";
      container.appendChild(section);
    }
    section.appendChild(matchCard(m, now, handlers.onFollow));
  }
}

function escapeHtml(s) {
  return String(s).replace(
    /[&<>"']/g,
    (c) =>
      ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c])
  );
}
