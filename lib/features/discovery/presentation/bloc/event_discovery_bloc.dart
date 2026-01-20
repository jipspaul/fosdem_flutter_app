import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/local/database.dart';
import '../../../../domain/entities/event_domain.dart';
import '../../../../data/repositories/event_repository.dart';
import '../../../../presentation/bloc/favorites/favorites_bloc.dart';
import '../../../../presentation/bloc/favorites/favorites_event.dart';
import 'event_discovery_event.dart';
import 'event_discovery_state.dart';

class EventDiscoveryBloc extends Bloc<EventDiscoveryEvent, EventDiscoveryState> {
  final EventRepository eventRepository;
  final FavoritesBloc? favoritesBloc;
  List<EventDomain> _unseenEvents = [];
  int _totalSeen = 0;
  final Random _random = Random();

  EventDiscoveryBloc({required this.eventRepository, this.favoritesBloc}) : super(EventDiscoveryInitial()) {
    on<LoadNextEvent>(_onLoadNextEvent);
    on<SwipeLeft>(_onSwipeLeft);
    on<SwipeRight>(_onSwipeRight);
    on<SkipEvent>(_onSkipEvent);
    on<ResetDiscovery>(_onResetDiscovery);
  }

  Future<void> _onLoadNextEvent(LoadNextEvent event, Emitter<EventDiscoveryState> emit) async {
    try {
      emit(EventDiscoveryLoading());

      if (_unseenEvents.isEmpty) {
        // Load unseen events
        final seenEventIds = await eventRepository.database.swipeHistoryDao.getSeenEventIds();
        print('DEBUG: Loaded ${seenEventIds.length} seen event IDs from history');
        
        // Get all events as EventDomain
        final allEvents = await eventRepository.getEvents();
        print('DEBUG: Total events in database: ${allEvents.length}');
        
        // Filter out seen events (use string comparison for consistency)
        _unseenEvents = allEvents
            .where((e) => !seenEventIds.contains(e.id.toString()))
            .toList();
        
        print('DEBUG: Unseen events after filtering: ${_unseenEvents.length}');
        
        // Shuffle for random order
        _unseenEvents.shuffle(_random);

        _totalSeen = seenEventIds.length;
      }

      if (_unseenEvents.isEmpty) {
        emit(const EventDiscoveryEmpty('🎉 You\'ve seen all events! Reset to start again.'));
        return;
      }

      final currentEvent = _unseenEvents.first;
      print('DEBUG: Showing event: ${currentEvent.title} (${currentEvent.id})');
      emit(EventDiscoveryLoaded(
        currentEvent: currentEvent,
        remainingCount: _unseenEvents.length - 1,
        totalSeen: _totalSeen,
      ));
    } catch (e) {
      print('ERROR: Error loading next event: $e');
      emit(EventDiscoveryError('Error loading events: $e'));
    }
  }

  Future<void> _onSwipeLeft(SwipeLeft event, Emitter<EventDiscoveryState> emit) async {
    try {
      print('DEBUG: Swiping left on event: ${event.eventId}');
      await eventRepository.database.swipeHistoryDao.recordSwipe(event.eventId, 'dislike');
      _unseenEvents.removeWhere((e) => e.id.toString() == event.eventId);
      _totalSeen++;
      print('DEBUG: Swipe recorded. Total seen: $_totalSeen, Remaining: ${_unseenEvents.length}');
      add(LoadNextEvent());
    } catch (e) {
      print('ERROR: Error recording swipe left: $e');
      emit(EventDiscoveryError('Error recording swipe: $e'));
    }
  }

  Future<void> _onSwipeRight(SwipeRight event, Emitter<EventDiscoveryState> emit) async {
    try {
      print('DEBUG: Recording swipe right for event: ${event.eventId}');
      
      // Add to favorites using repository
      await eventRepository.addFavorite(event.eventId);
      print('DEBUG: Added event ${event.eventId} to favorites');
      
      // Trigger FavoritesBloc reload
      favoritesBloc?.add(const LoadFavorites());
      print('DEBUG: Triggered FavoritesBloc reload');
      
      // Record in swipe history
      await eventRepository.database.swipeHistoryDao.recordSwipe(event.eventId, 'like');
      
      _unseenEvents.removeWhere((e) => e.id.toString() == event.eventId);
      _totalSeen++;
      print('DEBUG: Swipe recorded. Total seen: $_totalSeen, Remaining: ${_unseenEvents.length}');
      add(LoadNextEvent());
    } catch (e) {
      print('ERROR: Error recording swipe right: $e');
      emit(EventDiscoveryError('Error recording swipe: $e'));
    }
  }

  Future<void> _onSkipEvent(SkipEvent event, Emitter<EventDiscoveryState> emit) async {
    try {
      await eventRepository.database.swipeHistoryDao.recordSwipe(event.eventId, 'skip');
      _unseenEvents.removeWhere((e) => e.id.toString() == event.eventId);
      _totalSeen++;
      add(LoadNextEvent());
    } catch (e) {
      emit(EventDiscoveryError('Error skipping event: $e'));
    }
  }

  Future<void> _onResetDiscovery(ResetDiscovery event, Emitter<EventDiscoveryState> emit) async {
    try {
      await eventRepository.database.swipeHistoryDao.clearHistory();
      _unseenEvents.clear();
      _totalSeen = 0;
      add(LoadNextEvent());
    } catch (e) {
      emit(EventDiscoveryError('Error resetting discovery: $e'));
    }
  }
}
