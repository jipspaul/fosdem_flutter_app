class ApiEndpoints {
  // Base URLs
  static const String baseUrl = 'https://fosdem.org';
  static const String scheduleBaseUrl = 'https://fosdem.org';
  static const String videoBaseUrl = 'https://video.fosdem.org';

  // Schedule endpoints
  static String scheduleXml(int year) => '/$year/schedule/xml';
  static String scheduleJson(int year) => '/$year/schedule/json';
  static const String latestSchedule = '/schedule/xml';

  // Event endpoints
  static String eventDetails(int year, String eventId) =>
      '/$year/schedule/event/$eventId/';

  // Track endpoints
  static String trackSchedule(int year, String trackName) =>
      '/$year/schedule/track/$trackName.xml';

  // Building and map endpoints
  static String buildingMap(String buildingName) =>
      '/schedule/buildings/$buildingName.json';
  static const String allBuildings = '/schedule/buildings.json';

  // Video endpoints
  static String videoUrl(int year, String eventId) =>
      '$videoBaseUrl/$year/$eventId.webm';
  static String videoMetadata(int year, String eventId) =>
      '$videoBaseUrl/$year/$eventId.json';

  // Attachment endpoints
  static String attachmentUrl(String attachmentPath) =>
      '$baseUrl$attachmentPath';

  // API version
  static const String apiVersion = '2025';
  static const int currentYear = 2025;

  // Timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Retry settings
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Cache settings
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100 MB
}
