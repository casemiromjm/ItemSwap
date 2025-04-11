import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

// Import your screens.
import 'package:test1/screens/add_item_screen.dart';
import 'package:test1/screens/home_screen.dart';

// Import Firebase auth mocks.
import 'auth_mock.dart';
import 'auth_mock.mocks.dart'; // Ensure the mocks are generated and imported

/// A fake MapScreen widget to simulate location picking.
/// When pushed, it immediately pops with a test LatLng.
class FakeMapScreen extends StatelessWidget {
  const FakeMapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Immediately pop with a fake location.
    Future.delayed(Duration.zero, () {
      Navigator.pop(context, LatLng(12.3456, 65.4321));
    });
    return const Scaffold(body: Center(child: Text('Fake Map Screen')));
  }
}

void main() {
  // IMPORTANT: Set up Firebase Auth mocks before running tests.
  setupFirebaseAuthMocks();
  TestWidgetsFlutterBinding.ensureInitialized();
  // Override HttpOverrides to prevent network errors (e.g. for OSM tiles).
  HttpOverrides.global = TestHttpOverrides();

  // Initialize Firebase.
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('AddItemScreen Widget Tests', () {
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      // Create a mock user with a valid UID.
      mockUser = MockUser();
      when(mockUser.uid).thenReturn('test-uid');

      // Create a mock FirebaseAuth instance with the mockUser signed in.
      mockAuth = MockFirebaseAuth();
      // You may configure additional behaviors if needed.
      when(mockAuth.currentUser).thenReturn(mockUser);
    });

    testWidgets('Shows error SnackBar if fields are incomplete', (
      WidgetTester tester,
    ) async {
      // Build the widget inside a MaterialApp.
      final fakeFirestore = FakeFirebaseFirestore();
      await tester.pumpWidget(
        MaterialApp(
          home: AddItemScreen(
            mapScreenBuilder: (context) => const FakeMapScreen(),
            auth: mockAuth,
            firestore: fakeFirestore, // <-- Add the fakeFirestore instance
          ),
        ),
      );

      // Ensure the Submit Item button is visible.
      final submitFinder = find.text('Submit Item');
      await tester.ensureVisible(submitFinder);

      // Tap the "Submit Item" button without filling any fields.
      await tester.tap(submitFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Expect the SnackBar with the error text to be shown.
      expect(find.text('Please fill in all fields'), findsOneWidget);
    });

    testWidgets(
      'Submits item and navigates to HomeScreen when valid input is provided',
      (WidgetTester tester) async {
        // Build MaterialApp and inject FakeMapScreen using mapScreenBuilder,
        // and pass the mockAuth instance.
        final fakeFirestore = FakeFirebaseFirestore();
        await tester.pumpWidget(
          MaterialApp(
            home: AddItemScreen(
              mapScreenBuilder: (context) => const FakeMapScreen(),
              auth: mockAuth,
              firestore: fakeFirestore, // <-- Add the fakeFirestore instance
            ),
          ),
        );

        // Fill in the item type dropdown.
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Books').last);
        await tester.pumpAndSettle();

        // Enter text into the item name and description text fields.
        await tester.enterText(find.byType(TextField).at(0), 'Test Item');
        await tester.enterText(
          find.byType(TextField).at(1),
          'Test description',
        );

        // Tap the location button.
        final locationIconFinder = find.byIcon(Icons.map);
        await tester.ensureVisible(locationIconFinder);
        await tester.tap(locationIconFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Verify the location button displays the fake coordinates.
        expect(find.textContaining('Selected:'), findsOneWidget);

        // Tap the "Submit Item" button.
        final submitFinder = find.text('Submit Item');
        await tester.ensureVisible(submitFinder);
        await tester.tap(submitFinder, warnIfMissed: false);
        await tester.pumpAndSettle();

        // Verify that the item was added to the mock Firestore
        final itemsCollection = fakeFirestore.collection('items');
        final snapshot = await itemsCollection.get();
        expect(snapshot.docs.length, 1);
        // Verify that after submission the HomeScreen is shown.
        expect(find.byType(HomeScreen), findsOneWidget);
        // Also verify that the success SnackBar is shown.
        expect(find.text('Item submitted successfully!'), findsOneWidget);
      },
    );
  });
}

/// A simple HttpOverrides implementation for testing purposes.
/// It prevents network calls from failing in the widget tests.
class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => true;
  }
}
