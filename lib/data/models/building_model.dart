import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import 'blueprint_model.dart';

class BuildingModel extends Equatable {
  final String id;
  final String title;
  final String glyph;
  final LatLng coordinate;
  final List<LatLng> polygon;
  final List<BlueprintModel> blueprints;

  const BuildingModel({
    required this.id,
    required this.title,
    required this.glyph,
    required this.coordinate,
    this.polygon = const [],
    this.blueprints = const [],
  });

  factory BuildingModel.fromJson(Map<String, dynamic> json) {
    final lat = json['latitude'] as num? ?? json['lat'] as num?;
    final lng = json['longitude'] as num? ?? json['lng'] as num? ?? json['lon'] as num?;
    
    if (lat == null || lng == null) {
      throw ArgumentError('Building must have valid coordinates');
    }

    return BuildingModel(
      id: json['id'] as String,
      title: json['title'] as String,
      glyph: json['glyph'] as String? ?? '',
      coordinate: LatLng(lat.toDouble(), lng.toDouble()),
      polygon: _parsePolygon(json['polygon']),
      blueprints: (json['blueprints'] as List<dynamic>?)
              ?.map((b) => BlueprintModel.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static List<LatLng> _parsePolygon(dynamic polygonData) {
    if (polygonData == null) return [];
    
    try {
      final List<dynamic> points = polygonData as List<dynamic>;
      return points.map((point) {
        if (point is Map<String, dynamic>) {
          final lat = point['latitude'] as num? ?? point['lat'] as num?;
          final lng = point['longitude'] as num? ?? point['lng'] as num? ?? point['lon'] as num?;
          if (lat != null && lng != null) {
            return LatLng(lat.toDouble(), lng.toDouble());
          }
        } else if (point is List && point.length >= 2) {
          return LatLng((point[0] as num).toDouble(), (point[1] as num).toDouble());
        }
        throw ArgumentError('Invalid polygon point format');
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'glyph': glyph,
      'latitude': coordinate.latitude,
      'longitude': coordinate.longitude,
      'polygon': polygon
          .map((p) => {
                'latitude': p.latitude,
                'longitude': p.longitude,
              })
          .toList(),
      'blueprints': blueprints.map((b) => b.toJson()).toList(),
    };
  }

  bool get hasPolygon => polygon.isNotEmpty;

  bool get hasBlueprints => blueprints.isNotEmpty;

  double distanceTo(LatLng point) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, coordinate, point);
  }

  bool containsPoint(LatLng point) {
    if (!hasPolygon) return false;
    
    // Ray casting algorithm for point-in-polygon
    int intersections = 0;
    for (int i = 0; i < polygon.length; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % polygon.length];
      
      if (_rayIntersectsSegment(point, p1, p2)) {
        intersections++;
      }
    }
    
    return intersections % 2 == 1;
  }

  bool _rayIntersectsSegment(LatLng point, LatLng p1, LatLng p2) {
    if (p1.latitude > p2.latitude) {
      final temp = p1;
      p1 = p2;
      p2 = temp;
    }
    
    if (point.latitude < p1.latitude || point.latitude > p2.latitude) {
      return false;
    }
    
    if (point.longitude >= p1.longitude && point.longitude >= p2.longitude) {
      return false;
    }
    
    if (point.longitude < p1.longitude && point.longitude < p2.longitude) {
      return true;
    }
    
    final slope = (p2.longitude - p1.longitude) / (p2.latitude - p1.latitude);
    final x = p1.longitude + (point.latitude - p1.latitude) * slope;
    
    return point.longitude < x;
  }

  BuildingModel copyWith({
    String? id,
    String? title,
    String? glyph,
    LatLng? coordinate,
    List<LatLng>? polygon,
    List<BlueprintModel>? blueprints,
  }) {
    return BuildingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      glyph: glyph ?? this.glyph,
      coordinate: coordinate ?? this.coordinate,
      polygon: polygon ?? this.polygon,
      blueprints: blueprints ?? this.blueprints,
    );
  }

  @override
  List<Object?> get props => [id, title, glyph, coordinate, polygon, blueprints];
}
