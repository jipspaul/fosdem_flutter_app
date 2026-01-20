import 'package:equatable/equatable.dart';
import 'person.dart';
import 'link.dart';
import 'attachment.dart';

class Event extends Equatable {
  final int id;
  final String title;
  final String? subtitle;
  final String? abstract;
  final String? description;
  final String room;
  final String track;
  final DateTime date;
  final DateTime start;
  final int duration;
  final String? url;
  final List<Person> people;
  final List<Link> links;
  final List<Attachment> attachments;
  final bool isSync;

  const Event({
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
    required this.isSync,
  });

  DateTime get end => start.add(Duration(minutes: duration));

  bool get hasVideo => links.any((link) => link.isVideo);

  bool get hasAttachments => attachments.isNotEmpty;

  bool get hasSpeakers => people.isNotEmpty;

  String get durationText {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

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

  bool conflictsWith(Event other) {
    return (start.isBefore(other.end) && end.isAfter(other.start));
  }

  Event copyWith({
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
    List<Person>? people,
    List<Link>? links,
    List<Attachment>? attachments,
    bool? isSync,
  }) {
    return Event(
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
      isSync: isSync ?? this.isSync,
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
        isSync,
      ];

  @override
  String toString() => 'Event(id: $id, title: $title, track: $track)';
}
