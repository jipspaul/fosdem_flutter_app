import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';
import 'package:http/http.dart' as http;
import '../../domain/entities/event_detail.dart';

class EventScraperService {
  final http.Client _client;
  static const String baseUrl = 'https://fosdem.org';

  EventScraperService(this._client);
  
  // Expose the HTTP client for URL lookup
  http.Client get httpClient => _client;

  /// Scrapes detailed event information from FOSDEM website
  Future<EventDetail> scrapeEventDetail(String eventUrl) async {
    try {
      print('DEBUG: Scraping URL: $eventUrl');
      final response = await _client.get(Uri.parse(eventUrl));
      
      print('DEBUG: Response status: ${response.statusCode}');
      print('DEBUG: Response body length: ${response.body.length}');
      
      if (response.statusCode != 200) {
        throw Exception('Failed to load event: ${response.statusCode}');
      }

      final document = html_parser.parse(response.body);
      print('DEBUG: Document parsed, title: ${document.querySelector('title')?.text}');
      
      final result = EventDetail(
        title: _extractTitle(document),
        subtitle: _extractSubtitle(document),
        abstract: _extractAbstract(document),
        description: _extractDescription(document),
        speakers: _extractSpeakers(document),
        track: _extractTrack(document),
        room: _extractRoom(document),
        day: _extractDay(document),
        startTime: _extractStartTime(document),
        duration: _extractDuration(document),
        eventType: _extractEventType(document),
        language: _extractLanguage(document),
        links: _extractLinks(document),
        attachments: _extractAttachments(document),
      );
      
      print('DEBUG: Extracted - title: ${result.title}, abstract length: ${result.abstract.length}, speakers: ${result.speakers.length}');
      
      return result;
    } catch (e) {
      print('DEBUG: Scraper error: $e');
      throw Exception('Failed to scrape event: $e');
    }
  }

  String _extractTitle(Document doc) {
    return doc.querySelector('h2')?.text.trim() ?? '';
  }

  String _extractSubtitle(Document doc) {
    return doc.querySelector('h3')?.text.trim() ?? '';
  }

  String _extractAbstract(Document doc) {
    final abstractDiv = doc.querySelector('.event-abstract');
    final result = abstractDiv?.text.trim() ?? '';
    print('DEBUG: Abstract found: "${result.substring(0, result.length > 50 ? 50 : result.length)}..."');
    return result;
  }

  String _extractDescription(Document doc) {
    final descDiv = doc.querySelector('.event-description');
    final result = descDiv?.text.trim() ?? '';
    print('DEBUG: Description found: "${result.substring(0, result.length > 50 ? 50 : result.length)}..."');
    return result;
  }

  List<EventSpeaker> _extractSpeakers(Document doc) {
    final speakers = <EventSpeaker>[];
    
    // Try multiple selectors for speakers
    var speakerLinks = doc.querySelectorAll('.event-blurb a[href*="/speakers/"]');
    if (speakerLinks.isEmpty) {
      speakerLinks = doc.querySelectorAll('a[href*="/speaker/"]');
    }
    if (speakerLinks.isEmpty) {
      speakerLinks = doc.querySelectorAll('.speakers a');
    }
    
    print('DEBUG: Found ${speakerLinks.length} speaker links');
    
    for (var link in speakerLinks) {
      final name = link.text.trim();
      if (name.isNotEmpty) {
        speakers.add(EventSpeaker(
          name: name,
          profileUrl: baseUrl + (link.attributes['href'] ?? ''),
        ));
      }
    }
    
    print('DEBUG: Extracted ${speakers.length} speakers');
    return speakers;
  }

  String _extractTrack(Document doc) {
    final trackSpan = doc.querySelector('.event-track');
    return trackSpan?.text.trim() ?? '';
  }

  String _extractRoom(Document doc) {
    final roomSpan = doc.querySelector('.event-room');
    return roomSpan?.text.trim() ?? '';
  }

  String _extractDay(Document doc) {
    final daySpan = doc.querySelector('.event-day');
    return daySpan?.text.trim() ?? '';
  }

  String _extractStartTime(Document doc) {
    final timeSpan = doc.querySelector('.event-start');
    return timeSpan?.text.trim() ?? '';
  }

  String _extractDuration(Document doc) {
    final durationSpan = doc.querySelector('.event-duration');
    return durationSpan?.text.trim() ?? '';
  }

  String _extractEventType(Document doc) {
    final typeSpan = doc.querySelector('.event-type');
    return typeSpan?.text.trim() ?? '';
  }

  String _extractLanguage(Document doc) {
    final langSpan = doc.querySelector('.event-language');
    return langSpan?.text.trim() ?? 'English';
  }

  List<EventLink> _extractLinks(Document doc) {
    final links = <EventLink>[];
    final linkElements = doc.querySelectorAll('.event-links a');
    
    for (var link in linkElements) {
      final href = link.attributes['href'];
      if (href != null) {
        links.add(EventLink(
          title: link.text.trim(),
          url: href.startsWith('http') ? href : baseUrl + href,
        ));
      }
    }
    
    return links;
  }

  List<EventAttachment> _extractAttachments(Document doc) {
    final attachments = <EventAttachment>[];
    final attachmentLinks = doc.querySelectorAll('.event-attachments a');
    
    for (var link in attachmentLinks) {
      final href = link.attributes['href'];
      if (href != null) {
        attachments.add(EventAttachment(
          title: link.text.trim(),
          url: href.startsWith('http') ? href : baseUrl + href,
        ));
      }
    }
    
    return attachments;
  }
}
