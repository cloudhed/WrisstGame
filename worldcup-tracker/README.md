# World Cup 2026 Tracker

A small, dependency-free web app to follow the **2026 FIFA World Cup**: every match
in your **local time on a 24-hour clock**, a one-tap **Sweden filter**, **reminders**
before kickoff, optional **live scores**, and a **hide past games** toggle.

Plain HTML/CSS/JavaScript — no build step, no framework. Upload the folder to any web
host and it works. The full 104-match schedule is bundled, so everything except live
scores works with **zero setup and even offline**.

---

## Features

| Feature | How it works |
|---|---|
| All 104 matches | Bundled in `data/fixtures.json` (public-domain [openfootball](https://github.com/openfootball/worldcup.json)). |
| Local time, 24h | Kickoffs stored in UTC; shown in *your* device timezone automatically. |
| Sweden filter | "🇸🇪 Sweden only" chip (built on a generic per-team filter). |
| Follow any team | Tap ☆ on a team → reminders + "Followed only" view. |
| Reminders | Browser/PWA notification before kickoff (default 15 min). |
| Hide past games | Toggle in the filter bar; remembers your choice. |
| Filter & search | By group, stage, or free-text (team / city / group). |
| Live scores | Optional, via a tiny PHP proxy (see below). |
| Install as app | "Add to home screen" (PWA) + offline schedule. |

---

## Run locally

Because the app uses ES modules and `fetch`, open it through a **local server**, not by
double-clicking `index.html` (browsers block modules/fetch on `file://`).

```bash
cd worldcup-tracker
python3 -m http.server 8000
# then visit http://localhost:8000
```

---

## Deploy on your WordPress site (isaklundholm.se)

1. Upload the **entire `worldcup-tracker/` folder** to your web space (via your host's
   File Manager or FTP), e.g. into `public_html/worldcup/`.
2. Visit `https://isaklundholm.se/worldcup/`.

That's it for the schedule, filtering, and reminders. HTTPS (which your site already has)
is what lets notifications and the installable PWA work.

> Tip: keep it in its own subfolder so it stays separate from WordPress itself.

---

## Optional: live scores

Live scores need match data from a football API. The key is kept **server-side** so it's
never exposed in the browser, and the PHP proxy avoids cross-origin (CORS) issues.

1. Get a free API key at <https://www.football-data.org/client/register> (free tier
   includes the World Cup, competition code `WC`).
2. In `proxy/`, copy `config.sample.php` → `config.php` and paste your key.
   (`config.php` is gitignored, so your key never gets committed.)
3. In `config.js`, set `live.enabled = true`.

If the proxy isn't set up, the app silently skips live scores — the schedule still works.

Using a different provider? You only need to edit the fetch + normalize section of
`proxy/scores.php`; the front-end expects this shape per match:

```json
{ "utcDate": "...", "home": "Sweden", "away": "Tunisia",
  "homeScore": 1, "awayScore": 0, "status": "IN_PLAY", "minute": 67 }
```

---

## Project layout

```
worldcup-tracker/
├── index.html              App shell + filter controls
├── config.js               Front-end settings (no secrets)
├── manifest.webmanifest    PWA install metadata
├── sw.js                   Service worker (offline + notifications)
├── css/styles.css          Styling (light/dark)
├── js/
│   ├── app.js              Wires everything together
│   ├── data.js             Loads schedule, merges live data
│   ├── time.js             UTC → local 24h formatting
│   ├── filters.js          Filtering + sorting logic
│   ├── render.js           Builds the match cards
│   ├── settings.js         Saves preferences (localStorage)
│   ├── notifications.js     Schedules kickoff reminders
│   └── live.js             Polls the proxy for live scores
├── data/fixtures.json      Full 104-match schedule (UTC)
├── icons/                  PWA icons
└── proxy/
    ├── scores.php          Server-side live-scores proxy
    └── config.sample.php   Template for your API key
```

---

## Notifications: what works, and what's next

**Now (v1):** reminders fire while the site is open or installed as a PWA. Installing it
to your home screen makes them far more reliable on mobile.

**Future-ready hooks** (designed for, not built yet):
- **Calendar export (`.ics`)** — download your followed matches to your phone's calendar
  for rock-solid reminders even when everything is closed. No server needed.
- **Push when closed** — via a webhook (ntfy / Tasker / Join) fired by a server-side
  scheduler. Needs your host to support real cron jobs.

The notification code is isolated in `js/notifications.js` so these slot in cleanly.

---

## Updating the schedule

`data/fixtures.json` is a snapshot. As knockout fixtures get real teams (currently shown
as placeholders like `W74`), regenerate it from the upstream source and replace the file.

Data credit: [openfootball/worldcup.json](https://github.com/openfootball/worldcup.json)
(public domain).
