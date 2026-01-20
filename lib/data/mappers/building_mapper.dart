import 'dart:convert';
import 'package:latlong2/latlong.dart';
import '../datasources/local/database.dart';
import '../../domain/entities/building.dart';

/// Extension to convert database BuildingEntity to domain Building
extension BuildingEntityMapper on BuildingEntity {
  Building toDomain() {
    // Parse polygon from JSON
    final polygonList = <LatLng>[];
    try {
      final polygonJson = json.decode(polygon) as List;
      for (final point in polygonJson) {
        if (point is List && point.length >= 2) {
          polygonList.add(LatLng(point[0] as double, point[1] as double));
        }
      }
    } catch (_) {}

    // Parse blueprints from JSON
    final blueprintsList = <Blueprint>[];
    try {
      final blueprintsJson = json.decode(blueprints) as List;
      for (final bp in blueprintsJson) {
        if (bp is Map) {
          blueprintsList.add(Blueprint(
            title: bp['title'] as String? ?? '',
            imageName: bp['imageName'] as String? ?? '',
            imageUrl: bp['imageUrl'] as String?,
          ));
        }
      }
    } catch (_) {}

    return Building(
      id: id,
      title: title,
      glyph: glyph,
      coordinate: LatLng(latitude, longitude),
      polygon: polygonList,
      blueprints: blueprintsList,
    );
  }
}

/// Extension to convert domain Building to database BuildingEntity
extension BuildingToDatabaseMapper on Building {
  BuildingsCompanion toCompanion() {
    final polygonJson = json.encode(
      polygon.map((p) => [p.latitude, p.longitude]).toList(),
    );

    final blueprintsJson = json.encode(
      blueprints.map((bp) => {
        'title': bp.title,
        'imageName': bp.imageName,
        'imageUrl': bp.imageUrl,
      }).toList(),
    );

    return BuildingsCompanion.insert(
      id: id,
      title: title,
      glyph: glyph,
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
      polygon: polygonJson,
      blueprints: blueprintsJson,
    );
  }
}
