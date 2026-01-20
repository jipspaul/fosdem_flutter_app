import 'package:drift/drift.dart';
import '../database.dart';
import '../tables/tracks_table.dart';

part 'tracks_dao.g.dart';

@DriftAccessor(tables: [Tracks])
class TracksDao extends DatabaseAccessor<AppDatabase> with _$TracksDaoMixin {
  TracksDao(AppDatabase db) : super(db);

  Future<List<TrackEntity>> getAllTracks() => select(tracks).get();
  
  Future<TrackEntity?> getTrackByName(String name) =>
      (select(tracks)..where((t) => t.name.equals(name))).getSingleOrNull();
  
  Future<List<TrackEntity>> getTracksByDate(DateTime date) =>
      (select(tracks)..where((t) => t.date.equals(date))).get();
  
  Future<void> insertTrack(TracksCompanion track) =>
      into(tracks).insert(track, mode: InsertMode.insertOrReplace);
  
  Future<void> insertTracks(List<TracksCompanion> tracksList) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(tracks, tracksList);
    });
  }
  
  Future<bool> updateTrack(TrackEntity track) => update(tracks).replace(track);
  
  Future<int> deleteTrack(String name) =>
      (delete(tracks)..where((t) => t.name.equals(name))).go();
  
  Stream<List<TrackEntity>> watchAllTracks() => select(tracks).watch();

  Future<TrackEntity?> getTrackById(String id) => getTrackByName(id);

  Future<List<TrackEntity>> getTracksByType(String type) =>
      (select(tracks)..where((t) => t.type.equals(type))).get();

  Future<List<TrackEntity>> searchTracks(String query) {
    final searchTerm = '%${query.toLowerCase()}%';
    return (select(tracks)
          ..where((t) =>
              t.name.lower().like(searchTerm) |
              t.description.lower().like(searchTerm)))
        .get();
  }

  Future<int> getEventCount(String trackName) async {
    // This would need to join with events table
    // For now return 0
    return 0;
  }

  Future<int> deleteAllTracks() => delete(tracks).go();
}
