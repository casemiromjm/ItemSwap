import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'mocks/auth_mock.mocks.dart';
import 'package:itemswap/screens/login_screen.dart';
import 'package:flutter/material.dart';

// Create a fake FirebaseAuth instance
final mockUser = MockUser(
  isAnonymous: false,
  uid: '12345',
  email: 'test@example.com',
  displayName: 'Test User',
  emailVerified: true,
);

final mockAuth = MockFirebaseAuth(mockUser: mockUser);

void main() {
  setUpAll(() async {
    // Firebase needs to be initialized manually in tests
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(); // This needs a test config or fake options (see below)
  });

  testWidgets('renders email, password and login button', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        auth: mockAuth, // You'll need to inject this into your widget
      ),
    ));

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Login'), findsOneWidget);
  });
}
