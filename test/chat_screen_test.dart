import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:test1/screens/contacts.dart';
import 'package:test1/screens/chat_screen.dart';

void main(){
  group('Chat Tests', (){
    testWidgets('Navigates back when implicit back button is tapped', (
        WidgetTester tester,
        ) async {
      // Contacts -> Chat -> Contacts
      await tester.pumpWidget(
        MaterialApp(
          home: Contacts(),
        ),
      );

      Navigator.of(tester.element(find.byType(Contacts))).push(
        MaterialPageRoute(builder: (context) => ChatScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChatScreen), findsOneWidget);

      final backButton = find.byTooltip('Back');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(Contacts), findsOneWidget);
      expect(find.byType(ChatScreen), findsNothing);
    });

    testWidgets('Textfield Test', (
        WidgetTester tester
        ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ChatScreen(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'hi');
    });

    testWidgets('Button Test', (
        WidgetTester tester
        ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const ChatScreen(),
        ),
      );
      await tester.enterText(find.byType(TextField), 'hi');

      // Tap the add button.
      await tester.tap(find.byType(IconButton));

      // Rebuild the widget after the state has changed.
      await tester.pump();

      // Expect to find the item on screen.
      expect(find.text('hi'), findsOneWidget);
    });
  });
}