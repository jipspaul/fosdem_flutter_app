# Session: Journey YAML Export/Import

**Date:** 2026-01-30  
**Context:** Implemented journey YAML export/import per plan: export (planned + favorites-not-planned as wishlist), import from URL only on Settings, show/hide imported events on Journey screen with visual indicators.

## User Prompts

1. **Prompt 1:**
 > "Implement the plan as specified, it is attached for your reference. Do NOT edit the plan file itself. To-do's from the plan have already been created. Do not create them again. Mark them as in_progress as you work, starting with the first one. Don't stop until you have completed all the to-dos."

## AI Responses & Plan

### Analysis
- Plan required: export journey (planned + wishlist = favorites not planned) to YAML; import from URL only on Settings; Journey screen toggle show/hide imported events; timeline indicators for imported (user name, avatar, planned/wishlist).

### Implementation
- Created `JourneyExportData` and `JourneyExportEvent` models with YAML-friendly fields and `toJourneyItem()` for display.
- Implemented `JourneyExportService`: builds export from `JourneyLoaded` (planned + candidates as wishlist), serializes to YAML string (no external yaml encode; built manual YAML).
- Implemented `JourneyImportService`: fetches URL with `http`, parses YAML with `yaml` package, returns `JourneyExportData`; `JourneyImportException` for errors.
- Updated `JourneyState`: added `importedJourneys` (Map<String, JourneyExportData>), `showImportedJourney` (bool), `importError` (String?) for non-destructive import errors.
- Added events: `ImportJourneyFromUrl`, `RemoveImportedJourney`, `SetShowImportedJourney`, `ClearImportError`.
- Updated `JourneyBloc`: handlers for import/remove/show/clear; preserve `importedJourneys` and `showImportedJourney` on `LoadJourney`.
- Settings: `JourneyExportImportSection` widget (export button, URL field + import button, list of imported journeys with remove); used in both `SettingsPage` and `SettingsScreen` (main nav). Success/error snackbars; `BlocConsumer` for import error and success.
- Journey screen: toggle “Show imported journey” (only when `importedJourneys.isNotEmpty`); `_buildImportedEntries()` to convert imported data to `ImportedEventEntry`; pass `importedEntries` to `JourneyTimelineWidget`; `_getDaysToShow` extended to include days from imported events.
- `JourneyTimelineWidget`: new `ImportedEventEntry` type and `importedEntries` parameter; merge imported into timeline; `_TimelineEventCard` accepts `importedFrom` and shows user avatar, name, “Planned”/“Wishlist” chip; no actions for imported (read-only).
- Added `yaml` to `pubspec.yaml`.

## Code Changes Made

### New files
- `lib/features/journey/domain/models/journey_export_model.dart` – JourneyExportData, JourneyExportEvent, fromJson/toJson, toJourneyItem().
- `lib/features/journey/data/services/journey_export_service.dart` – buildExportData, toYaml, buildYamlFromJourney.
- `lib/features/journey/data/services/journey_import_service.dart` – importJourneyFromUrl (http GET + yaml parse), JourneyImportException.

### Modified files
- `pubspec.yaml` – added `yaml: ^3.1.2`.
- `lib/features/journey/presentation/bloc/journey_state.dart` – importedJourneys, showImportedJourney, importError; copyWith.
- `lib/features/journey/presentation/bloc/journey_event.dart` – ImportJourneyFromUrl, RemoveImportedJourney, SetShowImportedJourney, ClearImportError.
- `lib/features/journey/presentation/bloc/journey_bloc.dart` – handlers; preserve imported state on LoadJourney; JourneyImportService usage.
- `lib/features/settings/presentation/pages/settings_page.dart` – JourneyExportImportSection (export, import from URL, list/remove imported); public JourneyExportImportSection; BlocConsumer for snackbars.
- `lib/presentation/screens/settings_screen.dart` – Card with JourneyExportImportSection and BlocProvider.value(JourneyBloc).
- `lib/features/journey/presentation/screens/my_journey_screen.dart` – toggle “Show imported journey”; _buildImportedEntries; _getDaysToShow includes imported days; pass importedEntries to JourneyTimelineWidget (both branches).
- `lib/features/journey/presentation/widgets/journey_timeline_widget.dart` – ImportedEventEntry; importedEntries param; merge imported in _buildTimelineItems; _TimelineEventCard importedFrom, badge (avatar, name, Planned/Wishlist chip), no actions when imported.

## Decisions

- Wishlist in YAML = favorites not planned (candidates only); planned = journey planned items.
- Import from URL only (no file picker); http client in import service.
- Import/export UI only on Settings; Journey screen only shows/hides and displays imported events.
- Import errors surfaced via `importError` in state + snackbar; success via listener when imported count increases.
- Imported events shown as read-only cards with user name, avatar URL, and planned/wishlist status.

## Summary

Journey YAML export (planned + wishlist as favorites-not-planned), import from URL on Settings, and show/hide imported journey on the Journey screen with user/status indicators on the timeline are implemented and wired end-to-end.
