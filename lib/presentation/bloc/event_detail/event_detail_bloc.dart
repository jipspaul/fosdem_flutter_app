import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:drift/drift.dart';
import 'dart:convert';
import '../../../data/services/event_scraper_service.dart';
import '../../../data/datasources/local/database.dart';
import '../../../domain/entities/event_detail.dart';
import 'event_detail_event.dart';
import 'event_detail_state.dart';

class EventDetailBloc extends Bloc<EventDetailEvent, EventDetailState> {
  final EventScraperService _scraperService;
  final AppDatabase _database;

  EventDetailBloc(this._scraperService, this._database) : super(const EventDetailInitial()) {
    on<LoadEventDetail>(_onLoadEventDetail);
  }

  Future<void> _onLoadEventDetail(
    LoadEventDetail event,
    Emitter<EventDetailState> emit,
  ) async {
    emit(const EventDetailLoading());
    
    try {
      String? eventUrl = event.eventUrl;

      // If URL is missing, try to resolve from database (e.g. when opening from journey/Friends tab)
      if (eventUrl == null || eventUrl.isEmpty) {
        print('DEBUG: Event URL empty for event "${event.eventTitle}" (ID: ${event.eventId}), resolving from DB');
        final entity = await _database.eventsDao.getEventById(event.eventId.toString());
        if (entity != null && entity.url != null && entity.url!.trim().isNotEmpty) {
          eventUrl = entity.url!.trim();
          print('DEBUG: Resolved URL from DB: $eventUrl');
        }
      }

      if (eventUrl == null || eventUrl.isEmpty) {
        print('DEBUG: Event URL not available for event "${event.eventTitle}" (ID: ${event.eventId})');
        emit(const EventDetailError(
          'Event URL not available. Cannot load detailed information.'
        ));
        return;
      }

      // Fix malformed URLs (https:/fosdem.org -> https://fosdem.org)
      if (!eventUrl.startsWith('http://') && !eventUrl.startsWith('https://')) {
        eventUrl = 'https:$eventUrl';
      }
      
      // Try to load from cache first
      final cached = await _database.scrapedEventsDao.getValidScrapedEvent(event.eventId);
      if (cached != null) {
        print('DEBUG: Loading from cache for event ${event.eventId}');
        final eventDetail = _mapCachedToEventDetail(cached);
        emit(EventDetailLoaded(eventDetail));
        return;
      }
      
      print('DEBUG: Cache miss, scraping URL: $eventUrl');
      final eventDetail = await _scraperService.scrapeEventDetail(eventUrl);
      
      // Save to cache with 7 days expiration
      await _saveToCache(event.eventId, eventDetail);
      
      emit(EventDetailLoaded(eventDetail));
    } catch (e) {
      print('DEBUG: Scraper exception: $e');
      emit(EventDetailError('Failed to load event details: ${e.toString()}'));
    }
  }
  
  Future<void> _saveToCache(int eventId, dynamic eventDetail) async {
    try {
      final expiresAt = DateTime.now().add(const Duration(days: 7));
      
      await _database.scrapedEventsDao.upsertScrapedEvent(
        ScrapedEventsCompanion(
          eventId: Value(eventId),
          scrapedAbstract: Value(eventDetail.abstract),
          scrapedDescription: Value(eventDetail.description),
          scrapedSpeakers: Value(jsonEncode(
            eventDetail.speakers.map((s) => {'name': s.name}).toList()
          )),
          scrapedLinks: Value(jsonEncode(
            eventDetail.links.map((l) => {'url': l.url, 'title': l.title}).toList()
          )),
          scrapedAttachments: Value(jsonEncode(
            eventDetail.attachments.map((a) => {'url': a.url, 'title': a.title}).toList()
          )),
          eventType: Value(eventDetail.eventType),
          language: Value(eventDetail.language),
          scrapedAt: Value(DateTime.now()),
          expiresAt: Value(expiresAt),
        ),
      );
      print('DEBUG: Saved scraped data to cache, expires: $expiresAt');
    } catch (e) {
      print('DEBUG: Failed to save to cache: $e');
    }
  }
  
  EventDetail _mapCachedToEventDetail(ScrapedEventEntity cached) {
    final speakers = (jsonDecode(cached.scrapedSpeakers) as List)
        .map((s) => EventSpeaker(
              name: s['name'] as String,
              profileUrl: '',
            ))
        .toList();
    
    final links = (jsonDecode(cached.scrapedLinks) as List)
        .map((l) => EventLink(
              url: l['url'] as String,
              title: l['title'] as String,
            ))
        .toList();
    
    final attachments = (jsonDecode(cached.scrapedAttachments) as List)
        .map((a) => EventAttachment(
              url: a['url'] as String,
              title: a['title'] as String,
            ))
        .toList();
    
    return EventDetail(
      title: '',
      subtitle: '',
      abstract: cached.scrapedAbstract,
      description: cached.scrapedDescription,
      speakers: speakers,
      track: '',
      room: '',
      day: '',
      startTime: '',
      duration: '',
      eventType: cached.eventType ?? '',
      language: cached.language ?? '',
      links: links,
      attachments: attachments,
    );
  }
}
