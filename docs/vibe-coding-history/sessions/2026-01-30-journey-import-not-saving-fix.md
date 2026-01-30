# Journey import not saving – fix

**Date:** 2026-01-30  
**Context:** User reported imported journeys show 0 entries; logs showed `imported=0 keys=[]` and no ImportJourneyFromUrl success logs.

## User prompts

1. **Logs shared:**
   - `LoadJourney: stateBeforeLoad=JourneyInitial` then `JourneyLoading` (multiple)
   - `_loadImportedJourneysFromPrefs: no data` / `empty map`
   - `LoadJourney: restored from prefs: imported=0 keys=[], showImported=true`
   - `_buildJourneyTab: planned=4 wishlist=0 candidates=0 imported=0 showImported=true`
   - `_buildImportedEntries: 0 entries from 0 users`
   - User: "I got 0 entry, so the import don't save really"

## Analysis

- **Import handler** (`_onImportJourneyFromUrl`) only ran when `state is JourneyLoaded`. If the user opened Settings and tapped Import before the first `LoadJourney` finished (state still `JourneyInitial` or `JourneyLoading`), the handler returned early and did nothing — no save, no emit.
- Logs showed no `ImportJourneyFromUrl: OK` or `ImportJourneyFromUrl: SKIP` line, consistent with either a skip (state not loaded) or import never triggered.
- Fix: **Handle import when state is not JourneyLoaded**: fetch/parse the YAML, merge with existing imports from prefs, save to prefs, then dispatch `LoadJourney`. The next load restores from prefs and emits `JourneyLoaded` with the new import. On import failure when not loaded, persist error to a pref and apply it on the next `JourneyLoaded`.

## Code changes

### `lib/features/journey/presentation/bloc/journey_bloc.dart`

- Added `_kLastImportErrorKey` for persisting import error when state is not loaded.
- **`_onImportJourneyFromUrl`**:
  - No longer returns early when state is not `JourneyLoaded`.
  - If state is loaded: keep previous behavior (merge into current state, save prefs, emit).
  - If state is not loaded: call import service, merge with `_loadImportedJourneysFromPrefs().$1`, save to prefs, then `add(const LoadJourney())` so the next load picks up the import; on failure, set `_kLastImportErrorKey` and dispatch `LoadJourney` so the next state can show `importError`.
- **`_onLoadJourney`** (when emitting `JourneyLoaded`): read `_kLastImportErrorKey`, remove it from prefs, and pass it as `importError` so the Settings UI can show the snackbar after a deferred load.

## Decisions

- Import is allowed and persisted (to prefs) even when the bloc is still initial/loading; `LoadJourney` is used to refresh state so the same code path applies.
- Import errors when not loaded are stored in a single pref and applied on the next `JourneyLoaded` so the user still sees feedback.

## Summary

Import was effectively ignored when the user triggered it before the first journey load completed. The handler now always runs: it fetches and parses the URL, merges with existing imports (from state or prefs), saves to prefs, and either emits immediately (if loaded) or dispatches `LoadJourney` so the next load shows the imported journey. Re-running the app and importing from Settings should now show non-zero imported entries after the next load (or immediately if state was already loaded).
