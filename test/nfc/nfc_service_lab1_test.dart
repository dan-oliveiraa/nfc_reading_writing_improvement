import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_reading_writing_improvement/domain/entities/nfc_entities.dart';
import 'package:nfc_reading_writing_improvement/nfc/nfc_service_lab1.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel = MethodChannel('nfc_lab1');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'detect':
              return 11223344;
            case 'login':
              return true;
            case 'read':
              return <int>[1, 2, 3];
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

  test('read reads data correctly', () async {
    final service = NfcServiceLab1();
    final keys = [
      SectorKeyEntity(sector: 0, key: [0xFF, 0xFF]),
    ];

    final result = await service.read(keys);

    expect(result.length, 1);
    expect(result[0].sector, 0);
    expect(result[0].data, [1, 2, 3, 1, 2, 3, 1, 2, 3]);
  });

  test('read throws Exception if no card detected', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          if (methodCall.method == 'detect') return 0;
          return null;
        });

    final service = NfcServiceLab1();
    final keys = [
      SectorKeyEntity(sector: 0, key: [0xFF, 0xFF]),
    ];

    expect(() => service.read(keys), throwsA(isA<Exception>()));
  });

  test('writeCard writes blocks successfully', () async {
    final service = NfcServiceLab1();

    final keys = [
      SectorKeyEntity(sector: 0, key: [0xFF, 0xFF]),
    ];
    final blocks = [
      {'sector': 0, 'block': 0, 'type': 'BLOCK'},
      {'sector': 0, 'block': 1, 'type': 'DECREMENT'},
    ];

    final updateData = CardUpdateDataEntity(keys: keys, blocks: blocks);
    final initData = CardInitDataEntity(initialize: updateData);

    final writtenBlocks = await service.writeCard(initData, 11223344);

    expect(writtenBlocks.length, 2);
    expect(writtenBlocks[0].block, 0);
    expect(writtenBlocks[0].success, true);
    expect(writtenBlocks[1].block, 1);
    expect(writtenBlocks[1].success, true);
  });
}
