import 'quest_definition.dart';

class GameState {
  const GameState({
    required this.currentRoomId,
    required this.player,
    required this.visitedRoomIds,
    required this.inventoryItemIds,
    required this.equippedWeaponId,
    required this.roomItemOverrides,
    required this.questStatuses,
    required this.questFlags,
    required this.combat,
    required this.log,
  });

  factory GameState.initial({required String startingRoomId}) {
    return GameState(
      currentRoomId: startingRoomId,
      player: const PlayerState(
        name: '少侠',
        level: 1,
        hp: 80,
        maxHp: 80,
        innerPower: 30,
        maxInnerPower: 30,
        silver: 20,
      ),
      visitedRoomIds: {startingRoomId},
      inventoryItemIds: const [],
      equippedWeaponId: null,
      roomItemOverrides: const {},
      questStatuses: const {},
      questFlags: const {},
      combat: null,
      log: const ['你在晨雾中醒来，东方故事就此开始。'],
    );
  }

  final String currentRoomId;
  final PlayerState player;
  final Set<String> visitedRoomIds;
  final List<String> inventoryItemIds;
  final String? equippedWeaponId;
  final Map<String, List<String>> roomItemOverrides;
  final Map<String, QuestStatus> questStatuses;
  final Set<String> questFlags;
  final CombatState? combat;
  final List<String> log;

  GameState copyWith({
    String? currentRoomId,
    PlayerState? player,
    Set<String>? visitedRoomIds,
    List<String>? inventoryItemIds,
    Object? equippedWeaponId = _unchanged,
    Map<String, List<String>>? roomItemOverrides,
    Map<String, QuestStatus>? questStatuses,
    Set<String>? questFlags,
    Object? combat = _unchanged,
    List<String>? log,
  }) {
    return GameState(
      currentRoomId: currentRoomId ?? this.currentRoomId,
      player: player ?? this.player,
      visitedRoomIds: visitedRoomIds ?? this.visitedRoomIds,
      inventoryItemIds: inventoryItemIds ?? this.inventoryItemIds,
      equippedWeaponId:
          equippedWeaponId == _unchanged
              ? this.equippedWeaponId
              : equippedWeaponId as String?,
      roomItemOverrides: roomItemOverrides ?? this.roomItemOverrides,
      questStatuses: questStatuses ?? this.questStatuses,
      questFlags: questFlags ?? this.questFlags,
      combat: combat == _unchanged ? this.combat : combat as CombatState?,
      log: log ?? this.log,
    );
  }

  List<String> logWith(String message) {
    return [...log, message].takeLast(20);
  }
}

class PlayerState {
  const PlayerState({
    required this.name,
    required this.level,
    required this.hp,
    required this.maxHp,
    required this.innerPower,
    required this.maxInnerPower,
    required this.silver,
  });

  final String name;
  final int level;
  final int hp;
  final int maxHp;
  final int innerPower;
  final int maxInnerPower;
  final int silver;

  PlayerState copyWith({int? hp, int? silver}) {
    return PlayerState(
      name: name,
      level: level,
      hp: hp ?? this.hp,
      maxHp: maxHp,
      innerPower: innerPower,
      maxInnerPower: maxInnerPower,
      silver: silver ?? this.silver,
    );
  }
}

class CombatState {
  const CombatState({required this.npcId, required this.enemyHp});

  final String npcId;
  final int enemyHp;

  CombatState copyWith({int? enemyHp}) {
    return CombatState(npcId: npcId, enemyHp: enemyHp ?? this.enemyHp);
  }
}

const Object _unchanged = Object();

extension _RecentItems<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) {
      return this;
    }
    return sublist(length - count);
  }
}
