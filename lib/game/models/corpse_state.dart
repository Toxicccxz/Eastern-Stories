enum CorpseDecayPhase { fresh, rotting, skeleton }

class CorpseState {
  const CorpseState({
    required this.id,
    required this.npcId,
    required this.victimName,
    required this.roomId,
    required this.rottensAtTurn,
    required this.skeletonizesAtTurn,
    required this.decaysAtTurn,
    this.itemCounts = const {},
  });

  factory CorpseState.fromJson(Map<String, Object?> json) {
    return CorpseState(
      id: json['id'] as String,
      npcId: json['npcId'] as String,
      victimName: json['victimName'] as String,
      roomId: json['roomId'] as String,
      rottensAtTurn:
          json['rottensAtTurn'] as int? ?? (json['decaysAtTurn'] as int) - 18,
      skeletonizesAtTurn:
          json['skeletonizesAtTurn'] as int? ??
          (json['decaysAtTurn'] as int) - 6,
      decaysAtTurn: json['decaysAtTurn'] as int,
      itemCounts: (json['itemCounts'] as Map<String, Object?>? ?? const {}).map(
        (itemId, quantity) => MapEntry(itemId, quantity as int),
      ),
    );
  }

  final String id;
  final String npcId;
  final String victimName;
  final String roomId;
  final int rottensAtTurn;
  final int skeletonizesAtTurn;
  final int decaysAtTurn;
  final Map<String, int> itemCounts;

  CorpseDecayPhase phaseAt(int worldTurn) {
    if (worldTurn >= skeletonizesAtTurn) {
      return CorpseDecayPhase.skeleton;
    }
    if (worldTurn >= rottensAtTurn) {
      return CorpseDecayPhase.rotting;
    }
    return CorpseDecayPhase.fresh;
  }

  bool canAnimateAt(int worldTurn) =>
      phaseAt(worldTurn) != CorpseDecayPhase.skeleton;

  String nameAt(int worldTurn) {
    return switch (phaseAt(worldTurn)) {
      CorpseDecayPhase.fresh => '$victimName的尸体',
      CorpseDecayPhase.rotting => '腐烂的尸体',
      CorpseDecayPhase.skeleton => '一具枯干的骸骨',
    };
  }

  String descriptionAt(int worldTurn) {
    return switch (phaseAt(worldTurn)) {
      CorpseDecayPhase.fresh => '这是$victimName死后留下的尸体。',
      CorpseDecayPhase.rotting => '这具尸体已经躺了一段时间，正散发着一股腐尸的味道。',
      CorpseDecayPhase.skeleton => '这副骸骨已经躺在这里很久了。',
    };
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'npcId': npcId,
      'victimName': victimName,
      'roomId': roomId,
      'rottensAtTurn': rottensAtTurn,
      'skeletonizesAtTurn': skeletonizesAtTurn,
      'decaysAtTurn': decaysAtTurn,
      'itemCounts': itemCounts,
    };
  }

  CorpseState copyWith({Map<String, int>? itemCounts}) {
    return CorpseState(
      id: id,
      npcId: npcId,
      victimName: victimName,
      roomId: roomId,
      rottensAtTurn: rottensAtTurn,
      skeletonizesAtTurn: skeletonizesAtTurn,
      decaysAtTurn: decaysAtTurn,
      itemCounts: itemCounts ?? this.itemCounts,
    );
  }
}

class UndeadCompanionState {
  const UndeadCompanionState({
    required this.name,
    required this.attack,
    required this.hp,
    required this.maxHp,
    required this.defense,
    required this.remainingTurns,
  });

  factory UndeadCompanionState.fromJson(Map<String, Object?> json) {
    return UndeadCompanionState(
      name: json['name'] as String,
      attack: json['attack'] as int,
      hp: json['hp'] as int,
      maxHp: json['maxHp'] as int,
      defense: json['defense'] as int,
      remainingTurns: json['remainingTurns'] as int,
    );
  }

  final String name;
  final int attack;
  final int hp;
  final int maxHp;
  final int defense;
  final int remainingTurns;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'attack': attack,
      'hp': hp,
      'maxHp': maxHp,
      'defense': defense,
      'remainingTurns': remainingTurns,
    };
  }

  UndeadCompanionState copyWith({int? hp, int? remainingTurns}) {
    return UndeadCompanionState(
      name: name,
      attack: attack,
      hp: hp ?? this.hp,
      maxHp: maxHp,
      defense: defense,
      remainingTurns: remainingTurns ?? this.remainingTurns,
    );
  }
}
