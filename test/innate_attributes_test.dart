import 'dart:math';

import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/models/innate_attributes.dart';
import 'package:eastern_stories/game/models/world_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('original eight innate attributes roll between 10 and 30', () {
    final attributes = InnateAttributes.random(Random(7));

    for (final attribute in InnateAttribute.values) {
      expect(attributes.valueFor(attribute), inInclusiveRange(10, 30));
    }
  });

  test('new character identity and attributes survive save data', () {
    const attributes = InnateAttributes(
      strength: 22,
      courage: 18,
      intelligence: 27,
      spirituality: 16,
      composure: 20,
      personality: 14,
      constitution: 25,
      karma: 11,
    );
    final state = GameState.initial(
      startingRoomId: 'liu_home',
      playerName: '沈青',
      gender: PlayerGender.female,
      attributes: attributes,
    );

    expect(state.player.name, '沈青');
    expect(state.player.gender, PlayerGender.female);
    expect(state.player.maxHp, 100);
    expect(state.player.maxSpirit, 62);

    final restored = GameState.fromJson(state.toJson());
    expect(restored.player.attributes.intelligence, 27);
    expect(restored.player.attributes.constitution, 25);
  });

  test('world conditions can enforce original attribute requirements', () {
    final state = GameState.initial(startingRoomId: 'liu_home');
    final condition = WorldCondition.fromJson({
      'minimumAttributes': {'courage': 20, 'composure': 20},
    });

    expect(condition.isSatisfiedBy(state), isFalse);
    expect(condition.attributeFailureReason(state), contains('胆识'));
  });
}
