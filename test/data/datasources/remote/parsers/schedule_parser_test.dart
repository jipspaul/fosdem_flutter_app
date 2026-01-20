import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/data/datasources/remote/parsers/schedule_parser.dart';

void main() {
  late ScheduleParser parser;

  setUp(() {
    parser = ScheduleParser();
  });

  group('ScheduleParser', () {
    test('should parse valid FOSDEM XML schedule', () {
      // Arrange
      const xmlData = '''
<?xml version="1.0" encoding="UTF-8"?>
<schedule>
  <conference>
    <title>FOSDEM 2025</title>
    <start>2025-02-01</start>
    <end>2025-02-02</end>
  </conference>
  <day index="1" date="2025-02-01">
    <room name="Janson">
      <event id="12345">
        <start>09:00</start>
        <duration>00:50</duration>
        <title>Welcome to FOSDEM</title>
        <subtitle>Opening Keynote</subtitle>
        <track>Keynotes</track>
        <type>keynote</type>
        <abstract>Welcome everyone to FOSDEM 2025</abstract>
        <description>This is the opening keynote for FOSDEM 2025.</description>
        <persons>
          <person id="1001">John Doe</person>
          <person id="1002">Jane Smith</person>
        </persons>
        <links>
          <link href="https://fosdem.org/2025">FOSDEM Website</link>
        </links>
        <attachments>
          <attachment href="/2025/slides.pdf">Slides</attachment>
        </attachments>
      </event>
    </room>
  </day>
</schedule>
''';

      // Act
      final result = parser.parseSchedule(xmlData);

      // Assert
      expect(result.name, 'FOSDEM 2025');
      expect(result.year, 2025);
      expect(result.events.length, 1);
      
      final event = result.events.first;
      expect(event.id, 12345);
      expect(event.title, 'Welcome to FOSDEM');
      expect(event.subtitle, 'Opening Keynote');
      expect(event.track, 'Keynotes');
      expect(event.room, 'Janson');
      expect(event.duration, 50);
      expect(event.people.length, 2);
      expect(event.links.length, 1);
      expect(event.attachments.length, 1);
    });

    test('should parse multiple events across multiple rooms', () {
      // Arrange
      const xmlData = '''
<?xml version="1.0" encoding="UTF-8"?>
<schedule>
  <conference>
    <title>FOSDEM 2025</title>
    <start>2025-02-01</start>
  </conference>
  <day index="1" date="2025-02-01">
    <room name="Janson">
      <event id="1">
        <start>09:00</start>
        <duration>00:50</duration>
        <title>Event 1</title>
        <track>Track A</track>
        <type>talk</type>
        <persons />
        <links />
        <attachments />
      </event>
    </room>
    <room name="K.1.105">
      <event id="2">
        <start>09:00</start>
        <duration>00:50</duration>
        <title>Event 2</title>
        <track>Track B</track>
        <type>talk</type>
        <persons />
        <links />
        <attachments />
      </event>
    </room>
  </day>
</schedule>
''';

      // Act
      final result = parser.parseSchedule(xmlData);

      // Assert
      expect(result.events.length, 2);
      expect(result.events[0].room, 'Janson');
      expect(result.events[1].room, 'K.1.105');
    });

    test('should handle empty persons, links, and attachments', () {
      // Arrange
      const xmlData = '''
<?xml version="1.0" encoding="UTF-8"?>
<schedule>
  <conference>
    <title>FOSDEM 2025</title>
    <start>2025-02-01</start>
  </conference>
  <day index="1" date="2025-02-01">
    <room name="Janson">
      <event id="123">
        <start>09:00</start>
        <duration>00:50</duration>
        <title>Simple Event</title>
        <track>Simple Track</track>
        <type>talk</type>
      </event>
    </room>
  </day>
</schedule>
''';

      // Act
      final result = parser.parseSchedule(xmlData);

      // Assert
      expect(result.events.length, 1);
      final event = result.events.first;
      expect(event.title, 'Simple Event');
      expect(event.people.length, 0);
      expect(event.links.length, 0);
      expect(event.attachments.length, 0);
    });

    test('should extract tracks from events', () {
      // Arrange
      const xmlData = '''
<?xml version="1.0" encoding="UTF-8"?>
<schedule>
  <conference>
    <title>FOSDEM 2025</title>
    <start>2025-02-01</start>
  </conference>
  <day index="1" date="2025-02-01">
    <room name="Janson">
      <event id="1">
        <start>09:00</start>
        <duration>00:50</duration>
        <title>Event 1</title>
        <track>Rust</track>
        <type>talk</type>
        <persons />
        <links />
        <attachments />
      </event>
      <event id="2">
        <start>10:00</start>
        <duration>00:50</duration>
        <title>Event 2</title>
        <track>Go</track>
        <type>talk</type>
        <persons />
        <links />
        <attachments />
      </event>
      <event id="3">
        <start>11:00</start>
        <duration>00:50</duration>
        <title>Event 3</title>
        <track>Rust</track>
        <type>talk</type>
        <persons />
        <links />
        <attachments />
      </event>
    </room>
  </day>
</schedule>
''';

      // Act
      final result = parser.parseSchedule(xmlData);

      // Assert
      expect(result.tracks.length, 2);
      expect(result.tracks.any((t) => t.name == 'Rust'), true);
      expect(result.tracks.any((t) => t.name == 'Go'), true);
    });

    test('should throw exception for invalid XML', () {
      // Arrange
      const invalidXml = 'This is not valid XML';

      // Act & Assert
      expect(
        () => parser.parseSchedule(invalidXml),
        throwsA(isA<Exception>()),
      );
    });

    test('should parse event times correctly', () {
      // Arrange
      const xmlData = '''
<?xml version="1.0" encoding="UTF-8"?>
<schedule>
  <conference>
    <title>FOSDEM 2025</title>
    <start>2025-02-01</start>
  </conference>
  <day index="1" date="2025-02-01">
    <room name="Janson">
      <event id="123">
        <start>14:30</start>
        <duration>01:15</duration>
        <title>Afternoon Talk</title>
        <track>Testing</track>
        <type>talk</type>
        <persons />
        <links />
        <attachments />
      </event>
    </room>
  </day>
</schedule>
''';

      // Act
      final result = parser.parseSchedule(xmlData);

      // Assert
      final event = result.events.first;
      expect(event.start.hour, 14);
      expect(event.start.minute, 30);
      expect(event.duration, 75); // 1 hour 15 minutes
    });

    test('should handle missing track gracefully', () {
      // Arrange
      const xmlData = '''
<?xml version="1.0" encoding="UTF-8"?>
<schedule>
  <conference>
    <title>FOSDEM 2025</title>
    <start>2025-02-01</start>
  </conference>
  <day index="1" date="2025-02-01">
    <room name="Janson">
      <event id="123">
        <start>09:00</start>
        <duration>00:50</duration>
        <title>Event without track</title>
        <type>talk</type>
        <persons />
        <links />
        <attachments />
      </event>
    </room>
  </day>
</schedule>
''';

      // Act
      final result = parser.parseSchedule(xmlData);

      // Assert
      final event = result.events.first;
      expect(event.track, 'Unknown');
    });
  });
}

