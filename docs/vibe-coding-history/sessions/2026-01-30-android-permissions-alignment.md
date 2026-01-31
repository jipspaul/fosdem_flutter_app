# Android Permissions Alignment with iOS

**Date:** 2026-01-30  
**Context:** User requested to check all app permissions and add missing Android permissions to match iOS configuration.

## User Prompt

> "can you check all pemition I need for my apps, on IOS it's ok but I don't add permission on android. store this prompt command and the answer you give my on @docs/vibe-coding-history/"

## AI Response & Analysis

### Permissions Analysis

#### iOS Info.plist (Already configured)
- **Location permissions**:
  - `NSLocationWhenInUseUsageDescription` - For navigation between FOSDEM buildings and finding nearby events
  - `NSLocationAlwaysAndWhenInUseUsageDescription` - For background notifications about upcoming events
  
- **Background modes**:
  - `fetch`, `processing`, `remote-notification` - For background data sync and notifications
  - `BGTaskSchedulerPermittedIdentifiers` - For scheduled background tasks
  
- **File storage permissions**:
  - `UIFileSharingEnabled` - Allow Documents folder in Files app
  - `LSSupportsOpeningDocumentsInPlace` - Open documents from Files app
  - `NSDocumentsFolderUsageDescription` - Save/open journey YAML files
  - `NSDownloadsFolderUsageDescription` - Import journey files from downloads

#### Android AndroidManifest.xml (Before changes)
**Already had**:
- `INTERNET` - Network requests
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` - Location services
- `POST_NOTIFICATIONS` - Notifications (Android 13+)
- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` - Event reminders
- `WAKE_LOCK` - Keep device awake for background tasks
- `RECEIVE_BOOT_COMPLETED` - Restart background tasks after reboot

**Missing (added)**:
- `ACCESS_BACKGROUND_LOCATION` - Background location for event notifications
- `FOREGROUND_SERVICE` - Required for background location tracking
- `FOREGROUND_SERVICE_LOCATION` - Specific foreground service type
- Storage permissions for journey YAML export/import:
  - `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` - Android 13+ (API 33+)
  - `READ_EXTERNAL_STORAGE` - Android 11-12 (API 30-32, maxSdkVersion="32")
  - `WRITE_EXTERNAL_STORAGE` - Android 10 and below (maxSdkVersion="29")

## Code Changes Made

### File: android/app/src/main/AndroidManifest.xml

Added the following permissions:

```xml
<!-- Location permissions -->
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

<!-- Foreground service permission for background location tracking -->
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>

<!-- Storage permissions for journey export/import and file operations -->
<!-- For Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>

<!-- For Android 11-12 (API 30-32) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="29"/>
```

## Decisions

1. **Background location**: Added to match iOS "Always" location permission for background event notifications
2. **Foreground service**: Required on Android when using background location; specified `FOREGROUND_SERVICE_LOCATION` type
3. **Storage permissions**: Implemented Android version-specific permissions:
   - Android 13+ uses granular media permissions (`READ_MEDIA_*`)
   - Android 11-12 uses `READ_EXTERNAL_STORAGE`
   - Android 10 and below uses `WRITE_EXTERNAL_STORAGE`
   - Used `maxSdkVersion` to avoid requesting unnecessary permissions on newer Android versions
4. **Runtime permissions**: Note that `permission_handler: ^12.0.1` (already in pubspec.yaml) handles runtime permission requests in the app code

## App Features Requiring Permissions

1. **Location services** - Navigation and map features (`geolocator` package)
2. **Background notifications** - Event reminders with location context (`flutter_local_notifications`, `workmanager`)
3. **Journey export/import** - Save/load YAML files (`path_provider`, `share_plus`, `yaml`)
4. **Network requests** - Data sync and web scraping (`dio`, `http`)
5. **File sharing** - Export journey files (`share_plus`)

## Summary

Android permissions have been aligned with iOS configuration. The app now properly declares:
- Background location access for event notifications
- Foreground service permissions for location tracking
- Storage permissions (version-specific) for journey YAML export/import
- All existing permissions for location, notifications, alarms, and network access

**Next steps**: Rebuild the Android app for changes to take effect. Ensure runtime permission requests are implemented in the app code using the `permission_handler` package (already included in dependencies).
