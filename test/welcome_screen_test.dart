import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itemswap/screens/welcome_screen.dart';
import 'package:itemswap/screens/login_screen.dart';
import 'package:itemswap/screens/signup_screen.dart';
import 'mocks/auth_mock.dart';

void main() {
  // IMPORTANT: Set up the Firebase Core mocks at the very beginning.
  setupFirebaseAuthMocks();

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('WelcomeScreen tests', () {
    testWidgets('WelcomeScreen renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verifica se a imagem do logo é exibida
      expect(find.byType(Image), findsOneWidget);

      // Verifica se os botões Login e Sign Up estão presentes
      expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign Up'), findsOneWidget);
    });

    testWidgets(
        'WelcomeScreen navigates to Login screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Clica no botão Login e verifica se navega para LoginScreen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pumpAndSettle(); // espera pela navegação

      expect(find.byType(LoginScreen), findsOneWidget);

      // Volta para WelcomeScreen
      await tester.pageBack();
      await tester.pumpAndSettle();
    });

    testWidgets('WelcomeScreen navigates to Sign Up screen', (
        WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Clica no botão Sign Up e verifica se navega para SignupScreen
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
      await tester.pumpAndSettle(); // espera pela navegação

      expect(find.byType(SignupScreen), findsOneWidget);
    });
  });
}
