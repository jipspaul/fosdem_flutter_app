class ApiConstants {
  static const String baseUrl = 'https://fosdem.org';
  static const String scheduleXmlUrl = '$baseUrl/2025/schedule/xml';
  static const String scheduleJsonUrl = '$baseUrl/2025/schedule/json';
  
  // Endpoints
  static const String eventsEndpoint = '/schedule/events';
  static const String speakersEndpoint = '/schedule/speakers';
  static const String roomsEndpoint = '/schedule/rooms';
  static const String tracksEndpoint = '/schedule/tracks';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
