# Session: CORS fix for event scraper on web debug

**Date:** 2026-01-30  
**Context:** Event scraper was blocked by CORS when running the Flutter web app in debug (Chrome or web-server). User asked for a CORS fix using flutter_cors on the builder.

## User Prompts

1. **Prompt 1:**
   > can you make cors fix flutter_cors on bulder to make the event scrapper work for webapp in debug .@lib/data/services/event_scraper_service.dart

## AI Responses & Plan

### Analysis
- The event scraper (`EventScraperService`) fetches event details from fosdem.org via HTTP. On web, the browser enforces CORS; fosdem.org does not send `Access-Control-Allow-Origin` for the app origin, so requests fail.
- Two approaches: (1) use a CORS proxy in code when on web in debug so it works with both `flutter run -d chrome` and `flutter run -d web-server`; (2) add run scripts that use flutter_cors or Chrome’s `--disable-web-security` for the “builder” (run command).

### Implementation Plan
1. In `event_scraper_service.dart`: when `kIsWeb && kDebugMode`, resolve request URLs through a CORS proxy (corsproxy.io) so the scraper works without changing the browser.
2. In `package.json`: add `web:debug` (Chrome with `--disable-web-security`) and `web:debug:cors` (fluttercors --disable then flutter run -d chrome).
3. In README: document web debug and CORS options.

## Code Changes Made

### File 1: lib/data/services/event_scraper_service.dart
- Import `package:flutter/foundation.dart` for `kIsWeb` and `kDebugMode`.
- Added `_corsProxyBase` and `_useCorsProxy` (true only when `kIsWeb && kDebugMode`).
- Added `_resolveUrl(String eventUrl)` to return proxy-wrapped URL when `_useCorsProxy` is true.
- In `scrapeEventDetail`, use `_resolveUrl(eventUrl)` and log when using the CORS proxy.

### File 2: package.json
- Added script `web:debug`: `flutter run -d chrome --web-browser-flag "--disable-web-security"`.
- Added script `web:debug:cors`: `fluttercors --disable && flutter run -d chrome` (requires `dart pub global activate flutter_cors`).

### File 3: README.md
- Added subsection “Web debug and event scraper (CORS)” under Run the app.
- Documented Option A (npm run web:debug / Chrome flag) and Option B (flutter_cors + npm run web:debug:cors).

## Decisions

- CORS proxy is used only when `kIsWeb && kDebugMode`; mobile and release web are unchanged.
- corsproxy.io used as the proxy; it’s debug-only and not for production.
- Both a code fix (proxy) and run scripts (Chrome flag / flutter_cors) are provided so the event scraper works in web debug regardless of how the app is run.

## Summary

CORS for the event scraper on web debug is addressed by: (1) automatically using a CORS proxy in the scraper when running on web in debug, and (2) adding `web:debug` and `web:debug:cors` npm scripts plus README docs so the “builder” can use either Chrome’s disabled web security or flutter_cors.
