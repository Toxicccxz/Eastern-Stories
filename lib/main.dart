import 'package:flutter/material.dart';

import 'game/repositories/game_definition_repository.dart';
import 'game/repositories/save_game_repository.dart';
import 'ui/screens/start_screen.dart';

void main() {
  runApp(const EasternStoriesApp());
}

class EasternStoriesApp extends StatelessWidget {
  const EasternStoriesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = GameDefinitionRepository.demo();
    const saveRepository = SaveGameRepository();

    return MaterialApp(
      title: '东方故事',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5E6F45),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8F5EF),
        useMaterial3: true,
      ),
      home: StartScreen(repository: repository, saveRepository: saveRepository),
    );
  }
}
