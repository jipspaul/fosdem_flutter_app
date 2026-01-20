import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:fosdem_flutter/main.dart';

void main() {
  group('Main Navigation Tests', () {
    testWidgets('App starts with welcome screen', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('FOSDEM Companion'), findsOneWidget);
      expect(find.text('Welcome to FOSDEM Companion'), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
    });

    testWidgets('Navigation bar has 4 items', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Schedule'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
    });

    testWidgets('Can navigate to Schedule page', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule - Coming Soon'), findsOneWidget);
    });

    testWidgets('Can navigate to Favorites page', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favorites'));
      await tester.pumpAndSettle();

      expect(find.text('Favorites - Coming Soon'), findsOneWidget);
    });

    testWidgets('Can navigate to Map page', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Map'));
      await tester.pumpAndSettle();

      expect(find.text('Map - Coming Soon'), findsOneWidget);
    });

    testWidgets('Can navigate back to Home', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Navigate to Schedule
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      // Navigate back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to FOSDEM Companion'), findsOneWidget);
    });

    testWidgets('Theme colors are applied correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final MaterialApp app = tester.widget(find.byType(MaterialApp));
      expect(app.theme, isNotNull);
      expect(app.darkTheme, isNotNull);
    });
  });

  group('HomePage Navigation Tests', () {
    testWidgets('Selected index updates on navigation', (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      // Default is Home (index 0)
      final NavigationBar navBar = tester.widget(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(0));

      // Navigate to Schedule (index 1)
      await tester.tap(find.text('Schedule'));
      await tester.pumpAndSettle();

      final NavigationBar navBar2 = tester.widget(find.byType(NavigationBar));
      expect(navBar2.selectedIndex, equals(1));
    });
  });
}
