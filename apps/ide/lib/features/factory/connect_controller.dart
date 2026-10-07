import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session.dart';
import 'connect_models.dart';
import 'factory_controller.dart';

/// The two store accounts as the Runner last checked them. Looked at again
/// every minute while a screen shows them, so a key that stops working shows up here.
final storeAccountsProvider = FutureProvider.autoDispose<StoreAccounts>((ref) async {
  // The timer is set before anything is awaited: a provider thrown away meanwhile must not be asked to register more.
  final timer = Timer(const Duration(minutes: 1), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final api = await ref.watch(runnerApiProvider.future);
  return StoreAccounts.fromJson(await api.connectStatus());
});

/// What changes everywhere once an account is connected, checked or forgotten:
/// the cards, the readiness lines, and the apps that were waiting for it.
void storeAccountsChanged(WidgetRef ref) {
  ref.invalidate(storeAccountsProvider);
  ref.invalidate(factoryConnectionsProvider);
  unawaited(ref.read(factoryProvider.notifier).refresh(force: true));
}

/// The name the Runner's routes use for an account.
String providerPath(String provider) => provider == 'google_play' ? 'google-play' : 'apple';
