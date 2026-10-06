import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'env.dart';
import 'locale.dart';
import 'runner_api.dart';
import 'runner_socket.dart';
import 'settings_store.dart';

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

/// Who Ember signs in as on its own computer when nobody has signed in before.
const _kLocalEmail = 'me@ember.local';

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
    if (token != null && email != null) {
      if (!_expiresSoon(token)) return Session(runnerUrl: runner, email: email, devToken: token);
      // A dev token lasts 7 days: an older one made every call fail with
      // "invalid token" until the user signed out by hand. Renew it instead.
      try {
        final (fresh, _) = await RunnerApi(runner).devLogin(email);
        await _store.write(_kDevToken, fresh);
        return Session(runnerUrl: runner, email: email, devToken: fresh);
      } catch (_) {
        // Runner unreachable: fall through to the sign-in as last used on this Mac.
      }
    }
    // The browser opened by `flutter run` starts empty every time: sign in again
    // as whoever signed in last on this Mac, instead of asking each restart.
    final api = RunnerApi(runner);
    // Nobody has signed in here yet: Ember on your own computer needs no
    // account, so it opens as the local user instead of asking for an email.
    final last = await api.devLastEmail() ?? _kLocalEmail;
    try {
      final (fresh, _) = await api.devLogin(last);
      await _store.write(_kEmail, last);
      await _store.write(_kDevToken, fresh);
      return Session(runnerUrl: runner, email: last, devToken: fresh);
    } catch (_) {
      return null;
    }
  }

  /// True when the JWT is expired or has less than a day left (or cannot be read).
  static bool _expiresSoon(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is! num) return false;
      final expires = DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
      return expires.isBefore(DateTime.now().add(const Duration(days: 1)));
    } catch (_) {
      return true;
    }
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
            throw AuthException(ref.read(stringsProvider).checkEmailToConfirm);
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
    if (!Env.supabaseEnabled) await RunnerApi(await savedRunnerUrl()).forgetDevLast();
    state = const AsyncData(null);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, Session?>(SessionController.new);

/// Authenticated REST client; token is resolved per call.
final runnerApiProvider = FutureProvider<RunnerApi>((ref) async {
  final session = ref.watch(sessionProvider).value;
  if (session == null) throw StateError('not signed in');
  final api = RunnerApi(session.runnerUrl, token: await session.token());
  Settings.instance.attach(api); // what the user saves now lives on this Runner
  return api;
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
