import 'package:xml/xml.dart';
import '../../../models/event_model.dart';
import '../../../models/person_model.dart';
import '../../../models/link_model.dart';
import '../../../models/attachment_model.dart';
import '../../../models/track_model.dart';
import '../../../../core/errors/network_exceptions.dart';

class ParsedSchedule {
  final String name;
  final int year;
  final List<EventModel> events;
  final List<TrackModel> tracks;
  final DateTime lastUpdated;

  const ParsedSchedule({
    required this.name,
    required this.year,
    required this.events,
    required this.tracks,
    required this.lastUpdated,
  });
}

class ScheduleParser {
  /// Parse FOSDEM schedule XML format
  ParsedSchedule parseSchedule(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final scheduleElement = document.findElements('schedule').first;

      final events = <EventModel>[];
      final tracks = <String, TrackModel>{};

      // Parse conference info
      final conferenceElement = scheduleElement.findElements('conference').firstOrNull;
      final conferenceName = conferenceElement?.findElements('title').firstOrNull?.innerText ?? 'FOSDEM';
      final conferenceYear = conferenceElement?.findElements('start').firstOrNull?.innerText.substring(0, 4) ?? '2025';

      // Parse days
      for (final dayElement in scheduleElement.findElements('day')) {
        final dayIndex = int.tryParse(dayElement.getAttribute('index') ?? '0') ?? 0;
        final dayDate = dayElement.getAttribute('date') ?? '';

        // Parse rooms
        for (final roomElement in dayElement.findElements('room')) {
          final roomName = roomElement.getAttribute('name') ?? '';

          // Parse events
          for (final eventElement in roomElement.findElements('event')) {
            final event = _parseEvent(eventElement, dayIndex, dayDate, roomName);
            events.add(event);

            // Collect track info
            if (!tracks.containsKey(event.track)) {
              tracks[event.track] = TrackModel(
                name: event.track,
                day: dayIndex,
                date: _parseDate(dayDate),
              );
            }
          }
        }
      }

      return ParsedSchedule(
        name: conferenceName,
        year: int.tryParse(conferenceYear) ?? 2025,
        events: events,
        tracks: tracks.values.toList(),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      throw ParseException(
        message: 'Failed to parse schedule XML: $e',
        originalError: e,
      );
    }
  }

  EventModel _parseEvent(
    XmlElement eventElement,
    int dayIndex,
    String dayDate,
    String roomName,
  ) {
    final id = int.tryParse(eventElement.getAttribute('id') ?? '0') ?? 0;
    final title = eventElement.findElements('title').firstOrNull?.innerText ?? '';
    final subtitle = eventElement.findElements('subtitle').firstOrNull?.innerText;
    final track = eventElement.findElements('track').firstOrNull?.innerText ?? 'Unknown';
    final abstract = eventElement.findElements('abstract').firstOrNull?.innerText;
    final description = eventElement.findElements('description').firstOrNull?.innerText;
    final duration = eventElement.findElements('duration').firstOrNull?.innerText ?? '00:50';
    final startTime = eventElement.findElements('start').firstOrNull?.innerText ?? '09:00';

    // Parse persons
    final people = <PersonModel>[];
    final personsElement = eventElement.findElements('persons').firstOrNull;
    if (personsElement != null) {
      for (final personElement in personsElement.findElements('person')) {
        people.add(_parsePerson(personElement));
      }
    }

    // Parse links
    final links = <LinkModel>[];
    final linksElement = eventElement.findElements('links').firstOrNull;
    if (linksElement != null) {
      for (final linkElement in linksElement.findElements('link')) {
        links.add(_parseLink(linkElement));
      }
    }

    // Parse attachments
    final attachments = <AttachmentModel>[];
    final attachmentsElement = eventElement.findElements('attachments').firstOrNull;
    if (attachmentsElement != null) {
      for (final attachmentElement in attachmentsElement.findElements('attachment')) {
        attachments.add(_parseAttachment(attachmentElement));
      }
    }

    // Calculate start and end times
    final date = _parseDate(dayDate);
    final startDateTime = _parseDateTime(dayDate, startTime);
    final durationMinutes = _parseDuration(duration);

    return EventModel(
      id: id,
      title: title,
      subtitle: subtitle,
      abstract: abstract,
      description: description,
      room: roomName,
      track: track,
      date: date,
      start: startDateTime,
      duration: durationMinutes,
      people: people,
      links: links,
      attachments: attachments,
    );
  }

  PersonModel _parsePerson(XmlElement personElement) {
    final id = int.tryParse(personElement.getAttribute('id') ?? '0') ?? 0;
    final name = personElement.innerText;

    return PersonModel(
      id: id,
      name: name,
    );
  }

  LinkModel _parseLink(XmlElement linkElement) {
    final url = linkElement.getAttribute('href') ?? '';
    final title = linkElement.innerText;

    return LinkModel(
      url: url,
      title: title,
    );
  }

  AttachmentModel _parseAttachment(XmlElement attachmentElement) {
    final url = attachmentElement.getAttribute('href') ?? '';
    final title = attachmentElement.innerText;
    final typeString = _getAttachmentTypeString(url);

    return AttachmentModel(
      url: url,
      title: title,
      type: AttachmentType.fromString(typeString),
    );
  }

  String _getAttachmentTypeString(String url) {
    if (url.endsWith('.pdf')) return 'pdf';
    if (url.endsWith('.mp4') || url.endsWith('.webm')) return 'video';
    if (url.endsWith('.mp3') || url.endsWith('.ogg')) return 'audio';
    return 'other';
  }

  DateTime _parseDate(String date) {
    try {
      return DateTime.parse(date);
    } catch (e) {
      return DateTime.now();
    }
  }

  DateTime _parseDateTime(String date, String time) {
    try {
      final dateParts = date.split('-');
      final timeParts = time.split(':');

      return DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
    } catch (e) {
      return DateTime.now();
    }
  }

  int _parseDuration(String duration) {
    try {
      final parts = duration.split(':');
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      return hours * 60 + minutes;
    } catch (e) {
      return 50; // Default duration
    }
  }
}
