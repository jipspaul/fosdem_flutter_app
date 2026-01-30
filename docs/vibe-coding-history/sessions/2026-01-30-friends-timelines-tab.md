# Friends' timelines tab (replace Wishlist tab)

**Date:** 2026-01-30  
**Context:** User asked to change the Wishlist tab on My Journey to show friends' timelines instead, and to allow adding events to favorites from those timelines.

## User prompts

1. **Request:**
   > "on whislist tab, instead of whislist change it to see freinds timelines, o it will be easier for me. this friend time line can also help to add event for to your favorite"

## Implementation

### Changes

- **Tab label and icon:** Second tab renamed from "Wishlist" (bookmark icon) to "Friends' timelines" (people icon).
- **Tab content:** Replaced wishlist list with a Friends tab that:
  - **Empty state:** If no imported journeys, shows "No friends' timelines yet" and instructs the user to import from Settings (Journey → Import from URL).
  - **With imports:** For each imported friend (from `state.importedJourneys`), shows:
    - A header card with friend name and avatar (from `userPictureUrl` or initials).
    - Their events grouped by day (sorted by date and time).
    - Each event as a list tile: time range, title, room • track, and an "Add to favorites" heart button.
  - **Add to favorites:** Tapping the heart on a friend's event dispatches `FavoritesBloc.add(AddFavorite(eventId.toString()))`. Event IDs come from the imported YAML; if the same schedule data is loaded locally, the ID will match and the event will be added to favorites.

### Files modified

- **`lib/features/journey/presentation/screens/my_journey_screen.dart`**
  - Replaced `WishlistWidget` import with `FavoritesBloc`, `AddFavorite`, `intl`, and `journey_export_model`.
  - TabBar: second tab is now `Tab(icon: Icon(Icons.people), text: "Friends' timelines")`.
  - TabBarView second child: `_buildFriendsTab(state)` instead of `_buildWishlistTab(state)`.
  - Added `_buildFriendsTab(JourneyLoaded state)`: empty state or CustomScrollView with per-friend sections (header + events by day).
  - Added `_FriendEventTile` stateless widget: list tile for one `JourneyExportEvent` with time, title, room/track, and IconButton (favorite_border) that calls `onAddToFavorites` (dispatches AddFavorite).

### Decisions

- Wishlist content is no longer shown in a dedicated tab; it remains visible on the Journey tab (planned vs wishlist vs candidates).
- "Add to favorites" uses the event ID from the imported YAML; if the app’s schedule uses the same IDs (e.g. same FOSDEM source), it works. Title-based matching could be added later if needed.
- Friend events are grouped by calendar day and sorted by start time within each day.

## Summary

The second tab on My Journey is now "Friends' timelines". It shows each imported friend’s journey by day with an "Add to favorites" action on each event, making it easier to browse friends’ plans and add events to your favorites.
