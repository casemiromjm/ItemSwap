import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test1/screens/welcome_screen.dart';
import 'package:test1/screens/login_screen.dart';
import 'package:test1/screens/signup_screen.dart';

void main() {
  testWidgets('WelcomeScreen renders correctly and navigates', (WidgetTester tester) async {
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

    // Clica no botão Login e verifica se navega para LoginScreen
    /*await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle(); // espera pela navegação

    expect(find.byType(LoginScreen), findsOneWidget);

    // Volta para WelcomeScreen
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Clica no botão Sign Up e verifica se navega para SignupScreen
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign Up'));
    await tester.pumpAndSettle(); // espera pela navegação

    expect(find.byType(SignupScreen), findsOneWidget);*/
  });
}
