import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:itemswap/screens/mainpage_screen.dart';
import 'package:itemswap/screens/nav_bar.dart';
import 'auth_mock.dart';
import 'mock_search_screen.dart';
import 'mock_chat_screen.dart';

void main() {
  // IMPORTANT: Set up the Firebase Core mocks at the very beginning.
  setupFirebaseAuthMocks();

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('NavBar Tests', () {
    testWidgets('Navigates to MockSearchScreen when "Search" icon is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavBar(
            searchScreenBuilder: (context) => MockSearchScreen(),
          ),
        ),
      );

      expect(find.byType(NavBar), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.text('Mock Search Screen'), findsOneWidget);
    });

    testWidgets('Navigates to Profile when "Profile" icon is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: NavBar()));

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.byType(MainPage), findsOneWidget);
    });

    testWidgets('Navigates to Chat when "Chat" icon is tapped', (
        WidgetTester tester,)

    async {
      await tester.pumpWidget(MaterialApp(home: NavBar(
        searchScreenBuilder: (context) => MockChatScreen(),
      )));

      //expect(find.byIcon(Icons.chat_bubble), findsOneWidget);   // debug reason
      await tester.tap(find.byIcon(Icons.chat_bubble));
      await tester.pumpAndSettle();

      expect(find.text('Mock Chat Screen'), findsOneWidget);
    });

  });
}
