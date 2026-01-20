import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/core/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('ConnectivityService', () {
    late ConnectivityService service;

    setUp(() {
      service = ConnectivityService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should initialize with offline status by default', () {
      expect(service.currentStatus, equals(ConnectivityStatus.offline));
    });

    test('should emit status updates through stream', () async {
      expectLater(
        service.statusStream,
        emitsInOrder([
          isA<ConnectivityStatus>(),
        ]),
      );
    });

    test('isOnline should return false when offline', () {
      expect(service.isOnline, isFalse);
    });

    test('isWifi should return false when not on wifi', () {
      expect(service.isWifi, isFalse);
    });

    test('isMobile should return false when not on mobile', () {
      expect(service.isMobile, isFalse);
    });

    test('checkConnectivity should handle errors gracefully', () async {
      final result = await service.checkConnectivity();
      expect(result, isA<bool>());
    });
  });
}
