import 'package:flutter/material.dart';

import '../../game/models/game_state.dart';
import '../../game/models/room_definition.dart';
import 'shared/panel.dart';

class AreaMapView extends StatelessWidget {
  const AreaMapView({super.key, required this.rooms, required this.state});

  final List<RoomDefinition> rooms;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final columns =
        rooms.map((room) => room.mapX).reduce((a, b) => a > b ? a : b) + 1;
    final rows =
        rooms.map((room) => room.mapY).reduce((a, b) => a > b ? a : b) + 1;
    final roomByPoint = {
      for (final room in rooms) '${room.mapX},${room.mapY}': room,
    };

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('小村', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1.8,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: columns * rows,
              itemBuilder: (context, index) {
                final x = index % columns;
                final y = index ~/ columns;
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
          ),
        ],
      ),
    );
  }
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
