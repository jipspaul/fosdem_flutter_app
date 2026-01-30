import '../../domain/models/journey_export_model.dart';
import '../../domain/models/journey_models.dart';
import '../../presentation/bloc/journey_state.dart';

/// Builds YAML from journey state.
/// - planned = events in journey (plans to attend)
/// - wishlist = favorites not in journey (candidates)
class JourneyExportService {
  static const String defaultUserName = 'User';
  static const String defaultUserPictureUrl = 'https://placehold.co/600x400.png';

  /// Builds JourneyExportData from JourneyLoaded state.
  /// Planned = planned items; wishlist = candidates (favorites not planned).
  JourneyExportData buildExportData(
    JourneyLoaded state, {
    String userName = defaultUserName,
    String? userPictureUrl,
  }) {
    final events = <JourneyExportEvent>[];

    for (final item in state.planned) {
      events.add(_journeyItemToExportEvent(item, 'planned'));
    }
    for (final item in state.candidates) {
      events.add(_journeyItemToExportEvent(item, 'wishlist'));
    }

    final pictureUrl = (userPictureUrl != null && userPictureUrl.trim().isNotEmpty)
        ? userPictureUrl.trim()
        : defaultUserPictureUrl;

    return JourneyExportData(
      userName: userName,
      userPictureUrl: pictureUrl,
      events: events,
    );
  }

  JourneyExportEvent _journeyItemToExportEvent(JourneyItem item, String status) {
    return JourneyExportEvent(
      eventId: item.eventId,
      eventName: item.eventTitle,
      status: status,
      startTime: item.startTime.toIso8601String(),
      endTime: item.endTime.toIso8601String(),
      room: item.room,
      building: item.building,
      track: item.track,
      priority: item.priority,
      notes: item.notes,
    );
  }

  /// Serializes JourneyExportData to YAML string.
  String toYaml(JourneyExportData data) {
    final sb = StringBuffer();
    sb.writeln('userName: "${_escape(data.userName)}"');
    final pictureUrl = (data.userPictureUrl != null && data.userPictureUrl!.trim().isNotEmpty)
        ? data.userPictureUrl!.trim()
        : defaultUserPictureUrl;
    sb.writeln('userPictureUrl: "${_escape(pictureUrl)}"');
    sb.writeln('events:');
    for (final e in data.events) {
      sb.writeln('  - eventId: ${e.eventId}');
      sb.writeln('    eventName: "${_escape(e.eventName)}"');
      sb.writeln('    status: "${e.status}"');
      sb.writeln('    startTime: "${e.startTime}"');
      sb.writeln('    endTime: "${e.endTime}"');
      sb.writeln('    room: "${_escape(e.room)}"');
      sb.writeln('    building: "${_escape(e.building)}"');
      sb.writeln('    track: "${_escape(e.track)}"');
      sb.writeln('    priority: ${e.priority}');
      if (e.notes != null && e.notes!.isNotEmpty) {
        sb.writeln('    notes: "${_escape(e.notes!)}"');
      }
    }
    return sb.toString();
  }

  static String _escape(String s) => s.replaceAll('\\', '\\\\').replaceAll('"', '\\"').replaceAll('\n', '\\n');

  /// Builds YAML string from JourneyLoaded state.
  String buildYamlFromJourney(
    JourneyLoaded state, {
    String userName = defaultUserName,
    String? userPictureUrl,
  }) {
    final data = buildExportData(state, userName: userName, userPictureUrl: userPictureUrl);
    return toYaml(data);
  }
}
