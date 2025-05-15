import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:itemswap/screens/search_screen.dart';

void main() {

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: 'fake',
          appId: 'fake',
          messagingSenderId: 'fake',
          projectId: 'itemswap-5af05',
        ),
      );
    }

    FirebaseFirestore.instance.settings = const Settings(
      host: '127.0.0.1:8080',
      sslEnabled: false,
      persistenceEnabled: false,
    );

    final collection = FirebaseFirestore.instance.collection('items');
    final docs = await collection.get();
    for (final doc in docs.docs) {
      await doc.reference.delete();
    }
  });

  testWidgets('Search for items by name', (WidgetTester tester) async {

    await FirebaseFirestore.instance.collection('items').add({
      'name': 'Laptop',
      'description': 'Gaming laptop',
    });
    await FirebaseFirestore.instance.collection('items').add({
      'name': 'Phone',
      'description': 'Smartphone',
    });

    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(firestore: FirebaseFirestore.instance),
      ),
    );

    // Enter a search query
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'Laptop');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify the search query
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('Phone'), findsNothing);
  });
}