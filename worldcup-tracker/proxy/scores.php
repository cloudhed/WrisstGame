<?php
/**
 * Live-scores proxy.
 *
 * Why this exists: the football API key must NOT be exposed in the browser, and
 * many football APIs block direct browser (CORS) requests. This tiny PHP script
 * runs on your WordPress host, calls the API server-side with your key, caches
 * the response briefly (to respect rate limits), and returns a normalized JSON
 * array that the front-end understands.
 *
 * Setup:
 *   1. Copy config.sample.php to config.php and paste your free API key.
 *   2. Upload the whole worldcup-tracker folder to your site.
 *   3. In config.js set live.enabled = true.
 *
 * Output shape (array of):
 *   { utcDate, home, away, homeScore, awayScore, status, minute }
 * status is one of: SCHEDULED | IN_PLAY | PAUSED | FINISHED
 *
 * The default implementation targets football-data.org's v4 API. To use a
 * different provider, only the fetch + normalize section below needs editing —
 * the front-end contract stays the same.
 */

header("Content-Type: application/json; charset=utf-8");
header("Cache-Control: no-store");

$configPath = __DIR__ . "/config.php";
if (!file_exists($configPath)) {
    echo json_encode(["matches" => [], "error" => "missing config.php"]);
    exit;
}
$cfg = require $configPath;

$cacheFile = sys_get_temp_dir() . "/wc2026_live_cache.json";
$ttl = isset($cfg["cache_ttl"]) ? (int) $cfg["cache_ttl"] : 30;

// Serve cached response if still fresh.
if (file_exists($cacheFile) && (time() - filemtime($cacheFile)) < $ttl) {
    readfile($cacheFile);
    exit;
}

// --- Fetch from the provider (football-data.org by default) ---
$raw = http_get($cfg["api_url"], [
    "X-Auth-Token: " . $cfg["api_token"],
]);

$normalized = ["matches" => []];
if ($raw !== null) {
    $data = json_decode($raw, true);
    if (isset($data["matches"]) && is_array($data["matches"])) {
        foreach ($data["matches"] as $m) {
            $normalized["matches"][] = [
                "utcDate"   => $m["utcDate"] ?? null,
                "home"      => $m["homeTeam"]["name"] ?? null,
                "away"      => $m["awayTeam"]["name"] ?? null,
                "homeScore" => $m["score"]["fullTime"]["home"] ?? null,
                "awayScore" => $m["score"]["fullTime"]["away"] ?? null,
                "status"    => $m["status"] ?? null,
                "minute"    => $m["minute"] ?? null,
            ];
        }
    }
}

$out = json_encode($normalized);
@file_put_contents($cacheFile, $out);
echo $out;

/** Minimal GET helper using cURL, falling back to file_get_contents. */
function http_get($url, $headers)
{
    if (function_exists("curl_init")) {
        $ch = curl_init($url);
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_HTTPHEADER     => $headers,
            CURLOPT_TIMEOUT        => 8,
            CURLOPT_USERAGENT      => "wc2026-tracker",
        ]);
        $res = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        return ($res !== false && $code >= 200 && $code < 300) ? $res : null;
    }
    $ctx = stream_context_create([
        "http" => ["header" => implode("\r\n", $headers), "timeout" => 8],
    ]);
    $res = @file_get_contents($url, false, $ctx);
    return $res === false ? null : $res;
}
