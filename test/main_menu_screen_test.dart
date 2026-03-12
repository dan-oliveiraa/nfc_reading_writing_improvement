import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reading_writing_improvement/labs/lab1_screen.dart';
import 'package:nfc_reading_writing_improvement/labs/lab2_screen.dart';
import 'package:nfc_reading_writing_improvement/main.dart';

void main() {
  testWidgets('MainMenuScreen renders correctly and navigates to Labs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('NFC Performance Labs'), findsOneWidget);

    expect(
      find.text(
        'Select a Lab to run the NFC operations and measure execution time.',
      ),
      findsOneWidget,
    );

    expect(
      find.widgetWithText(ElevatedButton, 'Lab 1: The Bad Way'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(ElevatedButton, 'Lab 2: The Good Way'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(ElevatedButton, 'Lab 1: The Bad Way'));
    await tester.pumpAndSettle();

    expect(find.byType(Lab1Screen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Lab 2: The Good Way'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Lab2Screen), findsOneWidget);
  });
}
