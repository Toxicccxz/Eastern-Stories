class GameState {
  const GameState({
    required this.currentRoomId,
    required this.player,
    required this.visitedRoomIds,
    required this.inventoryItemIds,
    required this.roomItemOverrides,
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
      roomItemOverrides: const {},
      log: const ['你在晨雾中醒来，东方故事就此开始。'],
    );
  }

  final String currentRoomId;
  final PlayerState player;
  final Set<String> visitedRoomIds;
  final List<String> inventoryItemIds;
  final Map<String, List<String>> roomItemOverrides;
  final List<String> log;

  GameState copyWith({
    String? currentRoomId,
    PlayerState? player,
    Set<String>? visitedRoomIds,
    List<String>? inventoryItemIds,
    Map<String, List<String>>? roomItemOverrides,
    List<String>? log,
  }) {
    return GameState(
      currentRoomId: currentRoomId ?? this.currentRoomId,
      player: player ?? this.player,
      visitedRoomIds: visitedRoomIds ?? this.visitedRoomIds,
      inventoryItemIds: inventoryItemIds ?? this.inventoryItemIds,
      roomItemOverrides: roomItemOverrides ?? this.roomItemOverrides,
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
}

extension _RecentItems<T> on List<T> {
  List<T> takeLast(int count) {
    if (length <= count) {
      return this;
    }
    return sublist(length - count);
  }
}
