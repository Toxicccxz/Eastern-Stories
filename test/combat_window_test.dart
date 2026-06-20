import 'package:eastern_stories/game/core/game_action.dart';
import 'package:eastern_stories/game/core/game_controller.dart';
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
}
