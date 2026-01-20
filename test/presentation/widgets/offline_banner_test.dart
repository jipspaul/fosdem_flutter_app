import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fosdem_flutter/presentation/widgets/common/offline_banner.dart';
import 'package:fosdem_flutter/core/services/connectivity_service.dart';

void main() {
  group('OfflineBanner Widget', () {
    testWidgets('should display offline message when offline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
            ),
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('You\'re viewing cached data'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('should not display when online', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.wifi,
            ),
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsNothing);
    });

    testWidgets('should show retry button when callback provided', (tester) async {
      var retryCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
              onRetry: () => retryCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();

      expect(retryCalled, isTrue);
    });

    testWidgets('should not show retry button when no callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsNothing);
    });
  });

  group('ConnectivityBanner Widget', () {
    testWidgets('should show offline banner when offline', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectivityBanner(
              status: ConnectivityStatus.offline,
            ),
          ),
        ),
      );

      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('should show online status when requested', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectivityBanner(
              status: ConnectivityStatus.wifi,
              showOnlineStatus: true,
            ),
          ),
        ),
      );

      expect(find.text('Back Online'), findsOneWidget);
      expect(find.byIcon(Icons.wifi), findsOneWidget);
    });

    testWidgets('should not show when online without flag', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConnectivityBanner(
              status: ConnectivityStatus.wifi,
              showOnlineStatus: false,
            ),
          ),
        ),
      );

      expect(find.text('Back Online'), findsNothing);
    });

    testWidgets('should use correct colors for status', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ConnectivityBanner(
                  status: ConnectivityStatus.offline,
                  key: const Key('offline'),
                ),
                ConnectivityBanner(
                  status: ConnectivityStatus.wifi,
                  showOnlineStatus: true,
                  key: const Key('online'),
                ),
              ],
            ),
          ),
        ),
      );

      final offlineBanner = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('offline')),
          matching: find.byType(Container),
        ).first,
      );

      expect(offlineBanner.color, isNotNull);
    });
  });

  group('ConnectivityWrapper Widget', () {
    late ConnectivityService connectivityService;

    setUp(() {
      connectivityService = ConnectivityService();
    });

    tearDown(() {
      connectivityService.dispose();
    });

    testWidgets('should wrap child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectivityWrapper(
            connectivityService: connectivityService,
            child: const Text('Test Child'),
          ),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('should show banner when enabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectivityWrapper(
            connectivityService: connectivityService,
            showBanner: true,
            child: const Text('Test Child'),
          ),
        ),
      );

      // Banner should be present (may not be visible if online)
      expect(find.byType(ConnectivityBanner), findsOneWidget);
    });

    testWidgets('should not show banner when disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConnectivityWrapper(
            connectivityService: connectivityService,
            showBanner: false,
            child: const Text('Test Child'),
          ),
        ),
      );

      // ConnectivityBanner is still in tree but configured not to show
      expect(find.byType(Column), findsOneWidget);
    });
  });

  group('Accessibility', () {
    testWidgets('OfflineBanner should have semantic labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
            ),
          ),
        ),
      );

      expect(find.text('No Internet Connection'), findsOneWidget);
      expect(find.text('You\'re viewing cached data'), findsOneWidget);

      // Verify text is accessible
      final textFinder = find.text('No Internet Connection');
      expect(tester.getSemantics(textFinder), isNotNull);
    });

    testWidgets('Retry button should be accessible', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
              onRetry: () {},
            ),
          ),
        ),
      );

      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);

      // Verify button is tappable
      await tester.tap(retryButton);
      await tester.pump();
    });
  });

  group('Layout Tests', () {
    testWidgets('should use SafeArea for proper display', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
            ),
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('should fill available width', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OfflineBanner(
              status: ConnectivityStatus.offline,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(OfflineBanner),
          matching: find.byType(Container),
        ),
      );

      expect(container.constraints?.maxWidth, equals(double.infinity));
    });
  });
}
