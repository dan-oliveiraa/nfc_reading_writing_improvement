import 'package:flutter/services.dart';
import '../domain/entities/nfc_entities.dart';

class AtlasMobilePluginCardLab1 {
  static const MethodChannel _channel = MethodChannel('nfc_lab1');

  static Future<int> detect() async {
    final int? result = await _channel.invokeMethod<int>('detect');
    return result ?? 0;
  }

  static Future<bool> login(
      List<int> serialNumber, int sector, List<int> key, KeyType keyType) async {
    final bool? result = await _channel.invokeMethod<bool>('login', {
      'serialNumber': serialNumber,
      'sector': sector,
      'key': key,
      'keyType': keyType.toString(),
    });
    return result ?? false;
  }

  static Future<List<int>> read(int block) async {
    final List<dynamic>? result = await _channel.invokeMethod<List<dynamic>>('read', {
      'block': block,
    });
    return result?.cast<int>() ?? <int>[];
  }

  static Future<bool> writeBlock(int block) async {
    final bool? result = await _channel.invokeMethod<bool>('writeBlock', {
      'block': block,
    });
    return result ?? false;
  }
}
