# Persist "Show favorites" toggle in SharedPreferences

**Date:** 2026-01-31  
**Context:** My Journey screen – remember the "Show favorite events on timeline" toggle across visits.

## User Prompts

1. **Prompt 1:**
 > "can you save on shared pref the toggle for show favorite. so when I come back to the view it's still same"

## AI Responses & Plan

### Analysis
- Toggle lives in `MyJourneyScreen` as `_showFavorites` (default `true`), used in a `SwitchListTile`.
- Request: persist this in SharedPreferences and restore when the user returns to the view.

### Implementation Plan
1. Add SharedPreferences and DI imports; define a preference key.
2. In `initState`, load the saved boolean and call `setState` if present (with `mounted` check).
3. In the switch `onChanged`, save the new value to SharedPreferences after updating state.

## Code Changes Made

### File: lib/features/journey/presentation/screens/my_journey_screen.dart
- Import `shared_preferences` and `injection_container.dart` as `di`.
- Added `static const _prefKeyShowFavorites = 'journey_show_favorites';`.
- In `initState`, call `_loadShowFavorites()` after existing setup.
- New `_loadShowFavorites()`: get `SharedPreferences` via `di.sl<SharedPreferences>()`, `getBool(_prefKeyShowFavorites)`; if non-null and `mounted`, `setState(() => _showFavorites = saved)`.
- In the "Show favorite events on timeline" switch `onChanged`: after `setState(() => _showFavorites = value)`, get prefs and `setBool(_prefKeyShowFavorites, value)`.

## Decisions

- Use key `journey_show_favorites` to avoid clashes with other prefs.
- Load asynchronously in initState (no await in initState); only apply with `mounted` check.
- Reuse app’s existing SharedPreferences from DI (`di.sl<SharedPreferences>()`).

## Summary

The "Show favorite events on timeline" toggle is saved to SharedPreferences when changed and restored when the user opens the My Journey view again.
