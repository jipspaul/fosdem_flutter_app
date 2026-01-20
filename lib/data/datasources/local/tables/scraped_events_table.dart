import 'package:drift/drift.dart';

@DataClassName('ScrapedEventEntity')
class ScrapedEvents extends Table {
  IntColumn get eventId => integer()();
  TextColumn get scrapedAbstract => text().withDefault(const Constant(''))();
  TextColumn get scrapedDescription => text().withDefault(const Constant(''))();
  TextColumn get scrapedSpeakers => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get scrapedLinks => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get scrapedAttachments => text().withDefault(const Constant('[]'))(); // JSON array
  TextColumn get eventType => text().nullable()();
  TextColumn get language => text().nullable()();
  DateTimeColumn get scrapedAt => dateTime()(); // When data was scraped
  DateTimeColumn get expiresAt => dateTime().nullable()(); // Cache expiration
  
  @override
  Set<Column> get primaryKey => {eventId};
}
