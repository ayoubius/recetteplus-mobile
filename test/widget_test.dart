import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recette_plus/main.dart';

void main() {
  testWidgets('RecettePlusApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RecettePlusApp());

    // Verify that the app starts and doesn't crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
