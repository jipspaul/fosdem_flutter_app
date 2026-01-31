# Session: Map – no bottom sheet for itinerary + heading arrow

**Date:** 2026-01-30  
**Context:** User asked: the bottom sheet should disappear so they can see the map when viewing the itinerary; and they want to see an arrow to understand their position and navigate.

## User Prompts

1. **Prompt 1:**
   > the bottom sheet shoudl disapear to let be see the map . if possible I should se a arrow to help me understand my position and be able to navigate .

## AI Responses & Plan

### Analysis
- When tapping a meeting in "Go to next meeting", the building events bottom sheet was opening and covering the map. User wants to see the map and the route instead, so the sheet should not open in that case.
- They want a heading arrow on their position so they can see which way they're facing and navigate. Use device heading (Position.heading from Geolocator) to rotate an arrow icon on the user marker.

### Implementation Plan
1. Add _destinationBuildingForRoute (Building?): when user taps a meeting in "Go to next meeting", set this (and _routeToMeeting) but do NOT set _selectedBuilding and do NOT call _loadEventsForBuilding. So no bottom sheet; destination building is still highlighted on the map. Clear _destinationBuildingForRoute on map tap and close button.
2. PolygonLayer and MarkerLayer: treat a building as "selected" (blue) if it equals _selectedBuilding OR _destinationBuildingForRoute.
3. Show close button when _selectedBuilding != null OR _destinationBuildingForRoute != null (so user can clear the route without opening the sheet).
4. Add _userHeading (double? degrees). Update from position stream (position.heading). Clear when stopping tracking.
5. User location marker: use Icon(Icons.navigation) rotated by _userHeading (degrees to radians). If heading is null, use 0 so arrow points north.

## Code Changes Made

### File: lib/presentation/screens/map_screen.dart
- Import dart:math for pi.
- State: _destinationBuildingForRoute (Building?), _userHeading (double?).
- _toggleLocationTracking: when stopping, clear _userHeading; when receiving position, set _userHeading = position.heading; in initial getCurrentLocation also set _userHeading = position.heading.
- Close button: show when _selectedBuilding != null OR _destinationBuildingForRoute != null; on pressed clear _selectedBuilding, _destinationBuildingForRoute, _routeToMeeting.
- Map onTap: also clear _destinationBuildingForRoute.
- PolygonLayer/MarkerLayer: isSelected = _selectedBuilding == building || _destinationBuildingForRoute == building; same for marker color and text color.
- When tapping a meeting in next meeting list: set _destinationBuildingForRoute = building, _routeToMeeting = [from, to], _selectedBuilding = null; do NOT call _loadEventsForBuilding; center map on route.
- User location marker: use Transform.rotate(angle: (_userHeading ?? 0) * pi/180, child: Icon(Icons.navigation)); slightly larger marker (48x48, icon size 28).

## Decisions

- Tapping a meeting in "Go to next meeting" only shows the route and highlights the destination building; no bottom sheet. User can still tap a building on the map to open the events sheet.
- Heading arrow uses Position.heading (direction of travel in degrees); when unavailable the arrow points north (0).

## Summary

When you tap a meeting in "Go to next meeting", the bottom sheet no longer opens so the map and itinerary line stay visible; the destination building is still highlighted. The user position marker is now a navigation arrow that rotates with device heading so you can see which way you're facing and navigate. Close button and map tap clear both the sheet and the route.
