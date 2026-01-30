# iOS File Storage Permissions

**Date:** 2026-01-30  
**Context:** User could not access file paths on iOS and in the file manager; requested adding Info.plist permissions for local storage and download storage.

## User Prompts

1. **Prompt 1:**
 > "for IOS and file manager, I can't access path, you should add on info plist the permittion to acces local storage, download storage etc"

## AI Responses & Plan

### Analysis
The app (FOSDEM Flutter) uses file operations for journey export/import (YAML). On iOS, accessing Documents, Downloads, and the Files app requires declaring usage in `Info.plist` and enabling file sharing / document-in-place support.

### Implementation Plan
1. Read current `ios/Runner/Info.plist`.
2. Add standard iOS file-storage keys: `UIFileSharingEnabled`, `LSSupportsOpeningDocumentsInPlace`, `NSDocumentsFolderUsageDescription`, `NSDownloadsFolderUsageDescription`.
3. Use user-facing usage description strings for Documents and Downloads.

## Code Changes Made

### File: ios/Runner/Info.plist
- Added `UIFileSharingEnabled` (true) – allows app Documents folder to appear in Files app and iTunes/Finder.
- Added `LSSupportsOpeningDocumentsInPlace` (true) – allows opening documents from Files app in place.
- Added `NSDocumentsFolderUsageDescription` – reason for Documents folder access (save/open journey files).
- Added `NSDownloadsFolderUsageDescription` – reason for Downloads folder access (import journey files).

## Decisions

- Focused on Documents and Downloads plus file sharing; did not add photo library or other storage keys unless needed.
- Usage descriptions written for journey export/import to match app behavior.

## Summary

iOS file-storage permissions were added to `Info.plist` so the app can access local storage and download storage (Documents, Downloads, Files app). User should rebuild the iOS app for changes to take effect.
