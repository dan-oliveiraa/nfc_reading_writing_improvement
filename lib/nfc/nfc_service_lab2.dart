import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/services.dart';
import '../domain/entities/nfc_entities.dart';

// Fix #1: Progress event model
class NfcProgressEvent {
  final String type; // 'read' or 'write'
  final int sector;
  final int? block;
  final int index;
  final int total;

  NfcProgressEvent({
    required this.type,
    required this.sector,
    this.block,
    required this.index,
    required this.total,
  });

  double get percentage => total == 0 ? 0 : (index + 1) / total;

  factory NfcProgressEvent.fromMap(Map<dynamic, dynamic> map) {
    return NfcProgressEvent(
      type: map['type'] as String,
      sector: map['sector'] as int,
      block: map['block'] as int?,
      index: map['index'] as int,
      total: map['total'] as int,
    );
  }
}

class NfcServiceLab2 {
  static const MethodChannel _channel = MethodChannel('nfc_lab2');

  // Fix #1: EventChannel to receive progress from Kotlin
  static const EventChannel _progressChannel = EventChannel('nfc_lab2_progress');

  Stream<NfcProgressEvent> get progressStream =>
      _progressChannel.receiveBroadcastStream().map(
            (event) => NfcProgressEvent.fromMap(event as Map),
          );

  Future<List<SectorDataEntity>> read(
    List<SectorKeyEntity> sectorKeys, {
    // Fix #3: explicit cardType instead of magic number heuristic
    String cardType = '1K',
  }) async {
    final List<Map<String, dynamic>> keysMapped = sectorKeys
        .map((k) => {
              'sector': k.sector,
              'key': k.key,
              'keyType': 'keyA',
            })
        .toList();

    log('Calling Native to read all sectors in a single batch (cardType: $cardType)...');

    final List<dynamic>? result =
        await _channel.invokeMethod<List<dynamic>>('readAll', {
      'sectorKeys': keysMapped,
      'cardType': cardType, // Fix #3
      'isAllKeys': sectorKeys.length >= (cardType == '4K' ? 40 : 16),
    });

    if (result == null) return [];

    return result.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      // Fix #5: read the actual success field from Kotlin
      final success = map['success'] as bool? ?? false;
      if (!success) {
        log('Sector ${map['sector']} reported failure from native layer.');
      }
      return SectorDataEntity(
        sector: map['sector'] as int,
        data: (map['data'] as List<dynamic>).cast<int>(),
      );
    }).toList();
  }

  Future<List<CardWrittenBlockEntity>> writeCard(
    CardInitDataEntity command,
    int serialNumber, [
    bool isInit = true,
  ]) async {
    log('Calling Native to write data in a single batch...');

    final List<Map<String, dynamic>> keysMapped =
        command.initialize.keys.map((k) => {
              'sector': k.sector,
              'key': k.key,
              'keyType': 'keyA',
            }).toList();

    final List<dynamic>? result =
        await _channel.invokeMethod<List<dynamic>>('writeAll', {
      'serialNumber': serialNumber,
      'isInit': isInit,
      'blocks': command.initialize.blocks,
      'keys': keysMapped,
    });

    log("writeCard (Lab2): ${jsonEncode(result)}");

    if (result == null) return [];

    return result.map((e) {
      final map = Map<String, dynamic>.from(e as Map);
      // Fix #5: read actual success from Kotlin instead of hardcoding true
      return CardWrittenBlockEntity(
        block: map['block'] as int,
        success: map['success'] as bool? ?? false,
      );
    }).toList();
  }
}
