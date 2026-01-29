# FOSDEM Flutter App - Complete Implementation Plan

## Project Overview
This document outlines the complete implementation plan for creating a Flutter version of the FOSDEM iOS app. The original app is a comprehensive conference companion for the FOSDEM conference with 192 Swift files and extensive functionality.

## Core Features Analysis (from iOS app)

### 1. Event Management
- **Schedule Display**: View events by day, track, and room
- **Event Details**: Title, subtitle, abstract, summary, speakers, attachments
- **Real-time Updates**: Automatic schedule updates via network service
- **Search Functionality**: Full-text search across events, tracks, speakers
- **Favorites/Agenda**: Personal agenda with favorite events
- **Live Status**: Track which events are currently happening

### 2. Navigation & Maps
- **Campus Map**: Interactive map with building locations using MapKit
- **Building Blueprints**: Floor plans for each building
- **Location Services**: User location on campus
- **Transportation Info**: Getting to FOSDEM venue

### 3. Media & Content
- **Video Playback**: Stream/download event videos (MP4)
- **Background Audio**: Audio playback with background mode support
- **Attachments**: Access slides and speaker materials
- **Year Archives**: Browse previous years' content

### 4. User Experience
- **Dark Mode Support**: Light/dark theme switching
- **Accessibility**: VoiceOver support, Dynamic Type
- **Multi-platform**: iPhone, iPad, macOS support
- **Time Zone Support**: Display times in user's preferred timezone
- **Onboarding**: Welcome screens for new users

## Flutter Architecture Plan

### 1. State Management
```
bloc/
├── event/
│   ├── event_bloc.dart
│   ├── event_event.dart
│   └── event_state.dart
├── schedule/
├── favorites/
├── search/
├── navigation/
└── theme/
```

### 2. Data Layer
```
data/
├── models/
│   ├── event.dart
│   ├── track.dart
│   ├── person.dart
│   ├── building.dart
│   └── attachment.dart
├── repositories/
│   ├── schedule_repository.dart
│   ├── favorites_repository.dart
│   └── buildings_repository.dart
├── datasources/
│   ├── local/
│   │   ├── database_helper.dart
│   │   └── shared_preferences_helper.dart
│   └── remote/
│       ├── api_service.dart
│       └── schedule_api.dart
```

### 3. Presentation Layer
```
presentation/
├── screens/
│   ├── home/
│   ├── schedule/
│   ├── event_detail/
│   ├── search/
│   ├── favorites/
│   ├── map/
│   └── settings/
├── widgets/
│   ├── event_card.dart
│   ├── track_view.dart
│   └── custom_search_delegate.dart
└── navigation/
    └── app_router.dart
```

### 4. Core Services
```
core/
├── services/
│   ├── database_service.dart
│   ├── network_service.dart
│   ├── location_service.dart
│   ├── playback_service.dart
│   └── notification_service.dart
├── utils/
│   ├── date_formatter.dart
│   ├── html_parser.dart
│   └── constants.dart
└── extensions/
    ├── datetime_extensions.dart
    └── string_extensions.dart
```

## Required Flutter Packages

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_bloc: ^8.1.3
  
  # Database (Web Compatible)
  drift: ^2.13.1
  drift_flutter: ^0.1.0
  sqlite3_flutter_libs: ^0.5.0
  path_provider: ^2.1.1
  path: ^1.8.3
  
  # Networking
  dio: ^5.3.2
  retrofit: ^4.0.3
  
  # Local Storage
  shared_preferences: ^2.2.2
  hive_flutter: ^1.1.0
  
  # UI Components
  flutter_staggered_grid_view: ^0.7.0
  cached_network_image: ^3.3.0
  flutter_svg: ^2.0.9
  
  # Maps & Location (Web Compatible)
  google_maps_flutter: ^2.5.0
  google_maps_flutter_web: ^0.5.4+2
  geolocator: ^10.1.0
  geolocator_web: ^2.2.0
  permission_handler: ^11.0.1
  
  # Video & Audio (Web Compatible)
  video_player: ^2.7.2
  video_player_web: ^2.0.17
  chewie: ^1.7.1
  just_audio: ^0.9.35
  just_audio_web: ^0.4.8
  audio_session: ^0.1.16
  
  # Navigation
  go_router: ^12.1.1
  
  # Utilities
  intl: ^0.19.0
  xml: ^6.4.2
  html: ^0.15.4
  url_launcher: ^6.2.1
  url_launcher_web: ^2.0.19
  package_info_plus: ^4.2.0
  package_info_plus_web: ^1.0.6
  
  # Theme & UI
  flex_color_scheme: ^7.3.1
  animations: ^2.0.8
  
  # Web Specific
  js: ^0.6.7
  web: ^0.3.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.7
  json_annotation: ^4.8.1
  json_serializable: ^6.7.1
  drift_dev: ^2.13.2
  retrofit_generator: ^8.0.4
  
  # Testing
  bloc_test: ^9.1.5
  mocktail: ^1.0.1
  
  # Static Analysis
  flutter_lints: ^3.0.1
```

### Web Configuration
```yaml
# Additional web configuration in pubspec.yaml
flutter:
  uses-material-design: true
  
  # Web specific assets
  assets:
    - assets/images/
    - assets/icons/
    - assets/maps/
  
  # Web fonts
  fonts:
    - family: Roboto
      fonts:
        - asset: fonts/Roboto-Regular.ttf
        - asset: fonts/Roboto-Bold.ttf
          weight: 700
```

## Database Schema (Drift/SQLite)

### Tables Implementation
```dart
// events table
@DataClassName('EventData')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get subtitle => text().nullable()();
  TextColumn get abstract => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get room => text()();
  TextColumn get track => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get start => text()(); // Store as JSON
  TextColumn get duration => text()(); // Store as JSON
  TextColumn get links => text()(); // Store as JSON
  TextColumn get people => text()(); // Store as JSON
  TextColumn get attachments => text()(); // Store as JSON
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
}

// tracks table
class Tracks extends Table {
  TextColumn get name => text()();
  IntColumn get day => integer().nullable()();
  DateTimeColumn get date => dateTime().nullable()();
  
  @override
  Set<Column> get primaryKey => {name};
}

// people table
class People extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

// buildings table
class Buildings extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get glyph => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get polygon => text()(); // Store as JSON
  TextColumn get blueprints => text()(); // Store as JSON
  
  @override
  Set<Column> get primaryKey => {id};
}
```

## Implementation Phases

### Phase 1: Core Infrastructure (Week 1-2)
- [ ] Set up Flutter project structure
- [ ] Implement BLoC state management
- [ ] Set up Drift database with migrations
- [ ] Create basic models (Event, Track, Person, Building)
- [ ] Implement network service with Dio
- [ ] Basic app navigation with GoRouter

### Phase 2: Schedule & Events (Week 3-4)
- [ ] Schedule data parsing from XML/JSON
- [ ] Events list view with filtering
- [ ] Event detail screen with rich content
- [ ] Search functionality with FTS
- [ ] Favorites system
- [ ] Pull-to-refresh and auto-sync

### Phase 3: Maps & Navigation (Week 5-6)
- [ ] Integrate Google Maps
- [ ] Building overlays and markers
- [ ] User location services
- [ ] Blueprint viewer screens
- [ ] Navigation between buildings

### Phase 4: Media & Playback (Week 7-8)
- [ ] Video player integration
- [ ] Background audio playback
- [ ] Download management
- [ ] Playback controls and notifications
- [ ] Offline video support

### Phase 5: UI/UX Polish (Week 9-10)
- [ ] Dark/Light theme implementation
- [ ] Accessibility features
- [ ] Animations and transitions
- [ ] Responsive design for tablets
- [ ] Settings screen

### Phase 6: Advanced Features (Week 11-12)
- [ ] Multi-year support
- [ ] Offline mode
- [ ] Push notifications
- [ ] Share functionality
- [ ] Analytics integration

## Key Technical Challenges & Solutions

### 1. Data Synchronization
- **Challenge**: Real-time schedule updates from FOSDEM API
- **Solution**: Use WorkManager for background sync, implement incremental updates

### 2. Full-Text Search
- **Challenge**: Complex search across events, speakers, abstracts
- **Solution**: Use Drift's FTS5 support for efficient text search

### 3. Maps Integration
- **Challenge**: Custom building overlays and blueprints
- **Solution**: Use Google Maps with custom markers and overlay widgets

### 4. Video Playback
- **Challenge**: Streaming video with background audio
- **Solution**: Chewie + Just Audio with proper audio session management

### 5. Offline Support
- **Challenge**: App functionality without internet
- **Solution**: Comprehensive local caching with sync indicators

## App Architecture Diagram
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Presentation   │    │   Domain/BLoC   │    │      Data       │
│                 │    │                 │    │                 │
│ Screens/Widgets │◄──►│ Business Logic  │◄──►│ Repositories    │
│                 │    │                 │    │                 │
│ UI Components   │    │ State Management│    │ Data Sources    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                       │
                                              ┌─────────────────┐
                                              │   External      │
                                              │                 │
                                              │ API│Database    │
                                              │ GPS│Files       │
                                              └─────────────────┘
```

## Testing Strategy

### Unit Tests
- [ ] Model serialization/deserialization
- [ ] Business logic in BLoCs
- [ ] Repository implementations
- [ ] Utility functions

### Integration Tests
- [ ] Database operations
- [ ] API calls and data parsing
- [ ] Navigation flows
- [ ] State management

### Widget Tests
- [ ] Individual widget behaviors
- [ ] User interaction flows
- [ ] Accessibility features

### E2E Tests
- [ ] Complete user journeys
- [ ] Performance testing
- [ ] Cross-platform compatibility

## Performance Considerations

### Optimization Areas
- [ ] Image caching and lazy loading
- [ ] List virtualization for large datasets
- [ ] Database query optimization
- [ ] Background processing for data sync
- [ ] Memory management for video playback

### Metrics to Track
- [ ] App startup time
- [ ] List scrolling performance
- [ ] Database query speeds
- [ ] Network request latency
- [ ] Battery usage during video playback

## Deployment & Distribution

### Platform Targets
- [ ] Android (Google Play Store)
- [ ] iOS (Apple App Store)
- [ ] **Web (Progressive Web App)** - **MANDATORY**

### Web-Specific Requirements
- [ ] Responsive web design for desktop/tablet browsers
- [ ] PWA (Progressive Web App) functionality
- [ ] Web-optimized database (IndexedDB via Drift)
- [ ] Web-compatible media playback
- [ ] Web maps integration (Google Maps JavaScript API)
- [ ] Web push notifications (optional)
- [ ] SEO optimization for schedule/event pages
- [ ] Web app manifest and service worker

### CI/CD Pipeline
- [ ] Automated testing
- [ ] Code quality checks
- [ ] Build automation
- [ ] Release management

## Conclusion

This comprehensive plan provides a roadmap for creating a fully-featured Flutter version of the FOSDEM app. The implementation focuses on maintaining feature parity with the iOS version while leveraging Flutter's cross-platform capabilities. The modular architecture ensures maintainability and scalability for future enhancements.

**Estimated Timeline**: 12 weeks for complete implementation
**Team Size**: 2-3 developers
**Priority**: Focus on core features (Phases 1-3) first, then enhance with media and advanced features