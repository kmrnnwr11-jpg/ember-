/// What the Runner says about the Fabbrica (many apps at once), as described
/// in docs/FABBRICA_PIANO.md ("API del Runner"). Everything is read leniently:
/// a field the Runner adds later is ignored and a missing one gets a sensible
/// value, so a newer Runner never breaks these screens.
///
/// The texts the Runner writes (`title`, `detail`, `message`, log lines) are
/// English fallbacks. The screens say things in their own words from `kind`,
/// `stage` and `state`.
library;

/// The stages every app goes through, in the order they are shown.
const factoryStages = [
  'create',
  'code',
  'verify',
  'preview',
  'logo',
  'listing',
  'shots',
  'android',
  'play',
  'ios',
  'appstore',
];

/// AI engines a batch can use, in the order they are offered.
const factoryEngines = ['claude-code', 'qwen-code', 'gemini-cli', 'codex'];

/// How far a batch takes its apps. Each goal includes the ones before it.
enum Goal {
  app,
  assets,
  android,
  ios;

  static Goal parse(Object? v) => Goal.values.firstWhere((g) => g.name == v, orElse: () => Goal.android);
}

enum StageStatus {
  pending,
  queued,
  running,
  done,
  skipped,
  blocked,
  failed;

  static StageStatus parse(Object? v) =>
      StageStatus.values.firstWhere((s) => s.name == v, orElse: () => StageStatus.pending);
}

/// Where an app is as a whole.
enum AppStatus {
  queued,
  running,
  needsYou,
  done,
  failed,
  cancelled;

  static AppStatus parse(Object? v) => switch (v) {
    'needs_you' || 'needsYou' => AppStatus.needsYou,
    'running' => AppStatus.running,
    'done' => AppStatus.done,
    'failed' => AppStatus.failed,
    'cancelled' => AppStatus.cancelled,
    _ => AppStatus.queued,
  };
}

String _s(Object? v, [String fallback = '']) => v is String ? v : fallback;
int _i(Object? v, [int fallback = 0]) => v is num ? v.toInt() : fallback;
double _d(Object? v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;
bool _b(Object? v, [bool fallback = false]) => v is bool ? v : fallback;
Map<String, dynamic> _map(Object? v) => v is Map ? v.cast<String, dynamic>() : const {};
List<Map<String, dynamic>> _maps(Object? v) => [
  if (v is List)
    for (final e in v)
      if (e is Map) e.cast<String, dynamic>(),
];

class StageRun {
  const StageRun({this.status = StageStatus.pending, this.attempts = 0, this.message = '', this.until});
  final StageStatus status;
  final int attempts;

  /// The Runner's own words (English): only a fallback.
  final String message;

  /// The stage waits for this moment (the daily upload limit, a rest after a usage limit).
  final DateTime? until;

  factory StageRun.fromJson(Map<String, dynamic> j) => StageRun(
    status: StageStatus.parse(j['state'] ?? j['status']),
    attempts: _i(j['attempts']),
    message: _s(j['message']),
    until: DateTime.tryParse(_s(j['until'])),
  );
}

/// Something only the owner can do, with the values to copy.
class NeedsYou {
  const NeedsYou({
    required this.id,
    required this.kind,
    required this.stage,
    this.title = '',
    this.detail = '',
    this.data = const {},
    this.appId = '',
    this.appName = '',
  });
  final String id;

  /// `play_console_app`, `apple_app_record`, `mac`, `play_key`, `apple_key`, `login` or `other`.
  final String kind;
  final String stage;
  final String title;
  final String detail;
  final Map<String, String> data;
  final String appId;
  final String appName;

  factory NeedsYou.fromJson(Map<String, dynamic> j) => NeedsYou(
    id: _s(j['id']),
    kind: _s(j['kind'], 'other'),
    stage: _s(j['stage']),
    title: _s(j['title']),
    detail: _s(j['detail']),
    data: {for (final e in _map(j['data']).entries) e.key: '${e.value}'},
    appId: _s(j['appId']),
    appName: _s(j['appName']),
  );
}

class FactoryApp {
  const FactoryApp({
    required this.id,
    required this.batchId,
    required this.name,
    this.summary = '',
    this.brief = '',
    this.size = 'small',
    this.category = '',
    this.folder = '',
    this.projectId,
    this.packageName,
    this.engine = '',
    this.status = AppStatus.queued,
    this.stages = const {},
    this.doing = '',
    this.needs = const [],
    this.error,
    this.errorStage,
    this.log = const [],
    this.costUsd = 0,
    this.notBefore,
    this.order = 0,
  });

  final String id;
  final String batchId;
  final String name;
  final String summary;

  /// The full request for the coding agent: only in the detail answer.
  final String brief;
  final String size;
  final String category;
  final String folder;
  final String? projectId;
  final String? packageName;
  final String engine;
  final AppStatus status;
  final Map<String, StageRun> stages;

  /// What the app is doing this moment, in the Runner's English.
  final String doing;
  final List<NeedsYou> needs;
  final String? error;
  final String? errorStage;
  final List<String> log;
  final double costUsd;

  /// The app waits for this moment (a rest after a usage limit).
  final DateTime? notBefore;
  final int order;

  StageRun stage(String id) => stages[id] ?? const StageRun();

  /// Stages that count: the ones not skipped.
  int get plannedStages => factoryStages.where((s) => stage(s).status != StageStatus.skipped).length;
  int get doneStages => factoryStages.where((s) => stage(s).status == StageStatus.done).length;
  double get progress => plannedStages == 0 ? 0 : doneStages / plannedStages;

  /// The stage the app failed at, when it did.
  String? get failedStage {
    if (errorStage != null && errorStage!.isNotEmpty) return errorStage;
    for (final s in factoryStages) {
      if (stage(s).status == StageStatus.failed) return s;
    }
    return null;
  }

  /// The stage the app is on: the one running, else the one that failed or
  /// waits for the owner, else the first not finished. Null when all are done.
  String? get currentStage {
    for (final wanted in [
      StageStatus.running,
      StageStatus.failed,
      StageStatus.blocked,
      StageStatus.queued,
      StageStatus.pending,
    ]) {
      for (final s in factoryStages) {
        if (stage(s).status == wanted) return s;
      }
    }
    return null;
  }

  /// When a stage waits for a given moment (tomorrow's upload slot), the moment.
  DateTime? get waitingUntil {
    final now = DateTime.now();
    for (final s in factoryStages) {
      final u = stage(s).until;
      if (u != null && u.isAfter(now) && stage(s).status != StageStatus.done) return u;
    }
    final n = notBefore;
    return n != null && n.isAfter(now) ? n : null;
  }

  factory FactoryApp.fromJson(Map<String, dynamic> j) {
    final stagesJson = _map(j['stages']);
    return FactoryApp(
      id: _s(j['id']),
      batchId: _s(j['batchId']),
      name: _s(j['name']),
      summary: _s(j['summary'] ?? j['idea']),
      brief: _s(j['brief']),
      size: _s(j['size'], 'small'),
      category: _s(j['category']),
      folder: _s(j['folder']),
      projectId: j['projectId'] as String?,
      packageName: j['packageName'] as String?,
      engine: _s(j['engine']),
      status: AppStatus.parse(j['state'] ?? j['status']),
      stages: {
        for (final e in stagesJson.entries)
          if (e.value is Map) e.key: StageRun.fromJson(_map(e.value)),
      },
      doing: _s(j['doing']),
      needs: [
        for (final n in _maps(j['needs']))
          NeedsYou.fromJson({...n, 'appId': _s(n['appId'], _s(j['id'])), 'appName': _s(n['appName'], _s(j['name']))}),
      ],
      error: j['error'] as String?,
      errorStage: j['errorStage'] as String?,
      log: [
        if (j['log'] is List)
          for (final l in j['log'] as List) '$l',
      ],
      costUsd: _d(j['costUsd']),
      notBefore: DateTime.tryParse(_s(j['notBefore'])),
      order: _i(j['order']),
    );
  }
}

class FactoryBatch {
  const FactoryBatch({
    required this.id,
    required this.name,
    this.appIds = const [],
    this.goal = Goal.android,
    this.createdAt,
  });
  final String id;
  final String name;
  final List<String> appIds;
  final Goal goal;
  final DateTime? createdAt;

  factory FactoryBatch.fromJson(Map<String, dynamic> j) => FactoryBatch(
    id: _s(j['id']),
    name: _s(j['name']),
    appIds: [
      if (j['appIds'] is List)
        for (final a in j['appIds'] as List) '$a',
    ],
    goal: Goal.parse(_map(j['recipe'])['goal']),
    createdAt: DateTime.tryParse(_s(j['createdAt'])),
  );
}

class FactorySummary {
  const FactorySummary({
    this.total = 0,
    this.queued = 0,
    this.running = 0,
    this.needsYou = 0,
    this.done = 0,
    this.failed = 0,
    this.cancelled = 0,
    this.onPlay = 0,
    this.onAppStore = 0,
    this.progress = 0,
    this.etaSeconds,
  });
  final int total;
  final int queued;
  final int running;
  final int needsYou;
  final int done;
  final int failed;
  final int cancelled;
  final int onPlay;
  final int onAppStore;

  /// Stages finished over stages planned, 0 to 1.
  final double progress;
  final int? etaSeconds;

  factory FactorySummary.fromJson(Map<String, dynamic> j) => FactorySummary(
    total: _i(j['total']),
    queued: _i(j['queued']),
    running: _i(j['running']),
    needsYou: _i(j['needsYou']),
    done: _i(j['done']),
    failed: _i(j['failed']),
    cancelled: _i(j['cancelled']),
    onPlay: _i(j['onPlay']),
    onAppStore: _i(j['onAppStore']),
    progress: _d(j['progress']).clamp(0, 1).toDouble(),
    etaSeconds: j['etaSeconds'] is num ? (j['etaSeconds'] as num).toInt() : null,
  );
}

/// What the owner can regulate.
class FactorySettings {
  const FactorySettings({
    this.maxInFlight = 12,
    this.dailyPlayCap = 10,
    this.dailyAppStoreCap = 10,
    this.minFreeDiskGb = 10,
  });
  final int maxInFlight;

  /// Uploads per day to each store; the rest waits for tomorrow.
  final int dailyPlayCap;
  final int dailyAppStoreCap;
  final int minFreeDiskGb;

  /// One number for both stores, as the owner sets it.
  int get dailyStoreCap => dailyPlayCap;

  factory FactorySettings.fromJson(Map<String, dynamic> j) {
    final cap = _map(j['dailyStoreCap']);
    return FactorySettings(
      maxInFlight: _i(j['maxInFlight'], 12),
      dailyPlayCap: _i(cap['play'], 10),
      dailyAppStoreCap: _i(cap['appstore'], 10),
      minFreeDiskGb: _i(j['minFreeDiskGb'], 10),
    );
  }
}

/// Uploads made today to each store, against the daily limit.
class FactoryUploads {
  const FactoryUploads({this.play = 0, this.appstore = 0, this.capPlay = 10, this.capAppstore = 10, this.resetsAt});
  final int play;
  final int appstore;
  final int capPlay;
  final int capAppstore;
  final DateTime? resetsAt;

  factory FactoryUploads.fromJson(Map<String, dynamic> j) {
    final cap = _map(j['cap']);
    return FactoryUploads(
      play: _i(j['play']),
      appstore: _i(j['appstore']),
      capPlay: _i(cap['play'], 10),
      capAppstore: _i(cap['appstore'], 10),
      resetsAt: DateTime.tryParse(_s(j['resetsAt'])),
    );
  }
}

/// One poll of the Fabbrica: everything the dashboard shows.
class FactoryData {
  const FactoryData({
    this.rev = 0,
    this.paused = false,
    this.interrupted = false,
    this.lowDisk = false,
    this.simulated = false,
    this.summary = const FactorySummary(),
    this.settings = const FactorySettings(),
    this.uploads = const FactoryUploads(),
    this.batches = const [],
    this.apps = const [],
    this.needs = const [],
  });
  final int rev;
  final bool paused;

  /// The Runner restarted while work was going on: nothing resumes by itself.
  final bool interrupted;

  /// The disk is nearly full: the Runner stopped starting new apps.
  final bool lowDisk;

  /// The Runner is pretending (fake apps, no subscription used).
  final bool simulated;
  final FactorySummary summary;
  final FactorySettings settings;
  final FactoryUploads uploads;
  final List<FactoryBatch> batches;
  final List<FactoryApp> apps;
  final List<NeedsYou> needs;

  FactoryApp? app(String id) {
    for (final a in apps) {
      if (a.id == id) return a;
    }
    return null;
  }

  factory FactoryData.fromJson(Map<String, dynamic> j) {
    final apps = [for (final a in _maps(j['apps'])) FactoryApp.fromJson(a)]..sort((a, b) => a.order.compareTo(b.order));
    final needsJson = j['needsYou'] ?? j['needs'];
    final needs = [for (final n in _maps(needsJson)) NeedsYou.fromJson(n)];
    return FactoryData(
      rev: _i(j['rev']),
      paused: _b(j['paused']),
      interrupted: _b(j['interrupted']),
      lowDisk: _b(j['lowDisk']),
      simulated: _b(j['simulated']),
      summary: FactorySummary.fromJson(_map(j['summary'])),
      settings: FactorySettings.fromJson(_map(j['settings'])),
      uploads: FactoryUploads.fromJson(_map(j['uploads'])),
      batches: [for (final b in _maps(j['batches'])) FactoryBatch.fromJson(b)],
      apps: apps,
      // The list of needs may be missing: gather it from the apps.
      needs: needsJson != null ? needs : [for (final a in apps) ...a.needs],
    );
  }
}

/// One app the supervisor proposes from what the owner wrote.
class AppProposal {
  const AppProposal({
    required this.name,
    this.summary = '',
    this.brief = '',
    this.size = 'small',
    this.engine,
    this.category = '',
    this.include = true,
  });
  final String name;
  final String summary;
  final String brief;

  /// `small` or `big`.
  final String size;
  final String? engine;
  final String category;
  final bool include;

  AppProposal copyWith({String? name, String? size, bool? include}) => AppProposal(
    name: name ?? this.name,
    summary: summary,
    brief: brief,
    size: size ?? this.size,
    engine: engine,
    category: category,
    include: include ?? this.include,
  );

  factory AppProposal.fromJson(Map<String, dynamic> j) => AppProposal(
    name: _s(j['name']),
    summary: _s(j['summary'] ?? j['idea']),
    brief: _s(j['brief']),
    size: _s(j['size'], 'small'),
    engine: j['engine'] as String?,
    category: _s(j['category']),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'summary': summary,
    if (brief.isNotEmpty) 'brief': brief,
    'size': size,
    if (category.isNotEmpty) 'category': category,
    if (engine != null) 'engine': engine,
  };
}

/// An idea the supervisor left out, and why.
class DroppedIdea {
  const DroppedIdea({required this.name, required this.reason, this.keptInstead = ''});
  final String name;

  /// `duplicate_name`, `similar_idea` or `too_many`.
  final String reason;
  final String keptInstead;
}

/// What the supervisor made of the big box.
class PlanResult {
  const PlanResult({this.proposals = const [], this.dropped = const [], this.warnings = const [], this.source = ''});
  final List<AppProposal> proposals;
  final List<DroppedIdea> dropped;

  /// Codes, such as `no_ai`.
  final List<String> warnings;

  /// `supervisor` (an AI read it) or `list` (one app per line, no AI).
  final String source;

  factory PlanResult.fromJson(Map<String, dynamic> j) => PlanResult(
    proposals: [for (final p in _maps(j['apps'])) AppProposal.fromJson(p)],
    dropped: [
      for (final d in _maps(j['dropped']))
        DroppedIdea(name: _s(d['name']), reason: _s(d['reason']), keptInstead: _s(d['keptInstead'])),
    ],
    warnings: [
      if (j['warnings'] is List)
        for (final w in j['warnings'] as List) '$w',
    ],
    source: _s(j['source']),
  );
}

/// What the batch is made with, as the owner chose it.
class BatchRecipe {
  const BatchRecipe({this.engines = const {'claude-code': 1}, this.logoBy = 'auto', this.goal = Goal.android});

  /// Engine to weight: apps are shared out in that proportion.
  final Map<String, int> engines;
  final String logoBy;
  final Goal goal;

  BatchRecipe copyWith({Map<String, int>? engines, String? logoBy, Goal? goal}) =>
      BatchRecipe(engines: engines ?? this.engines, logoBy: logoBy ?? this.logoBy, goal: goal ?? this.goal);

  Map<String, dynamic> toJson() => {
    'engines': {
      for (final e in engines.entries)
        if (e.value > 0) e.key: e.value,
    },
    'quality': 'fast',
    'logoBy': logoBy,
    'goal': goal.name,
  };
}

/// Whether one thing the Fabbrica needs is ready.
class LinkStatus {
  const LinkStatus({required this.id, required this.ready, this.detail = ''});
  final String id;
  final bool ready;

  /// A code, not a sentence: `not_installed`, `not_signed_in`, `missing`, `windows`…
  final String detail;
}

/// What this computer and the accounts on it can do right now.
class FactoryConnections {
  const FactoryConnections({
    this.links = const [],
    this.cpus = 0,
    this.freeRamMb = 0,
    this.freeDiskGb = 0,
    this.buildSlots = 1,
    this.agentSlots = 1,
  });
  final List<LinkStatus> links;
  final int cpus;
  final int freeRamMb;
  final int freeDiskGb;
  final int buildSlots;
  final int agentSlots;

  bool ready(String id) => links.any((l) => l.id == id && l.ready);

  /// Whether the thing is ready, or null when the Runner did not say (then nothing is claimed either way).
  bool? readyOf(Iterable<String> ids) {
    final found = links.where((l) => ids.contains(l.id)).toList();
    return found.isEmpty ? null : found.any((l) => l.ready);
  }

  factory FactoryConnections.fromJson(Map<String, dynamic> j) {
    final cap = _map(j['capacity']);
    final links = _map(j['links']);
    return FactoryConnections(
      links: [
        for (final e in links.entries)
          LinkStatus(
            id: e.key,
            ready: e.value is bool ? e.value as bool : _b(_map(e.value)['ready']),
            detail: _s(_map(e.value)['detail']),
          ),
      ],
      cpus: _i(cap['cpus']),
      freeRamMb: _i(cap['freeRamMb']),
      freeDiskGb: _i(cap['freeDiskGb']),
      buildSlots: _i(cap['buildSlots'], 1),
      agentSlots: _i(cap['agentSlots'], 1),
    );
  }
}
