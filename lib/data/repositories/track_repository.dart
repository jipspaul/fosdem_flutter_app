import '../datasources/local/database.dart';
import '../datasources/remote/fosdem_api.dart';
import '../../domain/entities/track.dart';

class TrackRepository {
  final AppDatabase database;
  final FosdemApi api;

  TrackRepository({
    required this.database,
    required this.api,
  });

  Future<List<Track>> getAll() async {
    final tracks = await database.tracksDao.getAllTracks();
    return tracks.map((t) => Track(
      name: t.name,
      day: t.day,
      date: t.date,
    )).toList();
  }

  Future<Track?> getByName(String name) async {
    final tracks = await database.tracksDao.getAllTracks();
    final track = tracks.where((t) => t.name == name).firstOrNull;
    if (track == null) return null;
    return Track(
      name: track.name,
      day: track.day,
      date: track.date,
    );
  }

  Future<void> create(Track track) async {
    await database.tracksDao.insertTrack(TracksCompanion.insert(
      name: track.name,
    ));
  }

  Future<void> deleteAll() async {
    await database.tracksDao.deleteAllTracks();
  }
}
