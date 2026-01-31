# Session: Map location button – permission popup fix

**Date:** 2026-01-30  
**Context:** User reported that each time they tap the location button they get an error and never see the permission popup to accept location.

## User Prompts

1. **Prompt 1:**
   > each time I click locatino button a got error, I don't get the popup for persision accept

## AI Responses & Plan

### Analysis
- The map location flow used `permission_handler`’s `Permission.location.request()` in `LocationService`. On iOS (and some Android setups), that can fail to show the system “Allow location?” dialog, so the request returns denied and the user only sees an error.
- Geolocator’s docs state that on iOS the permission dialog is shown when you call `Geolocator.requestPermission()` or when using `getCurrentPosition()` / `getPositionStream()`. Using Geolocator for the permission request aligns with the API used for actual location and triggers the native dialog.

### Implementation Plan
1. In `LocationService`: stop using `permission_handler` for location; use `Geolocator.checkPermission()` and `Geolocator.requestPermission()` so the system dialog is shown.
2. Add `isPermissionDeniedForever()` to give a clearer error when the user had previously denied and the dialog won’t show again.
3. In `MapBloc`: improve error messages (denied vs denied forever) and add try/catch so exceptions don’t leave the bloc in a bad state.

## Code Changes Made

### File 1: lib/core/services/location_service.dart
- Removed `permission_handler` import and usage.
- `requestLocationPermission()`: uses `Geolocator.checkPermission()`; if `denied`, calls `Geolocator.requestPermission()` (this triggers the iOS/Android dialog); returns true for `whileInUse` or `always`.
- `checkLocationPermission()`: uses `Geolocator.checkPermission()` and returns true for `whileInUse` or `always`.
- Added `isPermissionDeniedForever()` returning true when permission is `deniedForever`.

### File 2: lib/presentation/bloc/map/map_bloc.dart
- In `_onEnableLocationTracking`: wrapped in try/catch; on permission failure, if `isPermissionDeniedForever()` then emit “Location was denied. You can enable it in your device Settings.” else “Location permission denied. Please allow access when prompted.”; on exception emit “Location error: $e”.
- Removed unused `map_buildings_loader.dart` import; removed unused `st` in catch.

## Decisions

- Use Geolocator for both permission request and location usage so the native permission dialog is shown when the user taps the location button.
- Keep `permission_handler` in the project for other permissions (e.g. notifications); only location flow was switched to Geolocator.

## Summary

The location button now uses Geolocator’s `requestPermission()`, so the system “Allow location?” popup should appear on iOS (and Android) when the user taps the location button. Clearer error messages are shown when permission is denied or denied forever.
