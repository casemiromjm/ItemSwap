import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:test1/screens/home_screen.dart';
import 'package:test1/screens/contacts.dart';
import 'package:test1/screens/chat_screen.dart';
import 'auth_mock.dart';
import 'mock_search_screen.dart';

void main() {
  // IMPORTANT: Set up the Firebase Core mocks at the very beginning.
  /*setupFirebaseAuthMocks();

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });*/

  // Since there's still no DataBase implementation on Contacts, isn't necessary to call the above methods

  group('Contacts Navigation Tests', () {
    testWidgets('Navigates to Chat when "Chat prototype" is tapped', (
        WidgetTester tester,
        ) async {
      await tester.pumpWidget(MaterialApp(home: Contacts()));

      expect(find.text('Chat prototype'), findsOneWidget);

      await tester.tap(find.text('Chat prototype'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);
    });

    testWidgets('Navigates back when implicit back button is tapped', (
        WidgetTester tester,
        ) async {
      // HomeScreen -> Contacts -> HomeScreen
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(),
        ),
      );

      Navigator.of(tester.element(find.byType(HomeScreen))).push(
        MaterialPageRoute(builder: (context) => Contacts()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Contacts), findsOneWidget);

      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(Contacts), findsNothing);
    });
  });
}