import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fosdem_flutter/main.dart';

void main() {
  testWidgets('FOSDEM app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that app title is present
    expect(find.text('FOSDEM'), findsOneWidget);
    
    // Verify welcome message
    expect(find.textContaining('Welcome'), findsOneWidget);
  });
}
