import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:test1/screens/signup_screen.dart'; // ajusta para o teu path real
import 'auth_mock.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';


void main() {

  // Initialize Firebase before tests run.
  setUpAll(() async {
    await Firebase.initializeApp();
  });
  testWidgets('Signup success shows verification dialog', (WidgetTester tester) async {
    final mockUser = MockUser(
      isAnonymous: false,
      email: 'test@example.com',
      displayName: 'Test User',
      emailVerified: false,
    );

    final mockAuth = MockFirebaseAuth(mockUser: mockUser);

    // Renderiza o widget com o mock
    await tester.pumpWidget(
      MaterialApp(
        home: SignupScreen(),)
    );

    // Preenche os campos
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');

    // Clica no botão "Sign Up"
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle(); // espera tudo renderizar

    // Verifica se a caixa de diálogo foi aberta
    expect(find.text('Email Verification'), findsOneWidget);
    expect(find.textContaining('check your email'), findsOneWidget);
  });
}