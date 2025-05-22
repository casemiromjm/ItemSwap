import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:itemswap/screens/search_screen.dart';

void main() {
  testWidgets('Filter items by date of posting', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchScreen(),
      ),
    );

    // Open the sort dropdown
    final sortDropdown = find.byType(DropdownButton<String>).last;
    expect(sortDropdown, findsOneWidget);
    await tester.tap(sortDropdown);
    await tester.pumpAndSettle();

    // Select "Time" as the sort option
    final timeOption = find.text('Time').last;
    expect(timeOption, findsOneWidget);
    await tester.tap(timeOption);
    await tester.pumpAndSettle();

    // Verify the selected sort option
    expect(find.text('Time'), findsWidgets);
  });
}