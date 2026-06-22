import '../models/game_state.dart';
import '../models/skill_progress.dart';
import '../repositories/game_definition_repository.dart';

class ApprenticeshipSystem {
  const ApprenticeshipSystem(this._repository);

  final GameDefinitionRepository _repository;

  GameState apprenticeTo(GameState state, String npcId) {
    if (state.combat != null) {
      return _withLog(state, '战斗之中无法行拜师之礼。');
    }
    final npcState = state.npcStates[npcId];
    if (npcState == null ||
        npcState.roomId != state.currentRoomId ||
        npcState.isDefeated ||
        npcState.isRemoved) {
      return _withLog(state, '你想拜师的人不在这里。');
    }
    final master = _repository.npc(npcId);
    final familyId = master.familyId;
    final masterGeneration = master.familyGeneration;
    if (!master.canAcceptApprentices ||
        familyId == null ||
        masterGeneration == null) {
      return _withLog(state, '${master.name}不打算收徒。');
    }
    if (!(master.apprenticeshipConditions?.isSatisfiedBy(state) ?? true)) {
      final conditions = master.apprenticeshipConditions;
      final failureMessage = master.apprenticeshipFailureMessage;
      final hasMissingFlag =
          conditions != null &&
          !conditions.requiredFlags.every(state.questFlags.contains);
      if (hasMissingFlag && failureMessage != null) {
        return _withLog(state, '${master.name}说道：“$failureMessage”');
      }
      final attributeReason = master.apprenticeshipConditions
          ?.attributeFailureReason(state);
      if (attributeReason != null) {
        return _withLog(state, '${master.name}摇了摇头：$attributeReason');
      }
      if (failureMessage != null) {
        return _withLog(state, '${master.name}说道：“$failureMessage”');
      }
      return _withLog(state, '${master.name}认为时机尚未成熟，没有答应收你为徒。');
    }
    if (state.apprenticeship?.masterNpcId == npcId) {
      return _withLog(state, '你向${master.name}恭敬行礼，叫了一声“师父”。');
    }

    final oldFamilyId = state.apprenticeship?.familyId;
    final changesFamily = oldFamilyId != null && oldFamilyId != familyId;
    final family = _repository.family(familyId);
    final initialRank = family.ranks.isEmpty ? null : family.ranks.first;
    final nextPlayer =
        changesFamily
            ? state.player.copyWith(
              betrayalCount: state.player.betrayalCount + 1,
            )
            : state.player;
    final nextSkills =
        changesFamily ? _applyBetrayalPenalty(state) : state.skillProgress;
    final message =
        changesFamily
            ? '你背离旧日师门，改投${master.name}门下。武学修为因心境动摇而受损。'
            : '你向${master.name}行过拜师之礼，成为${family.name}第${masterGeneration + 1}代${master.apprenticeTitle}。';

    return state.copyWith(
      player: nextPlayer,
      skillProgress: nextSkills,
      apprenticeship: ApprenticeshipState(
        familyId: familyId,
        masterNpcId: npcId,
        generation: masterGeneration + 1,
        title: initialRank?.title ?? master.apprenticeTitle,
        contribution: 0,
        rankId: initialRank?.id,
      ),
      log: state.logWith(message),
    );
  }

  GameState leaveFamily(GameState state) {
    final apprenticeship = state.apprenticeship;
    if (apprenticeship == null) {
      return _withLog(state, '你现在并无师承。');
    }
    final family = _repository.family(apprenticeship.familyId);
    return state.copyWith(
      player: state.player.copyWith(
        betrayalCount: state.player.betrayalCount + 1,
      ),
      skillProgress: _applyBetrayalPenalty(state),
      apprenticeship: null,
      log: state.logWith('你离开了${family.name}，从此不再以门下弟子自居。武学修为也因此受损。'),
    );
  }

  Map<String, SkillProgress> _applyBetrayalPenalty(GameState state) {
    return {
      for (final entry in state.skillProgress.entries)
        entry.key: SkillProgress(
          level: (entry.value.level ~/ 2).clamp(1, entry.value.level),
          experience: 0,
        ),
    };
  }

  GameState _withLog(GameState state, String message) {
    return state.copyWith(log: state.logWith(message));
  }
}
