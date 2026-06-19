import 'package:flutter/material.dart';

import '../../game/core/game_controller.dart';
import '../../game/models/game_state.dart';
import '../../game/repositories/game_definition_repository.dart';
import '../../game/repositories/save_game_repository.dart';
import 'main_game_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({
    super.key,
    required this.repository,
    required this.saveRepository,
  });

  final GameDefinitionRepository repository;
  final SaveGameRepository saveRepository;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  late Future<bool> _hasSave;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _hasSave = widget.saveRepository.hasSave();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.landscape_outlined,
                size: 72,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                '东方故事',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                '从刘家小房醒来，沿着村路、花园与玉螺湖，慢慢走进这段江湖。',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _isBusy ? null : _startNewGame,
                icon: const Icon(Icons.auto_stories_outlined),
                label: const Text('新的故事'),
              ),
              const SizedBox(height: 12),
              FutureBuilder<bool>(
                future: _hasSave,
                builder: (context, snapshot) {
                  final canContinue = snapshot.data ?? false;

                  return OutlinedButton.icon(
                    onPressed:
                        !_isBusy && canContinue ? _continueFromSave : null,
                    icon: const Icon(Icons.restore_outlined),
                    label: const Text('继续'),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                '进度会保存在本机。',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startNewGame() async {
    await _runBusy(() async {
      final state = widget.repository.createInitialState();
      await widget.saveRepository.save(state);
      _openGame(state);
    });
  }

  Future<void> _continueFromSave() async {
    await _runBusy(() async {
      final state = await widget.saveRepository.load();
      if (!mounted) {
        return;
      }
      if (state == null) {
        setState(() {
          _hasSave = widget.saveRepository.hasSave();
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('没有找到可用存档')));
        return;
      }
      _openGame(state);
    });
  }

  Future<void> _runBusy(Future<void> Function() task) async {
    if (_isBusy) {
      return;
    }
    setState(() {
      _isBusy = true;
    });
    try {
      await task();
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  void _openGame(GameState state) {
    final controller = GameController(
      repository: widget.repository,
      initialState: state,
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder:
            (gameContext) => MainGameScreen(
              controller: controller,
              onSave: () async {
                await widget.saveRepository.save(controller.state);
                if (!gameContext.mounted) {
                  return;
                }
                ScaffoldMessenger.of(
                  gameContext,
                ).showSnackBar(const SnackBar(content: Text('已保存')));
              },
            ),
      ),
    );
  }
}
