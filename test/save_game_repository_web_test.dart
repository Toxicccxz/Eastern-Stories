@TestOn('browser')
library;

import 'package:eastern_stories/game/models/game_state.dart';
import 'package:eastern_stories/game/repositories/save_game_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web save repository uses browser local storage', () async {
    const repository = SaveGameRepository();
    final state = GameState.initial(startingRoomId: 'web_room');
    await repository.delete();
    addTearDown(repository.delete);

    await repository.save(state);

    expect(await repository.hasSave(), isTrue);
    expect((await repository.load())?.currentRoomId, 'web_room');

    await repository.delete();
    expect(await repository.hasSave(), isFalse);
  });
}
