import 'quest_definition.dart';
import 'equipment_slot.dart';
import 'skill_progress.dart';
import 'skill_definition.dart';

class GameState {
  const GameState({
    required this.currentRoomId,
    required this.worldTurn,
    required this.player,
    required this.visitedRoomIds,
    required this.inventoryItemIds,
    required this.equippedItemIds,
    required this.skillProgress,
    required this.enabledSkillIds,
    required this.roomItemOverrides,
    required this.npcStates,
    required this.shopStates,
    required this.questStatuses,
    required this.questFlags,
    required this.combat,
    required this.log,
  });

  factory GameState.initial({
    required String startingRoomId,
    Map<String, NpcRuntimeState> npcStates = const {},
    Map<String, ShopRuntimeState> shopStates = const {},
  }) {
    return GameState(
      currentRoomId: startingRoomId,
      worldTurn: 0,
      player: const PlayerState(
        name: '少侠',
        level: 1,
        experience: 0,
        nextLevelExperience: 100,
        hp: 80,
        maxHp: 80,
        innerPower: 30,
        maxInnerPower: 30,
        silver: 20,
      ),
      visitedRoomIds: {startingRoomId},
      inventoryItemIds: const [],
      equippedItemIds: const {},
      skillProgress: const {},
      enabledSkillIds: const {},
      roomItemOverrides: const {},
      npcStates: npcStates,
      shopStates: shopStates,
      questStatuses: const {},
      questFlags: const {},
      combat: null,
      log: const ['你在晨雾中醒来，东方故事就此开始。'],
    );
  }

  factory GameState.fromJson(Map<String, Object?> json) {
    return GameState(
      currentRoomId: json['currentRoomId'] as String,
      worldTurn: json['worldTurn'] as int? ?? 0,
      player: PlayerState.fromJson(json['player'] as Map<String, Object?>),
      visitedRoomIds:
          (json['visitedRoomIds'] as List<Object?>).cast<String>().toSet(),
      inventoryItemIds:
          (json['inventoryItemIds'] as List<Object?>).cast<String>(),
      equippedItemIds: _equipmentFromJson(json),
      skillProgress: _skillProgressFromJson(json),
      enabledSkillIds:
          (json['enabledSkillIds'] as Map<String, Object?>? ?? const {}).map(
            (usage, skillId) =>
                MapEntry(SkillUsage.values.byName(usage), skillId as String),
          ),
      roomItemOverrides: (json['roomItemOverrides'] as Map<String, Object?>)
          .map(
            (roomId, itemIds) =>
                MapEntry(roomId, (itemIds as List<Object?>).cast<String>()),
          ),
      npcStates: (json['npcStates'] as Map<String, Object?>? ?? const {}).map(
        (npcId, npcState) => MapEntry(
          npcId,
          NpcRuntimeState.fromJson(npcState as Map<String, Object?>),
        ),
      ),
      shopStates: (json['shopStates'] as Map<String, Object?>? ?? const {}).map(
        (npcId, shopState) => MapEntry(
          npcId,
          ShopRuntimeState.fromJson(shopState as Map<String, Object?>),
        ),
      ),
      questStatuses: (json['questStatuses'] as Map<String, Object?>).map(
        (questId, status) => MapEntry(questId, _questStatusFromName(status)),
      ),
      questFlags: (json['questFlags'] as List<Object?>).cast<String>().toSet(),
      combat:
          json['combat'] == null
              ? null
              : CombatState.fromJson(json['combat'] as Map<String, Object?>),
      log: (json['log'] as List<Object?>).cast<String>(),
    );
  }

  final String currentRoomId;
  final int worldTurn;
  final PlayerState player;
  final Set<String> visitedRoomIds;
  final List<String> inventoryItemIds;
  final Map<EquipmentSlot, String> equippedItemIds;
  final Map<String, SkillProgress> skillProgress;
  final Map<SkillUsage, String> enabledSkillIds;
  final Map<String, List<String>> roomItemOverrides;
  final Map<String, NpcRuntimeState> npcStates;
  final Map<String, ShopRuntimeState> shopStates;
  final Map<String, QuestStatus> questStatuses;
  final Set<String> questFlags;
  final CombatState? combat;
  final List<String> log;

  Map<String, Object?> toJson() {
    return {
      'currentRoomId': currentRoomId,
      'worldTurn': worldTurn,
      'player': player.toJson(),
      'visitedRoomIds': visitedRoomIds.toList(),
      'inventoryItemIds': inventoryItemIds,
      'equippedItemIds': equippedItemIds.map(
        (slot, itemId) => MapEntry(slot.name, itemId),
      ),
      'equippedWeaponId': equippedWeaponId,
      'skillProgress': skillProgress.map(
        (skillId, progress) => MapEntry(skillId, progress.toJson()),
      ),
      'enabledSkillIds': enabledSkillIds.map(
        (usage, skillId) => MapEntry(usage.name, skillId),
      ),
      'learnedSkillIds': learnedSkillIds.toList(),
      'roomItemOverrides': roomItemOverrides,
      'npcStates': npcStates.map(
        (npcId, npcState) => MapEntry(npcId, npcState.toJson()),
      ),
      'shopStates': shopStates.map(
        (npcId, shopState) => MapEntry(npcId, shopState.toJson()),
      ),
      'questStatuses': questStatuses.map(
        (questId, status) => MapEntry(questId, status.name),
      ),
      'questFlags': questFlags.toList(),
      'combat': combat?.toJson(),
      'log': log,
    };
  }

  GameState copyWith({
    String? currentRoomId,
    int? worldTurn,
    PlayerState? player,
    Set<String>? visitedRoomIds,
    List<String>? inventoryItemIds,
    Map<EquipmentSlot, String>? equippedItemIds,
    Object? equippedWeaponId = _unchanged,
    Map<String, SkillProgress>? skillProgress,
    Map<SkillUsage, String>? enabledSkillIds,
    Set<String>? learnedSkillIds,
    Map<String, List<String>>? roomItemOverrides,
    Map<String, NpcRuntimeState>? npcStates,
    Map<String, ShopRuntimeState>? shopStates,
    Map<String, QuestStatus>? questStatuses,
    Set<String>? questFlags,
    Object? combat = _unchanged,
    List<String>? log,
  }) {
    final nextEquipment = {...(equippedItemIds ?? this.equippedItemIds)};
    if (equippedWeaponId != _unchanged) {
      final weaponId = equippedWeaponId as String?;
      if (weaponId == null) {
        nextEquipment.remove(EquipmentSlot.weapon);
      } else {
        nextEquipment[EquipmentSlot.weapon] = weaponId;
      }
    }
    var nextSkillProgress = skillProgress ?? this.skillProgress;
    if (learnedSkillIds != null) {
      nextSkillProgress = {
        for (final skillId in learnedSkillIds)
          skillId:
              nextSkillProgress[skillId] ??
              const SkillProgress(level: 1, experience: 0),
      };
    }

    return GameState(
      currentRoomId: currentRoomId ?? this.currentRoomId,
      worldTurn: worldTurn ?? this.worldTurn,
      player: player ?? this.player,
      visitedRoomIds: visitedRoomIds ?? this.visitedRoomIds,
      inventoryItemIds: inventoryItemIds ?? this.inventoryItemIds,
      equippedItemIds: nextEquipment,
      skillProgress: nextSkillProgress,
      enabledSkillIds: enabledSkillIds ?? this.enabledSkillIds,
      roomItemOverrides: roomItemOverrides ?? this.roomItemOverrides,
      npcStates: npcStates ?? this.npcStates,
      shopStates: shopStates ?? this.shopStates,
      questStatuses: questStatuses ?? this.questStatuses,
      questFlags: questFlags ?? this.questFlags,
      combat: combat == _unchanged ? this.combat : combat as CombatState?,
      log: log ?? this.log,
    );
  }

  List<String> logWith(String message) {
    return [...log, message].takeLast(20);
  }

  String? get equippedWeaponId => equippedItemIds[EquipmentSlot.weapon];

  Set<String> get learnedSkillIds => skillProgress.keys.toSet();
}

class ShopRuntimeState {
  const ShopRuntimeState({required this.stockByItemId});

  factory ShopRuntimeState.fromJson(Map<String, Object?> json) {
    return ShopRuntimeState(
      stockByItemId: (json['stockByItemId'] as Map<String, Object?>).map(
        (itemId, stock) => MapEntry(itemId, stock as int),
      ),
    );
  }

  final Map<String, int> stockByItemId;

  Map<String, Object?> toJson() {
    return {'stockByItemId': stockByItemId};
  }

  ShopRuntimeState copyWith({Map<String, int>? stockByItemId}) {
    return ShopRuntimeState(stockByItemId: stockByItemId ?? this.stockByItemId);
  }
}

class NpcRuntimeState {
  const NpcRuntimeState({
    required this.roomId,
    required this.currentHp,
    required this.isDefeated,
    this.respawnAtTurn,
    this.hasDroppedLoot = false,
    this.isFollowing = false,
    this.isRemoved = false,
  });

  factory NpcRuntimeState.fromJson(Map<String, Object?> json) {
    return NpcRuntimeState(
      roomId: json['roomId'] as String,
      currentHp: json['currentHp'] as int,
      isDefeated: json['isDefeated'] as bool,
      respawnAtTurn: json['respawnAtTurn'] as int?,
      hasDroppedLoot: json['hasDroppedLoot'] as bool? ?? false,
      isFollowing: json['isFollowing'] as bool? ?? false,
      isRemoved: json['isRemoved'] as bool? ?? false,
    );
  }

  final String roomId;
  final int currentHp;
  final bool isDefeated;
  final int? respawnAtTurn;
  final bool hasDroppedLoot;
  final bool isFollowing;
  final bool isRemoved;

  Map<String, Object?> toJson() {
    return {
      'roomId': roomId,
      'currentHp': currentHp,
      'isDefeated': isDefeated,
      'respawnAtTurn': respawnAtTurn,
      'hasDroppedLoot': hasDroppedLoot,
      'isFollowing': isFollowing,
      'isRemoved': isRemoved,
    };
  }

  NpcRuntimeState copyWith({
    String? roomId,
    int? currentHp,
    bool? isDefeated,
    Object? respawnAtTurn = _unchanged,
    bool? hasDroppedLoot,
    bool? isFollowing,
    bool? isRemoved,
  }) {
    return NpcRuntimeState(
      roomId: roomId ?? this.roomId,
      currentHp: currentHp ?? this.currentHp,
      isDefeated: isDefeated ?? this.isDefeated,
      respawnAtTurn:
          respawnAtTurn == _unchanged
              ? this.respawnAtTurn
              : respawnAtTurn as int?,
      hasDroppedLoot: hasDroppedLoot ?? this.hasDroppedLoot,
      isFollowing: isFollowing ?? this.isFollowing,
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }
}

class PlayerState {
  const PlayerState({
    required this.name,
    required this.level,
    required this.experience,
    required this.nextLevelExperience,
    required this.hp,
    required this.maxHp,
    required this.innerPower,
    required this.maxInnerPower,
    required this.silver,
  });

  final String name;
  final int level;
  final int experience;
  final int nextLevelExperience;
  final int hp;
  final int maxHp;
  final int innerPower;
  final int maxInnerPower;
  final int silver;

  factory PlayerState.fromJson(Map<String, Object?> json) {
    return PlayerState(
      name: json['name'] as String,
      level: json['level'] as int,
      experience: json['experience'] as int,
      nextLevelExperience: json['nextLevelExperience'] as int,
      hp: json['hp'] as int,
      maxHp: json['maxHp'] as int,
      innerPower: json['innerPower'] as int,
      maxInnerPower: json['maxInnerPower'] as int,
      silver: json['silver'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'level': level,
      'experience': experience,
      'nextLevelExperience': nextLevelExperience,
      'hp': hp,
      'maxHp': maxHp,
      'innerPower': innerPower,
      'maxInnerPower': maxInnerPower,
      'silver': silver,
    };
  }

  PlayerState copyWith({
    int? level,
    int? experience,
    int? nextLevelExperience,
    int? hp,
    int? maxHp,
    int? innerPower,
    int? maxInnerPower,
    int? silver,
  }) {
    return PlayerState(
      name: name,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      nextLevelExperience: nextLevelExperience ?? this.nextLevelExperience,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      innerPower: innerPower ?? this.innerPower,
      maxInnerPower: maxInnerPower ?? this.maxInnerPower,
      silver: silver ?? this.silver,
    );
  }
}

class CombatState {
  const CombatState({
    required this.npcId,
    required this.enemyHp,
    this.round = 0,
  });

  factory CombatState.fromJson(Map<String, Object?> json) {
    return CombatState(
      npcId: json['npcId'] as String,
      enemyHp: json['enemyHp'] as int,
      round: json['round'] as int? ?? 0,
    );
  }

  final String npcId;
  final int enemyHp;
  final int round;

  Map<String, Object?> toJson() {
    return {'npcId': npcId, 'enemyHp': enemyHp, 'round': round};
  }

  CombatState copyWith({int? enemyHp, int? round}) {
    return CombatState(
      npcId: npcId,
      enemyHp: enemyHp ?? this.enemyHp,
      round: round ?? this.round,
    );
  }
}

const Object _unchanged = Object();

Map<EquipmentSlot, String> _equipmentFromJson(Map<String, Object?> json) {
  final equipment =
      (json['equippedItemIds'] as Map<String, Object?>? ?? const {}).map(
        (slot, itemId) =>
            MapEntry(EquipmentSlot.values.byName(slot), itemId as String),
      );
  final legacyWeaponId = json['equippedWeaponId'] as String?;
  if (legacyWeaponId != null) {
    equipment.putIfAbsent(EquipmentSlot.weapon, () => legacyWeaponId);
  }
  return equipment;
}

Map<String, SkillProgress> _skillProgressFromJson(Map<String, Object?> json) {
  final savedProgress = json['skillProgress'] as Map<String, Object?>?;
  if (savedProgress != null) {
    return savedProgress.map(
      (skillId, progress) => MapEntry(
        skillId,
        SkillProgress.fromJson(progress as Map<String, Object?>),
      ),
    );
  }
  return {
    for (final skillId
        in (json['learnedSkillIds'] as List<Object?>? ?? const [])
            .cast<String>())
      skillId: const SkillProgress(level: 1, experience: 0),
  };
}

QuestStatus _questStatusFromName(Object? name) {
  return QuestStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => QuestStatus.notStarted,
  );
}

extension _RecentItems<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) {
      return this;
    }
    return sublist(length - count);
  }
}
