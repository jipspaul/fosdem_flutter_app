# Session: Map – itinerary/route when tapping next meeting

**Date:** 2026-01-30  
**Context:** User asked that when they click on a meeting in the "Go to next meeting" section they should get the itinerary (route) to go to that next meeting.

## User Prompts

1. **Prompt 1:**
   > good, when I click on a meeting in the next meeting section I should get the itinaire to goto the next meeting

## AI Responses & Plan

### Analysis
- "Itinaire" (itinerary) = route/directions to the next meeting. When the user taps a meeting in the "Go to next meeting" bar, we should show the path on the map from their current position (or last meeting) to the meeting's building.
- Implementation: store a "route" (from, to) when user taps a meeting; draw a polyline on the map; optionally center the map so both points are visible.

### Implementation Plan
1. Add state `_routeToMeeting` (List<LatLng>?): the line from start to destination.
2. When user taps a meeting: compute "from" (user location, or last meeting on journey, or FOSDEM center), set _routeToMeeting = [from, building.coordinate], set _selectedBuilding, _loadEventsForBuilding, center map on route midpoint.
3. Add PolylineLayer when _routeToMeeting has at least 2 points (primary color, strokeWidth 5).
4. Clear _routeToMeeting when user closes the building sheet or taps the map.

## Code Changes Made

### File: lib/presentation/screens/map_screen.dart
- State: `List<LatLng>? _routeToMeeting`.
- Map onTap and close button: also set `_routeToMeeting = null`.
- Added PolylineLayer after user-location marker: when `_routeToMeeting != null && _routeToMeeting!.length >= 2`, draw one Polyline with theme primary color, strokeWidth 5.
- Added `_routeFromPoint()`: returns _userLocation, or last planned meeting (past/current by endTime) location from JourneyBloc, or fosdemLocation.
- On tap of a meeting in next meeting list: get building, from = _routeFromPoint(), to = building.coordinate; setState with _selectedBuilding = building, _routeToMeeting = [from, to]; _loadEventsForBuilding(building); move map to midpoint of from/to at zoom 16.5.

## Decisions

- Route is drawn as a straight line (no routing API); sufficient to show direction from start to meeting building.
- Start of route: user GPS if available, else last meeting on journey (past or current), else FOSDEM center.
- Route is cleared when user taps the map or closes the building sheet.

## Summary

Tapping a meeting in "Go to next meeting" now draws an itinerary line on the map from the user (or last meeting) to the meeting's building, opens the building events sheet, and centers the map on the route. The route is cleared when the user closes the sheet or taps the map.
