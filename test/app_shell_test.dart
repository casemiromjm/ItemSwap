import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:itemswap/screens/home_screen.dart';
import 'package:itemswap/screens/search_chats_screen.dart';
import 'package:itemswap/screens/app_shell.dart';
import 'package:itemswap/screens/search_screen.dart';
import 'mocks/auth_mock.dart';

void main() {

  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('AppShell Navigation Tests', () {
    testWidgets('Starts on HomeScreenContent', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppShell()));

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Navigates to SearchScreen when "Search" icon is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AppShell()),
      );

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);

      await tester.tap(find.byIcon(Icons.search));
      await tester.pump();

      expect(find.byType(SearchScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Navigates to SearchChats when "Chat" Icon is tapped', (
        WidgetTester tester,
        ) async {

      await tester.pumpWidget(const MaterialApp(
        home: AppShell(),
      ));

      expect(find.byType(HomeScreen), findsOneWidget);

      final chatIcon = Icons.chat_bubble_outline;
      expect(find.byIcon(chatIcon), findsOneWidget);

      await tester.tap(find.byIcon(chatIcon));
      await tester.pump();

      expect(find.byType(SearchChatsScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Does not navigate when tapping home icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AppShell(),
        ),
      );

      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.home));
      await tester.pump();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    //testWidgets('Navigates back to Home')
  });
}
