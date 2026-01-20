import '../../../core/services/http_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/network_exceptions.dart';
import 'parsers/schedule_parser.dart';
import '../../../domain/entities/schedule_entity.dart';
import '../../../domain/entities/event_domain.dart';

class ScheduleApi {
  final HttpClient _httpClient;
  final ScheduleParser _parser;

  ScheduleApi({
    required HttpClient httpClient,
    ScheduleParser? parser,
  })  : _httpClient = httpClient,
        _parser = parser ?? ScheduleParser();

  /// Fetch FOSDEM schedule for a specific year
  Future<ScheduleEntity> fetchSchedule(int year) async {
    try {
      final response = await _httpClient.get(
        ApiEndpoints.scheduleXml(year),
      );

      if (response.data == null) {
        throw const ParseException(
          message: 'Empty response from server',
        );
      }

      final parsed = _parser.parseSchedule(response.data.toString());
      
      // Convert ParsedSchedule to ScheduleEntity
      return ScheduleEntity(
        id: year,
        name: parsed.name,
        year: parsed.year,
        events: parsed.events.map((e) => _toEventEntity(e)).toList(),
        tracks: parsed.tracks,
        lastUpdated: parsed.lastUpdated,
      );
    } catch (e) {
      throw NetworkExceptionHandler.handleError(e);
    }
  }

  /// Fetch latest schedule
  Future<ScheduleEntity> fetchLatestSchedule() async {
    return fetchSchedule(ApiEndpoints.currentYear);
  }

  /// Fetch events (filtered from schedule)
  Future<List<EventDomain>> fetchEvents({
    int? year,
    String? track,
    String? room,
  }) async {
    try {
      final schedule = await fetchSchedule(year ?? ApiEndpoints.currentYear);
      var events = schedule.events;

      if (track != null) {
        events = events.where((e) => e.track == track).toList();
      }

      if (room != null) {
        events = events.where((e) => e.room == room).toList();
      }

      return events;
    } catch (e) {
      throw NetworkExceptionHandler.handleError(e);
    }
  }

  /// Fetch tracks from schedule
  Future<List<dynamic>> fetchTracks(int year) async {
    try {
      final schedule = await fetchSchedule(year);
      return schedule.tracks;
    } catch (e) {
      throw NetworkExceptionHandler.handleError(e);
    }
  }

  /// Check for schedule updates
  Future<bool> hasUpdates(int year, DateTime lastFetch) async {
    try {
      final schedule = await fetchSchedule(year);
      return schedule.lastUpdated.isAfter(lastFetch);
    } catch (e) {
      return false;
    }
  }

  EventDomain _toEventEntity(dynamic e) {
    return EventDomain(
      id: e.id,
      title: e.title,
      subtitle: e.subtitle,
      track: e.track,
      type: '',
      startTime: e.start,
      endTime: e.start.add(Duration(minutes: e.duration)),
      duration: e.duration,
      room: e.room,
      abstract: e.abstract,
      description: e.description,
      day: e.date.day,
    );
  }
}
