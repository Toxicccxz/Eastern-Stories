import 'package:flutter/material.dart';

import 'game/repositories/game_definition_repository.dart';
import 'game/repositories/save_game_repository.dart';
import 'ui/screens/start_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = await GameDefinitionRepository.loadDemo();
  runApp(EasternStoriesApp(repository: repository));
}

class EasternStoriesApp extends StatelessWidget {
  const EasternStoriesApp({super.key, required this.repository});

  final GameDefinitionRepository repository;

  @override
  Widget build(BuildContext context) {
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
