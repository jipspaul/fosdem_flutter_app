# Session: Map – GPS on map + “Go to next meeting” fix

**Date:** 2026-01-30  
**Context:** User reported: “Go to next meeting” still doesn’t work, and GPS position is not shown on the map even when they tap and grant permission.

## User Prompts

1. **Prompt 1:**
   > the go to next meeting still don't work. and the position gps is not shown on the map, event when I click and permission ok

## AI Responses & Plan

### Analysis
- **GPS:** MapScreen had no location tracking; the my_location button only centered on FOSDEM. We needed to request permission via LocationService, get current position and watch the stream, and show a user-location marker on the map.
- **Go to next meeting:** (1) “Next 30 min” could be empty (e.g. FOSDEM in February, or no events in that window). (2) The bar didn’t rebuild when JourneyBloc loaded. (3) Building matching: JourneyItem.building can be "J" (room "J.1.105") but Building.title can be "Janson"; _loadEventsForBuilding filtered by building.title so "J.1.105" didn’t match "Janson".

### Implementation Plan
1. Add GPS to MapScreen: LocationService from DI, state for _userLocation and _isTrackingLocation, subscription to watchLocation(); on my_location tap request permission and start tracking; add MarkerLayer for _userLocation; dispose subscription; add “center on my location or FOSDEM” button.
2. Fix next meeting: (a) If “next 30 min” is empty, use “next 5 upcoming” (any startTime >= now from planned + candidates). (b) Wrap the bar in BlocBuilder<JourneyBloc, JourneyState> so it rebuilds when journey loads. (c) Allow expanding the bar when there are 0 meetings and show “No upcoming meetings…”. (d) In _loadEventsForBuilding, also match room by first letter of building title (e.g. "J.1.105" for "Janson").

## Code Changes Made

### File: lib/presentation/screens/map_screen.dart
- Imports: added `dart:async`, `geolocator`, `LocationService` from di.
- State: `_userLocation`, `_isTrackingLocation`, `_locationSubscription`; `_locationService = di.sl<LocationService>()`.
- dispose(): cancel _locationSubscription.
- _toggleLocationTracking(): request permission; if granted, get current position and set _userLocation, move map to user; subscribe to watchLocation() and update _userLocation; on stop cancel subscription and clear _userLocation.
- AppBar: my_location button calls _toggleLocationTracking(), icon toggles location_on when tracking; added “center” button (center on _userLocation or FOSDEM).
- Map: added MarkerLayer for _userLocation (blue circle + my_location icon) when non-null.
- Next meetings bar wrapped in BlocBuilder<JourneyBloc, JourneyState>.
- _computeNextMeetings(): if “next 30 min” is empty, use “next 5 upcoming” (planned + candidates with startTime >= now).
- Bar: always tappable to expand/collapse; when expanded and empty, show “No upcoming meetings. Add events to your journey or favorites.”
- _loadEventsForBuilding(): also match room by first letter of building title (room.startsWith('$firstLetter.') || room == firstLetter) so "J.1.105" matches building "Janson".

## Decisions

- GPS is implemented inside MapScreen with LocationService (Geolocator); no MapBloc. User taps my_location to start/stop tracking; blue dot on map when tracking.
- “Go to next meeting” shows next 5 in next 30 min, or next 5 upcoming if none in 30 min, so it’s useful even when FOSDEM is in the future or no events soon.
- Room matching by first letter fixes “Janson” / “J.1.105” so tapping a next meeting in J opens the correct building events sheet.

## Summary

MapScreen now shows GPS position on the map when the user taps the location button and grants permission (blue dot, continuous updates). “Go to next meeting” was fixed: bar rebuilds with journey, shows next 5 in 30 min or next 5 upcoming, bar is always expandable with a message when empty, and building/room matching (including first letter) ensures tapping a meeting opens the right building’s events sheet.
