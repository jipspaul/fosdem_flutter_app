# Journey timeline: fold past events

**Date:** 2026-01-31  
**Context:** Journey timeline widget – show next event first by folding finished events.

## User Prompts

1. **Prompt 1:**
 > "@lib/features/journey/presentation/widgets/journey_timeline_widget.dart I would like that the event that already finish to be fold together so when I go to this view I can see the next event, not have to scroll all liste."

## AI Responses & Plan

### Analysis
- Timeline currently lists all events in time order; past events force the user to scroll to reach the next one.
- Request: group finished events into a collapsible section so the view opens with the next event visible.

### Implementation Plan
1. After merging and sorting items, split by `endTime < DateTime.now()` into past vs upcoming.
2. Render past items inside an `ExpansionTile` with title "Past events (N)", initially collapsed.
3. Render upcoming items as before, so they appear first (below the collapsed row).
4. Extract card building into `_buildCardsForItems` to avoid duplication.

## Code Changes Made

### File: lib/features/journey/presentation/widgets/journey_timeline_widget.dart
- In `_buildTimelineItems`: added split of `allItems` into `pastItems` and `upcomingItems` using `DateTime.now()` and `item.endTime.isBefore(now)`.
- If `pastItems.isNotEmpty`, add an `ExpansionTile` (initiallyExpanded: false, tilePadding/childrenPadding set) with title row (history icon + "Past events (N)"); children built via new helper.
- New method `_buildCardsForItems(context, items)` builds the list of `_TimelineEventCard` widgets (same logic as before: showBreak, breakDuration, conflicts, etc.).
- Upcoming cards are added with `widgets.addAll(_buildCardsForItems(context, upcomingItems))`.

## Decisions

- Use `endTime.isBefore(now)` so an event is “past” only after it has finished.
- Use `ExpansionTile` so expand/collapse state is handled without converting to StatefulWidget.
- Keep past and upcoming card rendering identical (same `_TimelineEventCard` and break lines).

## Summary

Past events are grouped in a collapsed “Past events (N)” section; the next event and the rest of the day appear immediately when opening the journey view, without scrolling through finished events.
