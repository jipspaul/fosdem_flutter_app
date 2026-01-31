# Session: Map – bottom sheet closes when selecting destination

**Date:** 2026-01-30  
**Context:** User asked that the bottom sheet should close when they select a destination (tap a meeting in "Go to next meeting").

## User Prompts

1. **Prompt 1:**
   > the bottomsheet should close when I select a destination

## AI Responses & Plan

### Analysis
- When the user taps a meeting in "Go to next meeting", we already set _selectedBuilding = null so the bottom sheet (which only shows when _selectedBuilding != null) should not be shown. To make the behaviour explicit and fully reset building-selection state, we also clear _buildingEvents when selecting a destination.

### Implementation
- In the onTap of a meeting in the next meeting list: keep _selectedBuilding = null and add _buildingEvents = [] in the same setState so the sheet is closed and any previous building-events state is cleared.

## Code Changes Made

### File: lib/presentation/screens/map_screen.dart
- When tapping a meeting in "Go to next meeting": in setState, added _buildingEvents = [] alongside _selectedBuilding = null, _destinationBuildingForRoute = building, _routeToMeeting = [from, to]. Comment updated to "bottom sheet stays closed so map is visible".

## Summary

Selecting a destination from "Go to next meeting" already closed the bottom sheet by setting _selectedBuilding = null. We now also clear _buildingEvents so the building-selection state is fully reset and the sheet is guaranteed to close when a destination is selected.
