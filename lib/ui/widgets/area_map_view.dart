import 'package:flutter/material.dart';

import '../../game/models/area_definition.dart';
import '../../game/models/game_state.dart';
import '../../game/models/room_definition.dart';
import 'shared/panel.dart';

class AreaMapView extends StatelessWidget {
  const AreaMapView({
    super.key,
    required this.area,
    required this.rooms,
    required this.state,
  });

  final AreaDefinition area;
  final List<RoomDefinition> rooms;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final minX = rooms.map((room) => room.mapX).reduce(_min);
    final maxX = rooms.map((room) => room.mapX).reduce(_max);
    final minY = rooms.map((room) => room.mapY).reduce(_min);
    final maxY = rooms.map((room) => room.mapY).reduce(_max);
    final columns = maxX - minX + 1;
    final rows = maxY - minY + 1;
    final roomByPoint = {
      for (final room in rooms) '${room.mapX},${room.mapY}': room,
    };

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            area.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(area.description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              final availableWidth =
                  constraints.maxWidth - spacing * (columns - 1);
              final cellWidth = availableWidth / columns;
              final cellHeight = cellWidth.clamp(48.0, 72.0);
              final mapHeight = cellHeight * rows + spacing * (rows - 1);

              return SizedBox(
                height: mapHeight,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: cellWidth / cellHeight,
                  ),
                  itemCount: columns * rows,
                  itemBuilder: (context, index) {
                    final x = minX + index % columns;
                    final y = minY + index ~/ columns;
                    final room = roomByPoint['$x,$y'];
                    final isCurrent = room?.id == state.currentRoomId;
                    final isVisited =
                        room != null && state.visitedRoomIds.contains(room.id);

                    return _MapCell(
                      label: room?.name ?? '',
                      isCurrent: isCurrent,
                      isVisited: isVisited,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int _min(int first, int second) => first < second ? first : second;

  int _max(int first, int second) => first > second ? first : second;
}

class _MapCell extends StatelessWidget {
  const _MapCell({
    required this.label,
    required this.isCurrent,
    required this.isVisited,
  });

  final String label;
  final bool isCurrent;
  final bool isVisited;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background =
        isCurrent
            ? colorScheme.primary
            : isVisited
            ? const Color(0xFFE7DECB)
            : const Color(0xFFF0ECE2);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFD4C8B5)),
      ),
      child: Center(
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isCurrent ? colorScheme.onPrimary : const Color(0xFF433D33),
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
