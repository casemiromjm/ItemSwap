import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test1/screens/home_screen.dart';
import 'package:test1/screens/add_item_screen.dart';
import 'package:test1/screens/welcome_screen.dart';
import 'package:test1/screens/user_creation_screen.dart';
import 'auth_mock.dart';
import 'mock_search_screen.dart';

void main() {
  // IMPORTANT: Set up the Firebase Core mocks at the very beginning.
  setupFirebaseAuthMocks();

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('HomeScreen Navigation Tests', () {
    testWidgets('Navigates to AddItemScreen when "Add New Item" is tapped', (
      WidgetTester tester,
    ) async {
      // Build HomeScreen wrapped in a MaterialApp.
      await tester.pumpWidget(MaterialApp(home: HomeScreen()));

      // Verify the button is present.
      expect(find.text('Add New Item'), findsOneWidget);

      // Tap the button.
      await tester.tap(find.text('Add New Item'));
      await tester.pumpAndSettle();

      // Verify that the AddItemScreen is displayed.
      expect(find.byType(AddItemScreen), findsOneWidget);
    });

    testWidgets('Navigates to MockSearchScreen when "Search Items" is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            searchScreenBuilder: (context) => MockSearchScreen(),
          ),
        ),
      );

      expect(find.text('Search Items'), findsOneWidget);

      await tester.tap(find.text('Search Items'));
      await tester.pumpAndSettle();

      expect(find.text('Mock Search Screen'), findsOneWidget);
    });

    testWidgets('Navigates to WelcomeScreen when "Welcome" is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: HomeScreen()));

      expect(find.text('Welcome'), findsOneWidget);

      await tester.tap(find.text('Welcome'));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets(
      'Navigates to UserCreationScreen when "Change profile" is tapped',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(home: HomeScreen()));

        expect(find.text('Change profile'), findsOneWidget);

        await tester.tap(find.text('Change profile'));
        await tester.pumpAndSettle();

        expect(find.byType(UserCreationScreen), findsOneWidget);
      },
    );
  });
}
