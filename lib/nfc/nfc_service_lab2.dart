import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import '../domain/entities/nfc_entities.dart';

class NfcServiceLab2 {
  static const MethodChannel _channel = MethodChannel('nfc_lab2');

  Future<List<SectorDataEntity>> read(List<SectorKeyEntity> sectorKeys) async {
    // We send all sector keys to the native side in a single batch call.
    final List<Map<String, dynamic>> keysMapped = sectorKeys.map((k) => {
      'sector': k.sector,
      'key': k.key,
      'keyType': 'keyA', // Hardcoded as in original logic
    }).toList();

    log('Calling Native to read all sectors in a single batch...');
    final List<dynamic>? result = await _channel.invokeMethod<List<dynamic>>('readAll', {
      'sectorKeys': keysMapped,
      'isAllKeys': sectorKeys.length >= 40,
    });

    if (result == null) return [];

    return result.map((e) {
      final map = Map<String, dynamic>.from(e);
      return SectorDataEntity(
        sector: map['sector'] as int,
        data: (map['data'] as List<dynamic>).cast<int>(),
      );
    }).toList();
  }

  Future<List<CardWrittenBlockEntity>> writeCard(
      CardInitDataEntity command, int serialNumber,
      [bool isInit = true]) async {
      
    log('Calling Native to write data in a single batch...');
    
    // Convert keys back to map for passing through MethodChannel
    final List<Map<String, dynamic>> keysMapped = command.initialize.keys.map((k) => {
      'sector': k.sector,
      'key': k.key,
      'keyType': 'keyA', // Hardcoded as in original logic
    }).toList();

    final List<dynamic>? result = await _channel.invokeMethod<List<dynamic>>('writeAll', {
      'serialNumber': serialNumber,
      'isInit': isInit,
      'blocks': command.initialize.blocks,
      'keys': keysMapped,
    });

    log("writeCard (Lab2): ${jsonEncode(result)}");

    if (result == null) return [];

    return result.map((e) {
      final map = Map<String, dynamic>.from(e);
      return CardWrittenBlockEntity(
        block: map['block'] as int,
        success: true, // We mapped block and sector dynamically in Kotlin
      );
    }).toList();
  }
}
