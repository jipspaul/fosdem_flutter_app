# FavoritesBloc Provider Fix

## Issue
The app was crashing on startup with:
```
Error: Could not find the correct Provider<FavoritesBloc> above this ScheduleScreen Widget
```

## Root Cause
The `FavoritesBloc` was not added to the app's `MultiBlocProvider` in `main.dart`, but screens were trying to access it via `context.read<FavoritesBloc>()`.

## Solution
Updated `/Users/jeanpauljacquot/dev/fosdemApp/fosdem_flutter/lib/main.dart`:

1. **Added import:**
```dart
import 'presentation/bloc/favorites/favorites_bloc.dart';
```

2. **Added FavoritesBloc to providers:**
```dart
MultiBlocProvider(
  providers: [
    BlocProvider(
      create: (context) => ScheduleBloc(
        eventRepository: di.sl(),
      )..add(const LoadSchedule()),
    ),
    BlocProvider(
      create: (context) => FavoritesBloc(
        eventRepository: di.sl(),
      )..add(LoadFavorites()),
    ),
  ],
  // ...
)
```

## Testing
To test the fix:

1. **Hot Restart Required:** Since we added a new provider, you MUST do a hot restart (not hot reload):
   ```bash
   # Stop the app and restart it
   flutter run -d chrome
   ```

2. **Verify:**
   - App should launch without the provider error
   - Schedule screen should load events
   - Favorite button should be visible on each event
   - Clicking favorites should work
   - Favorites screen should show favorited events

## Files Modified
- `/Users/jeanpauljacquot/dev/fosdemApp/fosdem_flutter/lib/main.dart`

## Status
✅ Fix applied - Ready for hot restart and testing
