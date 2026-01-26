import '../datasources/local/database.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/link.dart';
import '../../domain/entities/attachment.dart';
import 'dart:convert';

class FavoritesRepository {
  final AppDatabase _database;

  FavoritesRepository(this._database);

  Future<List<Event>> getFavorites() async {
    final favorites = await _database.eventsDao.getFavoriteEvents();
    return favorites.map((e) => _entityToEvent(e)).toList();
  }

  Future<void> addFavorite(int eventId) async {
    await _database.favoritesDao.addFavorite(eventId);
  }

  Future<void> removeFavorite(int eventId) async {
    await _database.favoritesDao.removeFavorite(eventId);
  }

  Future<bool> isFavorite(int eventId) async {
    return await _database.favoritesDao.isFavorite(eventId);
  }

  Stream<List<Event>> watchFavorites() {
    return _database.eventsDao.watchFavoriteEvents().map(
          (events) => events.map((e) => _entityToEvent(e)).toList(),
        );
  }

  Event _entityToEvent(EventEntity entity) {
    return Event(
      id: entity.id,
      title: entity.title,
      subtitle: entity.subtitle,
      abstract: entity.abstract,
      description: entity.description,
      room: entity.room,
      track: entity.track,
      date: entity.date,
      start: entity.start,
      duration: entity.duration,
      url: entity.url,
      people: _parsePeople(entity.people),
      links: _parseLinks(entity.links),
      attachments: _parseAttachments(entity.attachments),
      isSync: false,
    );
  }

  List<Person> _parsePeople(String json) {
    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((p) => Person(
        id: p['id'] ?? 0,
        name: p['name'] ?? '',
      )).toList();
    } catch (e) {
      return [];
    }
  }

  List<Link> _parseLinks(String json) {
    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((l) => Link(
        title: l['title'] ?? '',
        url: l['href'] ?? l['url'] ?? '',
        isVideo: l['isVideo'] ?? false,
      )).toList();
    } catch (e) {
      return [];
    }
  }

  List<Attachment> _parseAttachments(String json) {
    try {
      final List<dynamic> list = jsonDecode(json);
      return list.map((a) => Attachment(
        title: a['title'] ?? '',
        url: a['href'] ?? a['url'] ?? '',
        type: _parseAttachmentType(a['type']),
      )).toList();
    } catch (e) {
      return [];
    }
  }
  
  AttachmentType _parseAttachmentType(dynamic type) {
    if (type == null) return AttachmentType.other;
    final typeStr = type.toString().toLowerCase();
    if (typeStr.contains('slide')) return AttachmentType.slides;
    if (typeStr.contains('video')) return AttachmentType.video;
    if (typeStr.contains('audio')) return AttachmentType.audio;
    if (typeStr.contains('doc') || typeStr.contains('pdf')) return AttachmentType.document;
    return AttachmentType.other;
  }
}
