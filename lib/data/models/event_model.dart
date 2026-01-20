import 'package:equatable/equatable.dart';
import 'person_model.dart';
import 'link_model.dart';
import 'attachment_model.dart';

class EventModel extends Equatable {
  final int id;
  final String title;
  final String? subtitle;
  final String? abstract;
  final String? description;
  final String room;
  final String track;
  final DateTime date;
  final DateTime start;
  final int duration; // Duration in minutes
  final String? url;
  final List<PersonModel> people;
  final List<LinkModel> links;
  final List<AttachmentModel> attachments;

  const EventModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.abstract,
    this.description,
    required this.room,
    required this.track,
    required this.date,
    required this.start,
    required this.duration,
    this.url,
    this.people = const [],
    this.links = const [],
    this.attachments = const [],
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as int,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      abstract: json['abstract'] as String?,
      description: json['description'] as String?,
      room: json['room'] as String,
      track: json['track'] as String,
      date: DateTime.parse(json['date'] as String),
      start: DateTime.parse(json['start'] as String),
      duration: json['duration'] as int,
      url: json['url'] as String?,
      people: (json['persons'] as List<dynamic>?)
              ?.map((p) => PersonModel.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      links: (json['links'] as List<dynamic>?)
              ?.map((l) => LinkModel.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((a) => AttachmentModel.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'abstract': abstract,
      'description': description,
      'room': room,
      'track': track,
      'date': date.toIso8601String(),
      'start': start.toIso8601String(),
      'duration': duration,
      'url': url,
      'persons': people.map((p) => p.toJson()).toList(),
      'links': links.map((l) => l.toJson()).toList(),
      'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  DateTime get end => start.add(Duration(minutes: duration));

  bool get hasVideo => links.any((link) => link.isVideo);

  bool get hasAttachments => attachments.isNotEmpty;

  bool isHappeningNow() {
    final now = DateTime.now();
    return now.isAfter(start) && now.isBefore(end);
  }

  bool isUpcoming() {
    return DateTime.now().isBefore(start);
  }

  bool isPast() {
    return DateTime.now().isAfter(end);
  }

  bool isOnDay(DateTime day) {
    return date.year == day.year &&
        date.month == day.month &&
        date.day == day.day;
  }

  bool conflictsWith(EventModel other) {
    return (start.isBefore(other.end) && end.isAfter(other.start));
  }

  EventModel copyWith({
    int? id,
    String? title,
    String? subtitle,
    String? abstract,
    String? description,
    String? room,
    String? track,
    DateTime? date,
    DateTime? start,
    int? duration,
    String? url,
    List<PersonModel>? people,
    List<LinkModel>? links,
    List<AttachmentModel>? attachments,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      abstract: abstract ?? this.abstract,
      description: description ?? this.description,
      room: room ?? this.room,
      track: track ?? this.track,
      date: date ?? this.date,
      start: start ?? this.start,
      duration: duration ?? this.duration,
      url: url ?? this.url,
      people: people ?? this.people,
      links: links ?? this.links,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        abstract,
        description,
        room,
        track,
        date,
        start,
        duration,
        url,
        people,
        links,
        attachments,
      ];
}
