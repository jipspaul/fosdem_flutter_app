# Session: Map – restore MapScreen + “Go to next meeting”

**Date:** 2026-01-30  
**Context:** User reported: “Go to next meeting” doesn’t work, map doesn’t load like before, and they lost the click-on-building bottom sheet that showed events. They asked to fix the code to work like it used to and keep the navigation button.

## User Prompts

1. **Prompt 1:**
   > the go to next meeting don't work, and the map not load like before, I lose also the click on building that who me a botom sheet of my event. can you check the modifcation you don and fix the code like it use to be + navigation button

## AI Responses & Plan

### Analysis
- The map tab had been switched from **MapScreen** to **MapPage** (with MapBloc). MapPage used entity buildings loaded via MapBloc, a simple building-info modal on tap, and a “Go to next meeting” bar that depended on MapBloc state and entity buildings. That led to: map loading differently (or failing), building tap no longer showing the events bottom sheet (only a small modal), and “Go to next meeting” not working as expected.
- **MapScreen** (original): loads buildings in initState with BuildingsService, tap on building opens a **DraggableScrollableSheet** with events in that building (journey/favorites indicators, tap event → EventDetailScreen), and the map/tiles matched the previous behavior.

### Implementation Plan
1. **Revert map tab to MapScreen** in main.dart (remove MapBloc provider for the map tab, use MapScreen() again).
2. **Add “Go to next meeting” to MapScreen**: compute next meetings from JourneyBloc (planned + candidates, next 30 min, max 5), add a bar at the bottom with expand/collapse; on tap of a meeting, find the building in _buildings by matching JourneyItem.building to Building.title, set _selectedBuilding and call _loadEventsForBuilding(building) so the same events bottom sheet opens.

## Code Changes Made

### File 1: lib/main.dart
- Removed imports: `presentation/pages/map/map_page.dart`, `presentation/bloc/map/map_bloc.dart`, `presentation/bloc/map/map_buildings_loader.dart`.
- Restored import: `presentation/screens/map_screen.dart`.
- Removed MapBloc BlocProvider from MultiBlocProvider.
- Replaced `MapPage()` with `MapScreen()` in _pages.

### File 2: lib/presentation/screens/map_screen.dart
- Imported `journey_models.dart` and added `_NextMeetingItem` (item + isFromJourney).
- Added state: `_nextMeetingsExpanded`.
- Wrapped body in Column: Expanded(Stack(FlutterMap, _buildBuildingInfo)), then _buildNextMeetingsBar().
- Added _computeNextMeetings(): JourneyLoaded planned + candidates, start in next 30 min, sort by time, take 5.
- Added _buildingForJourneyItem(buildingId): find Building in _buildings by title match (case-insensitive, with startsWith fallback).
- Added _buildNextMeetingsBar(): “Go to next meeting” row, expand/collapse, list of up to 5 meetings (journey bold, favorites grey); onTap finds building and calls setState(_selectedBuilding = building) and _loadEventsForBuilding(building) so the existing events bottom sheet opens.

## Decisions

- Map tab uses MapScreen again so the map loads the same way and building tap again shows the events bottom sheet (DraggableScrollableSheet with events list and EventDetailScreen navigation).
- “Go to next meeting” is implemented inside MapScreen using the same _buildings and _loadEventsForBuilding flow; tapping a next meeting selects that building and opens the same events sheet.

## Summary

The map tab is back to MapScreen: map loads as before, tapping a building opens the bottom sheet with events in that building (and tap to open event detail). The “Go to next meeting” bar is now part of MapScreen: it shows up to 5 meetings in the next 30 minutes (journey in bold, favorites in grey), and tapping one focuses that building and opens the events bottom sheet for it.
