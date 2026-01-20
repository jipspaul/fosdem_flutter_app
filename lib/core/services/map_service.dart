import 'package:latlong2/latlong.dart';

class MapService {
  // FOSDEM Brussels coordinates
  static const LatLng fosdemCenter = LatLng(50.8120, 4.3810);
  
  static const double defaultZoom = 16.0;
  static const double minZoom = 12.0;
  static const double maxZoom = 19.0;

  LatLng calculateCenter(List<LatLng> points) {
    if (points.isEmpty) return fosdemCenter;

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return LatLng(
      totalLat / points.length,
      totalLng / points.length,
    );
  }

  double calculateZoomLevel(List<LatLng> points) {
    if (points.length < 2) return defaultZoom;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final point in points) {
      minLat = point.latitude < minLat ? point.latitude : minLat;
      maxLat = point.latitude > maxLat ? point.latitude : maxLat;
      minLng = point.longitude < minLng ? point.longitude : minLng;
      maxLng = point.longitude > maxLng ? point.longitude : maxLng;
    }

    final latDiff = maxLat - minLat;
    final lngDiff = maxLng - minLng;
    final maxDiff = latDiff > lngDiff ? latDiff : lngDiff;

    if (maxDiff < 0.001) return 18.0;
    if (maxDiff < 0.005) return 16.0;
    if (maxDiff < 0.01) return 15.0;
    if (maxDiff < 0.05) return 13.0;
    return 12.0;
  }

  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int i = 0; i < polygon.length; i++) {
      final vertex1 = polygon[i];
      final vertex2 = polygon[(i + 1) % polygon.length];

      if (vertex1.longitude == vertex2.longitude) continue;

      if (point.longitude < vertex1.longitude && point.longitude < vertex2.longitude) {
        continue;
      }

      if (point.longitude >= vertex1.longitude && point.longitude >= vertex2.longitude) {
        continue;
      }

      final x = (point.longitude - vertex1.longitude) /
          (vertex2.longitude - vertex1.longitude);
      final y = vertex1.latitude + x * (vertex2.latitude - vertex1.latitude);

      if (point.latitude < y) {
        intersectCount++;
      }
    }

    return (intersectCount % 2) == 1;
  }
}
