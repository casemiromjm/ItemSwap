import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itemswap/screens/search_screen.dart';
import 'mocks/auth_mock.dart';

void main() {
  setupFirebaseAuthMocks();

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Sort items by distance', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(),
      ),
    );

    // Open the sort dropdown
    final sortDropdown = find.byType(DropdownButton<String>).last;
    expect(sortDropdown, findsOneWidget);
    await tester.tap(sortDropdown);
    await tester.pumpAndSettle();

    // Select "Location" as the sort option
    final locationOption = find.text('Location').last;
    expect(locationOption, findsOneWidget);
    await tester.tap(locationOption);
    await tester.pumpAndSettle();

    // Verify the selected sort option
    expect(find.text('Location'), findsWidgets);
  });
}