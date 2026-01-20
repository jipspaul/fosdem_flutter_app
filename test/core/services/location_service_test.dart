import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/core/services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([])
void main() {
  group('LocationService', () {
    late LocationService locationService;

    setUp(() {
      locationService = LocationService();
    });

    test('calculateDistance returns correct distance', () {
      // Brussels to Paris roughly 265 km
      final distance = locationService.calculateDistance(
        50.8503, 4.3517, // Brussels
        48.8566, 2.3522, // Paris
      );
      
      // Allow 10km margin of error
      expect(distance, greaterThan(255000));
      expect(distance, lessThan(275000));
    });

    test('calculateDistance returns zero for same location', () {
      final distance = locationService.calculateDistance(
        50.8503, 4.3517,
        50.8503, 4.3517,
      );
      
      expect(distance, equals(0.0));
    });

    test('calculateDistance handles equator crossing', () {
      final distance = locationService.calculateDistance(
        10.0, 0.0,
        -10.0, 0.0,
      );
      
      expect(distance, greaterThan(2200000)); // ~2220 km
      expect(distance, lessThan(2240000));
    });
  });
}
