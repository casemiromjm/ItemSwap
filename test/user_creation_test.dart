import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test1/screens/user_creation_screen.dart';
import 'auth_mock.dart';
import 'auth_mock.mocks.dart'; // Gera com @GenerateMocks

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('User can update display name in UserCreationScreen', (
      WidgetTester tester) async {
    final mockAuth = MockFirebaseAuth();
    final mockUser = MockUser();
    final mockFirestore = MockFirebaseFirestore();
    final mockCollection = MockCollectionReference();
    final mockDocRef = MockDocumentReference();
    final mockDocSnapshot = MockDocumentSnapshot();

    // Mock auth
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.uid).thenReturn('uid_teste');
    when(mockUser.displayName).thenReturn('Nome Antigo');
    when(mockUser.updateDisplayName(any)).thenAnswer((_) async => null);


    // Mock Firestore
    when(mockFirestore.collection('users')).thenReturn(mockCollection);
    when(mockCollection.doc('uid_teste')).thenReturn(mockDocRef);
    when(mockDocRef.get()).thenAnswer((_) async => mockDocSnapshot);

    // Dados simulados do documento
    when(mockDocSnapshot.exists).thenReturn(true);
    when(mockDocSnapshot.data()).thenReturn({
      'username': 'Nome Antigo',
      'description': 'Descrição Antiga',
      'image': null,
      'items_given': 0,
      'items_received': 0,
      'created_at': Timestamp.now(),
    });

    await tester.pumpWidget(
      MaterialApp(
        home: UserCreationScreen(auth: mockAuth, firestore: mockFirestore),
      ),
    );

    await tester.pumpAndSettle();

    final nameField = find.byKey(Key('nameField'));
    final descField = find.byKey(Key('descField'));

    expect(nameField, findsOneWidget);
    expect(descField, findsOneWidget);

    await tester.enterText(nameField, 'Novo Nome');
    await tester.enterText(descField, 'Nova descrição');

    const base64Pixel = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO8MB70AAAAASUVORK5CYII=';

    final state = tester.state(find.byType(UserCreationScreen)) as dynamic;
    state.setImageBase64(base64Pixel);


    final saveButton = find.byKey(Key('saveButton'));
    expect(saveButton, findsOneWidget);
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    verify(mockUser.updateDisplayName('Novo Nome')).called(1);
  });
}
