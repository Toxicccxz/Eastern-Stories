import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/models/quest_definition.dart';
import 'package:eastern_stories/game/models/room_definition.dart';
import 'package:eastern_stories/game/models/world_condition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('world condition combines flags, quest status, and defeated NPCs', () {
    const condition = WorldCondition(
      requiredFlags: {'gate_key'},
      forbiddenFlags: {'gate_sealed'},
      requiredQuestStatuses: {'open_gate': QuestStatus.active},
      requiredDefeatedNpcIds: {'gate_guard'},
    );
    final state = GameState.initial(
      startingRoomId: 'gate',
      npcStates: {
        'gate_guard': const NpcRuntimeState(
          roomId: 'gate',
          currentHp: 0,
          isDefeated: true,
        ),
      },
    ).copyWith(
      questFlags: {'gate_key'},
      questStatuses: {'open_gate': QuestStatus.active},
    );

    expect(condition.isSatisfiedBy(state), isTrue);
    expect(
      condition.isSatisfiedBy(state.copyWith(questFlags: {'gate_sealed'})),
      isFalse,
    );
  });

  test('room filters conditional exits and actions', () {
    final room = RoomDefinition.fromJson({
      'id': 'gate',
      'name': '石门',
      'areaId': 'test',
      'description': '一道紧闭的石门。',
      'mapX': 0,
      'mapY': 0,
      'exits': {
        'north': {
          'roomId': 'beyond_gate',
          'conditions': {
            'requiredFlags': ['gate_open'],
          },
        },
      },
      'actions': [
        {
          'id': 'enter_gate',
          'label': '进入石门',
          'description': '穿过石门。',
          'resultRoomId': 'beyond_gate',
          'log': '你穿过了石门。',
          'conditions': {
            'requiredFlags': ['gate_open'],
          },
        },
      ],
    });
    final closedState = GameState.initial(startingRoomId: 'gate');
    final openState = closedState.copyWith(questFlags: {'gate_open'});

    expect(room.availableExits(closedState), isEmpty);
    expect(room.availableActions(closedState), isEmpty);
    expect(room.availableExits(openState), hasLength(1));
    expect(room.availableActions(openState), hasLength(1));
  });
}
