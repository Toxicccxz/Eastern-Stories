import 'package:flutter/material.dart';

import '../../game/core/game_action.dart';
import '../../game/core/game_controller.dart';
import '../../game/models/direction.dart';
import '../../game/models/room_definition.dart';

class DirectionPad extends StatelessWidget {
  const DirectionPad({super.key, required this.room, required this.controller});

  final RoomDefinition room;
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final exits = room.availableExits(controller.state);
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _DirectionWheel(
          exits: exits,
          colorScheme: colorScheme,
          onMove: (direction) {
            controller.dispatch(GameAction.move(direction));
          },
        ),
        const SizedBox(width: 10),
        _VerticalControls(
          exits: exits,
          colorScheme: colorScheme,
          onMove: (direction) {
            controller.dispatch(GameAction.move(direction));
          },
        ),
      ],
    );
  }
}

class _DirectionWheel extends StatelessWidget {
  const _DirectionWheel({
    required this.exits,
    required this.colorScheme,
    required this.onMove,
  });

  final Map<Direction, String> exits;
  final ColorScheme colorScheme;
  final ValueChanged<Direction> onMove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: 124,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.62,
              ),
              border: Border.all(color: const Color(0xFFD7CFBE)),
            ),
            child: const SizedBox.expand(),
          ),
          _PadButton(
            direction: Direction.north,
            exits: exits,
            icon: Icons.keyboard_arrow_up,
            alignment: const Alignment(0, -0.86),
            onMove: onMove,
          ),
          _PadButton(
            direction: Direction.south,
            exits: exits,
            icon: Icons.keyboard_arrow_down,
            alignment: const Alignment(0, 0.86),
            onMove: onMove,
          ),
          _PadButton(
            direction: Direction.east,
            exits: exits,
            icon: Icons.keyboard_arrow_right,
            alignment: const Alignment(0.86, 0),
            onMove: onMove,
          ),
          _PadButton(
            direction: Direction.west,
            exits: exits,
            icon: Icons.keyboard_arrow_left,
            alignment: const Alignment(-0.86, 0),
            onMove: onMove,
          ),
          _PadButton(
            direction: Direction.northeast,
            exits: exits,
            icon: Icons.north_east,
            alignment: const Alignment(0.62, -0.62),
            onMove: onMove,
          ),
          _PadButton(
            direction: Direction.northwest,
            exits: exits,
            icon: Icons.north_west,
            alignment: const Alignment(-0.62, -0.62),
            onMove: onMove,
          ),
          _PadButton(
            direction: Direction.southeast,
            exits: exits,
            icon: Icons.south_east,
            alignment: const Alignment(0.62, 0.62),
            onMove: onMove,
          ),
          _PadButton(
            direction: Direction.southwest,
            exits: exits,
            icon: Icons.south_west,
            alignment: const Alignment(-0.62, 0.62),
            onMove: onMove,
          ),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface,
              border: Border.all(color: const Color(0xFFD7CFBE)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalControls extends StatelessWidget {
  const _VerticalControls({
    required this.exits,
    required this.colorScheme,
    required this.onMove,
  });

  final Map<Direction, String> exits;
  final ColorScheme colorScheme;
  final ValueChanged<Direction> onMove;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VerticalButton(
          direction: Direction.up,
          exits: exits,
          icon: Icons.arrow_upward,
          label: '上',
          onMove: onMove,
        ),
        const SizedBox(height: 10),
        _VerticalButton(
          direction: Direction.down,
          exits: exits,
          icon: Icons.arrow_downward,
          label: '下',
          onMove: onMove,
        ),
      ],
    );
  }
}

class _PadButton extends StatelessWidget {
  const _PadButton({
    required this.direction,
    required this.exits,
    required this.icon,
    required this.alignment,
    required this.onMove,
  });

  final Direction direction;
  final Map<Direction, String> exits;
  final IconData icon;
  final Alignment alignment;
  final ValueChanged<Direction> onMove;

  @override
  Widget build(BuildContext context) {
    final enabled = exits.containsKey(direction);
    final colorScheme = Theme.of(context).colorScheme;
    return Align(
      alignment: alignment,
      child: Tooltip(
        message: direction.label,
        child: InkResponse(
          onTap: enabled ? () => onMove(direction) : null,
          radius: 22,
          customBorder: const CircleBorder(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? colorScheme.primary : const Color(0xFFE4DED1),
              boxShadow:
                  enabled
                      ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.24),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                      : null,
            ),
            child: Icon(
              icon,
              size: 22,
              color: enabled ? colorScheme.onPrimary : const Color(0xFF9A9284),
            ),
          ),
        ),
      ),
    );
  }
}

class _VerticalButton extends StatelessWidget {
  const _VerticalButton({
    required this.direction,
    required this.exits,
    required this.icon,
    required this.label,
    required this.onMove,
  });

  final Direction direction;
  final Map<Direction, String> exits;
  final IconData icon;
  final String label;
  final ValueChanged<Direction> onMove;

  @override
  Widget build(BuildContext context) {
    final enabled = exits.containsKey(direction);
    return SizedBox(
      width: 58,
      child: FilledButton.tonalIcon(
        onPressed: enabled ? () => onMove(direction) : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(58, 40),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        icon: Icon(icon, size: 18),
        label: Text(label),
      ),
    );
  }
}
