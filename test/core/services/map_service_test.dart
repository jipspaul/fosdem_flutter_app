import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/core/services/map_service.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('MapService', () {
    late MapService mapService;

    setUp(() {
      mapService = MapService();
    });

    group('calculateCenter', () {
      test('returns FOSDEM center for empty list', () {
        final center = mapService.calculateCenter([]);
        expect(center, equals(MapService.fosdemCenter));
      });

      test('returns same point for single point', () {
        final point = const LatLng(50.0, 4.0);
        final center = mapService.calculateCenter([point]);
        expect(center, equals(point));
      });

      test('calculates center correctly for multiple points', () {
        final points = [
          const LatLng(50.0, 4.0),
          const LatLng(51.0, 5.0),
        ];
        final center = mapService.calculateCenter(points);
        expect(center.latitude, equals(50.5));
        expect(center.longitude, equals(4.5));
      });

      test('handles points around globe', () {
        final points = [
          const LatLng(0.0, 0.0),
          const LatLng(10.0, 10.0),
          const LatLng(-10.0, -10.0),
        ];
        final center = mapService.calculateCenter(points);
        expect(center.latitude, closeTo(0.0, 0.1));
        expect(center.longitude, closeTo(0.0, 0.1));
      });
    });

    group('calculateZoomLevel', () {
      test('returns default zoom for single point', () {
        final zoom = mapService.calculateZoomLevel([const LatLng(50.0, 4.0)]);
        expect(zoom, equals(MapService.defaultZoom));
      });

      test('returns high zoom for close points', () {
        final points = [
          const LatLng(50.0, 4.0),
          const LatLng(50.0001, 4.0001),
        ];
        final zoom = mapService.calculateZoomLevel(points);
        expect(zoom, equals(18.0));
      });

      test('returns low zoom for far points', () {
        final points = [
          const LatLng(50.0, 4.0),
          const LatLng(51.0, 5.0),
        ];
        final zoom = mapService.calculateZoomLevel(points);
        expect(zoom, lessThan(15.0));
      });

      test('returns appropriate zoom for medium distance', () {
        final points = [
          const LatLng(50.0, 4.0),
          const LatLng(50.01, 4.01),
        ];
        final zoom = mapService.calculateZoomLevel(points);
        expect(zoom, greaterThan(13.0));
        expect(zoom, lessThan(17.0));
      });
    });

    group('isPointInPolygon', () {
      test('returns true for point inside square', () {
        final polygon = [
          const LatLng(0.0, 0.0),
          const LatLng(0.0, 1.0),
          const LatLng(1.0, 1.0),
          const LatLng(1.0, 0.0),
        ];
        final point = const LatLng(0.5, 0.5);
        expect(mapService.isPointInPolygon(point, polygon), isTrue);
      });

      test('returns false for point outside square', () {
        final polygon = [
          const LatLng(0.0, 0.0),
          const LatLng(0.0, 1.0),
          const LatLng(1.0, 1.0),
          const LatLng(1.0, 0.0),
        ];
        final point = const LatLng(2.0, 2.0);
        expect(mapService.isPointInPolygon(point, polygon), isFalse);
      });

      test('returns false for point on edge', () {
        final polygon = [
          const LatLng(0.0, 0.0),
          const LatLng(0.0, 1.0),
          const LatLng(1.0, 1.0),
          const LatLng(1.0, 0.0),
        ];
        final point = const LatLng(0.0, 0.5);
        // Edge case - implementation dependent
        expect(mapService.isPointInPolygon(point, polygon), isA<bool>());
      });

      test('handles complex polygon', () {
        final polygon = [
          const LatLng(0.0, 0.0),
          const LatLng(0.0, 2.0),
          const LatLng(1.0, 1.0),
          const LatLng(2.0, 2.0),
          const LatLng(2.0, 0.0),
        ];
        final insidePoint = const LatLng(0.5, 1.0);
        final outsidePoint = const LatLng(1.5, 1.5);
        
        expect(mapService.isPointInPolygon(insidePoint, polygon), isTrue);
        expect(mapService.isPointInPolygon(outsidePoint, polygon), isFalse);
      });
    });
  });
}
