<?php
/**
 * Copy this file to `config.php` (same folder) and fill in your API key.
 * config.php is gitignored so your key is never committed.
 *
 * Get a free key at https://www.football-data.org/client/register
 * (the free tier covers the World Cup competition, code "WC").
 */
return [
    // Your football-data.org API token.
    "api_token" => "PASTE_YOUR_FREE_API_KEY_HERE",

    // Endpoint returning the competition's matches. "WC" = FIFA World Cup.
    "api_url" => "https://api.football-data.org/v4/competitions/WC/matches",

    // Seconds to cache the upstream response (protects your rate limit).
    "cache_ttl" => 30,
];
