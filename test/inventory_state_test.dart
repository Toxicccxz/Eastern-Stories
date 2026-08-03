import 'package:eastern_stories/game/models/inventory_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inventory tracks quantities without exposing mutable state', () {
    final inventory = InventoryState.fromItemIds(const ['melon', 'melon']);

    expect(inventory.countOf('melon'), 2);
    expect(inventory.remove('melon').countOf('melon'), 1);
    expect(inventory.add('melon', 2).countOf('melon'), 4);
    expect(() => inventory.itemCounts['melon'] = 0, throwsUnsupportedError);
  });

  test('inventory reads both quantity saves and legacy item lists', () {
    final inventory = InventoryState.fromJson(const {'melon': 3});
    final legacyInventory = InventoryState.fromJson(
      null,
      legacyItemIds: const ['melon', 'melon', 'cloth'],
    );

    expect(inventory.countOf('melon'), 3);
    expect(inventory.toJson(), {'melon': 3});
    expect(legacyInventory.countOf('melon'), 2);
    expect(legacyInventory.countOf('cloth'), 1);
  });
}
