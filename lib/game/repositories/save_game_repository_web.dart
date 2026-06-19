import 'dart:convert';
import 'dart:js_interop';

import '../models/game_state.dart';

class SaveGameRepository {
  const SaveGameRepository();

  static const int _version = 1;
  static const String _storageKey = 'eastern_stories.save';

  Future<bool> hasSave() async {
    return _localStorage.getItem(_storageKey.toJS) != null;
  }

  Future<GameState?> load() async {
    final content = _localStorage.getItem(_storageKey.toJS)?.toDart;
    if (content == null) {
      return null;
    }

    final json = jsonDecode(content) as Map<String, Object?>;
    if (json['version'] != _version) {
      return null;
    }
    return GameState.fromJson(json['state'] as Map<String, Object?>);
  }

  Future<void> save(GameState state) async {
    final content = jsonEncode({'version': _version, 'state': state.toJson()});
    _localStorage.setItem(_storageKey.toJS, content.toJS);
  }

  Future<void> delete() async {
    _localStorage.removeItem(_storageKey.toJS);
  }
}

@JS('window.localStorage')
external _WebStorage get _localStorage;

extension type _WebStorage(JSObject _) implements JSObject {
  external JSString? getItem(JSString key);

  external void setItem(JSString key, JSString value);

  external void removeItem(JSString key);
}
