import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reading_writing_improvement/labs/lab1_screen.dart';

void main() {
  const MethodChannel channel = MethodChannel('nfc_lab1');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'detect':
              return 123456789;
            case 'login':
              return true;
            case 'read':
              return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16];
            case 'writeBlock':
              return true;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  testWidgets('Lab1Screen executes NFC flow successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Lab1Screen()));

    expect(find.text('Start Lab 1'), findsOneWidget);
    expect(find.textContaining('✅ Success'), findsNothing);

    await tester.tap(find.text('Start Lab 1'));

    await tester.pumpAndSettle();

    expect(find.textContaining('✅ Success'), findsOneWidget);
    expect(find.textContaining('Read 40 sectors'), findsOneWidget);
    expect(find.textContaining('Written 48 blocks'), findsOneWidget);
  });

  testWidgets('Lab1Screen handles NFC error gracefully', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'detect') {
            return 0;
          }
          return null;
        });

    await tester.pumpWidget(const MaterialApp(home: Lab1Screen()));

    await tester.tap(find.text('Start Lab 1'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('❌ Error: Exception: No card detected'),
      findsOneWidget,
    );
  });
}
