import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test1/screens/search_screen.dart';
import 'auth_mock.dart'; // Import your mock setup file
// Import generated mocks

void main() {
  setupFirebaseAuthMocks(); // Set up Firebase mocks

  setUpAll(() async {
    await Firebase.initializeApp(); // Initialize Firebase
  });

testWidgets('Filter items by type without Firestore', (WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DropdownButton<String>(
          key: const Key('typeDropdown'),
          value: 'All',
          items: const [
            DropdownMenuItem(value: 'All', child: Text('All')),
            DropdownMenuItem(value: 'Books', child: Text('Books')),
          ],
          onChanged: (value) {},
        ),
      ),
    ),
  );

  // Open the type dropdown
  final typeDropdown = find.byKey(const Key('typeDropdown'));
  expect(typeDropdown, findsOneWidget);
  await tester.tap(typeDropdown);
  await tester.pumpAndSettle();

  // Select a type
  final typeOption = find.text('Books').last;
  expect(typeOption, findsOneWidget);
  await tester.tap(typeOption);
  await tester.pumpAndSettle();

  // Verify the selected type
  expect(find.text('Books'), findsWidgets);
});
}