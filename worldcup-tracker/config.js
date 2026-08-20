// Front-end configuration. Safe to commit — contains NO secrets.
// (The football API key lives only server-side in proxy/config.php.)
window.WC_CONFIG = {
  live: {
    // Flip to true once you've deployed proxy/scores.php with an API key.
    enabled: false,
    // Path to the PHP proxy, relative to index.html.
    proxyUrl: "./proxy/scores.php",
    // How often to poll for live scores while matches are in play (ms).
    pollMs: 45000,
  },
  notifications: {
    // Default minutes before kickoff to remind you (user-adjustable in Settings).
    defaultLeadMinutes: 15,
  },
  // The team pre-selected by the "My team only" quick filter.
  defaultTeam: "Sweden",
};
