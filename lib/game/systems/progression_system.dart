import '../models/game_state.dart';
import '../repositories/game_definition_repository.dart';
import 'equipment_system.dart';

class ProgressionSystem {
  const ProgressionSystem(this._repository, this._equipmentSystem);

  final GameDefinitionRepository _repository;
  final EquipmentSystem _equipmentSystem;

  GameState awardRewards(
    GameState state, {
    required int silver,
    required int experience,
    required String logPrefix,
    List<String> itemIds = const [],
    int? potential,
  }) {
    final rewardNames = itemIds
        .map(_repository.item)
        .map((item) => item.name)
        .join('、');
    final rewardText = [
      if (silver > 0) '银两 +$silver',
      if (experience > 0) '经验 +$experience',
      if ((potential ?? 0) > 0) '潜能 +$potential',
      if (rewardNames.isNotEmpty) rewardNames,
    ].join('，');

    final previousLevel = state.player.level;
    final nextPlayer = _applyExperience(
      state.player.copyWith(
        silver: state.player.silver + silver,
        combatExperience: state.player.combatExperience + experience,
        potential:
            state.player.potential +
            (potential ?? (experience == 0 ? 0 : experience ~/ 10 + 1)),
      ),
      experience,
    );
    final stats = _equipmentSystem.statsFor(state.copyWith(player: nextPlayer));
    final healedPlayer = nextPlayer.copyWith(
      hp: stats.maxHp,
      innerPower: stats.maxInnerPower,
    );
    final log = [
      ...state.logWith(
        rewardText.isEmpty ? logPrefix : '$logPrefix。获得$rewardText。',
      ),
      if (nextPlayer.level > previousLevel)
        '你升到了 Lv.${nextPlayer.level}，气血和内力更加充沛。',
    ];

    return state.copyWith(player: healedPlayer, log: log);
  }

  PlayerState _applyExperience(PlayerState player, int gainedExperience) {
    var level = player.level;
    var experience = player.experience + gainedExperience;
    var nextLevelExperience = player.nextLevelExperience;
    var maxHp = player.maxHp;
    var maxInnerPower = player.maxInnerPower;

    while (experience >= nextLevelExperience) {
      experience -= nextLevelExperience;
      level += 1;
      maxHp += 12;
      maxInnerPower += 6;
      nextLevelExperience += 60;
    }

    return player.copyWith(
      level: level,
      experience: experience,
      nextLevelExperience: nextLevelExperience,
      maxHp: maxHp,
      maxInnerPower: maxInnerPower,
    );
  }
}
