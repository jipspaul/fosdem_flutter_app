import '../../../domain/entities/building.dart';
import '../../../data/services/buildings_service.dart';
import '../../../domain/models/building.dart' as model;

/// Loads buildings from assets and converts to domain entities for the map.
Future<List<Building>> loadEntityBuildings(BuildingsService service) async {
  final models = await service.loadBuildings();
  return models.map(_toEntity).toList();
}

Building _toEntity(model.Building b) {
  return Building(
    id: b.title,
    title: b.title,
    glyph: b.glyph,
    coordinate: b.coordinate,
    polygon: b.polygon,
    blueprints: b.blueprints
        .map((bp) => Blueprint(
              title: bp.title,
              imageName: bp.imageName,
              imageUrl: null,
            ))
        .toList(),
  );
}
