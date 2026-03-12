import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reading_writing_improvement/domain/entities/nfc_entities.dart';
import 'package:nfc_reading_writing_improvement/nfc/nfc_service_lab2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('nfc_lab2');
  final nfcService = NfcServiceLab2();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'readAll') {
            return [
              {
                'sector': 0,
                'success': true,
                'data': <int>[10, 20],
              },
              {'sector': 1, 'success': false, 'data': <int>[]},
            ];
          } else if (methodCall.method == 'writeAll') {
            return [
              {'block': 0, 'success': true},
              {'block': 1, 'success': false},
            ];
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('read calls readAll and returns sectors', () async {
    final keys = [
      SectorKeyEntity(sector: 0, key: [0xFF, 0xFF]),
    ];
    final result = await nfcService.read(keys);

    expect(result.length, 2);
    expect(result[0].sector, 0);
    expect(result[0].data, [10, 20]);
    expect(result[1].sector, 1);
    expect(result[1].data, []);
  });

  test('writeCard calls writeAll and returns block results', () async {
    final keys = [
      SectorKeyEntity(sector: 0, key: [0xFF, 0xFF]),
    ];
    final blocks = [
      {'sector': 0, 'block': 0, 'type': 'BLOCK'},
      {'sector': 0, 'block': 1, 'type': 'BLOCK'},
    ];

    final updateData = CardUpdateDataEntity(keys: keys, blocks: blocks);
    final initData = CardInitDataEntity(initialize: updateData);

    final result = await nfcService.writeCard(initData, 12345);

    expect(result.length, 2);
    expect(result[0].block, 0);
    expect(result[0].success, true);
    expect(result[1].block, 1);
    expect(result[1].success, false);
  });

  test('NfcProgressEvent calculates percentage correctly', () {
    final event = NfcProgressEvent(
      type: 'read',
      sector: 0,
      index: 4,
      total: 10,
    );
    expect(event.percentage, 0.5);

    final zeroTotalEvent = NfcProgressEvent(
      type: 'read',
      sector: 0,
      index: 0,
      total: 0,
    );
    expect(zeroTotalEvent.percentage, 0.0);
  });
}
