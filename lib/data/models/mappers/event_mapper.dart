import '../../datasources/local/database.dart';
import '../../../domain/entities/event.dart';
import '../../../domain/entities/person.dart';
import '../../../domain/entities/link.dart';
import '../../../domain/entities/attachment.dart';
import 'package:drift/drift.dart' hide JsonKey;
import 'dart:convert';

extension EventEntityMapper on EventEntity {
  Event toEntity() {
    // Parse JSON fields
    final peopleJson = jsonDecode(people) as List;
    final linksJson = jsonDecode(links) as List;
    final attachmentsJson = jsonDecode(attachments) as List;
    
    return Event(
      id: id,
      title: title,
      subtitle: subtitle,
      abstract: abstract,
      description: description,
      room: room,
      track: track,
      date: date,
      start: start,
      duration: duration,
      url: url,
      people: peopleJson.map((p) => Person(
        id: p['id'] as int,
        name: p['name'] as String,
      )).toList(),
      links: linksJson.map((l) => Link(
        url: l['url'] as String,
        title: l['title'] as String,
        isVideo: l['isVideo'] as bool? ?? false,
      )).toList(),
      attachments: attachmentsJson.map((a) => Attachment(
        url: a['url'] as String,
        title: a['title'] as String,
        type: AttachmentType.document,
      )).toList(),
      isSync: false,
    );
  }
}

extension EventModelMapper on Event {
  EventsCompanion toCompanion() {
    // Convert lists to JSON strings
    final peopleJson = jsonEncode(people.map((p) => {
      'id': p.id,
      'name': p.name,
    }).toList());
    final linksJson = jsonEncode(links.map((l) => {
      'url': l.url,
      'title': l.title,
      'isVideo': l.isVideo,
    }).toList());
    final attachmentsJson = jsonEncode(attachments.map((a) => {
      'url': a.url,
      'title': a.title,
    }).toList());
    
    return EventsCompanion(
      id: Value(id),
      title: Value(title),
      subtitle: Value(subtitle),
      abstract: Value(abstract),
      description: Value(description),
      room: Value(room),
      track: Value(track),
      date: Value(date),
      start: Value(start),
      duration: Value(duration),
      url: Value(url),
      people: Value(peopleJson),
      links: Value(linksJson),
      attachments: Value(attachmentsJson),
    );
  }
}

