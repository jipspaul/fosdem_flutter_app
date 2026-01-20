import 'package:xml/xml.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/track.dart';
import '../../domain/entities/person.dart';
import '../../domain/entities/link.dart';

class XCalParserService {
  Future<List<Event>> parseXCalString(String xmlContent) async {
    final document = XmlDocument.parse(xmlContent);
    final events = <Event>[];

    final vevents = document.findAllElements('vevent');
    
    for (final vevent in vevents) {
      try {
        final event = _parseEvent(vevent);
        if (event != null) {
          events.add(event);
        }
      } catch (e) {
        print('Error parsing event: $e');
      }
    }

    return events;
  }

  Event? _parseEvent(XmlElement vevent) {
    String? getValue(String tagName) {
      return vevent.findElements(tagName).firstOrNull?.innerText.trim();
    }

    final uid = getValue('uid');
    final summary = getValue('summary');
    final description = getValue('description');
    final dtstart = getValue('dtstart');
    final dtend = getValue('dtend');
    final duration = getValue('duration');
    final room = getValue('location');
    final trackName = getValue('categories');
    final url = getValue('url');
    final abstractText = getValue('abstract');
    
    // Debug: Check if URL was found
    if (url != null && url.isNotEmpty) {
      print('DEBUG XCalParser: Found URL for event "$summary": $url');
    } else {
      print('DEBUG XCalParser: NO URL found for event "$summary"');
    }

    if (uid == null || summary == null) {
      return null;
    }

    // Parse datetime
    final startDateTime = dtstart != null ? DateTime.tryParse(dtstart) : null;
    if (startDateTime == null) {
      return null; // Can't create event without start time
    }

    // Parse duration in minutes
    final durationMinutes = _parseDurationInMinutes(duration);

    // Parse persons
    final persons = <Person>[];
    final attendees = vevent.findElements('attendee');
    for (final attendee in attendees) {
      final name = attendee.innerText.trim();
      if (name.isNotEmpty) {
        persons.add(Person(
          id: name.hashCode,
          name: name,
        ));
      }
    }

    // Parse attachments/links
    final links = <Link>[];
    final attachments = vevent.findElements('attach');
    for (final attachment in attachments) {
      final href = attachment.innerText.trim();
      if (href.isNotEmpty) {
        links.add(Link(
          url: href,
          title: 'Attachment',
        ));
      }
    }
    if (url != null && url.isNotEmpty) {
      // Fix malformed URL (https:/fosdem.org -> https://fosdem.org)
      final fixedUrl = url.replaceFirst('https:/', 'https://');
      links.add(Link(
        url: fixedUrl,
        title: 'Event URL',
      ));
    }

    final parsedEvent = Event(
      id: uid.hashCode,
      title: summary,
      subtitle: abstractText,
      abstract: abstractText,
      description: description ?? '',
      date: DateTime(startDateTime.year, startDateTime.month, startDateTime.day),
      start: startDateTime,
      duration: durationMinutes,
      room: room ?? '',
      track: trackName ?? '',
      url: url != null && url.isNotEmpty ? url.replaceFirst('https:/', 'https://') : null,
      people: persons,
      links: links,
      isSync: false,
    );
    
    print('DEBUG XCalParser: Created Event - ID: ${parsedEvent.id}, Title: ${parsedEvent.title}, URL: ${parsedEvent.url}');
    return parsedEvent;
  }

  int _parseDurationInMinutes(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return 30; // Default 30min
    
    final duration = _parseDuration(durationStr);
    return duration?.inMinutes ?? 30;
  }

  Duration? _parseDuration(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) return null;
    
    // Parse ISO 8601 duration format (PT1H30M)
    final regex = RegExp(r'PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?');
    final match = regex.firstMatch(durationStr);
    
    if (match == null) return null;
    
    final hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    final minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final seconds = int.tryParse(match.group(3) ?? '0') ?? 0;
    
    return Duration(hours: hours, minutes: minutes, seconds: seconds);
  }

  List<Track> extractTracks(List<Event> events) {
    final trackSet = <String>{};
    
    for (final event in events) {
      if (event.track.isNotEmpty) {
        trackSet.add(event.track);
      }
    }
    
    // Return simple track list with just names
    return trackSet.map((name) => Track(name: name)).toList();
  }

  String _guessTrackType(String trackName) {
    final lower = trackName.toLowerCase();
    if (lower.contains('keynote')) return 'keynote';
    if (lower.contains('main')) return 'maintrack';
    if (lower.contains('developer')) return 'devroom';
    if (lower.contains('lightning')) return 'lightning';
    return 'devroom';
  }
}
