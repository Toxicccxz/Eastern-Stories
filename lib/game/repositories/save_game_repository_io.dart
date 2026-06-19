import 'dart:convert';
import 'dart:io';

import '../models/game_state.dart';

class SaveGameRepository {
  const SaveGameRepository({File? file}) : _file = file;

  static const int _version = 1;

  final File? _file;

  Future<bool> hasSave() async {
    final file = await _saveFile();
    return file.exists();
  }

  Future<GameState?> load() async {
    final file = await _saveFile();
    if (!await file.exists()) {
      return null;
    }

    final content = await file.readAsString();
    final json = jsonDecode(content) as Map<String, Object?>;
    if (json['version'] != _version) {
      return null;
    }
    return GameState.fromJson(json['state'] as Map<String, Object?>);
  }

  Future<void> save(GameState state) async {
    final file = await _saveFile();
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({'version': _version, 'state': state.toJson()}),
    );
  }

  Future<void> delete() async {
    final file = await _saveFile();
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _saveFile() async {
    final file = _file;
    if (file != null) {
      return file;
    }

    final directory = await _storageDirectory();
    return File('${directory.path}${Platform.pathSeparator}save.json');
  }

  Future<Directory> _storageDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty) {
        return Directory('$appData${Platform.pathSeparator}EasternStories');
      }
    }

    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home != null && home.isNotEmpty) {
      return Directory('$home${Platform.pathSeparator}.eastern_stories');
    }

    return Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}eastern_stories',
    );
  }
}
