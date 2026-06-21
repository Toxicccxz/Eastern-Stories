import 'package:eastern_stories/game/repositories/game_definition_repository.dart';
import 'package:eastern_stories/ui/screens/character_creation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('character creation renders original attributes on mobile', (
    tester,
  ) async {
    final repository = await GameDefinitionRepository.loadDemo();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(home: CharacterCreationScreen(repository: repository)),
    );

    expect(find.text('初入江湖'), findsOneWidget);
    expect(find.text('进入故事'), findsOneWidget);
    for (final label in const [
      '膂力',
      '胆识',
      '悟性',
      '灵性',
      '定力',
      '容貌',
      '根骨',
      '福缘',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
