import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class Blueprint extends Equatable {
  final String title;
  final String imageName;
  final String? imageUrl;

  const Blueprint({
    required this.title,
    required this.imageName,
    this.imageUrl,
  });

  bool get hasNetworkImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasAssetImage => imageName.isNotEmpty;
  String get imageAssetPath => 'assets/images/$imageName';

  Blueprint copyWith({
    String? title,
    String? imageName,
    String? imageUrl,
  }) {
    return Blueprint(
      title: title ?? this.title,
      imageName: imageName ?? this.imageName,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  List<Object?> get props => [title, imageName, imageUrl];

  @override
  String toString() => 'Blueprint(title: $title)';
}

class Building extends Equatable {
  final String id;
  final String title;
  final String glyph;
  final LatLng coordinate;
  final List<LatLng> polygon;
  final List<Blueprint> blueprints;

  const Building({
    required this.id,
    required this.title,
    required this.glyph,
    required this.coordinate,
    this.polygon = const [],
    this.blueprints = const [],
  });

  bool get hasPolygon => polygon.isNotEmpty;
  bool get hasBlueprints => blueprints.isNotEmpty;

  double distanceTo(LatLng point) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, coordinate, point);
  }

  bool containsPoint(LatLng point) {
    if (!hasPolygon) return false;
    
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

  Building copyWith({
    String? id,
    String? title,
    String? glyph,
    LatLng? coordinate,
    List<LatLng>? polygon,
    List<Blueprint>? blueprints,
  }) {
    return Building(
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

  @override
  String toString() => 'Building(id: $id, title: $title)';
}
