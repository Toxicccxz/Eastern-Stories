import 'dart:collection';

class InventoryState {
  InventoryState._(Map<String, int> itemCounts)
    : itemCounts = UnmodifiableMapView(itemCounts);

  factory InventoryState.empty() => InventoryState._(const {});

  factory InventoryState.fromItemIds(Iterable<String> itemIds) {
    final counts = <String, int>{};
    for (final itemId in itemIds) {
      counts[itemId] = (counts[itemId] ?? 0) + 1;
    }
    return InventoryState._(counts);
  }

  factory InventoryState.fromJson(Object? json, {Object? legacyItemIds}) {
    if (json case final Map<String, Object?> values) {
      return InventoryState._({
        for (final entry in values.entries)
          if (entry.value case final int quantity when quantity > 0)
            entry.key: quantity,
      });
    }
    return InventoryState.fromItemIds(
      (legacyItemIds as List<Object?>? ?? const []).cast<String>(),
    );
  }

  final Map<String, int> itemCounts;

  bool get isEmpty => itemCounts.isEmpty;

  Iterable<String> get itemIds => itemCounts.keys;

  Iterable<MapEntry<String, int>> get entries => itemCounts.entries;

  bool contains(String itemId) => countOf(itemId) > 0;

  int countOf(String itemId) => itemCounts[itemId] ?? 0;

  InventoryState add(String itemId, [int quantity = 1]) {
    if (quantity <= 0) {
      return this;
    }
    return InventoryState._({
      ...itemCounts,
      itemId: countOf(itemId) + quantity,
    });
  }

  InventoryState addAll(Iterable<String> itemIds) {
    var inventory = this;
    for (final itemId in itemIds) {
      inventory = inventory.add(itemId);
    }
    return inventory;
  }

  InventoryState remove(String itemId, [int quantity = 1]) {
    final currentQuantity = countOf(itemId);
    if (quantity <= 0 || currentQuantity == 0) {
      return this;
    }
    final counts = {...itemCounts};
    final nextQuantity = currentQuantity - quantity;
    if (nextQuantity > 0) {
      counts[itemId] = nextQuantity;
    } else {
      counts.remove(itemId);
    }
    return InventoryState._(counts);
  }

  Map<String, Object?> toJson() => Map<String, Object?>.from(itemCounts);

  List<String> toExpandedItemIds() => [
    for (final entry in itemCounts.entries)
      for (var index = 0; index < entry.value; index++) entry.key,
  ];
}
