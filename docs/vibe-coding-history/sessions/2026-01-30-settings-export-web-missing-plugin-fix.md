# Settings Journey Export – Web Missing Plugin Fix

**Date:** 2026-01-30  
**Context:** User had a "missing plugin exception" when exporting the journey from Settings on the web. The settings page used `dart:io` (File, Directory), `path_provider`, and `share_plus`, which are not available or behave differently on Flutter web.

## User Prompts

1. **Prompt 1:**
 > "peut tu aussi corriger ce plugin sur le web , j'ai un missing plugin expetion. quand je veut fair eun export de la journey dans les @lib/features/settings/presentation/pages/settings_page.dart"

## AI Responses & Plan

### Analysis
- The export flow in `settings_page.dart` used `dart:io` (File, Directory), `path_provider` (getDownloadsDirectory, getTemporaryDirectory), and `share_plus` (Share.shareXFiles). On web, `dart:io` is not available and path_provider/share can trigger "missing plugin" or unsupported behavior.
- Solution: use conditional imports so that on web we use a web-only implementation that triggers a browser download via `dart:html` (Blob + AnchorElement), and on mobile/desktop we keep the existing file + share flow.

### Implementation Plan
1. Create `save_journey_io.dart` – uses path_provider, dart:io, share_plus (mobile/desktop).
2. Create `save_journey_web.dart` – uses dart:html to create a Blob and trigger download (web).
3. Update `settings_page.dart` to remove direct dart:io/path_provider/share_plus usage and call the conditional helper `save_journey.saveAndShareJourneyYaml(yaml)`.

## Code Changes Made

### File: lib/features/settings/utils/save_journey_io.dart (new)
- Implements `Future<String> saveAndShareJourneyYaml(String yaml)`.
- Uses getDownloadsDirectory/getTemporaryDirectory, writes to File, calls Share.shareXFiles, returns path string for snackbar.
- Imports: dart:io, dart:ui (Rect), path_provider, share_plus.

### File: lib/features/settings/utils/save_journey_web.dart (new)
- Implements `Future<String> saveAndShareJourneyYaml(String yaml)`.
- Encodes YAML to UTF-8 bytes, creates Blob, creates object URL, adds temporary AnchorElement with download="journey.yaml", triggers click, removes anchor, revokes URL.
- Null-safe access to document.body.
- Imports: dart:convert, dart:html.

### File: lib/features/settings/presentation/pages/settings_page.dart
- Removed: `import 'dart:io'`, path_provider, share_plus.
- Added: conditional import `import '../../utils/save_journey_io.dart' if (dart.library.html) '../../utils/save_journey_web.dart' as save_journey;`
- In `_exportJourney`: replaced inline file/share logic with `final result = await save_journey.saveAndShareJourneyYaml(yaml);` and snackbar `'Saved to $result'`.

## Decisions

- Used conditional import so that on web only `save_journey_web.dart` (with dart:html) is compiled, and on mobile/desktop only `save_journey_io.dart` (with dart:io) is compiled, avoiding missing plugin and compile errors.
- Web implementation triggers a browser download of `journey.yaml` instead of share sheet, which is the standard pattern for web.

## Summary

The "missing plugin" on web when exporting the journey from Settings was fixed by splitting the export logic into platform-specific implementations (IO vs web) and using conditional imports. On web, the export now triggers a browser download of `journey.yaml`; on iOS/Android/desktop, the previous behavior (save to file + share sheet) is unchanged.
