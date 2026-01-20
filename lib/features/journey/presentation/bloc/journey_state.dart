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

  const JourneyLoaded({
    required this.wishlist,
    required this.planned,
    this.candidates = const [],
    required this.conflicts,
    required this.stats,
    required this.preferences,
  });

  JourneyLoaded copyWith({
    List<JourneyItem>? wishlist,
    List<JourneyItem>? planned,
    List<JourneyItem>? candidates,
    List<Conflict>? conflicts,
    JourneyStats? stats,
    JourneyPreferences? preferences,
  }) {
    return JourneyLoaded(
      wishlist: wishlist ?? this.wishlist,
      planned: planned ?? this.planned,
      candidates: candidates ?? this.candidates,
      conflicts: conflicts ?? this.conflicts,
      stats: stats ?? this.stats,
      preferences: preferences ?? this.preferences,
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
