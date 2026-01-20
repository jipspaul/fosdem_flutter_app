# FOSDEM Flutter App

A comprehensive mobile application for attending FOSDEM (Free and Open Source Developers' European Meeting) conference, built with Flutter.

## 🎯 Features

### 📅 Schedule Management
- Browse complete FOSDEM schedule with all events, tracks, and rooms
- Filter events by track, room, day, and duration
- Search events by title, speaker, or description
- View detailed event information including scraped content from event URLs

### ⭐ Favorites & Personal Journey
- Mark events as favorites with a single tap
- Build your personal conference journey with conflict detection
- Smart conflict detection that considers:
  - Time overlaps between events
  - Walking time between different buildings/rooms
  - Intelligent buffer time (skipped if events are in the same room)
- Timeline visualization of your planned schedule
- Quick event discovery with Tinder-like swipe interface

### 🗺️ Interactive Maps
- Campus map showing all FOSDEM buildings
- Click on buildings to see all events happening there
- Events sorted by favorites first, then by date/time
- GPS integration for location tracking

### 🔔 Smart Notifications
- Background notifications for upcoming events in your journey
- Configurable notification timing
- Works even when the app is closed
- Test notifications to verify system setup

### 🔍 Event Discovery
- Swipe right to add events to favorites
- Swipe left to skip events
- Progress tracking showing seen/remaining events
- Randomized event presentation
- History tracking to avoid showing the same event twice

### 💾 Offline Support
- Local database caching of all schedule data
- Scraped event content cached to avoid repeated fetching
- Works without internet connection after initial sync

## ⚡ Project Status: Vibe Coding POC

**This app is functional but built as a 100% vibe coding project!**

### 🙏 Credits

This project was inspired by and started from [mttcrsp/fosdem](https://github.com/mttcrsp/fosdem) - an excellent iOS app for FOSDEM. This Flutter version was created as a proof-of-concept to explore rapid mobile development with AI assistance. 

### What does "vibe coding" mean?

This project is a **deliberate experiment in development velocity** - testing how fast we can build complex features while maintaining functionality. Here's what that means:

#### 🧪 The Experiment
**Hypothesis:** Can we achieve 10x development velocity by embracing AI-assisted coding, rapid iteration, and production QA testing?

**Method:**
- 🤖 **AI-First Development:** Using GitHub Copilot as the primary coding assistant
- 🎯 **Ship Fast, Fix Fast:** Deploy working features immediately, refine based on real usage
- 🧪 **Production QA:** Test by actually using the app, not just running test suites
- 💭 **Pure Vibes:** Let intuition and rapid experimentation guide architecture
- 🔄 **Continuous Iteration:** Fix bugs as they're discovered, not before

#### 📊 Results So Far
- ⚡ **Development Speed:** Full-featured conference app built in days, not months
- ✅ **Feature Completeness:** Journey planning, conflict detection, swipe discovery, maps, notifications
- 🎯 **Real-World Ready:** Actually usable at FOSDEM conference
- 🐛 **Bug Discovery:** Issues found and fixed through actual usage
- 🚀 **Velocity Proof:** Complex features delivered 5-10x faster than traditional development

#### 🎭 What to Expect

**✅ It Works:**
- All features are functional and tested in real usage
- The app successfully helps plan and navigate FOSDEM
- Critical user flows work reliably

**⚠️ The Trade-offs:**
- 🔍 **Code Quality:** Works great, but not production-grade
  - Code duplication exists (copy-paste over abstraction)
  - Architecture patterns are pragmatic, not perfect
  - Some technical debt accumulated for speed
- 🧪 **Testing:** Manual QA over automated tests
  - Features validated through actual usage
  - Edge cases discovered and fixed as encountered
- 🔧 **Maintenance:** Rapid iteration over upfront planning
  - Bugs fixed within hours of discovery
  - Refactoring happens when needed, not proactively

**🎯 The Point:**
This proves you can build **complex, working software extremely fast** by prioritizing velocity over perfection. The app delivers real value despite imperfect code. Perfect for:
- Rapid prototyping and MVPs
- Proof-of-concepts and experiments  
- Time-constrained projects (like conference apps)
- Learning and exploring new features

**Not suitable for:**
- Mission-critical production systems
- Long-term enterprise maintenance
- Large team codebases
- Regulatory/compliance requirements
- 🚀 **Fast evolution** - new features ship continuously

**The Verdict:** Vibe coding works! By embracing speed and iteration over perfection, we've proven you can build sophisticated, working software incredibly fast. This is real development velocity.

This is an **evolving experiment** - contributions, bug reports, and feedback help us push the boundaries of how fast we can build!

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.9.2 or higher
- Android Studio / Xcode for mobile development
- Android SDK (for Android builds)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/fosdem_flutter.git
   cd fosdem_flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate database code**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   # For Android
   flutter run -d android
   
   # For iOS
   flutter run -d ios
   
   # For Web
   flutter run -d chrome
   ```

### Building for Production

#### Android APK
```bash
flutter build apk --release
```

#### Android App Bundle
```bash
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## 📱 Permissions

The app requires the following permissions:

- **Notifications**: To send reminders for upcoming events
- **Location**: To show your position on the campus map
- **Internet**: To sync schedule data and scrape event content

## 🏗️ Architecture

The app follows Clean Architecture principles with BLoC (Business Logic Component) pattern:

```
lib/
├── core/                    # Core utilities and constants
├── data/                    # Data layer
│   ├── datasources/        # API and local database
│   ├── models/             # Data models
│   └── repositories/       # Repository implementations
├── domain/                  # Domain layer
│   ├── entities/           # Business entities
│   ├── repositories/       # Repository interfaces
│   └── usecases/           # Business logic
├── features/               # Feature modules
│   ├── event_discovery/   # Swipe-to-favorite feature
│   ├── favorites/         # Favorites management
│   ├── journey/           # Personal journey planning
│   ├── map/               # Interactive campus map
│   └── schedule/          # Event schedule browsing
└── presentation/           # UI layer
    ├── bloc/              # State management
    ├── screens/           # App screens
    └── widgets/           # Reusable widgets
```

## 🔧 Technologies & Dependencies

### Core Framework
- **Flutter**: Cross-platform UI framework
- **Dart**: Programming language

### State Management
- **flutter_bloc** (9.1.1): BLoC pattern implementation
- **equatable** (2.0.8): Value equality for state management

### Networking
- **dio** (5.9.0): HTTP client
- **http** (1.6.0): Alternative HTTP client
- **pretty_dio_logger** (1.4.0): Network logging

### Local Storage
- **drift** (2.20.0): Type-safe SQL database
- **sqlite3_flutter_libs** (0.5.24): SQLite implementation
- **path_provider** (2.1.1): File system paths
- **shared_preferences** (2.5.4): Key-value storage

### Maps & Location
- **flutter_map** (8.2.2): Interactive map widget
- **latlong2** (0.9.1): Geographic coordinates
- **geolocator** (14.0.2): GPS positioning

### Notifications & Background Tasks
- **flutter_local_notifications** (19.5.0): Local notifications
- **workmanager** (0.9.0): Background task scheduling
- **timezone** (0.10.1): Timezone support for notifications

### UI Components
- **flutter_slidable** (4.0.3): Swipeable list items
- **video_player** (2.8.1): Video playback
- **chewie** (1.7.5): Video player UI

### Utilities
- **intl** (0.20.2): Internationalization
- **url_launcher** (6.3.2): Open URLs
- **share_plus** (12.0.1): Native sharing
- **uuid** (4.0.0): Unique identifiers
- **xml** (6.6.1): XML parsing for schedule data
- **html** (0.15.6): HTML scraping for event content
- **dartz** (0.10.1): Functional programming utilities
- **rxdart** (0.28.0): Reactive extensions

### Navigation
- **go_router** (17.0.1): Declarative routing

### Dependency Injection
- **get_it** (9.2.0): Service locator

## 📖 Usage Guide

### First Launch
1. The app will automatically sync the FOSDEM schedule
2. Grant notification and location permissions when prompted
3. Browse the schedule and mark events you're interested in

### Building Your Journey
1. **Browse Events**: Go to Schedule tab and explore events
2. **Add Favorites**: Tap the heart icon on any event
3. **Plan Journey**: Visit the Journey tab to see your timeline
4. **Resolve Conflicts**: The app will highlight time conflicts and impossible transitions
5. **Add to Journey**: Tap "Add to Journey" to confirm events

### Using Event Discovery
1. Go to Favorites tab
2. Tap "Discover Events" button
3. Swipe right on events you like (adds to favorites)
4. Swipe left to skip events
5. Track your progress in the stats section

### Exploring the Map
1. Go to Map tab
2. Tap on any building to see events there
3. Events are sorted with your favorites at the top
4. Tap an event to see full details

### Setting Up Notifications
1. Go to Settings tab
2. Test notifications with the test button
3. Schedule notifications will automatically alert you 15 minutes before each event in your journey

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- FOSDEM organizers for providing the conference schedule data
- Flutter team for the amazing framework
- All open-source contributors whose packages made this app possible

## 📧 Contact

For questions, issues, or suggestions, please open an issue on GitHub.

## 🗓️ FOSDEM Information

FOSDEM (Free and Open Source Developers' European Meeting) is a free event for software developers to meet, share ideas and collaborate. It takes place annually in Brussels, Belgium.

- Website: https://fosdem.org
- Dates: Usually first weekend of February
- Location: ULB Campus Solbosch, Brussels

---

**Note**: This is an unofficial FOSDEM app created by the community. For official FOSDEM information, please visit https://fosdem.org
