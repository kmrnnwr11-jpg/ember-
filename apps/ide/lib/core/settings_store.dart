import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'runner_api.dart';
import 'session.dart';

/// Everything the user types once — GitHub token, Play service account, AI
/// keys, chat history, choices — saved on the Runner (~/.ember/settings), not
/// in the browser.
///
/// The browser alone lost it all: `flutter run -d chrome` starts a throw-away
/// profile, so each restart of the IDE began empty, and another browser or
/// computer never saw it. The browser keeps a copy only as a fallback, and
/// anything still found only there is moved to the Runner the first time it
/// is read.
class Settings {
  Settings._();

  static final instance = Settings._();

  static const _browser = SecureKeyValueStore();

  RunnerApi? _api;
  Map<String, String>? _cache;
  Future<Map<String, String>>? _loading;

  /// Called when the user is signed in: from now on values live on this Runner.
  void attach(RunnerApi api) {
    if (identical(api, _api)) return;
    _api = api;
    _cache = null;
    _loading = null;
  }

  Future<Map<String, String>> _all() {
    final api = _api;
    if (api == null) return Future.value(const {});
    return _loading ??= api.settings().then((v) => _cache = {...v}).catchError((Object _) {
      _loading = null; // Runner unreachable for now: try again next time
      return <String, String>{};
    });
  }

  /// What the browser still holds from before (secure storage or preferences).
  static Future<String?> _fromBrowser(String key) async {
    try {
      final v = await _browser.read(key);
      if (v != null && v.isNotEmpty) return v;
    } catch (_) {}
    try {
      final p = await SharedPreferences.getInstance();
      final v = p.get(key);
      if (v is String && v.isNotEmpty) return v;
      if (v is bool) return '$v';
      if (v is List) return v.join('\n');
    } catch (_) {}
    return null;
  }

  Future<String?> read(String key) async {
    final all = await _all();
    final v = all[key];
    if (v != null) return v;
    final old = await _fromBrowser(key);
    // Saved before settings moved to the Runner: move it there, once.
    if (old != null && _cache != null) unawaited(write(key, old).catchError((Object _) {}));
    return old;
  }

  Future<void> write(String key, String value) async {
    _cache?[key] = value;
    try {
      await _browser.write(key, value);
    } catch (_) {}
    await _api?.patchSettings({key: value});
  }

  Future<void> delete(String key) async {
    _cache?.remove(key);
    try {
      await _browser.delete(key);
    } catch (_) {}
    await _api?.patchSettings({key: null});
  }
}

/// The same, where a [KeyValueStore] is expected (cards that keep tokens).
class SettingsKeyValueStore implements KeyValueStore {
  const SettingsKeyValueStore();
  @override
  Future<String?> read(String key) => Settings.instance.read(key);
  @override
  Future<void> write(String key, String value) => Settings.instance.write(key, value);
  @override
  Future<void> delete(String key) => Settings.instance.delete(key);
}

final settingsStoreProvider = Provider<KeyValueStore>((_) => const SettingsKeyValueStore());
