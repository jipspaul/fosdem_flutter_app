import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../../../data/datasources/local/database.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/daos/journey_items_dao.dart';
import '../../domain/models/journey_models.dart';
import '../../domain/services/conflict_detector_service.dart';
import 'journey_event.dart';
import 'journey_state.dart';

class JourneyBloc extends Bloc<JourneyEvent, JourneyState> {
  final AppDatabase database;
  final NotificationService? notificationService;
  late final JourneyItemsDao _dao;
  JourneyPreferences _preferences = const JourneyPreferences();
  late final ConflictDetectorService _conflictDetector;
  StreamSubscription? _favoritesSubscription;

  JourneyBloc({
    required this.database,
    this.notificationService,
  }) : super(const JourneyInitial()) {
    _dao = JourneyItemsDao(database);
    _conflictDetector = ConflictDetectorService(_preferences);

    on<LoadJourney>(_onLoadJourney);
    on<AddToWishlist>(_onAddToWishlist);
    on<AddToJourney>(_onAddToJourney);
    on<RemoveFromJourney>(_onRemoveFromJourney);
    on<MoveToJourney>(_onMoveToJourney);
    on<MoveToWishlist>(_onMoveToWishlist);
    on<UpdatePriority>(_onUpdatePriority);
    on<UpdateNotes>(_onUpdateNotes);
    on<UpdateStatus>(_onUpdateStatus);
    on<DetectConflicts>(_onDetectConflicts);
    on<UpdatePreferences>(_onUpdatePreferences);
    
    // Listen to favorites changes and auto-reload
    _favoritesSubscription = database.eventsDao.watchFavoriteEvents().listen((favorites) {
      add(const LoadJourney());
    });
  }
  
  @override
  Future<void> close() {
    _favoritesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadJourney(LoadJourney event, Emitter<JourneyState> emit) async {
    try {
      emit(const JourneyLoading());

      // Load journey items
      final allItems = await _dao.getAllJourneyItems();
      final journeyItems = _convertToJourneyItems(allItems);

      print('DEBUG Journey: Loaded ${journeyItems.length} journey items');

      final wishlist = journeyItems.where((i) => i.status == JourneyStatus.wishlist).toList();
      final planned = journeyItems.where((i) => i.status == JourneyStatus.planned).toList();

      print('DEBUG Journey: Wishlist: ${wishlist.length}, Planned: ${planned.length}');

      // Load favorites from Events table (isFavorite = true) as candidates
      final favoriteEvents = await database.eventsDao.getFavoriteEvents();
      print('DEBUG Journey: Total favorite events: ${favoriteEvents.length}');
      
      final journeyEventIds = journeyItems.map((i) => i.eventId).toSet();
      
      final candidateItems = <JourneyItem>[];
      for (final event in favoriteEvents) {
        if (!journeyEventIds.contains(event.id)) {
          final building = _extractBuilding(event.room);
          final location = _getLocationForBuilding(building);
          candidateItems.add(JourneyItem(
            id: 'candidate_${event.id}',
            eventId: event.id,
            eventTitle: event.title,
            startTime: event.start,
            endTime: event.start.add(Duration(minutes: event.duration)),
            duration: Duration(minutes: event.duration),
            room: event.room,
            building: building,
            track: event.track,
            location: location,
            status: JourneyStatus.wishlist,
            priority: 3,
            addedAt: DateTime.now(),
            notes: null,
            tags: [],
          ));
        }
      }

      print('DEBUG Journey: Candidates (favorites not in journey): ${candidateItems.length}');

      final conflicts = _conflictDetector.detectConflicts(journeyItems);
      final stats = _conflictDetector.calculateStats(journeyItems);

      emit(JourneyLoaded(
        wishlist: wishlist,
        planned: planned,
        candidates: candidateItems,
        conflicts: conflicts,
        stats: stats,
        preferences: _preferences,
      ));
      
      // Schedule notifications for all journey items (wishlist + planned)
      await _scheduleNotificationsForJourney();
    } catch (e, stackTrace) {
      print('DEBUG Journey: Error loading journey: $e');
      print('DEBUG Journey: Stack trace: $stackTrace');
      emit(JourneyError('Failed to load journey: $e'));
    }
  }

  Future<void> _onAddToWishlist(AddToWishlist event, Emitter<JourneyState> emit) async {
    try {
      // Check if already in journey
      final existing = await _dao.getJourneyItemByEventId(event.eventId);
      if (existing != null) return;

      await _dao.addJourneyItem(
        eventId: event.eventId,
        status: JourneyStatus.wishlist,
        priority: event.priority,
      );

      add(const LoadJourney());
      
      // Schedule notifications for all journey items (including new wishlist item)
      await _scheduleNotificationsForJourney();
    } catch (e) {
      emit(JourneyError('Failed to add to wishlist: $e'));
    }
  }

  Future<void> _onAddToJourney(AddToJourney event, Emitter<JourneyState> emit) async {
    try {
      // Check if already in journey
      final existing = await _dao.getJourneyItemByEventId(event.eventId);
      if (existing != null) {
        // Update status to planned
        await _dao.updateStatus(existing.id, JourneyStatus.planned);
      } else {
        await _dao.addJourneyItem(
          eventId: event.eventId,
          status: JourneyStatus.planned,
          priority: event.priority,
        );
      }

      add(const LoadJourney());
      
      // Schedule notification for this event
      await _scheduleNotificationsForJourney();
    } catch (e) {
      emit(JourneyError('Failed to add to journey: $e'));
    }
  }

  Future<void> _onRemoveFromJourney(RemoveFromJourney event, Emitter<JourneyState> emit) async {
    try {
      await _dao.deleteJourneyItem(event.journeyItemId);
      add(const LoadJourney());
      
      // Reschedule notifications
      await _scheduleNotificationsForJourney();
    } catch (e) {
      emit(JourneyError('Failed to remove from journey: $e'));
    }
  }

  Future<void> _onMoveToJourney(MoveToJourney event, Emitter<JourneyState> emit) async {
    try {
      await _dao.moveToPlanned(event.journeyItemId);
      add(const LoadJourney());
      
      // Reschedule notifications
      await _scheduleNotificationsForJourney();
    } catch (e) {
      emit(JourneyError('Failed to move to journey: $e'));
    }
  }

  Future<void> _onMoveToWishlist(MoveToWishlist event, Emitter<JourneyState> emit) async {
    try {
      await _dao.moveToWishlist(event.journeyItemId);
      add(const LoadJourney());
      
      // Reschedule notifications
      await _scheduleNotificationsForJourney();
    } catch (e) {
      emit(JourneyError('Failed to move to wishlist: $e'));
    }
  }

  Future<void> _onUpdatePriority(UpdatePriority event, Emitter<JourneyState> emit) async {
    try {
      await _dao.updatePriority(event.journeyItemId, event.priority);
      add(const LoadJourney());
    } catch (e) {
      emit(JourneyError('Failed to update priority: $e'));
    }
  }

  Future<void> _onUpdateNotes(UpdateNotes event, Emitter<JourneyState> emit) async {
    try {
      await _dao.updateNotes(event.journeyItemId, event.notes);
      add(const LoadJourney());
    } catch (e) {
      emit(JourneyError('Failed to update notes: $e'));
    }
  }

  Future<void> _onUpdateStatus(UpdateStatus event, Emitter<JourneyState> emit) async {
    try {
      await _dao.updateStatus(event.journeyItemId, event.status);
      add(const LoadJourney());
    } catch (e) {
      emit(JourneyError('Failed to update status: $e'));
    }
  }

  Future<void> _onDetectConflicts(DetectConflicts event, Emitter<JourneyState> emit) async {
    if (state is JourneyLoaded) {
      final currentState = state as JourneyLoaded;
      final conflicts = _conflictDetector.detectConflicts(currentState.allItems);
      emit(currentState.copyWith(conflicts: conflicts));
    }
  }

  Future<void> _onUpdatePreferences(UpdatePreferences event, Emitter<JourneyState> emit) async {
    _preferences = event.preferences;
    _conflictDetector = ConflictDetectorService(_preferences);
    add(const DetectConflicts());
  }

  List<JourneyItem> _convertToJourneyItems(List<JourneyItemWithEvent> items) {
    return items.map((item) {
      final event = item.event;
      final journeyItem = item.journeyItem;

      // Parse building from room (e.g., "K.1.105" -> "K")
      final building = _extractBuilding(event.room);

      // Get location from building (you may need to fetch from buildings service)
      final location = _getLocationForBuilding(building);

      return JourneyItem(
        id: journeyItem.id,
        eventId: event.id,
        eventTitle: event.title,
        startTime: event.start,
        endTime: event.start.add(Duration(minutes: event.duration)),
        duration: Duration(minutes: event.duration),
        room: event.room,
        building: building,
        track: event.track,
        location: location,
        status: JourneyStatus.values.firstWhere(
          (s) => s.name == journeyItem.status,
          orElse: () => JourneyStatus.wishlist,
        ),
        priority: journeyItem.priority,
        addedAt: journeyItem.addedAt,
        notes: journeyItem.notes,
        tags: journeyItem.tags.isEmpty ? [] : List<String>.from(jsonDecode(journeyItem.tags)),
      );
    }).toList();
  }

  String _extractBuilding(String room) {
    if (room.isEmpty) return 'Unknown';
    
    // Handle formats like "K.1.105", "AW.1.120", "H.2.214"
    final parts = room.split('.');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    
    // Handle single letter buildings
    if (room.length == 1) {
      return room;
    }
    
    return room.split(' ').first;
  }

  LatLng _getLocationForBuilding(String building) {
    // Default FOSDEM location
    const defaultLocation = LatLng(50.8120, 4.3800);

    // Map of building coordinates (approximate ULB campus locations)
    final buildingLocations = <String, LatLng>{
      'K': const LatLng(50.8120, 4.3800),
      'H': const LatLng(50.8125, 4.3810),
      'AW': const LatLng(50.8115, 4.3790),
      'J': const LatLng(50.8130, 4.3805),
      'U': const LatLng(50.8110, 4.3795),
      'UA': const LatLng(50.8110, 4.3795),
      'UD': const LatLng(50.8108, 4.3792),
    };

    return buildingLocations[building] ?? defaultLocation;
  }

  /// Schedule notifications for ALL journey events (wishlist + planned)
  /// This ensures users get notified about all events in their journey
  Future<void> _scheduleNotificationsForJourney() async {
    if (notificationService == null) {
      print('⚠️ Journey: Notification service not available');
      return;
    }

    try {
      // Get ALL journey items (both wishlist and planned)
      final allItems = await _dao.getAllJourneyItems();

      // Convert to notification data
      final events = <JourneyEventData>[];
      for (final item in allItems) {
        events.add(JourneyEventData(
          eventId: item.event.id,
          title: item.event.title,
          room: item.event.room,
          startTime: item.event.start,
        ));
      }

      // Schedule notifications for all items
      await notificationService!.scheduleJourneyNotifications(events: events);
      
      print('✅ Journey: Scheduled ${events.length} notifications for all journey items (wishlist + planned)');
    } catch (e, stackTrace) {
      print('❌ Error scheduling notifications: $e');
      print('Stack trace: $stackTrace');
    }
  }
}
