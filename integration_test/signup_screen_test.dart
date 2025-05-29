import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:itemswap/screens/signup_screen.dart';
import 'package:itemswap/firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  group('Signup Screen Tests', () {
    late FirebaseAuth auth;
    late FirebaseFirestore firestore;

    const testEmail = 'test_user@example.com';
    const testPassword = 'test_password';

    setUpAll(() async {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      auth = FirebaseAuth.instance;
      firestore = FirebaseFirestore.instance;
      if (kIsWeb) {
        auth.useAuthEmulator('localhost', 9099);
        firestore.useFirestoreEmulator('localhost', 8080);
      }
      await auth.signOut();
    });

    testWidgets('SignUp', (WidgetTester tester) async {
      // Sign out any existing user
      await auth.signOut();

      // Launch the app
      await tester.pumpWidget(
        MaterialApp(
          home: SignupScreen(), // Directly test this screen
        ),
      );
      await tester.pumpAndSettle();

      // Fill in email and password by keys
      final emailField = find.byKey(ValueKey('signup_email'));
      final passwordField = find.byKey(ValueKey('signup_password'));
      expect(emailField, findsOneWidget);
      expect(passwordField, findsOneWidget);

      await tester.tap(emailField);
      await tester.enterText(emailField, testEmail);
      await tester.tap(passwordField);
      await tester.enterText(passwordField, testPassword);
      await tester.pumpAndSettle();

      // Submit sign up by key
      final signUpButton = find.byKey(ValueKey('signup_button'));
      expect(signUpButton, findsOneWidget);
      await tester.tap(signUpButton);
      await tester.pumpAndSettle();
    });
  });
}
