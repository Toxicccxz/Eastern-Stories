import 'package:flutter/material.dart';

import '../../game/core/game_controller.dart';
import '../widgets/action_bar.dart';
import '../widgets/area_map_view.dart';
import '../widgets/combat_window.dart';
import '../widgets/event_log_panel.dart';
import '../widgets/location_info_panel.dart';
import '../widgets/objective_tracker_panel.dart';
import '../widgets/player_status_bar.dart';

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key, required this.controller, this.onSave});

  final GameController controller;
  final Future<void> Function()? onSave;

  @override
  State<MainGameScreen> createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  bool _combatWindowOpen = false;
  bool _combatWindowScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _scheduleCombatWindow();
  }

  @override
  void didUpdateWidget(MainGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
    _scheduleCombatWindow();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final room = widget.controller.repository.room(state.currentRoomId);
        final area = widget.controller.repository.area(room.areaId);
        final areaRooms =
            widget.controller.repository.roomsInArea(area.id).toList();

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                PlayerStatusBar(
                  state: state,
                  stats: widget.controller.characterStats(),
                  onSave: _save,
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    children: [
                      AreaMapView(
                        area: area,
                        rooms: areaRooms,
                        allAreas: widget.controller.repository.areas.toList(),
                        allRooms: widget.controller.repository.rooms.toList(),
                        state: state,
                      ),
                      const SizedBox(height: 12),
                      LocationInfoPanel(
                        areaName: area.name,
                        room: room,
                        controller: widget.controller,
                        state: state,
                      ),
                      const SizedBox(height: 12),
                      ObjectiveTrackerPanel(controller: widget.controller),
                      const SizedBox(height: 12),
                      EventLogPanel(messages: state.log),
                    ],
                  ),
                ),
                ActionBar(room: room, controller: widget.controller),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleControllerChanged() {
    _scheduleCombatWindow();
  }

  void _scheduleCombatWindow() {
    if (_combatWindowOpen ||
        _combatWindowScheduled ||
        widget.controller.state.combat == null) {
      return;
    }
    _combatWindowScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _combatWindowScheduled = false;
      if (!mounted ||
          _combatWindowOpen ||
          widget.controller.state.combat == null) {
        return;
      }
      _showCombatWindow();
    });
  }

  Future<void> _showCombatWindow() async {
    _combatWindowOpen = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CombatWindow(controller: widget.controller),
    );
    _combatWindowOpen = false;
    if (mounted) {
      _scheduleCombatWindow();
    }
  }

  void _save() {
    widget.onSave?.call();
  }
}
