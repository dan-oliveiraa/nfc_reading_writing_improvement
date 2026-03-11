import 'dart:convert';
import 'dart:developer';

import '../domain/entities/nfc_entities.dart';
import 'atlas_mobile_plugin_card_lab1.dart';

class NfcServiceLab1 {
  List<int> _intToList(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  Future<List<SectorDataEntity>> read(List<SectorKeyEntity> sectorKeys) async {
    String sLog = "";
    int lastSectorLogged = -1;
    bool logged = false;
    var ret = <SectorDataEntity>[];

    List<int> serialNumberListInt = [];

    for (var key in sectorKeys) {
      if (serialNumberListInt.isEmpty) {
        if (!logged) {
          sLog += "detect ${key.sector}\n";
          final sn = await AtlasMobilePluginCardLab1.detect();
          if (sn == 0) {
             throw Exception("No card detected");
          }
          serialNumberListInt = _intToList(sn);
        }
      }
      
      if (serialNumberListInt.isNotEmpty) {
        int sector = key.sector * 4;
        if (lastSectorLogged != key.sector) {
          logged = await AtlasMobilePluginCardLab1.login(
              serialNumberListInt, sector, key.key, KeyType.keyA);
          sLog += "login ${key.sector} - success $logged\n";
          log("logou setor ${key.sector}");
        }
        if (logged) {
          lastSectorLogged = key.sector;
          var sectorData = <int>[];
          for (var i = sector; i < (sector + 3); i++) {
            sLog += "reading ${key.sector} - $i\n";
            var dataReaded = await AtlasMobilePluginCardLab1.read(i);

            sectorData.addAll(dataReaded);
          }

          ret.add(SectorDataEntity(sector: key.sector, data: sectorData));
        }
      }
    }
    return ret;
  }

  Future<List<CardWrittenBlockEntity>> writeCard(
      CardInitDataEntity command, int serialNumber,
      [bool isInit = true]) async {
    final writtenBlocks = <CardWrittenBlockEntity>[];

    List<int> serialNumberListInt = _intToList(serialNumber);

    CardUpdateDataEntity commands;

    if (isInit) {
      commands = command.initialize;
    } else {
      commands = command.initialize; // assuming same model for mock, real app would use command.update
    }

    if (commands.blocks.isNotEmpty) {
      int lastSector = -1;
      bool logged = false;

      for (var item in commands.blocks) {
        int itemSector = item['sector'] as int;
        int itemBlock = item['block'] as int;
        String itemType = item['type'] as String? ?? 'BLOCK';
        
        int block = itemBlock + (itemSector * 4);

        if (lastSector != itemSector) {
          final sectorKeyObj = commands.keys.where((element) => element.sector == itemSector).firstOrNull;
          if (sectorKeyObj != null) {
             logged = await AtlasMobilePluginCardLab1.login(
                 serialNumberListInt, itemSector, sectorKeyObj.key, KeyType.keyA);
          }
        }

        if (logged) {
          lastSector = itemSector;
          
          if (itemType == 'BLOCK') {
            // Write 
            final success = await AtlasMobilePluginCardLab1.writeBlock(block);
            if (success) {
               writtenBlocks.add(CardWrittenBlockEntity(block: itemBlock, success: true));
            } else {
               break;
            }
          } else if (itemType == 'DECREMENT') {
             // Mock decrement
            final success = await AtlasMobilePluginCardLab1.writeBlock(block);
            if (success) {
               writtenBlocks.add(CardWrittenBlockEntity(block: itemBlock, success: true));
            } else {
               break;
            }
          }
        } else {
          break;
        }
      }
    }

    log("writeCard: ${jsonEncode(writtenBlocks)}");
    return writtenBlocks;
  }
}
