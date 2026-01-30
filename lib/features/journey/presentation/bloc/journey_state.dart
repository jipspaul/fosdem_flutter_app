import '../../domain/models/journey_export_model.dart';
import '../../domain/models/journey_models.dart';

abstract class JourneyState {
  const JourneyState();
}

class JourneyInitial extends JourneyState {
  const JourneyInitial();
}

class JourneyLoading extends JourneyState {
  const JourneyLoading();
}

class JourneyLoaded extends JourneyState {
  final List<JourneyItem> wishlist;
  final List<JourneyItem> planned;
  final List<JourneyItem> candidates; // Favorites not yet in journey/wishlist
  final List<Conflict> conflicts;
  final JourneyStats stats;
  final JourneyPreferences preferences;
  final Map<String, JourneyExportData> importedJourneys;
  final bool showImportedJourney;
  final String? importError;

  const JourneyLoaded({
    required this.wishlist,
    required this.planned,
    this.candidates = const [],
    required this.conflicts,
    required this.stats,
    required this.preferences,
    this.importedJourneys = const {},
    this.showImportedJourney = true,
    this.importError,
  });

  JourneyLoaded copyWith({
    List<JourneyItem>? wishlist,
    List<JourneyItem>? planned,
    List<JourneyItem>? candidates,
    List<Conflict>? conflicts,
    JourneyStats? stats,
    JourneyPreferences? preferences,
    Map<String, JourneyExportData>? importedJourneys,
    bool? showImportedJourney,
    String? importError,
  }) {
    return JourneyLoaded(
      wishlist: wishlist ?? this.wishlist,
      planned: planned ?? this.planned,
      candidates: candidates ?? this.candidates,
      conflicts: conflicts ?? this.conflicts,
      stats: stats ?? this.stats,
      preferences: preferences ?? this.preferences,
      importedJourneys: importedJourneys ?? this.importedJourneys,
      showImportedJourney: showImportedJourney ?? this.showImportedJourney,
      importError: importError,
    );
  }

  List<JourneyItem> get allItems => [...wishlist, ...planned];

  bool isInWishlist(int eventId) {
    return wishlist.any((item) => item.eventId == eventId);
  }

  bool isInJourney(int eventId) {
    return planned.any((item) => item.eventId == eventId);
  }

  bool hasEvent(int eventId) {
    return isInWishlist(eventId) || isInJourney(eventId);
  }

  JourneyItem? getItemByEventId(int eventId) {
    try {
      return allItems.firstWhere((item) => item.eventId == eventId);
    } catch (e) {
      return null;
    }
  }
}

class JourneyError extends JourneyState {
  final String message;

  const JourneyError(this.message);
}
