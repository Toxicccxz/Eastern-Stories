import 'package:flutter_test/flutter_test.dart';

import '../tool/validate_game_data.dart';

void main() {
  test(
    'game data validator accepts the current manifest',
    () async {
      final validator = GameDataValidator();

      await validator.validate('assets/data/demo_world.json');

      expect(validator.errors, isEmpty);
      expect(validator.countFor('areas'), 7);
      expect(validator.countFor('rooms'), 125);
      expect(validator.countFor('quests'), 6);
    },
    timeout: const Timeout(Duration(seconds: 10)),
  );
}
