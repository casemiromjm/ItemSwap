import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:itemswap/screens/login_screen.dart';
import 'package:itemswap/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Screen Tests', () {
    late FirebaseAuth auth;

    const testEmail = 'test_user@example.com';
    const testPassword = 'test_password';

    setUpAll(() async {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      auth = FirebaseAuth.instance;
      if (kIsWeb) {
        auth.useAuthEmulator('localhost', 9099);
      }
      await auth.signOut();
    });

    testWidgets('Login', (WidgetTester tester) async {
      // Sign out any existing user
      await auth.signOut();

      // Launch the app
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(), // Directly test this screen
        ),
      );
      await tester.pumpAndSettle();

      // Enter email and password by keys
      final loginEmailField = find.byKey(ValueKey('login_email'));
      final loginPasswordField = find.byKey(ValueKey('login_password'));
      expect(loginEmailField, findsOneWidget);
      expect(loginPasswordField, findsOneWidget);

      await tester.tap(loginEmailField);
      await tester.enterText(loginEmailField, testEmail);
      await tester.tap(loginPasswordField);
      await tester.enterText(loginPasswordField, testPassword);
      await tester.pumpAndSettle();

      // Tap on Login button by key
      final loginButton = find.byKey(ValueKey('login_button'));
      expect(loginButton, findsOneWidget);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();
    });
  });
}
