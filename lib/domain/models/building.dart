import 'package:latlong2/latlong.dart';

class Blueprint {
  final String title;
  final String imageName;

  const Blueprint({
    required this.title,
    required this.imageName,
  });

  factory Blueprint.fromJson(Map<String, dynamic> json) {
    return Blueprint(
      title: json['title'] as String,
      imageName: json['imageName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imageName': imageName,
    };
  }
}

class Building {
  final String title;
  final String glyph;
  final LatLng coordinate;
  final List<LatLng> polygon;
  final List<Blueprint> blueprints;

  const Building({
    required this.title,
    required this.glyph,
    required this.coordinate,
    required this.polygon,
    required this.blueprints,
  });

  factory Building.fromJson(Map<String, dynamic> json) {
    final coordinateJson = json['coordinate'] as Map<String, dynamic>;
    final coordinate = LatLng(
      coordinateJson['latitude'] as double,
      coordinateJson['longitude'] as double,
    );

    final polygonJson = json['polygon'] as List<dynamic>;
    final polygon = polygonJson.map((point) {
      final p = point as Map<String, dynamic>;
      return LatLng(
        p['latitude'] as double,
        p['longitude'] as double,
      );
    }).toList();

    final blueprintsJson = json['blueprints'] as List<dynamic>;
    final blueprints = blueprintsJson
        .map((b) => Blueprint.fromJson(b as Map<String, dynamic>))
        .toList();

    final title = json['title'] as String;
    final glyph = json['glyph'] as String? ?? title;

    return Building(
      title: title,
      glyph: glyph,
      coordinate: coordinate,
      polygon: polygon,
      blueprints: blueprints,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'glyph': glyph,
      'coordinate': {
        'latitude': coordinate.latitude,
        'longitude': coordinate.longitude,
      },
      'polygon': polygon
          .map((p) => {
                'latitude': p.latitude,
                'longitude': p.longitude,
              })
          .toList(),
      'blueprints': blueprints.map((b) => b.toJson()).toList(),
    };
  }
}
