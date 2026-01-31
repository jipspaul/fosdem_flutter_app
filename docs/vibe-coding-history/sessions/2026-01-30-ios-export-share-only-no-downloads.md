# iOS Export – Share Only, No Downloads Folder

**Date:** 2026-01-30  
**Context:** On iOS the user still could not access the Downloads folder. User asked to just share the file without saving to Downloads; share is enough.

## User Prompts

1. **Prompt 1:**
 > "On ios I still can't acces download folder. maybe you can just share the file without save it on download. share is enough"

## AI Responses & Plan

### Analysis
The iOS export flow in `save_journey_io.dart` was using `getDownloadsDirectory()` first, then falling back to `getTemporaryDirectory()`. Access to the Downloads folder on iOS can require extra permissions or still fail. The user only needs to share the file; saving to Downloads is not required.

### Implementation Plan
Simplify `save_journey_io.dart` to use only `getTemporaryDirectory()`, write the YAML file there, then open the share sheet. The user can save to Files/Downloads from the share sheet if they want. No Downloads folder access needed from the app.

## Code Changes Made

### File: lib/features/settings/utils/save_journey_io.dart
- Removed all use of `getDownloadsDirectory()` and related try/catch/UnsupportedError handling.
- Now only calls `getTemporaryDirectory()`, writes `journey.yaml` there, then `Share.shareXFiles(...)`.
- Return value changed from full path to `'journey.yaml'` for the snackbar (snackbar still shows "Saved to journey.yaml").
- Comment updated: "Saves YAML to a temporary file and opens the share sheet. Does not use Downloads folder; user can save to Files/Downloads via the share sheet."

## Decisions

- Left Info.plist entries (e.g. NSDownloadsFolderUsageDescription) as-is; they do not cause harm and may be useful for other features later.
- No change to web or settings_page; only the IO (mobile/desktop) implementation was updated.

## Summary

iOS journey export now writes only to the app's temporary directory and opens the share sheet. The user can then save the file to Fichiers/Téléchargements from the share sheet if desired, without the app needing access to the Downloads folder.
