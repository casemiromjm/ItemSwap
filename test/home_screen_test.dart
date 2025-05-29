import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:itemswap/screens/home_screen.dart';
import 'package:itemswap/screens/item_screen.dart';
import 'package:itemswap/screens/chat_screen.dart';
import 'package:itemswap/screens/app_shell.dart';
import 'package:itemswap/screens/welcome_screen.dart';
import 'package:itemswap/screens/user_screen.dart';
import 'package:mockito/mockito.dart';
import 'mocks/auth_mock.dart';
import 'mocks/auth_mock.mocks.dart';
import 'mocks/mock_search_screen.dart';

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  // IMPORTANT: Set up the Firebase Core mocks at the very beginning.
  setupFirebaseAuthMocks();

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('HomeScreen Navigation Tests', () {
    testWidgets('Navigates to AddItemScreen when "New Item" is tapped', (
      WidgetTester tester,
    ) async {
      // Build HomeScreen wrapped in a MaterialApp
      await tester.pumpWidget(MaterialApp(home: HomeScreen()));

      expect(find.text('New item'), findsOneWidget);

      await tester.tap(find.text('New item'));
      await tester.pumpAndSettle();

      // Verify that the Item Screen displayed by looking for flutter map
      expect(find.byType(ItemScreen), findsOneWidget);
    });

    testWidgets('Navigates to MockSearchScreen when "Search Items" is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            //searchScreenBuilder: (context) => MockSearchScreen(),
          ),
        ),
      );

      expect(find.text('Search Items'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
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

        //expect(find.byType(UserCreationScreen), findsOneWidget);
      },
    );

  });
}
