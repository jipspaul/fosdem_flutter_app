class DatabaseConstants {
  static const String databaseName = 'fosdem.db';
  static const int databaseVersion = 1;
  
  // Table names
  static const String eventsTable = 'events';
  static const String speakersTable = 'speakers';
  static const String roomsTable = 'rooms';
  static const String tracksTable = 'tracks';
  static const String bookmarksTable = 'bookmarks';
  static const String notificationsTable = 'notifications';
  
  // Column names - Events
  static const String eventId = 'id';
  static const String eventTitle = 'title';
  static const String eventSubtitle = 'subtitle';
  static const String eventDescription = 'description';
  static const String eventStart = 'start';
  static const String eventDuration = 'duration';
  static const String eventRoom = 'room';
  static const String eventTrack = 'track';
  static const String eventType = 'type';
  static const String eventUrl = 'url';
  static const String eventVideoUrl = 'video_url';
  
  // Column names - Bookmarks
  static const String bookmarkEventId = 'event_id';
  static const String bookmarkCreatedAt = 'created_at';
}
