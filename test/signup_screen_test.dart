import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:itemswap/screens/signup_screen.dart';
import 'mocks/auth_mock.dart';
import 'package:mockito/mockito.dart';
import 'mocks/auth_mock.mocks.dart';

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Signup success shows verification dialog', (WidgetTester tester) async {
    final mockUser = MockUser();
    final mockAuth = MockFirebaseAuth();
    final mockUserCredential = MockUserCredential();

// Configura os comportamentos
    when(mockUser.isAnonymous).thenReturn(false);
    when(mockUser.email).thenReturn('test@example.com');
    when(mockUser.displayName).thenReturn('Test User');
    when(mockUser.emailVerified).thenReturn(false);
    when(mockUser.reload()).thenAnswer((_) async {});
    when(mockUser.sendEmailVerification()).thenAnswer((_) async {});
    when(mockUserCredential.user).thenReturn(mockUser);
    when(mockAuth.createUserWithEmailAndPassword(
      email: anyNamed('email'),
      password: anyNamed('password'),
    )).thenAnswer((_) async => mockUserCredential);
    when(mockAuth.currentUser).thenReturn(mockUser);


    // Renderiza o SignupScreen com o mock
    await tester.pumpWidget(
      MaterialApp(
        home: SignupScreen(auth: mockAuth),
      ),
    );

    // Preenche os campos de email e password
    await tester.enterText(find.byType(TextField).at(0), 'test@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');

    // Tap no botão 'Sign Up'
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));

    await tester.pump(); // primeiro frame
    await tester.pump(const Duration(seconds: 1)); // animação/dialog

    // Verifica se o diálogo de verificação aparece
    expect(find.text('Email Verification'), findsOneWidget);
    expect(find.textContaining('verify your account'), findsOneWidget);
  });
}
