import 'package:flutter/material.dart';

import '../../game/core/game_controller.dart';
import '../widgets/action_bar.dart';
import '../widgets/area_map_view.dart';
import '../widgets/combat_panel.dart';
import '../widgets/event_log_panel.dart';
import '../widgets/location_info_panel.dart';
import '../widgets/player_status_bar.dart';

class MainGameScreen extends StatelessWidget {
  const MainGameScreen({super.key, required this.controller, this.onSave});

  final GameController controller;
  final Future<void> Function()? onSave;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final state = controller.state;
        final room = controller.repository.room(state.currentRoomId);
        final area = controller.repository.area(room.areaId);
        final areaRooms = controller.repository.roomsInArea(area.id).toList();

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                PlayerStatusBar(state: state, onSave: _save),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    children: [
                      AreaMapView(area: area, rooms: areaRooms, state: state),
                      const SizedBox(height: 12),
                      LocationInfoPanel(
                        areaName: area.name,
                        room: room,
                        controller: controller,
                        state: state,
                      ),
                      const SizedBox(height: 12),
                      if (state.combat != null) ...[
                        CombatPanel(controller: controller, state: state),
                        const SizedBox(height: 12),
                      ],
                      EventLogPanel(messages: state.log),
                    ],
                  ),
                ),
                ActionBar(room: room, controller: controller),
              ],
            ),
          ),
        );
      },
    );
  }

  void _save() {
    final save = onSave;
    if (save != null) {
      save();
    }
  }
}
