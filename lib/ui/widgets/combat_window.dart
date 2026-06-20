import 'package:flutter/material.dart';

import '../../game/core/game_controller.dart';
import 'combat_panel.dart';
import 'event_log_panel.dart';

class CombatWindow extends StatefulWidget {
  const CombatWindow({super.key, required this.controller});

  final GameController controller;

  @override
  State<CombatWindow> createState() => _CombatWindowState();
}

class _CombatWindowState extends State<CombatWindow> {
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(CombatWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }
    oldWidget.controller.removeListener(_handleControllerChanged);
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final windowHeight = (screenSize.height * 0.86).clamp(320.0, 720.0);

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: SizedBox(
          width: 560,
          height: windowHeight,
          child: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final state = widget.controller.state;
              if (state.combat == null) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFFE0D8C8)),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department_outlined),
                        const SizedBox(width: 8),
                        Text(
                          '交战',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        CombatPanel(
                          controller: widget.controller,
                          state: state,
                        ),
                        const SizedBox(height: 12),
                        EventLogPanel(
                          messages: state.log,
                          title: '战斗记录',
                          maxMessages: 10,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _handleControllerChanged() {
    if (_closing || widget.controller.state.combat != null) {
      return;
    }
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }
}
