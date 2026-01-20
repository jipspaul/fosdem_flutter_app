import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/data/models/event_model.dart';
import 'package:fosdem_flutter/data/models/person_model.dart';
import 'package:fosdem_flutter/data/models/link_model.dart';
import 'package:fosdem_flutter/data/models/attachment_model.dart';

void main() {
  group('EventModel', () {
    final testDate = DateTime(2025, 2, 1);
    final testStart = DateTime(2025, 2, 1, 10, 0);
    
    final sampleEvent = EventModel(
      id: 1,
      title: 'Test Event',
      subtitle: 'A test subtitle',
      room: 'H.1302',
      track: 'Testing',
      date: testDate,
      start: testStart,
      duration: 45,
    );

    test('creates event with required fields', () {
      expect(sampleEvent.id, 1);
      expect(sampleEvent.title, 'Test Event');
      expect(sampleEvent.room, 'H.1302');
      expect(sampleEvent.track, 'Testing');
      expect(sampleEvent.duration, 45);
    });

    test('calculates end time correctly', () {
      final expectedEnd = testStart.add(const Duration(minutes: 45));
      expect(sampleEvent.end, expectedEnd);
    });

    test('isPast returns true for past event', () {
      final pastEvent = EventModel(
        id: 1,
        title: 'Past Event',
        room: 'H.1302',
        track: 'Testing',
        date: DateTime(2020, 1, 1),
        start: DateTime(2020, 1, 1, 10, 0),
        duration: 45,
      );
      expect(pastEvent.isPast(), true);
    });

    test('isUpcoming returns true for future event', () {
      final futureEvent = EventModel(
        id: 1,
        title: 'Future Event',
        room: 'H.1302',
        track: 'Testing',
        date: DateTime(2030, 1, 1),
        start: DateTime(2030, 1, 1, 10, 0),
        duration: 45,
      );
      expect(futureEvent.isUpcoming(), true);
    });

    test('isOnDay returns true for same day', () {
      expect(sampleEvent.isOnDay(testDate), true);
      expect(sampleEvent.isOnDay(DateTime(2025, 2, 2)), false);
    });

    test('conflictsWith detects overlapping events', () {
      final overlappingEvent = EventModel(
        id: 2,
        title: 'Overlapping Event',
        room: 'H.1303',
        track: 'Testing',
        date: testDate,
        start: DateTime(2025, 2, 1, 10, 30),
        duration: 45,
      );
      expect(sampleEvent.conflictsWith(overlappingEvent), true);
    });

    test('conflictsWith returns false for non-overlapping events', () {
      final laterEvent = EventModel(
        id: 2,
        title: 'Later Event',
        room: 'H.1303',
        track: 'Testing',
        date: testDate,
        start: DateTime(2025, 2, 1, 11, 0),
        duration: 45,
      );
      expect(sampleEvent.conflictsWith(laterEvent), false);
    });

    test('hasVideo returns true when links contain video', () {
      final eventWithVideo = sampleEvent.copyWith(
        links: [
          LinkModel(
            title: 'Video',
            url: 'https://youtube.com/watch?v=123',
            isVideo: true,
          ),
        ],
      );
      expect(eventWithVideo.hasVideo, true);
    });

    test('toJson and fromJson work correctly', () {
      final json = sampleEvent.toJson();
      final decoded = EventModel.fromJson(json);
      
      expect(decoded.id, sampleEvent.id);
      expect(decoded.title, sampleEvent.title);
      expect(decoded.room, sampleEvent.room);
    });

    test('equality works correctly', () {
      final event1 = EventModel(
        id: 1,
        title: 'Event',
        room: 'H.1302',
        track: 'Testing',
        date: testDate,
        start: testStart,
        duration: 45,
      );
      
      final event2 = EventModel(
        id: 1,
        title: 'Event',
        room: 'H.1302',
        track: 'Testing',
        date: testDate,
        start: testStart,
        duration: 45,
      );
      
      expect(event1, event2);
    });
  });
}
