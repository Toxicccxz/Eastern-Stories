import 'quest_definition.dart';
import 'equipment_slot.dart';
import 'skill_progress.dart';
import 'skill_definition.dart';
import 'innate_attributes.dart';

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
    required this.apprenticeship,
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
    String playerName = '少侠',
    PlayerGender gender = PlayerGender.male,
    InnateAttributes attributes = const InnateAttributes.standard(),
  }) {
    final maxHp = 50 + attributes.constitution * 2;
    final maxSpirit = 30 + attributes.spirituality * 2;
    return GameState(
      currentRoomId: startingRoomId,
      worldTurn: 0,
      player: PlayerState(
        name: playerName,
        gender: gender,
        attributes: attributes,
        level: 1,
        experience: 0,
        nextLevelExperience: 100,
        hp: maxHp,
        maxHp: maxHp,
        innerPower: 30,
        maxInnerPower: 30,
        spirit: maxSpirit,
        maxSpirit: maxSpirit,
        potential: 20,
        combatExperience: 0,
        betrayalCount: 0,
        silver: 20,
      ),
      visitedRoomIds: {startingRoomId},
      inventoryItemIds: const [],
      equippedItemIds: const {},
      skillProgress: const {},
      enabledSkillIds: const {},
      apprenticeship: null,
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
      apprenticeship:
          json['apprenticeship'] == null
              ? null
              : ApprenticeshipState.fromJson(
                json['apprenticeship'] as Map<String, Object?>,
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
  final ApprenticeshipState? apprenticeship;
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
      'apprenticeship': apprenticeship?.toJson(),
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
    Object? apprenticeship = _unchanged,
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
      apprenticeship:
          apprenticeship == _unchanged
              ? this.apprenticeship
              : apprenticeship as ApprenticeshipState?,
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

class ApprenticeshipState {
  const ApprenticeshipState({
    required this.familyId,
    required this.masterNpcId,
    required this.generation,
    required this.title,
    required this.contribution,
    this.rankId,
    this.completedTaskCount = 0,
    this.activeTask,
  });

  factory ApprenticeshipState.fromJson(Map<String, Object?> json) {
    return ApprenticeshipState(
      familyId: json['familyId'] as String,
      masterNpcId: json['masterNpcId'] as String,
      generation: json['generation'] as int,
      title: json['title'] as String,
      contribution: json['contribution'] as int? ?? 0,
      rankId: json['rankId'] as String?,
      completedTaskCount: json['completedTaskCount'] as int? ?? 0,
      activeTask:
          json['activeTask'] == null
              ? null
              : FamilyTaskProgress.fromJson(
                json['activeTask'] as Map<String, Object?>,
              ),
    );
  }

  final String familyId;
  final String masterNpcId;
  final int generation;
  final String title;
  final int contribution;
  final String? rankId;
  final int completedTaskCount;
  final FamilyTaskProgress? activeTask;

  Map<String, Object?> toJson() {
    return {
      'familyId': familyId,
      'masterNpcId': masterNpcId,
      'generation': generation,
      'title': title,
      'contribution': contribution,
      'rankId': rankId,
      'completedTaskCount': completedTaskCount,
      'activeTask': activeTask?.toJson(),
    };
  }

  ApprenticeshipState copyWith({
    String? title,
    int? contribution,
    Object? rankId = _unchanged,
    int? completedTaskCount,
    Object? activeTask = _unchanged,
  }) {
    return ApprenticeshipState(
      familyId: familyId,
      masterNpcId: masterNpcId,
      generation: generation,
      title: title ?? this.title,
      contribution: contribution ?? this.contribution,
      rankId: rankId == _unchanged ? this.rankId : rankId as String?,
      completedTaskCount: completedTaskCount ?? this.completedTaskCount,
      activeTask:
          activeTask == _unchanged
              ? this.activeTask
              : activeTask as FamilyTaskProgress?,
    );
  }
}

class FamilyTaskProgress {
  const FamilyTaskProgress({
    required this.taskId,
    this.isObjectiveComplete = false,
  });

  factory FamilyTaskProgress.fromJson(Map<String, Object?> json) {
    return FamilyTaskProgress(
      taskId: json['taskId'] as String,
      isObjectiveComplete: json['isObjectiveComplete'] as bool? ?? false,
    );
  }

  final String taskId;
  final bool isObjectiveComplete;

  Map<String, Object?> toJson() {
    return {'taskId': taskId, 'isObjectiveComplete': isObjectiveComplete};
  }

  FamilyTaskProgress copyWith({bool? isObjectiveComplete}) {
    return FamilyTaskProgress(
      taskId: taskId,
      isObjectiveComplete: isObjectiveComplete ?? this.isObjectiveComplete,
    );
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
    required this.gender,
    required this.attributes,
    required this.level,
    required this.experience,
    required this.nextLevelExperience,
    required this.hp,
    required this.maxHp,
    required this.innerPower,
    required this.maxInnerPower,
    required this.spirit,
    required this.maxSpirit,
    required this.potential,
    required this.combatExperience,
    required this.betrayalCount,
    required this.silver,
  });

  final String name;
  final PlayerGender gender;
  final InnateAttributes attributes;
  final int level;
  final int experience;
  final int nextLevelExperience;
  final int hp;
  final int maxHp;
  final int innerPower;
  final int maxInnerPower;
  final int spirit;
  final int maxSpirit;
  final int potential;
  int get intelligence => attributes.intelligence;
  final int combatExperience;
  final int betrayalCount;
  final int silver;

  factory PlayerState.fromJson(Map<String, Object?> json) {
    return PlayerState(
      name: json['name'] as String,
      gender: PlayerGender.values.byName(
        json['gender'] as String? ?? PlayerGender.male.name,
      ),
      attributes:
          json['attributes'] == null
              ? const InnateAttributes.standard().copyWith(
                intelligence: json['intelligence'] as int?,
              )
              : InnateAttributes.fromJson(
                json['attributes'] as Map<String, Object?>,
              ),
      level: json['level'] as int,
      experience: json['experience'] as int,
      nextLevelExperience: json['nextLevelExperience'] as int,
      hp: json['hp'] as int,
      maxHp: json['maxHp'] as int,
      innerPower: json['innerPower'] as int,
      maxInnerPower: json['maxInnerPower'] as int,
      spirit: json['spirit'] as int? ?? 60,
      maxSpirit: json['maxSpirit'] as int? ?? 60,
      potential: json['potential'] as int? ?? 20,
      combatExperience: json['combatExperience'] as int? ?? 0,
      betrayalCount: json['betrayalCount'] as int? ?? 0,
      silver: json['silver'] as int,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'gender': gender.name,
      'attributes': attributes.toJson(),
      'level': level,
      'experience': experience,
      'nextLevelExperience': nextLevelExperience,
      'hp': hp,
      'maxHp': maxHp,
      'innerPower': innerPower,
      'maxInnerPower': maxInnerPower,
      'spirit': spirit,
      'maxSpirit': maxSpirit,
      'potential': potential,
      'combatExperience': combatExperience,
      'betrayalCount': betrayalCount,
      'silver': silver,
    };
  }

  PlayerState copyWith({
    String? name,
    PlayerGender? gender,
    InnateAttributes? attributes,
    int? level,
    int? experience,
    int? nextLevelExperience,
    int? hp,
    int? maxHp,
    int? innerPower,
    int? maxInnerPower,
    int? spirit,
    int? maxSpirit,
    int? potential,
    int? intelligence,
    int? combatExperience,
    int? betrayalCount,
    int? silver,
  }) {
    return PlayerState(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      attributes: (attributes ?? this.attributes).copyWith(
        intelligence: intelligence,
      ),
      level: level ?? this.level,
      experience: experience ?? this.experience,
      nextLevelExperience: nextLevelExperience ?? this.nextLevelExperience,
      hp: hp ?? this.hp,
      maxHp: maxHp ?? this.maxHp,
      innerPower: innerPower ?? this.innerPower,
      maxInnerPower: maxInnerPower ?? this.maxInnerPower,
      spirit: spirit ?? this.spirit,
      maxSpirit: maxSpirit ?? this.maxSpirit,
      potential: potential ?? this.potential,
      combatExperience: combatExperience ?? this.combatExperience,
      betrayalCount: betrayalCount ?? this.betrayalCount,
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
