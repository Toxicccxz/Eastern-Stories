import 'package:flutter_test/flutter_test.dart';

import '../tool/validate_game_data.dart';

void main() {
  test(
    'game data validator accepts the current manifest',
    () async {
      final validator = GameDataValidator();

      await validator.validate('assets/data/demo_world.json');

      expect(validator.errors, isEmpty);
      expect(validator.countFor('areas'), 6);
      expect(validator.countFor('rooms'), 56);
      expect(validator.countFor('quests'), 5);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
