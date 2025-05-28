import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:itemswap/screens/home_screen.dart';
import 'package:itemswap/screens/search_chats_screen.dart';
import 'package:itemswap/screens/app_shell.dart';
import 'package:itemswap/screens/search_chats_screen.dart';
import 'package:itemswap/screens/search_screen.dart';
import 'package:mockito/mockito.dart';
import 'mocks/auth_mock.dart';
import 'mocks/auth_mock.mocks.dart';

void main() {

  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('AppShell Navigation Tests', () {
    testWidgets('Navigates to SearchScreen when "Search" icon is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: HomeScreen()),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Navigates to SearchChats when "Chat" Icon is tapped', (
        WidgetTester tester,
        ) async {

      await tester.pumpWidget(MaterialApp(
        home: HomeScreen(),
      ));

      expect(find.byType(HomeScreen), findsOneWidget);

      final chatIcon = Icons.chat_bubble_outline;
      expect(find.byIcon(chatIcon), findsOneWidget);

      await tester.tap(find.byIcon(chatIcon));
      await tester.pumpAndSettle();

      expect(find.byType(SearchChatsScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Does not navigate when tapping home icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(), // HomeScreen already contains AppShell
        ),
      );

      // Verify we're starting at home
      expect(find.byType(HomeScreen), findsOneWidget);

      // Tap home icon (current index)
      await tester.tap(find.byIcon(Icons.home));
      await tester.pumpAndSettle();

      // Should still be on HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    //testWidgets('Navigates back to Home')
  });
}
