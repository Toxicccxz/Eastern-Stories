import 'package:flutter/material.dart';

import '../../game/models/area_definition.dart';
import '../../game/models/direction.dart';
import '../../game/models/game_state.dart';
import '../../game/models/room_definition.dart';
import 'shared/panel.dart';

class AreaMapView extends StatelessWidget {
  const AreaMapView({
    super.key,
    required this.area,
    required this.rooms,
    required this.allAreas,
    required this.allRooms,
    required this.state,
  });

  final AreaDefinition area;
  final List<RoomDefinition> rooms;
  final List<AreaDefinition> allAreas;
  final List<RoomDefinition> allRooms;
  final GameState state;

  static const double _viewportHeight = 180;
  static const double _gridSize = 22;
  static const double _nodeGap = 42;
  static const double _nodeSize = 14;
  static const double _mapPadding = 48;

  @override
  Widget build(BuildContext context) {
    if (rooms.isEmpty) {
      return Panel(child: Text(area.name));
    }

    final roomById = {for (final room in rooms) room.id: room};
    final currentRoom = roomById[state.currentRoomId] ?? rooms.first;
    final points = _roomPoints(rooms);
    final currentPoint = points[currentRoom.id] ?? Offset.zero;
    final mapSize = _mapSize(rooms);
    final colorScheme = Theme.of(context).colorScheme;

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
              final viewportCenter = Offset(
                constraints.maxWidth / 2,
                _viewportHeight / 2,
              );
              final targetOffset = viewportCenter - currentPoint;

              return ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: _viewportHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      const Positioned.fill(
                        child: CustomPaint(
                          painter: _GridBackgroundPainter(gridSize: _gridSize),
                        ),
                      ),
                      TweenAnimationBuilder<Offset>(
                        tween: Tween<Offset>(end: targetOffset),
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                        builder: (context, offset, child) {
                          return Transform.translate(
                            offset: offset,
                            child: child,
                          );
                        },
                        child: SizedBox(
                          width: mapSize.width,
                          height: mapSize.height,
                          child: CustomPaint(
                            painter: _TopologyMapPainter(
                              rooms: rooms,
                              roomById: roomById,
                              points: points,
                              state: state,
                              nodeSize: _nodeSize,
                              stubLength: _nodeGap * 0.48,
                              currentColor: colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Tooltip(
                          message: '世界地图',
                          child: IconButton.filledTonal(
                            onPressed:
                                () => _showWorldMap(context, colorScheme),
                            icon: const Icon(Icons.travel_explore),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Map<String, Offset> _roomPoints(List<RoomDefinition> rooms) {
    final minX = rooms.map((room) => room.mapX).reduce(_min);
    final minY = rooms.map((room) => room.mapY).reduce(_min);
    return {
      for (final room in rooms)
        room.id: Offset(
          (room.mapX - minX) * _nodeGap + _mapPadding,
          (room.mapY - minY) * _nodeGap + _mapPadding,
        ),
    };
  }

  Size _mapSize(List<RoomDefinition> rooms) {
    final minX = rooms.map((room) => room.mapX).reduce(_min);
    final maxX = rooms.map((room) => room.mapX).reduce(_max);
    final minY = rooms.map((room) => room.mapY).reduce(_min);
    final maxY = rooms.map((room) => room.mapY).reduce(_max);
    return Size(
      (maxX - minX) * _nodeGap + _mapPadding * 2,
      (maxY - minY) * _nodeGap + _mapPadding * 2,
    );
  }

  int _min(int first, int second) => first < second ? first : second;

  int _max(int first, int second) => first > second ? first : second;

  void _showWorldMap(BuildContext context, ColorScheme colorScheme) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          child: _WorldMapDialog(
            areas: allAreas,
            rooms: allRooms,
            state: state,
            currentColor: colorScheme.primary,
          ),
        );
      },
    );
  }
}

class _WorldMapDialog extends StatefulWidget {
  const _WorldMapDialog({
    required this.areas,
    required this.rooms,
    required this.state,
    required this.currentColor,
  });

  final List<AreaDefinition> areas;
  final List<RoomDefinition> rooms;
  final GameState state;
  final Color currentColor;

  @override
  State<_WorldMapDialog> createState() => _WorldMapDialogState();
}

class _WorldMapDialogState extends State<_WorldMapDialog> {
  late String _selectedRoomId = widget.state.currentRoomId;

  @override
  Widget build(BuildContext context) {
    final roomById = {for (final room in widget.rooms) room.id: room};
    final areaById = {for (final area in widget.areas) area.id: area};
    final selectedRoom = roomById[_selectedRoomId] ?? roomById.values.first;
    final selectedArea = areaById[selectedRoom.areaId];
    final layout = _WorldMapLayout.build(
      areas: widget.areas,
      rooms: widget.rooms,
    );

    final screenSize = MediaQuery.sizeOf(context);
    return SizedBox(
      width: screenSize.width * 0.92,
      height: screenSize.height * 0.82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '世界地图',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${selectedArea?.name ?? selectedRoom.areaId} · ${selectedRoom.name}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '关闭',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final canvasSize = Size(
                  layout.size.width < constraints.maxWidth
                      ? constraints.maxWidth
                      : layout.size.width,
                  layout.size.height < constraints.maxHeight
                      ? constraints.maxHeight
                      : layout.size.height,
                );

                return ClipRect(
                  child: InteractiveViewer(
                    minScale: 0.75,
                    maxScale: 2.5,
                    constrained: false,
                    boundaryMargin: EdgeInsets.zero,
                    child: SizedBox(
                      width: canvasSize.width,
                      height: canvasSize.height,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _GridBackgroundPainter(
                                gridSize: AreaMapView._gridSize,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _AreaLabelPainter(
                                labels: layout.areaLabels,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _CrossAreaLinkPainter(
                                links: layout.crossAreaLinks,
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _TopologyMapPainter(
                                rooms: widget.rooms,
                                roomById: roomById,
                                points: layout.points,
                                state: widget.state,
                                nodeSize: AreaMapView._nodeSize,
                                stubLength: AreaMapView._nodeGap * 0.48,
                                currentColor: widget.currentColor,
                                selectedRoomId: _selectedRoomId,
                                drawCrossAreaLinks: false,
                              ),
                            ),
                          ),
                          for (final room in widget.rooms)
                            if (layout.points[room.id] case final point?)
                              Positioned(
                                left: point.dx - AreaMapView._nodeGap / 2,
                                top: point.dy - AreaMapView._nodeGap / 2,
                                width: AreaMapView._nodeGap,
                                height: AreaMapView._nodeGap,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap:
                                      () => setState(() {
                                        _selectedRoomId = room.id;
                                      }),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldMapLayout {
  const _WorldMapLayout({
    required this.points,
    required this.areaLabels,
    required this.crossAreaLinks,
    required this.size,
  });

  final Map<String, Offset> points;
  final Map<String, Offset> areaLabels;
  final List<_CrossAreaLink> crossAreaLinks;
  final Size size;

  factory _WorldMapLayout.build({
    required List<AreaDefinition> areas,
    required List<RoomDefinition> rooms,
  }) {
    final roomsByArea = <String, List<RoomDefinition>>{
      for (final area in areas) area.id: [],
    };
    for (final room in rooms) {
      roomsByArea.putIfAbsent(room.areaId, () => []).add(room);
    }

    final points = <String, Offset>{};
    final areaLabels = <String, Offset>{};
    final blockSizes = <String, Size>{};
    final areaRoomsById = <String, List<RoomDefinition>>{};

    for (final area in areas) {
      final areaRooms = roomsByArea[area.id] ?? const [];
      if (areaRooms.isEmpty) {
        continue;
      }
      final minX = areaRooms.map((room) => room.mapX).reduce(_min);
      final maxX = areaRooms.map((room) => room.mapX).reduce(_max);
      final minY = areaRooms.map((room) => room.mapY).reduce(_min);
      final maxY = areaRooms.map((room) => room.mapY).reduce(_max);
      blockSizes[area.id] = Size(
        (maxX - minX) * AreaMapView._nodeGap + AreaMapView._mapPadding * 2,
        (maxY - minY) * AreaMapView._nodeGap + AreaMapView._mapPadding * 2,
      );
      areaRoomsById[area.id] = areaRooms;
    }

    var cursorX = AreaMapView._mapPadding;
    var cursorY = AreaMapView._mapPadding + 28;
    var rowHeight = 0.0;
    var maxWidth = 0.0;
    const areaGap = 68.0;
    const rowWidthLimit = 620.0;

    for (final area in areas) {
      final areaRooms = areaRoomsById[area.id] ?? const [];
      final blockSize = blockSizes[area.id];
      if (areaRooms.isEmpty || blockSize == null) {
        continue;
      }
      if (cursorX > AreaMapView._mapPadding &&
          cursorX + blockSize.width > rowWidthLimit) {
        cursorX = AreaMapView._mapPadding;
        cursorY += rowHeight + areaGap;
        rowHeight = 0;
      }

      final minX = areaRooms.map((room) => room.mapX).reduce(_min);
      final minY = areaRooms.map((room) => room.mapY).reduce(_min);
      final origin = Offset(cursorX + AreaMapView._mapPadding, cursorY);

      areaLabels[area.name] = origin - const Offset(0, 28);
      for (final room in areaRooms) {
        points[room.id] = Offset(
          origin.dx + (room.mapX - minX) * AreaMapView._nodeGap,
          origin.dy + (room.mapY - minY) * AreaMapView._nodeGap,
        );
      }

      final rightEdge = cursorX + blockSize.width;
      maxWidth = maxWidth < rightEdge ? rightEdge : maxWidth;
      rowHeight = rowHeight < blockSize.height ? blockSize.height : rowHeight;
      cursorX += blockSize.width + areaGap;
    }

    final roomById = {for (final room in rooms) room.id: room};
    final crossAreaLinks = _crossAreaLinks(
      rooms: rooms,
      roomById: roomById,
      points: points,
    );

    return _WorldMapLayout(
      points: points,
      areaLabels: areaLabels,
      crossAreaLinks: crossAreaLinks,
      size: Size(
        maxWidth + AreaMapView._mapPadding,
        cursorY + rowHeight + AreaMapView._mapPadding,
      ),
    );
  }

  static int _min(int first, int second) => first < second ? first : second;

  static int _max(int first, int second) => first > second ? first : second;

  static List<_CrossAreaLink> _crossAreaLinks({
    required List<RoomDefinition> rooms,
    required Map<String, RoomDefinition> roomById,
    required Map<String, Offset> points,
  }) {
    final links = <_CrossAreaLink>[];
    final drawnLinks = <String>{};
    const maximumDistance = 260.0;
    for (final room in rooms) {
      final start = points[room.id];
      if (start == null) {
        continue;
      }
      for (final targetRoomId in room.exits.values) {
        final targetRoom = roomById[targetRoomId];
        final end = points[targetRoomId];
        if (targetRoom == null ||
            end == null ||
            targetRoom.areaId == room.areaId) {
          continue;
        }
        final linkKey = _linkKey(room.id, targetRoomId);
        if (!drawnLinks.add(linkKey) ||
            (end - start).distance > maximumDistance) {
          continue;
        }
        links.add(_CrossAreaLink(start: start, end: end));
      }
    }
    return links;
  }

  static String _linkKey(String first, String second) {
    return first.compareTo(second) < 0 ? '$first|$second' : '$second|$first';
  }
}

class _CrossAreaLink {
  const _CrossAreaLink({required this.start, required this.end});

  final Offset start;
  final Offset end;
}

class _GridBackgroundPainter extends CustomPainter {
  const _GridBackgroundPainter({required this.gridSize});

  final double gridSize;

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()..color = const Color(0xFFF8F7F1);
    final gridPaint =
        Paint()
          ..color = const Color(0xFFDCD8CE)
          ..strokeWidth = 1;
    canvas.drawRect(Offset.zero & size, backgroundPaint);
    for (var x = 0.0; x <= size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y <= size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridBackgroundPainter oldDelegate) {
    return oldDelegate.gridSize != gridSize;
  }
}

class _AreaLabelPainter extends CustomPainter {
  const _AreaLabelPainter({required this.labels});

  final Map<String, Offset> labels;

  @override
  void paint(Canvas canvas, Size size) {
    for (final label in labels.entries) {
      final painter = TextPainter(
        text: TextSpan(
          text: label.key,
          style: const TextStyle(
            color: Color(0xFF4E5546),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, label.value);
    }
  }

  @override
  bool shouldRepaint(covariant _AreaLabelPainter oldDelegate) {
    return oldDelegate.labels != labels;
  }
}

class _CrossAreaLinkPainter extends CustomPainter {
  const _CrossAreaLinkPainter({required this.links});

  final List<_CrossAreaLink> links;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF838879)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.square;
    for (final link in links) {
      _drawDashedLine(canvas, link.start, link.end, paint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashLength = 8.0;
    const gapLength = 6.0;
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) {
      return;
    }
    final direction = delta / distance;
    var traveled = 0.0;
    while (traveled < distance) {
      final next = (traveled + dashLength).clamp(0.0, distance);
      canvas.drawLine(
        start + direction * traveled,
        start + direction * next,
        paint,
      );
      traveled += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant _CrossAreaLinkPainter oldDelegate) {
    return oldDelegate.links != links;
  }
}

class _TopologyMapPainter extends CustomPainter {
  const _TopologyMapPainter({
    required this.rooms,
    required this.roomById,
    required this.points,
    required this.state,
    required this.nodeSize,
    required this.stubLength,
    required this.currentColor,
    this.selectedRoomId,
    this.drawCrossAreaLinks = true,
  });

  final List<RoomDefinition> rooms;
  final Map<String, RoomDefinition> roomById;
  final Map<String, Offset> points;
  final GameState state;
  final double nodeSize;
  final double stubLength;
  final Color currentColor;
  final String? selectedRoomId;
  final bool drawCrossAreaLinks;

  @override
  void paint(Canvas canvas, Size size) {
    final linkPaint =
        Paint()
          ..color = const Color(0xFF24271E)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.square;
    final remoteLinkPaint =
        Paint()
          ..color = const Color(0xFF74796B)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.square;
    final drawnLinks = <String>{};

    for (final room in rooms) {
      final start = points[room.id];
      if (start == null) {
        continue;
      }
      for (final exit in room.availableExits(state).entries) {
        final targetRoom = roomById[exit.value];
        if (targetRoom == null) {
          canvas.drawLine(
            start,
            start + _directionVector(exit.key) * stubLength,
            remoteLinkPaint,
          );
          continue;
        }
        final end = points[targetRoom.id];
        if (end == null) {
          continue;
        }
        if (!drawCrossAreaLinks && targetRoom.areaId != room.areaId) {
          canvas.drawLine(
            start,
            start + _directionVector(exit.key) * stubLength,
            remoteLinkPaint,
          );
          continue;
        }
        final linkKey = _linkKey(room.id, targetRoom.id);
        if (!drawnLinks.add(linkKey)) {
          continue;
        }
        canvas.drawLine(start, end, linkPaint);
      }
    }

    for (final room in rooms) {
      final center = points[room.id];
      if (center == null) {
        continue;
      }
      final isCurrent = room.id == state.currentRoomId;
      final isSelected = room.id == selectedRoomId;
      final isVisited = state.visitedRoomIds.contains(room.id);
      final rect = Rect.fromCenter(
        center: center,
        width: nodeSize,
        height: nodeSize,
      );
      final fillPaint =
          Paint()
            ..color =
                isCurrent
                    ? currentColor
                    : isVisited
                    ? const Color(0xFFFFFCF3)
                    : const Color(0xFFF4F1E8);
      final borderPaint =
          Paint()
            ..color = const Color(0xFF1F241B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isCurrent ? 2.2 : 1.8;
      canvas.drawRect(rect, fillPaint);
      canvas.drawRect(rect, borderPaint);
      if (isSelected && !isCurrent) {
        final selectedPaint =
            Paint()
              ..color = const Color(0xFF8A6A22)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2;
        canvas.drawRect(rect.inflate(4), selectedPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TopologyMapPainter oldDelegate) {
    return oldDelegate.rooms != rooms ||
        oldDelegate.state.currentRoomId != state.currentRoomId ||
        oldDelegate.state.visitedRoomIds != state.visitedRoomIds ||
        oldDelegate.currentColor != currentColor ||
        oldDelegate.selectedRoomId != selectedRoomId ||
        oldDelegate.drawCrossAreaLinks != drawCrossAreaLinks;
  }

  String _linkKey(String first, String second) {
    return first.compareTo(second) < 0 ? '$first|$second' : '$second|$first';
  }

  Offset _directionVector(Direction direction) {
    return switch (direction) {
      Direction.north => const Offset(0, -1),
      Direction.south => const Offset(0, 1),
      Direction.east => const Offset(1, 0),
      Direction.west => const Offset(-1, 0),
      Direction.up => const Offset(0, -1),
      Direction.down => const Offset(0, 1),
    };
  }
}
