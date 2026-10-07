import 'package:ide_core/ide_core.dart' show RunnerException;
import 'package:ide/features/factory/factory_controller.dart';
import 'package:ide/features/factory/factory_models.dart';

import 'fakes.dart';

const _stageOrder = factoryStages;

/// The stages of an app, as the Runner sends them: the first [done] finished,
/// then [now] in [status], the rest waiting. Stages after [goal] are skipped.
Map<String, dynamic> _stages({
  required int done,
  String status = 'running',
  int upTo = 11,
  Map<String, String> until = const {},
}) => {
  for (final (i, s) in _stageOrder.indexed)
    s: {
      'state': i >= upTo ? 'skipped' : (i < done ? 'done' : (i == done ? status : 'pending')),
      'attempts': i <= done && i < upTo ? 1 : 0,
      'message': i == done && status == 'failed' ? 'flutter analyze found 3 errors' : '',
      if (until[s] != null) 'until': until[s],
    },
};

/// One app in the Runner's shape. [kind] is running, queued, needs, failed, done or waiting.
Map<String, dynamic> fakeAppJson(int i, String kind, {String? name}) {
  final base = {
    'id': 'a$i',
    'batchId': 'b1',
    'order': i,
    'name': name ?? 'App number $i',
    'summary': 'A small helper app, number $i, that does one useful thing well.',
    'size': i % 5 == 0 ? 'big' : 'small',
    'category': 'tools',
    'engine': factoryEngines[i % factoryEngines.length],
    'folder': 'app_$i',
    'packageName': 'com.emberapps.app_$i',
    'costUsd': 0.12 * i,
    'log': ['Writes lib/home.dart', 'Runs flutter analyze'],
    'createdAt': '2026-10-06T10:00:00.000Z',
    'updatedAt': '2026-10-06T10:05:00.000Z',
  };
  switch (kind) {
    case 'running':
      return {
        ...base,
        'state': 'running',
        'projectId': 'p$i',
        'stages': _stages(done: 1 + i % 6),
        'doing': 'Writes lib/home.dart',
      };
    case 'queued':
      return {...base, 'state': 'queued', 'stages': _stages(done: 0, status: 'queued')};
    case 'waiting':
      // Built, and waiting for tomorrow's upload slot.
      return {
        ...base,
        'state': 'queued',
        'projectId': 'p$i',
        'stages': _stages(
          done: 8,
          status: 'queued',
          upTo: 9,
          until: {'play': DateTime.now().add(const Duration(hours: 9)).toUtc().toIso8601String()},
        ),
      };
    case 'needs':
      return {
        ...base,
        'state': 'needs_you',
        'projectId': 'p$i',
        'stages': _stages(done: 8, status: 'blocked', upTo: 9),
        'needs': [
          {
            'id': 'n$i',
            'kind': 'play_console_app',
            'stage': 'play',
            'title': 'Create the app in Play Console',
            'detail': 'English detail',
            'data': {
              'name': name ?? 'App number $i',
              'package': 'com.emberapps.app_$i',
              'shortDescription': 'Does one useful thing well',
              'category': 'Tools',
            },
            'createdAt': '2026-10-06T10:00:00.000Z',
          },
        ],
      };
    case 'failed':
      return {
        ...base,
        'state': 'failed',
        'projectId': 'p$i',
        'stages': _stages(done: 2, status: 'failed'),
        'error': 'flutter analyze found 3 errors',
        'errorStage': 'verify',
      };
    default:
      return {...base, 'state': 'done', 'projectId': 'p$i', 'stages': _stages(done: 9, status: 'done', upTo: 9)};
  }
}

/// A factory with [count] apps in every state, as the Runner would send it.
Map<String, dynamic> fakeFactoryJson({
  int count = 100,
  bool paused = false,
  bool interrupted = false,
  bool lowDisk = false,
  bool simulated = false,
}) {
  const kinds = ['running', 'queued', 'waiting', 'needs', 'failed', 'done', 'queued', 'running'];
  final apps = [
    for (var i = 0; i < count; i++)
      fakeAppJson(
        i,
        kinds[i % kinds.length],
        // One long name in each direction, to catch rows that forget to wrap.
        name: i == 1
            ? 'This is a very long app name that keeps going well past anything sensible for a card'
            : i == 2
            ? 'اسم تطبيق طويل جداً يتجاوز كل ما هو معقول في بطاقة واحدة من البطاقات'
            : null,
      ),
  ];
  return {
    'rev': 7,
    'paused': paused,
    'interrupted': interrupted,
    'lowDisk': lowDisk,
    'simulated': simulated,
    'summary': {
      'total': count,
      'queued': 40,
      'running': 25,
      'needsYou': 12,
      'done': 12,
      'failed': 11,
      'cancelled': 0,
      'onPlay': 4,
      'onAppStore': 0,
      'progress': 0.31,
      'etaSeconds': 5400,
    },
    'settings': {
      'lanes': {'light': 3, 'build': 2},
      'maxInFlight': 12,
      'dailyStoreCap': {'play': 10, 'appstore': 10},
      'minFreeDiskGb': 10,
    },
    'uploads': {
      'date': '2026-10-06',
      'play': 4,
      'appstore': 0,
      'cap': {'play': 10, 'appstore': 10},
      'resetsAt': '2026-10-07T00:00:00.000+02:00',
    },
    'batches': [
      {
        'id': 'b1',
        'name': 'Garden batch',
        'createdAt': '2026-10-06T10:00:00.000Z',
        'appIds': [for (final a in apps) a['id']],
        'recipe': {'goal': 'android'},
      },
    ],
    'apps': apps,
    'needsYou': [
      for (final a in apps)
        for (final n in (a['needs'] as List? ?? const []))
          {...(n as Map<String, dynamic>), 'appId': a['id'], 'appName': a['name']},
    ],
  };
}

/// A [FactoryController] that shows fixed data and writes down what it was asked to do.
class FakeFactory extends FactoryController {
  FakeFactory(this.data);
  FactoryData data;
  final calls = <String>[];

  @override
  Future<FactoryData> build() async => data;
  @override
  Future<void> refresh({bool force = false}) async {}
  @override
  Future<void> setPaused(bool paused) async => calls.add('paused:$paused');
  @override
  Future<void> appAction(String appId, String action, {Map<String, dynamic>? body}) async =>
      calls.add('$action:$appId:${body ?? {}}');
  @override
  Future<void> remove(String appId) async => calls.add('remove:$appId');
  @override
  Future<void> bulk(List<String> ids, String action) async => calls.add('bulk:$action:${ids.join(',')}');
  @override
  Future<void> retryFailed({String? batchId}) async => calls.add('retryFailed:${batchId ?? 'all'}');
  @override
  Future<void> cancelBatch(String batchId) async => calls.add('cancelBatch:$batchId');
  @override
  Future<void> setMaxInFlight(int value) async => calls.add('maxInFlight:$value');
  @override
  Future<void> setDailyCap(int value) async => calls.add('dailyCap:$value');
  @override
  Future<void> startBatch({required String name, required List<AppProposal> apps, required BatchRecipe recipe}) async =>
      calls.add('start:$name:${apps.map((a) => a.name).join('|')}:${recipe.toJson()}');
}

/// The Runner's REST side for the Fabbrica: the supervisor's answer and the connections.
class FakeFactoryApi extends FakeRunnerApi {
  FakeFactoryApi({this.plan = const {}, this.connections = const {}, this.planError, Map<String, dynamic>? stores}) : stores = stores ?? fakeStoresJson();
  final Map<String, dynamic> plan;
  final Map<String, dynamic> connections;
  final RunnerException? planError;
  final planRequests = <Map<String, Object?>>[];
  final signIns = <String>[];

  /// The store accounts as `GET /v1/connect` answers them; connecting changes them like the Runner does.
  Map<String, dynamic> stores;

  /// What was asked of the store accounts, in order.
  final storeCalls = <String>[];

  /// Set to make the next connection attempt fail the way a store refusal does.
  RunnerException? storeError;

  Map<String, dynamic> _connected(String provider, String account) => {
    'provider': provider,
    'state': 'connected',
    'detail': 'ok',
    'account': account,
  };

  @override
  Future<Map<String, dynamic>> connectStatus({bool fresh = false}) async => stores;

  @override
  Future<Map<String, dynamic>> connectGooglePlay({required String serviceAccount, String? developerId}) async {
    storeCalls.add('google:${serviceAccount.length}:${developerId ?? ''}');
    if (storeError != null) throw storeError!;
    return stores['googlePlay'] = _connected('google_play', 'ember@proj.iam.gserviceaccount.com');
  }

  @override
  Future<Map<String, dynamic>> connectApple({required String keyId, required String issuerId, String? privateKey, String? teamId}) async {
    storeCalls.add('apple:$keyId:$issuerId:${privateKey ?? '-'}:${teamId ?? ''}');
    if (storeError != null) throw storeError!;
    return stores['apple'] = _connected('apple', keyId);
  }

  @override
  Future<Map<String, dynamic>> connectVerify(String provider) async {
    storeCalls.add('verify:$provider');
    return stores[provider == 'apple' ? 'apple' : 'googlePlay'] as Map<String, dynamic>;
  }

  @override
  Future<void> connectDisconnect(String provider) async {
    storeCalls.add('disconnect:$provider');
    final key = provider == 'apple' ? 'apple' : 'googlePlay';
    stores[key] = {'provider': key == 'apple' ? 'apple' : 'google_play', 'state': 'missing', 'detail': 'missing', 'account': ''};
  }

  @override
  Future<Map<String, dynamic>> factoryPlan({required String text, int? count, Map<String, int>? engines}) async {
    planRequests.add({'text': text, 'count': count, 'engines': engines});
    if (planError != null) throw planError!;
    return plan;
  }

  @override
  Future<Map<String, dynamic>> factoryConnections() async => connections;

  @override
  Future<void> startSubscriptionLogin(String engine) async => signIns.add(engine);
}

Map<String, dynamic> fakePlanJson({int count = 6}) => {
  'apps': [
    for (var i = 0; i < count; i++)
      {
        'name': 'Idea $i',
        'summary': 'The idea number $i, in one line.',
        'brief': 'Long brief $i',
        'size': i == 0 ? 'big' : 'small',
        'category': 'tools',
        'engine': factoryEngines[i % 2],
      },
  ],
  'dropped': [
    {'name': 'Idea 1 again', 'reason': 'duplicate_name', 'keptInstead': 'Idea 1'},
    {'name': 'Almost Idea 2', 'reason': 'similar_idea', 'keptInstead': 'Idea 2'},
  ],
  'warnings': ['no_ai'],
  'source': 'list',
};

const fakeConnectionsJson = {
  'links': {
    'claude': {'ready': true, 'detail': ''},
    'qwen': {'ready': false, 'detail': 'not_installed'},
    'gemini': {'ready': false, 'detail': 'not_signed_in'},
    'codex': {'ready': true, 'detail': ''},
    'flutter': {'ready': true, 'detail': ''},
    'android': {'ready': true, 'detail': ''},
    'chrome': {'ready': true, 'detail': ''},
    'playKey': {'ready': false, 'detail': 'missing'},
    'appleKey': {'ready': false, 'detail': 'missing'},
    'mac': {'ready': false, 'detail': 'windows'},
  },
  'capacity': {'cpus': 16, 'totalRamMb': 8100, 'freeRamMb': 3200, 'freeDiskGb': 108, 'buildSlots': 1, 'agentSlots': 6},
};

/// `GET /v1/connect`: each account is `missing`, `connected`, `invalid` or `unreachable`.
Map<String, dynamic> fakeStoresJson({String google = 'missing', String apple = 'missing', bool gcloud = false}) {
  Map<String, dynamic> one(String provider, String state, String account) => {
    'provider': provider,
    'state': state,
    'detail': switch (state) {
      'connected' => 'ok',
      'invalid' => 'key_refused',
      'unreachable' => 'offline',
      _ => 'missing',
    },
    'account': state == 'missing' ? '' : account,
    if (provider == 'apple' && state == 'connected') 'teamId': 'ABCDE12345',
  };
  return {
    'googlePlay': one('google_play', google, 'ember@proj.iam.gserviceaccount.com'),
    'apple': one('apple', apple, 'Z47GM3ZDZ6'),
    'gcloud': {'installed': gcloud, 'account': gcloud ? 'me@gmail.com' : null},
    'developerId': '',
    'links': {
      'playConsole': 'https://play.google.com/console/developers',
      'googleCloudKeys': 'https://console.cloud.google.com/iam-admin/serviceaccounts',
      'appStoreKeys': 'https://appstoreconnect.apple.com/access/integrations/api',
    },
  };
}
