# Session: Map – iOS location & “Go to next meeting”

**Date:** 2026-01-30  
**Context:** User asked for: (1) localization/GPS on the map for iOS, (2) a “Go to next meeting” button that shows the path from the last meeting on the journey (bold) and favorites (grey), only meetings in the next 30 min, max 5.

## User Prompts

1. **Prompt 1:**
   > @lib/presentation/pages/map/map_page.dart can you on map the localisation, for IOS. so I can use gps. can you also add a button, go to next mettings, and show the path to go from the last metting on my journey ( in Bold) and favorite (in grey) only show the metting for the next 30min . max 5

## AI Responses & Plan

### Analysis
- Map page uses MapBloc; location tracking already existed (EnableLocationTracking). iOS already had NSLocationWhenInUseUsageDescription in Info.plist. Need to request permission and enable tracking when opening the map on iOS.
- “Go to next meeting”: use JourneyBloc (planned = journey, candidates = favorites not in journey). Filter items with start time in next 30 min, max 5; journey items in bold, favorites in grey. Draw path from user location (or last meeting on journey) to each next meeting on the map.
- MapPage was not the active map tab (main used MapScreen). MapBloc was not in DI and had no building loading. Plan: add MapBloc with building loader, use MapPage in main, add polylines to FosdemMapWidget, implement next-meetings bar and paths.

### Implementation Plan
1. iOS location: in MapPage didChangeDependencies, on iOS post-frame call EnableLocationTracking so GPS is used when the map is opened.
2. Map buildings: add map_buildings_loader (load entity buildings from BuildingsService). MapBloc accepts loadBuildings callback and uses it in LoadMapData.
3. DI: register BuildingsService, LocationService, MapService; add MapBloc provider in main with loadBuildings; switch map tab to MapPage.
4. FosdemMapWidget: add MapRoutePolyline type and routePolylines parameter; draw PolylineLayer (bold = primary color, grey = favorites).
5. MapPage: compute next meetings (planned + candidates, start in next 30 min, max 5); compute polylines from user/last-meeting to each; add “Go to next meeting” bar (expandable list, journey bold, favorites grey); tap focuses building and shows info.

## Code Changes Made

### File 1: lib/presentation/bloc/map/map_buildings_loader.dart (new)
- loadEntityBuildings(BuildingsService) loads model buildings and converts to domain entities (id = title, Blueprint with imageUrl: null).

### File 2: lib/presentation/bloc/map/map_bloc.dart
- Replaced `buildings` with `Future<List<Building>> Function()? loadBuildings`. In _onLoadMapData, await loadBuildings() when non-null and emit MapLoaded with result.

### File 3: lib/presentation/widgets/map/fosdem_map_widget.dart
- Added MapRoutePolyline (points, isBold). Added routePolylines parameter. PolylineLayer draws polylines (bold = primary, strokeWidth 5; grey = 3).

### File 4: lib/presentation/pages/map/map_page.dart
- Converted to StatefulWidget. didChangeDependencies: on iOS, post-frame EnableLocationTracking. Removed inner BlocProvider (MapBloc provided in main). _computeNextMeetings: from JourneyLoaded, planned + candidates with start in [now, now+30min], sort by time, take 5; wrap in _NextMeeting(isFromJourney). _computeRoutePolylines: from = userLocation or last planned meeting (past/current by endTime); one polyline per next meeting (from → item.location). Added _NextMeetingsBar: “Go to next meeting” row, expandable list (journey bold, favorites grey), onTap selects building and shows info. Pass routePolylines to FosdemMapWidget. _buildingForItem to resolve Building from journey item.

### File 5: lib/core/di/injection_container.dart
- Registered BuildingsService, LocationService, MapService.

### File 6: lib/main.dart
- Import MapPage, MapBloc, loadEntityBuildings. Added BlocProvider for MapBloc (locationService, mapService, loadBuildings: () => loadEntityBuildings(di.sl()))..add(LoadMapData()). Replaced MapScreen() with MapPage() in _pages.

## Decisions

- “Last meeting” = last planned item that has ended or is current (by endTime), to compute path origin; else use user location or FOSDEM center.
- Next meetings = journey planned + candidates (favorites not in journey), filtered to start in next 30 min, max 5, sorted by start time. Journey items shown bold, candidates grey.
- Map tab now uses MapPage (with MapBloc and building loading) instead of MapScreen. iOS location is enabled when the map tab is opened.

## Summary

Implemented iOS GPS on the map (request + enable tracking when opening map on iOS), and “Go to next meeting”: button with expandable list of up to 5 meetings in the next 30 min (journey in bold, favorites in grey), with paths on the map from user/last meeting to each next meeting.
