import '../datasources/local/database.dart';
import '../datasources/remote/fosdem_api.dart';
import '../../domain/entities/event_domain.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/attachment.dart';
import 'package:drift/drift.dart';
import 'dart:convert';

class EventRepository {
  final AppDatabase database;
  final FosdemApi api;

  EventRepository({
    required this.database,
    required this.api,
  });

  Future<List<EventDomain>> getEvents() async {
    final events = await database.eventsDao.getAllEvents();
    return events.map(_mapToDomain).toList();
  }

  Future<List<EventDomain>> getEventsByTrack(String trackId) async {
    final events = await database.eventsDao.getEventsByTrack(trackId);
    return events.map(_mapToDomain).toList();
  }

  Future<List<EventDomain>> getEventsByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final allEvents = await database.eventsDao.getAllEvents();
    final filteredEvents = allEvents.where((event) {
      final eventDate = event.start;
      return eventDate.isAfter(startOfDay) && eventDate.isBefore(endOfDay);
    }).toList();
    
    return filteredEvents.map(_mapToDomain).toList();
  }

  Future<List<EventDomain>> searchEvents(String query) async {
    final events = await database.eventsDao.searchEvents(query);
    return events.map(_mapToDomain).toList();
  }

  Future<List<EventDomain>> getFavoriteEvents() async {
    final events = await database.eventsDao.getFavoriteEvents();
    return events.map(_mapToDomain).toList();
  }

  Future<Event?> getEventById(int id) async {
    final event = await database.eventsDao.getEventById(id.toString());
    if (event == null) return null;
    return _mapToEvent(event);
  }

  Future<void> addFavorite(String eventId) async {
    await database.eventsDao.setFavorite(eventId, true);
  }

  Future<void> removeFavorite(String eventId) async {
    await database.eventsDao.setFavorite(eventId, false);
  }

  Future<void> syncEvents() async {
    // This would be implemented to fetch from API
    // For now, just a placeholder
  }

  // Methods for data loading
  Future<List<Event>> getAll() async {
    final events = await database.eventsDao.getAllEvents();
    return events.map(_mapToEvent).toList();
  }

  Future<void> create(Event event) async {
    // Convert lists to JSON strings
    final peopleJson = jsonEncode(event.people.map((p) => {'id': p.id, 'name': p.name}).toList());
    final linksJson = jsonEncode(event.links.map((l) => {'url': l.url, 'title': l.title, 'isVideo': l.isVideo}).toList());
    final attachmentsJson = jsonEncode(event.attachments.map((a) => {'url': a.url, 'title': a.title}).toList());
    
    print('DEBUG EventRepository: Creating event ID ${event.id} "${event.title}" with URL: ${event.url}');
    
    await database.eventsDao.insertEvent(EventsCompanion.insert(
      id: Value(event.id),
      title: event.title,
      subtitle: Value(event.subtitle),
      abstract: Value(event.abstract),
      description: Value(event.description),
      room: event.room,
      track: event.track,
      date: event.date,
      start: event.start,
      duration: event.duration,
      url: Value(event.url),
      people: peopleJson,
      links: linksJson,
      attachments: attachmentsJson,
    ));
  }

  Future<void> upsert(Event event) async {
    // Convert lists to JSON strings
    final peopleJson = jsonEncode(event.people.map((p) => {'id': p.id, 'name': p.name}).toList());
    final linksJson = jsonEncode(event.links.map((l) => {'url': l.url, 'title': l.title, 'isVideo': l.isVideo}).toList());
    final attachmentsJson = jsonEncode(event.attachments.map((a) => {'url': a.url, 'title': a.title}).toList());
    
    print('DEBUG EventRepository: Upserting event ID ${event.id} "${event.title}" (preserving favorites)');
    
    await database.eventsDao.upsertEvent(EventsCompanion.insert(
      id: Value(event.id),
      title: event.title,
      subtitle: Value(event.subtitle),
      abstract: Value(event.abstract),
      description: Value(event.description),
      room: event.room,
      track: event.track,
      date: event.date,
      start: event.start,
      duration: event.duration,
      url: Value(event.url),
      people: peopleJson,
      links: linksJson,
      attachments: attachmentsJson,
    ));
  }

  Future<void> deleteAll() async {
    await database.eventsDao.deleteAllEvents();
  }
  
  EventDomain _mapToDomain(EventEntity entity) {
    return EventDomain(
      id: entity.id,
      title: entity.title,
      subtitle: entity.subtitle,
      track: entity.track,
      type: 'lecture', // Default type - could be parsed from track
      startTime: entity.start,
      endTime: entity.start.add(Duration(minutes: entity.duration)),
      duration: entity.duration,
      room: entity.room,
      abstract: entity.abstract,
      description: entity.description,
      url: entity.url,
      day: entity.date.day,
      isFavorite: entity.isFavorite,
      isNotified: false,
    );
  }

  Event _mapToEvent(EventEntity entity) {
    // Parse JSON fields
    final peopleJson = jsonDecode(entity.people) as List;
    final linksJson = jsonDecode(entity.links) as List;
    final attachmentsJson = jsonDecode(entity.attachments) as List;
    
    return Event(
      id: entity.id,
      title: entity.title,
      subtitle: (entity.subtitle != null && entity.subtitle!.isNotEmpty) ? entity.subtitle : null,
      abstract: (entity.abstract != null && entity.abstract!.isNotEmpty) ? entity.abstract : null,
      description: entity.description ?? '',
      room: entity.room,
      track: entity.track,
      date: entity.date,
      start: entity.start,
      duration: entity.duration,
      url: entity.url,  // IMPORTANT: Include the URL!
      people: peopleJson.map((p) => Person(id: p['id'] as int, name: p['name'] as String)).toList(),
      links: linksJson.map((l) => Link(url: l['url'] as String, title: l['title'] as String)).toList(),
      attachments: attachmentsJson.map((a) => Attachment(
        url: a['url'] as String, 
        title: a['title'] as String,
        type: AttachmentType.document, // Default type
      )).toList(),
      isSync: false,
    );
  }
}

