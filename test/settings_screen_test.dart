import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itemswap/screens/settings_screen.dart';
import 'package:itemswap/screens/change_email_screen.dart';
import 'package:itemswap/screens/change_password_screen.dart';
import 'package:itemswap/screens/delete_count_screen.dart';
import 'package:itemswap/screens/credits_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mocks/auth_mock.dart';

void main() {
  // IMPORTANT: Set up the Firebase Core mocks at the very beginning.
  setupFirebaseAuthMocks();

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Displays all setting buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );

    expect(find.text('Change Email'), findsOneWidget);
    expect(find.text('Change Password'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Credits'), findsOneWidget);
  });

  testWidgets('Navigates to ChangeEmailScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );

    await tester.tap(find.text('Change Email'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangeEmailScreen), findsOneWidget);
  });

  testWidgets('Navigates to ChangePasswordScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );

    await tester.tap(find.text('Change Password'));
    await tester.pumpAndSettle();

    expect(find.byType(ChangePasswordScreen), findsOneWidget);
  });

  testWidgets('Navigates to DeleteCountScreen and CreditsScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SettingsScreen()),
    );

    // Delete Account
    await tester.tap(find.text('Delete Account'));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteCountScreen), findsOneWidget);

    // Navigate back
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Credits
    await tester.tap(find.text('Credits'));
    await tester.pumpAndSettle();
    expect(find.byType(CreditsScreen), findsOneWidget);
  });


}
