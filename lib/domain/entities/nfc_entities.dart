enum KeyType { keyA, keyB }

class SectorKeyEntity {
  final int sector;
  final List<int> key;

  SectorKeyEntity({required this.sector, required this.key});
}

class SectorDataEntity {
  final int sector;
  final List<int> data;

  SectorDataEntity({required this.sector, required this.data});
}

class CardUpdateDataEntity {
  final List<SectorKeyEntity> keys;
  final List<Map<String, dynamic>> blocks;

  CardUpdateDataEntity({required this.keys, required this.blocks});
}

class CardInitDataEntity {
  final CardUpdateDataEntity initialize;

  CardInitDataEntity({required this.initialize});
}

class CardWrittenBlockEntity {
  final int block;
  final bool success;

  CardWrittenBlockEntity({required this.block, required this.success});

  Map<String, dynamic> toJson() => {
        'block': block,
        'success': success,
      };
}
