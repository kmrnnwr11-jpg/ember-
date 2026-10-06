import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/runner_api.dart';
import '../../core/session.dart';
import 'factory_models.dart';

/// The live state of the Fabbrica, asked again every two seconds.
///
/// The work lives on the Runner, not on this screen: apps keep being built
/// while the user is elsewhere in Ember or Ember is shut. The Runner numbers
/// every change, so a poll that finds nothing new costs a few bytes.
class FactoryController extends AsyncNotifier<FactoryData> {
  Timer? _timer;
  bool _polling = false;

  @override
  Future<FactoryData> build() async {
    final api = await ref.watch(runnerApiProvider.future);
    final first = FactoryData.fromJson(await api.factoryState());
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(refresh()));
    ref.onDispose(() => _timer?.cancel());
    return first;
  }

  /// Asks for what changed since the last answer. When the Runner cannot be
  /// reached the screen keeps showing what it knew.
  Future<void> refresh({bool force = false}) async {
    final current = state.value;
    if (current == null || _polling) return;
    _polling = true;
    try {
      final api = await ref.read(runnerApiProvider.future);
      final json = await api.factoryState(rev: force ? null : current.rev);
      if (!ref.mounted || json['unchanged'] == true) return;
      state = AsyncData(FactoryData.fromJson(json));
    } catch (_) {
      // Unreachable for a moment: the connection badge says so.
    } finally {
      _polling = false;
    }
  }

  /// Runs an action on the Runner, then shows its effect at once.
  Future<void> _act(Future<void> Function(RunnerApi api) call) async {
    final api = await ref.read(runnerApiProvider.future);
    await call(api);
    await refresh(force: true);
  }

  Future<void> setPaused(bool paused) => _act((api) => api.factorySetPaused(paused));

  /// `retry`, `cancel` or `resolve` on one app.
  Future<void> appAction(String appId, String action, {Map<String, dynamic>? body}) =>
      _act((api) => api.factoryAppAction(appId, action, body: body));

  Future<void> remove(String appId) => _act((api) => api.factoryRemoveApp(appId));

  /// One action on many apps: `retry`, `cancel` or `delete`.
  Future<void> bulk(List<String> ids, String action) => _act((api) => api.factoryBulk(ids, action));

  /// Retries the failed apps of one batch, or of all of them.
  Future<void> retryFailed({String? batchId}) {
    if (batchId != null) return _act((api) => api.factoryRetryBatchFailed(batchId));
    final failed = [
      for (final a in state.value?.apps ?? const <FactoryApp>[])
        if (a.status == AppStatus.failed) a.id,
    ];
    return failed.isEmpty ? Future.value() : bulk(failed, 'retry');
  }

  Future<void> cancelBatch(String batchId) => _act((api) => api.factoryCancelBatch(batchId));

  Future<void> setMaxInFlight(int value) => _act((api) => api.factoryPatchSettings({'maxInFlight': value}));

  /// The same limit for Google Play and the App Store.
  Future<void> setDailyCap(int value) => _act(
    (api) => api.factoryPatchSettings({
      'dailyStoreCap': {'play': value, 'appstore': value},
    }),
  );

  /// Starts a batch of the apps the owner approved, with the recipe chosen.
  Future<void> startBatch({required String name, required List<AppProposal> apps, required BatchRecipe recipe}) => _act(
    (api) => api.factoryStartBatch({
      'name': name,
      'apps': [for (final a in apps) a.toJson()],
      'recipe': recipe.toJson(),
    }),
  );
}

final factoryProvider = AsyncNotifierProvider.autoDispose<FactoryController, FactoryData>(FactoryController.new);

/// Which tools and accounts are ready, and what this computer can carry.
final factoryConnectionsProvider = FutureProvider.autoDispose<FactoryConnections>((ref) async {
  final api = await ref.watch(runnerApiProvider.future);
  return FactoryConnections.fromJson(await api.factoryConnections());
});
