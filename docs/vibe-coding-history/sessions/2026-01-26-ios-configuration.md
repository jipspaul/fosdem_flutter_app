# iOS Configuration Setup Session

**Date:** January 26, 2026  
**Context:** Adapting the FOSDEM Flutter app to work on iOS

## User Prompts

1. **Initial Request:**
   > "I would like to adapt this app to be working on ios"

2. **Documentation Request:**
   > "can you also create a folder, that will contain all the prompt I do and the response off your through objectif is to can an historique of the vibe coding I did"

3. **Cursor Rule Request:**
   > "can you also add a cursor rules to maintain the fact that store the prompting history"

## AI Responses & Plan

### Analysis
The app uses several features requiring iOS-specific configuration:
- **Location services** (`geolocator`, `permission_handler`) - needs `NSLocationWhenInUseUsageDescription`
- **Notifications** (`flutter_local_notifications`) - needs notification permission descriptions
- **Background tasks** (`workmanager`) - needs background modes capability
- **URL launching** (`url_launcher`) - may need URL schemes
- **Database** (`sqlite3_flutter_libs`) - should work but needs verification

### Implementation Plan

1. **Update Info.plist** with permission descriptions and background modes
2. **Set minimum iOS version** in Podfile (initially 13.0, updated to 14.0 for workmanager compatibility)
3. **Create documentation folder structure** for vibe coding history
4. **Create Cursor rule** to automatically maintain prompting history

## Code Changes Made

### 1. iOS Configuration Files

#### `ios/Runner/Info.plist`
Added the following keys:
- `NSLocationWhenInUseUsageDescription` - "This app uses your location to help you navigate between FOSDEM buildings and find events near you on the map."
- `NSLocationAlwaysAndWhenInUseUsageDescription` - "This app uses your location to provide background notifications for upcoming events in your journey."
- `UIBackgroundModes` - Array with `fetch` and `processing` for workmanager background tasks
- `LSApplicationQueriesSchemes` - Array with `https` and `http` for url_launcher

#### `ios/Podfile`
- Uncommented and set `platform :ios, '14.0'` (updated from 13.0 due to workmanager_apple requirements)

#### CocoaPods Installation
- Successfully ran `pod install` which installed 14 pods including:
  - workmanager_apple
  - geolocator_apple
  - flutter_local_notifications
  - permission_handler_apple
  - sqlite3_flutter_libs
  - And other required dependencies

### 2. Documentation Structure

Created folder structure:
```
docs/vibe-coding-history/
├── README.md (overview and index)
└── sessions/
    └── 2026-01-26-ios-configuration.md (this file)
```

### 3. Cursor Rule

Created `.cursor/rules/vibe-coding-history.mdc` to automatically maintain prompting history in future sessions.

## Decisions Made

1. **iOS Version:** Set to 14.0 instead of 13.0 to ensure compatibility with workmanager_apple plugin
2. **Location Permissions:** Added both "when in use" and "always and when in use" descriptions to support both foreground and background location features
3. **Background Modes:** Added `fetch` and `processing` modes to support workmanager periodic tasks
4. **Documentation:** Created structured documentation system to track all vibe coding sessions

## Next Steps

- Test the app on iOS simulator/device
- Verify permissions are requested correctly
- Test background notifications
- Test location services on map screen
- Verify database functionality on iOS

## Notes

- The notification service already has iOS-specific initialization code in `lib/core/services/notification_service.dart`
- Location service uses permission_handler which should work once Info.plist is configured
- Workmanager background tasks may have limitations on iOS compared to Android
- All Flutter plugins should auto-register via GeneratedPluginRegistrant
