import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:eastern_stories/ui/screens/main_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GameDefinitionRepository repository;

  setUpAll(() async {
    repository = await GameDefinitionRepository.loadDemo();
  });

  testWidgets('combat opens in a modal window and closes after fleeing', (
    tester,
  ) async {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'ice_cave',
        visitedRoomIds: {...initialState.visitedRoomIds, 'ice_cave'},
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: MainGameScreen(controller: controller)),
    );

    controller.dispatch(const GameAction.startCombat('white_ice_dragon'));
    await tester.pumpAndSettle();

    expect(find.text('交战'), findsOneWidget);
    expect(find.text('战斗记录'), findsOneWidget);
    expect(find.text('普通攻击'), findsOneWidget);
    expect(find.text('退避'), findsOneWidget);

    await tester.tap(find.text('普通攻击'));
    await tester.pump();
    expect(find.textContaining('反击'), findsOneWidget);

    await tester.tap(find.text('退避'));
    await tester.pumpAndSettle();

    expect(find.text('交战'), findsNothing);
    expect(controller.state.combat, isNull);
  });

  testWidgets('combat window shows active status effects', (tester) async {
    final initialState = repository.createInitialState();
    final controller = GameController(
      repository: repository,
      initialState: initialState.copyWith(
        currentRoomId: 'latemoon_entrance',
        visitedRoomIds: {...initialState.visitedRoomIds, 'latemoon_entrance'},
        combat: const CombatState(
          npcId: 'latemoon_guard',
          enemyHp: 30,
          ally: SummonedAllyState(
            name: '天甲神兵',
            attack: 20,
            hp: 812,
            maxHp: 1000,
            defense: 14,
            attackMessage: '神兵挥剑。',
            defeatMessage: '神兵消散。',
            leaveMessage: '神兵归天。',
            remainingRounds: 0,
          ),
          playerStatusEffects: [
            StatusEffectState(
              id: 'rose_poison',
              name: '玫瑰花毒',
              remainingRounds: 2,
              damagePerRound: 4,
              defensePenalty: 1,
            ),
          ],
          enemyStatusEffects: [
            StatusEffectState(
              id: 'iceshock',
              name: '寒震',
              remainingRounds: 3,
              damagePerRound: 3,
              attackPenalty: 2,
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: MainGameScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(find.text('敌方状态'), findsOneWidget);
    expect(find.text('寒震 3'), findsOneWidget);
    expect(find.text('玫瑰花毒 2'), findsNWidgets(2));
    expect(find.byIcon(Icons.ac_unit), findsOneWidget);
    expect(find.byIcon(Icons.local_florist), findsOneWidget);
    expect(find.textContaining('法力 '), findsNWidgets(2));
    expect(find.text('护法：天甲神兵'), findsOneWidget);
    expect(find.text('本场战斗'), findsOneWidget);
    expect(find.text('812/1000'), findsOneWidget);
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
  });
}
