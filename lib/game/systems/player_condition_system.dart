import '../models/game_state.dart';
import '../models/skill_definition.dart';
import '../repositories/game_definition_repository.dart';
import 'equipment_system.dart';

class PlayerConditionSystem {
  const PlayerConditionSystem(this._repository, this._equipmentSystem);

  final GameDefinitionRepository _repository;
  final EquipmentSystem _equipmentSystem;

  GameState apply(GameState state, String statusEffectId, {String? source}) {
    final definition = _repository.statusEffectOrNull(statusEffectId);
    if (definition == null) {
      return state;
    }
    return applyDefinition(state, definition, source: source);
  }

  GameState applyDefinition(
    GameState state,
    StatusEffectDefinition definition, {
    String? source,
    int? durationOverride,
  }) {
    final status = _fromDefinition(
      definition,
      durationOverride: durationOverride,
    );
    final message =
        definition.applicationMessage
            ?.replaceAll('{target}', '你')
            .replaceAll('{source}', source ?? '') ??
        '你受到${definition.name}影响。';
    return state.copyWith(
      playerStatusEffects: _replace(state.playerStatusEffects, status),
      log: state.logWith(message),
    );
  }

  GameState reduce(GameState state, String statusEffectId, int amount) {
    if (amount <= 0) {
      return state;
    }
    final current =
        state.playerStatusEffects
            .where((effect) => effect.id == statusEffectId)
            .firstOrNull;
    if (current == null) {
      return state;
    }
    final remainingRounds = current.remainingRounds - amount;
    final effects = [
      for (final effect in state.playerStatusEffects)
        if (effect.id != statusEffectId)
          effect
        else if (remainingRounds > 0)
          effect.copyWith(remainingRounds: remainingRounds),
    ];
    final message =
        remainingRounds > 0
            ? '你体内的${current.name}减轻了一些。'
            : current.expireMessage
                    ?.replaceAll('{target}', '你')
                    .replaceAll('{status}', current.name) ??
                '你已经摆脱${current.name}的影响。';
    return state.copyWith(
      playerStatusEffects: effects,
      log: state.logWith(message),
    );
  }

  PlayerConditionTickResult advance(GameState state) {
    if (state.playerStatusEffects.isEmpty) {
      return PlayerConditionTickResult(state: state);
    }
    final blockingEffect =
        state.playerStatusEffects
            .where((effect) => effect.blocksAction)
            .firstOrNull;
    var hpDamage = 0;
    var spiritDamage = 0;
    var innerPowerDamage = 0;
    var hpRecovery = 0;
    final nextEffects = <StatusEffectState>[];
    final messages = <String>[];

    for (final effect in state.playerStatusEffects) {
      hpDamage += effect.damagePerRound;
      spiritDamage += effect.spiritDamagePerRound;
      innerPowerDamage += effect.innerPowerDamagePerRound;
      hpRecovery += effect.hpRecoveryPerRound;
      final changesResources =
          effect.damagePerRound > 0 ||
          effect.spiritDamagePerRound > 0 ||
          effect.innerPowerDamagePerRound > 0 ||
          effect.hpRecoveryPerRound > 0;
      if ((changesResources || effect.blocksAction) &&
          effect.tickMessage != null) {
        messages.add(_formatTickMessage(effect));
      }
      final nextEffect = effect.tick();
      if (nextEffect.remainingRounds > 0) {
        nextEffects.add(nextEffect);
      } else if (effect.expireMessage != null) {
        messages.add(
          effect.expireMessage!
              .replaceAll('{target}', '你')
              .replaceAll('{status}', effect.name),
        );
      }
    }

    final stats = _equipmentSystem.statsFor(state);
    var nextState = state.copyWith(
      player: state.player.copyWith(
        hp: (state.player.hp - hpDamage + hpRecovery).clamp(0, stats.maxHp),
        spirit: (state.player.spirit - spiritDamage).clamp(
          0,
          state.player.maxSpirit,
        ),
        innerPower: (state.player.innerPower - innerPowerDamage).clamp(
          0,
          stats.maxInnerPower,
        ),
      ),
      playerStatusEffects: nextEffects,
    );
    for (final message in messages) {
      nextState = nextState.copyWith(log: nextState.logWith(message));
    }
    return PlayerConditionTickResult(
      state: nextState,
      blockingEffectName: blockingEffect?.name,
    );
  }

  String _formatTickMessage(StatusEffectState effect) {
    return effect.tickMessage!
        .replaceAll('{target}', '你')
        .replaceAll('{status}', effect.name)
        .replaceAll('{damage}', effect.damagePerRound.toString())
        .replaceAll('{spiritDamage}', effect.spiritDamagePerRound.toString())
        .replaceAll(
          '{innerPowerDamage}',
          effect.innerPowerDamagePerRound.toString(),
        )
        .replaceAll('{healing}', effect.hpRecoveryPerRound.toString());
  }

  StatusEffectState _fromDefinition(
    StatusEffectDefinition effect, {
    int? durationOverride,
  }) {
    return StatusEffectState(
      id: effect.id,
      name: effect.name,
      remainingRounds: durationOverride ?? effect.duration,
      damagePerRound: effect.damagePerRound,
      spiritDamagePerRound: effect.spiritDamagePerRound,
      innerPowerDamagePerRound: effect.innerPowerDamagePerRound,
      hpRecoveryPerRound: effect.hpRecoveryPerRound,
      attackPenalty: effect.attackPenalty,
      defensePenalty: effect.defensePenalty,
      blocksAction: effect.blocksAction,
      grantsAstralVision: effect.grantsAstralVision,
      tickMessage: effect.tickMessage,
      expireMessage: effect.expireMessage,
    );
  }

  List<StatusEffectState> _replace(
    List<StatusEffectState> effects,
    StatusEffectState status,
  ) {
    return [
      for (final effect in effects)
        if (effect.id != status.id) effect,
      status,
    ];
  }
}

class PlayerConditionTickResult {
  const PlayerConditionTickResult({
    required this.state,
    this.blockingEffectName,
  });

  final GameState state;
  final String? blockingEffectName;
}
