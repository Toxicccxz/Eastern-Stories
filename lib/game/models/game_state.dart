import 'quest_definition.dart';
import 'equipment_slot.dart';
import 'skill_progress.dart';
import 'skill_definition.dart';
import 'innate_attributes.dart';
import 'inventory_state.dart';

class GameState {
  const GameState({
    required this.currentRoomId,
    required this.worldTurn,
    required this.player,
    required this.visitedRoomIds,
    required this.inventory,
    required this.equippedItemIds,
    required this.skillProgress,
    required this.enabledSkillIds,
    required this.apprenticeship,
    required this.roomItemOverrides,
    required this.npcStates,
    required this.shopStates,
    required this.questStatuses,
    required this.questFlags,
    required this.playerStatusEffects,
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
      inventory: InventoryState.empty(),
      equippedItemIds: const {},
      skillProgress: const {},
      enabledSkillIds: const {},
      apprenticeship: null,
      roomItemOverrides: const {},
      npcStates: npcStates,
      shopStates: shopStates,
      questStatuses: const {},
      questFlags: const {},
      playerStatusEffects: const [],
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
      inventory: InventoryState.fromJson(
        json['inventory'],
        legacyItemIds: json['inventoryItemIds'],
      ),
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
      playerStatusEffects: _playerStatusEffectsFromJson(json),
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
  final InventoryState inventory;
  final Map<EquipmentSlot, String> equippedItemIds;
  final Map<String, SkillProgress> skillProgress;
  final Map<SkillUsage, String> enabledSkillIds;
  final ApprenticeshipState? apprenticeship;
  final Map<String, List<String>> roomItemOverrides;
  final Map<String, NpcRuntimeState> npcStates;
  final Map<String, ShopRuntimeState> shopStates;
  final Map<String, QuestStatus> questStatuses;
  final Set<String> questFlags;
  final List<StatusEffectState> playerStatusEffects;
  final CombatState? combat;
  final List<String> log;

  Map<String, Object?> toJson() {
    return {
      'currentRoomId': currentRoomId,
      'worldTurn': worldTurn,
      'player': player.toJson(),
      'visitedRoomIds': visitedRoomIds.toList(),
      'inventory': inventory.toJson(),
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
      'playerStatusEffects': [
        for (final effect in playerStatusEffects) effect.toJson(),
      ],
      'combat': combat?.toJson(),
      'log': log,
    };
  }

  GameState copyWith({
    String? currentRoomId,
    int? worldTurn,
    PlayerState? player,
    Set<String>? visitedRoomIds,
    InventoryState? inventory,
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
    List<StatusEffectState>? playerStatusEffects,
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
      inventory:
          inventory ??
          (inventoryItemIds == null
              ? this.inventory
              : InventoryState.fromItemIds(inventoryItemIds)),
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
      playerStatusEffects: playerStatusEffects ?? this.playerStatusEffects,
      combat: combat == _unchanged ? this.combat : combat as CombatState?,
      log: log ?? this.log,
    );
  }

  List<String> logWith(String message) {
    return [...log, message].takeLast(20);
  }

  String? get equippedWeaponId => equippedItemIds[EquipmentSlot.weapon];

  Set<String> get learnedSkillIds => skillProgress.keys.toSet();

  List<String> get inventoryItemIds => inventory.toExpandedItemIds();
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
    this.completedTargetIds = const {},
  });

  factory FamilyTaskProgress.fromJson(Map<String, Object?> json) {
    return FamilyTaskProgress(
      taskId: json['taskId'] as String,
      isObjectiveComplete: json['isObjectiveComplete'] as bool? ?? false,
      completedTargetIds:
          (json['completedTargetIds'] as List<Object?>? ?? const [])
              .cast<String>()
              .toSet(),
    );
  }

  final String taskId;
  final bool isObjectiveComplete;
  final Set<String> completedTargetIds;

  Map<String, Object?> toJson() {
    return {
      'taskId': taskId,
      'isObjectiveComplete': isObjectiveComplete,
      'completedTargetIds': completedTargetIds.toList(),
    };
  }

  FamilyTaskProgress copyWith({
    bool? isObjectiveComplete,
    Set<String>? completedTargetIds,
  }) {
    return FamilyTaskProgress(
      taskId: taskId,
      isObjectiveComplete: isObjectiveComplete ?? this.isObjectiveComplete,
      completedTargetIds: completedTargetIds ?? this.completedTargetIds,
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
    this.followUntilTurn,
    this.followReturnRoomId,
    this.isRemoved = false,
    this.patrolStep = 0,
    this.stateValues = const {},
  });

  factory NpcRuntimeState.fromJson(Map<String, Object?> json) {
    return NpcRuntimeState(
      roomId: json['roomId'] as String,
      currentHp: json['currentHp'] as int,
      isDefeated: json['isDefeated'] as bool,
      respawnAtTurn: json['respawnAtTurn'] as int?,
      hasDroppedLoot: json['hasDroppedLoot'] as bool? ?? false,
      isFollowing: json['isFollowing'] as bool? ?? false,
      followUntilTurn: json['followUntilTurn'] as int?,
      followReturnRoomId: json['followReturnRoomId'] as String?,
      isRemoved: json['isRemoved'] as bool? ?? false,
      patrolStep: json['patrolStep'] as int? ?? 0,
      stateValues: (json['stateValues'] as Map<String, Object?>? ?? const {})
          .map((key, value) => MapEntry(key, value as int)),
    );
  }

  final String roomId;
  final int currentHp;
  final bool isDefeated;
  final int? respawnAtTurn;
  final bool hasDroppedLoot;
  final bool isFollowing;
  final int? followUntilTurn;
  final String? followReturnRoomId;
  final bool isRemoved;
  final int patrolStep;
  final Map<String, int> stateValues;

  int valueFor(String key) => stateValues[key] ?? 0;

  bool matchesStateValues(Map<String, int> requiredValues) {
    return requiredValues.entries.every(
      (entry) => valueFor(entry.key) == entry.value,
    );
  }

  NpcRuntimeState applyStateChanges({
    Map<String, int> setValues = const {},
    Map<String, int> incrementValues = const {},
  }) {
    if (setValues.isEmpty && incrementValues.isEmpty) {
      return this;
    }
    final nextValues = {...stateValues, ...setValues};
    for (final entry in incrementValues.entries) {
      nextValues[entry.key] = (nextValues[entry.key] ?? 0) + entry.value;
    }
    return copyWith(stateValues: nextValues);
  }

  Map<String, Object?> toJson() {
    return {
      'roomId': roomId,
      'currentHp': currentHp,
      'isDefeated': isDefeated,
      'respawnAtTurn': respawnAtTurn,
      'hasDroppedLoot': hasDroppedLoot,
      'isFollowing': isFollowing,
      'followUntilTurn': followUntilTurn,
      'followReturnRoomId': followReturnRoomId,
      'isRemoved': isRemoved,
      'patrolStep': patrolStep,
      'stateValues': stateValues,
    };
  }

  NpcRuntimeState copyWith({
    String? roomId,
    int? currentHp,
    bool? isDefeated,
    Object? respawnAtTurn = _unchanged,
    bool? hasDroppedLoot,
    bool? isFollowing,
    Object? followUntilTurn = _unchanged,
    Object? followReturnRoomId = _unchanged,
    bool? isRemoved,
    int? patrolStep,
    Map<String, int>? stateValues,
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
      followUntilTurn:
          followUntilTurn == _unchanged
              ? this.followUntilTurn
              : followUntilTurn as int?,
      followReturnRoomId:
          followReturnRoomId == _unchanged
              ? this.followReturnRoomId
              : followReturnRoomId as String?,
      isRemoved: isRemoved ?? this.isRemoved,
      patrolStep: patrolStep ?? this.patrolStep,
      stateValues: stateValues ?? this.stateValues,
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
    this.playerStatusEffects = const [],
    this.enemyStatusEffects = const [],
  });

  factory CombatState.fromJson(Map<String, Object?> json) {
    return CombatState(
      npcId: json['npcId'] as String,
      enemyHp: json['enemyHp'] as int,
      round: json['round'] as int? ?? 0,
      playerStatusEffects: [
        for (final effect
            in json['playerStatusEffects'] as List<Object?>? ?? const [])
          StatusEffectState.fromJson(effect as Map<String, Object?>),
      ],
      enemyStatusEffects: [
        for (final effect
            in json['enemyStatusEffects'] as List<Object?>? ?? const [])
          StatusEffectState.fromJson(effect as Map<String, Object?>),
      ],
    );
  }

  final String npcId;
  final int enemyHp;
  final int round;
  final List<StatusEffectState> playerStatusEffects;
  final List<StatusEffectState> enemyStatusEffects;

  Map<String, Object?> toJson() {
    return {
      'npcId': npcId,
      'enemyHp': enemyHp,
      'round': round,
      'playerStatusEffects': [
        for (final effect in playerStatusEffects) effect.toJson(),
      ],
      'enemyStatusEffects': [
        for (final effect in enemyStatusEffects) effect.toJson(),
      ],
    };
  }

  CombatState copyWith({
    int? enemyHp,
    int? round,
    List<StatusEffectState>? playerStatusEffects,
    List<StatusEffectState>? enemyStatusEffects,
  }) {
    return CombatState(
      npcId: npcId,
      enemyHp: enemyHp ?? this.enemyHp,
      round: round ?? this.round,
      playerStatusEffects: playerStatusEffects ?? this.playerStatusEffects,
      enemyStatusEffects: enemyStatusEffects ?? this.enemyStatusEffects,
    );
  }
}

class StatusEffectState {
  const StatusEffectState({
    required this.id,
    required this.name,
    required this.remainingRounds,
    this.damagePerRound = 0,
    this.spiritDamagePerRound = 0,
    this.innerPowerDamagePerRound = 0,
    this.hpRecoveryPerRound = 0,
    this.attackPenalty = 0,
    this.defensePenalty = 0,
    this.blocksAction = false,
    this.tickMessage,
    this.expireMessage,
  });

  factory StatusEffectState.fromJson(Map<String, Object?> json) {
    return StatusEffectState(
      id: json['id'] as String,
      name: json['name'] as String,
      remainingRounds: json['remainingRounds'] as int,
      damagePerRound: json['damagePerRound'] as int? ?? 0,
      spiritDamagePerRound: json['spiritDamagePerRound'] as int? ?? 0,
      innerPowerDamagePerRound: json['innerPowerDamagePerRound'] as int? ?? 0,
      hpRecoveryPerRound: json['hpRecoveryPerRound'] as int? ?? 0,
      attackPenalty: json['attackPenalty'] as int? ?? 0,
      defensePenalty: json['defensePenalty'] as int? ?? 0,
      blocksAction: json['blocksAction'] as bool? ?? false,
      tickMessage: json['tickMessage'] as String?,
      expireMessage: json['expireMessage'] as String?,
    );
  }

  final String id;
  final String name;
  final int remainingRounds;
  final int damagePerRound;
  final int spiritDamagePerRound;
  final int innerPowerDamagePerRound;
  final int hpRecoveryPerRound;
  final int attackPenalty;
  final int defensePenalty;
  final bool blocksAction;
  final String? tickMessage;
  final String? expireMessage;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'remainingRounds': remainingRounds,
      'damagePerRound': damagePerRound,
      'spiritDamagePerRound': spiritDamagePerRound,
      'innerPowerDamagePerRound': innerPowerDamagePerRound,
      'hpRecoveryPerRound': hpRecoveryPerRound,
      'attackPenalty': attackPenalty,
      'defensePenalty': defensePenalty,
      'blocksAction': blocksAction,
      'tickMessage': tickMessage,
      'expireMessage': expireMessage,
    };
  }

  StatusEffectState copyWith({int? remainingRounds}) {
    return StatusEffectState(
      id: id,
      name: name,
      remainingRounds: remainingRounds ?? this.remainingRounds,
      damagePerRound: damagePerRound,
      spiritDamagePerRound: spiritDamagePerRound,
      innerPowerDamagePerRound: innerPowerDamagePerRound,
      hpRecoveryPerRound: hpRecoveryPerRound,
      attackPenalty: attackPenalty,
      defensePenalty: defensePenalty,
      blocksAction: blocksAction,
      tickMessage: tickMessage,
      expireMessage: expireMessage,
    );
  }

  StatusEffectState tick() {
    return copyWith(remainingRounds: remainingRounds - 1);
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

List<StatusEffectState> _playerStatusEffectsFromJson(
  Map<String, Object?> json,
) {
  final savedEffects = json['playerStatusEffects'] as List<Object?>?;
  final legacyCombat = json['combat'] as Map<String, Object?>?;
  final effects =
      savedEffects ??
      legacyCombat?['playerStatusEffects'] as List<Object?>? ??
      const [];
  return [
    for (final effect in effects)
      StatusEffectState.fromJson(effect as Map<String, Object?>),
  ];
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
