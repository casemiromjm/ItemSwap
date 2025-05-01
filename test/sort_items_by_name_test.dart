import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:itemswap/screens/search_screen.dart';
import 'auth_mock.dart'; // Import your mock setup file

void main() {
  setupFirebaseAuthMocks(); // Set up Firebase mocks

  setUpAll(() async {
    await Firebase.initializeApp(); // Initialize Firebase
  });

  testWidgets('Search for items by name', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(),
      ),
    );

    // Enter a search query
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'Laptop');
    await tester.pumpAndSettle();

    // Increase timeout
    await tester.pumpAndSettle(const Duration(seconds: 10));

    // Or manually pump frames
    await tester.pump(const Duration(seconds: 1));

    // Verify the search query
    expect(find.text('Laptop'), findsOneWidget);
  });
}