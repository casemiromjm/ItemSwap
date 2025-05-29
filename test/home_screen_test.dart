import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:itemswap/screens/home_screen.dart';
import 'package:itemswap/screens/item_screen.dart';
import 'package:itemswap/screens/settings_screen.dart';
import 'package:itemswap/screens/user_screen.dart';
import 'mocks/auth_mock.dart';

void main() {
  // IMPORTANT: Set up the Firebase Core mocks at the very beginning.
  setupFirebaseAuthMocks();

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('HomeScreen Navigation Tests', () {
    // this wont work because the itemscreen relies on info about each user
    testWidgets('Navigates to AddItemScreen when "New Item" is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      expect(find.text('New item'), findsOneWidget);

      await tester.tap(find.text('New item'));
      await tester.pump();

      expect(find.byType(ItemScreen), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets('Navigates to Settings when "Settings" icon is tapped', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(MaterialApp(home: HomeScreen()));

      expect(find.byIcon(Icons.settings), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    // this wont work because the user screen relies on info about each user
    testWidgets(
      'Navigates to UpdateProfileScreen when "Pencil" icon is tapped',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(home: HomeScreen()));

        expect(find.byIcon(Icons.edit), findsOneWidget);

        await tester.tap(find.byIcon(Icons.edit));
        await tester.pumpAndSettle();

        expect(find.byType(UserScreen), findsOneWidget);
      },
    );

  });
}
