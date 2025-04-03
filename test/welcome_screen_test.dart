import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test1/screens/welcome_screen.dart';
import 'package:test1/screens/login_screen.dart';
import 'package:test1/screens/signup_screen.dart';
import 'package:test1/firebase_options.dart';


// Create a Mock Firebase instance
class MockFirebaseApp extends Mock implements Firebase {}

void main() {
  setUpAll(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Properly initialize Firebase for tests
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  testWidgets('WelcomeScreen UI and navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WelcomeScreen(),
      ),
    );

    // Check if the logo is present
    expect(find.byType(Image), findsOneWidget);

    // Verify if Login and Sign Up buttons exist
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Sign Up'), findsOneWidget);

    // Tap on Login button and navigate
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    // Navigate back
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Tap on Sign Up button and navigate
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.byType(SignupScreen), findsOneWidget);
  });
}