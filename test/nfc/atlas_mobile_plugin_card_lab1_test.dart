import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reading_writing_improvement/domain/entities/nfc_entities.dart';
import 'package:nfc_reading_writing_improvement/nfc/atlas_mobile_plugin_card_lab1.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('nfc_lab1');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'detect':
            return 987654321;
          case 'login':
            return true;
          case 'read':
            return <int>[10, 20, 30, 40];
          case 'writeBlock':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('detect returns serial number', () async {
    final result = await AtlasMobilePluginCardLab1.detect();
    expect(result, 987654321);
  });

  test('login returns true', () async {
    final result = await AtlasMobilePluginCardLab1.login([1, 2, 3], 0, [0xFF, 0xFF], KeyType.keyA);
    expect(result, true);
  });

  test('read returns list of ints', () async {
    final result = await AtlasMobilePluginCardLab1.read(5);
    expect(result, [10, 20, 30, 40]);
  });

  test('writeBlock returns true', () async {
    final result = await AtlasMobilePluginCardLab1.writeBlock(5);
    expect(result, true);
  });
}
