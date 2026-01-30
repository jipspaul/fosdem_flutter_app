# Event detail: use scraper for description when opening from journey

**Date:** 2026-01-30  
**Context:** User wanted that when opening an event (e.g. from journey or Friends' timelines), the app uses the event scraper service to get the description.

## User prompts

1. **Request:**
   > "https://raw.githubusercontent.com/jipspaul/jsone/refs/heads/main/jips.yaml when open an event use @lib/data/services/event_scraper_service.dart to get the description."

## Analysis

- **EventDetailBloc** already uses `EventScraperService.scrapeEventDetail(eventUrl)` when it has a non-empty URL. It first tries cache, then scrapes.
- **Problem:** When opening an event from the **journey timeline** or from **Friends' timelines**, the screen was given an `Event` with `url: ''` (or null). The bloc then emitted `EventDetailError('Event URL not available...')` and never called the scraper.
- **Fix:** When `eventUrl` is null or empty, resolve the URL from the local database (event by id). If the event exists in the DB (e.g. from the same schedule), use its `url` and proceed to scrape. That way opening from journey or Friends uses the scraper to load description (and abstract, speakers, links, etc.).

## Code changes

### `lib/presentation/bloc/event_detail/event_detail_bloc.dart`

- In `_onLoadEventDetail`, **before** returning an error for missing URL:
  - If `eventUrl` is null or empty, call `_database.eventsDao.getEventById(event.eventId.toString())`.
  - If an entity is found and `entity.url` is non-empty, set `eventUrl = entity.url!.trim()` and continue (fix malformed URL, then cache check + scrape as before).
- So when opening from journey timeline (or Friends tab), the bloc resolves the URL from the DB and then uses the existing scraper flow.

### `lib/features/journey/presentation/screens/my_journey_screen.dart`

- **Friends tab:** Added tap-to-open on friend event tiles.
  - Imported `Event` (domain entity) and `EventDetailScreen`.
  - In `_FriendEventTile`, added `onTap` on the `ListTile` that navigates to `EventDetailScreen` with an `Event` built from `exportEvent` (id, title, room, track, start/end, `url: null`).
  - Tapping a friend's event now opens the detail screen; the bloc resolves URL from DB (if that event exists in the local schedule) and scrapes the description.

## Decisions

- URL resolution is done in the bloc only when the passed URL is empty; no change to the existing scraper/cache flow when URL is already provided (e.g. from schedule/favorites).
- For imported friends' events, if the same event exists in the local database (same FOSDEM schedule), the resolved URL is used and the scraper runs. If the event is not in the DB, the user still sees "Event URL not available" (no FOSDEM URL built from numeric id, as FOSDEM uses slugs in URLs).

## Summary

When opening an event from the journey timeline or from Friends' timelines, the app now uses the event scraper service to load the description (and abstract, speakers, links, attachments): the EventDetailBloc resolves a missing URL from the database by event id, then runs the existing scrape/cache flow. Tap-to-open was added on Friends tab event tiles so users can open event detail (and thus trigger the scraper) from there as well.
