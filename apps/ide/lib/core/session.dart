import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';
import 'runner_api.dart';
import 'runner_socket.dart';

class Session {
  const Session({required this.runnerUrl, required this.email, this.devToken});

  final String runnerUrl;
  final String email;

  /// Set in dev-auth mode; in Supabase mode the token is read live from the
  /// Supabase client so refreshes are picked up automatically.
  final String? devToken;

  Future<String?> token() async =>
      devToken ?? Supabase.instance.client.auth.currentSession?.accessToken;
}

/// Abstraction over secure storage so tests can run without platform channels.
abstract interface class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureKeyValueStore implements KeyValueStore {
  const SecureKeyValueStore();
  static const _s = FlutterSecureStorage();
  @override
  Future<String?> read(String key) => _s.read(key: key);
  @override
  Future<void> write(String key, String value) => _s.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _s.delete(key: key);
}

final keyValueStoreProvider = Provider<KeyValueStore>((_) => const SecureKeyValueStore());

const _kRunner = 'runner_url';
const _kEmail = 'email';
const _kDevToken = 'dev_token';

class SessionController extends AsyncNotifier<Session?> {
  KeyValueStore get _store => ref.read(keyValueStoreProvider);

  @override
  Future<Session?> build() async {
    final runner = await _store.read(_kRunner) ?? Env.runnerUrl;
    final email = await _store.read(_kEmail);
    if (Env.supabaseEnabled) {
      final s = Supabase.instance.client.auth.currentSession;
      if (s == null) return null;
      final sub = Supabase.instance.client.auth.onAuthStateChange.listen((e) {
        if (e.event == AuthChangeEvent.signedOut) state = const AsyncData(null);
      });
      ref.onDispose(sub.cancel);
      return Session(runnerUrl: runner, email: s.user.email ?? email ?? '');
    }
    final token = await _store.read(_kDevToken);
    if (token == null || email == null) return null;
    return Session(runnerUrl: runner, email: email, devToken: token);
  }

  Future<String> savedRunnerUrl() async => await _store.read(_kRunner) ?? Env.runnerUrl;

  Future<void> signIn({
    required String runnerUrl,
    required String email,
    String? password,
    bool signUp = false,
  }) async {
    final url = runnerUrl.trim().replaceAll(RegExp(r'/+$'), '');
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await _store.write(_kRunner, url);
      await _store.write(_kEmail, email);
      if (Env.supabaseEnabled) {
        final auth = Supabase.instance.client.auth;
        if (signUp) {
          final res = await auth.signUp(email: email, password: password!);
          if (res.session == null) {
            throw const AuthException('Controlla la tua email per confermare la registrazione.');
          }
        } else {
          await auth.signInWithPassword(email: email, password: password!);
        }
        return Session(runnerUrl: url, email: email);
      }
      final (token, _) = await RunnerApi(url).devLogin(email);
      await _store.write(_kDevToken, token);
      return Session(runnerUrl: url, email: email, devToken: token);
    });
  }

  Future<void> signOut() async {
    if (Env.supabaseEnabled) await Supabase.instance.client.auth.signOut();
    await _store.delete(_kDevToken);
    state = const AsyncData(null);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

/// Authenticated REST client; token is resolved per call.
final runnerApiProvider = FutureProvider<RunnerApi>((ref) async {
  final session = ref.watch(sessionProvider).value;
  if (session == null) throw StateError('not signed in');
  return RunnerApi(session.runnerUrl, token: await session.token());
});

/// Runner capabilities (`GET /v1/health`), e.g. whether Claude Code is usable.
final runnerHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = await ref.watch(runnerApiProvider.future);
  return api.health();
});

final runnerSocketProvider = Provider<RunnerSocket>((ref) {
  final session = ref.watch(sessionProvider).value;
  if (session == null) throw StateError('not signed in');
  final socket = RunnerSocket(runnerUrl: session.runnerUrl, tokenProvider: session.token);
  unawaited(socket.connect());
  ref.onDispose(socket.dispose);
  return socket;
});
