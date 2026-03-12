import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reading_writing_improvement/labs/lab2_screen.dart';

void main() {
  const MethodChannel channel = MethodChannel('nfc_lab2');
  const MethodChannel progressChannel = MethodChannel('nfc_lab2_progress');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'readAll') {
            const int numSectors = 40;
            return List.generate(
              numSectors,
              (i) => {
                'sector': i,
                'success': true,
                'data': List.generate(16, (j) => j),
              },
            );
          } else if (methodCall.method == 'writeAll') {
            const int numBlocks = 48;
            return List.generate(
              numBlocks,
              (i) => {'block': i, 'success': true},
            );
          }
          return null;
        });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(progressChannel, (
          MethodCall methodCall,
        ) async {
          if (methodCall.method == 'listen') {
            return null;
          } else if (methodCall.method == 'cancel') {
            return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(progressChannel, null);
  });

  testWidgets('Lab2Screen executes batch NFC flow successfully', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: Lab2Screen()));

    expect(find.text('Start Lab 2'), findsOneWidget);

    await tester.tap(find.text('Start Lab 2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('✅ Success'), findsOneWidget);
    expect(find.textContaining('Read 40 sectors'), findsOneWidget);
    expect(find.textContaining('Written 48 blocks'), findsOneWidget);
  });

  testWidgets('Lab2Screen handles partial success', (
    WidgetTester tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'readAll') {
            return List.generate(
              40,
              (i) => {
                'sector': i,
                'success': true,
                'data': [1],
              },
            );
          } else if (methodCall.method == 'writeAll') {
            var writeResult = List.generate(
              47,
              (i) => {'block': i, 'success': true},
            ).toList();
            writeResult.add({'block': 47, 'success': false});
            return writeResult;
          }
          return null;
        });

    await tester.pumpWidget(const MaterialApp(home: Lab2Screen()));

    await tester.tap(find.text('Start Lab 2'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Partial Success'), findsOneWidget);
    expect(find.textContaining('1 block(s) failed to write.'), findsOneWidget);
  });
}
