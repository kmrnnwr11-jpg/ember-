import 'package:dio/dio.dart';
import 'package:ide_core/ide_core.dart';

/// REST client for the Runner (docs/API.md).
class RunnerApi {
  RunnerApi(String baseUrl, {String? token, Dio? dio})
    : _dio = dio ?? Dio() {
    _dio.options
      ..baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '')
      ..connectTimeout = const Duration(seconds: 10)
      ..receiveTimeout = const Duration(seconds: 30)
      ..headers = {if (token != null) 'Authorization': 'Bearer $token'};
  }

  final Dio _dio;

  Future<T> _call<T>(Future<Response<dynamic>> Function() fn, T Function(dynamic) map) async {
    try {
      final res = await fn();
      return map(res.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic> && data['code'] is String) {
        throw RunnerException.fromPayload(data);
      }
      throw RunnerException('network', e.message ?? 'Runner unreachable');
    }
  }

  Future<Map<String, dynamic>> health() =>
      _call(() => _dio.get('/v1/health'), (d) => d as Map<String, dynamic>);

  /// Returns `(token, userId)`.
  Future<(String, String)> devLogin(String email) => _call(
    () => _dio.post('/v1/auth/dev-login', data: {'email': email}),
    (d) => (d['token'] as String, (d['user'] as Map)['id'] as String),
  );

  Future<List<Workspace>> workspaces() => _call(
    () => _dio.get('/v1/workspaces'),
    (d) => [for (final w in d['workspaces'] as List) Workspace.fromJson(w as Map<String, dynamic>)],
  );

  Future<Workspace> createWorkspace(String name) => _call(
    () => _dio.post('/v1/workspaces', data: {'name': name}),
    (d) => Workspace.fromJson(d as Map<String, dynamic>),
  );

  Future<List<Project>> projects(String workspaceId) => _call(
    () => _dio.get('/v1/workspaces/$workspaceId/projects'),
    (d) => [for (final p in d['projects'] as List) Project.fromJson(p as Map<String, dynamic>)],
  );

  Future<(Project, JobStatus)> createProject(String workspaceId, String name, {String template = 'empty'}) => _call(
    () => _dio.post('/v1/workspaces/$workspaceId/projects', data: {'name': name, 'template': template}),
    (d) => (
      Project.fromJson(d['project'] as Map<String, dynamic>),
      JobStatus.fromJson(d['job'] as Map<String, dynamic>),
    ),
  );

  Future<Project> project(String id) =>
      _call(() => _dio.get('/v1/projects/$id'), (d) => Project.fromJson(d as Map<String, dynamic>));

  Future<void> deleteProject(String id) => _call(() => _dio.delete('/v1/projects/$id'), (_) {});

  /// Upload-key backup: `{path, alias, password, expiresAt}` (one-time link, 10 min).
  Future<Map<String, dynamic>> signingLink(String projectId) =>
      _call(() => _dio.post('/v1/projects/$projectId/signing/link'), (d) => d as Map<String, dynamic>);

  /// Play Store apps matching a name (id, title, developer, icon, summary).
  Future<List<Map<String, dynamic>>> searchPlayApps(String query, {String lang = 'it'}) => _call(
    () => _dio.get('/v1/research/play/search', queryParameters: {'q': query, 'lang': lang}),
    (d) => ((d as Map<String, dynamic>)['apps'] as List).cast<Map<String, dynamic>>(),
  );

  /// Full Play Store listing of one app.
  Future<Map<String, dynamic>> playApp(String id, {String lang = 'it'}) =>
      _call(() => _dio.get('/v1/research/play/app', queryParameters: {'id': id, 'lang': lang}), (d) => d as Map<String, dynamic>);

  /// Saves the Play Store screenshots of the app being copied inside the
  /// project, so the engine can see it instead of only reading about it.
  Future<Map<String, dynamic>> saveReferenceShots(String projectId, String playAppId) => _call(
    () => _dio.post('/v1/projects/$projectId/reference-shots', data: {'appId': playAppId}, options: Options(receiveTimeout: const Duration(minutes: 3))),
    (d) => d as Map<String, dynamic>,
  );

  /// Reads a website as the model for an app (no project needed yet).
  Future<Map<String, dynamic>> readSite(String url) => _call(
    () => _dio.get('/v1/research/site', queryParameters: {'url': url}, options: Options(receiveTimeout: const Duration(seconds: 60))),
    (d) => d as Map<String, dynamic>,
  );

  /// Photographs the site's pages into the project, as a model for the engine.
  Future<Map<String, dynamic>> saveSiteShots(String projectId, String url) => _call(
    () => _dio.post('/v1/projects/$projectId/site-reference', data: {'url': url, 'shots': true}, options: Options(receiveTimeout: const Duration(minutes: 6))),
    (d) => d as Map<String, dynamic>,
  );

  /// Android package name + SHA-1 fingerprints (release upload key, debug key).
  Future<Map<String, dynamic>> androidInfo(String projectId) =>
      _call(() => _dio.get('/v1/projects/$projectId/android-info'), (d) => d as Map<String, dynamic>);

  /// Uploads the signed AAB to Google Play (edit → bundle → listing → track → commit).
  /// Saved logos, applied logo, screenshots and store listing.
  Future<Map<String, dynamic>> storeState(String projectId) => _call(() => _dio.get('/v1/projects/$projectId/store'), (d) => d as Map<String, dynamic>);

  /// Saves the store listing texts for future versions.
  Future<void> saveListing(String projectId, Map<String, dynamic> listing) => _call(() => _dio.put('/v1/projects/$projectId/store/listing', data: listing), (_) {});

  /// Logo proposals (base64 PNG) drawn by the AI for a project.
  Future<Map<String, dynamic>> generateLogos(String projectId, Map<String, dynamic> body) => _call(
    () => _dio.post('/v1/projects/$projectId/logos', data: body, options: Options(receiveTimeout: const Duration(minutes: 6))),
    (d) => d as Map<String, dynamic>,
  );

  /// gcloud on the Runner PC: installed / logged-in account.
  Future<Map<String, dynamic>> playSetupStatus() => _call(() => _dio.get('/v1/play/setup/status'), (d) => d as Map<String, dynamic>);

  /// Creates the Google Cloud project, Play API and service account key automatically.
  Future<Map<String, dynamic>> playCreateKey() => _call(
    () => _dio.post('/v1/play/setup/service-account', data: const <String, dynamic>{}, options: Options(receiveTimeout: const Duration(minutes: 8))),
    (d) => d as Map<String, dynamic>,
  );

  /// Invites the service account into the Play Console developer account.
  Future<Map<String, dynamic>> playInvite(String developerId, String serviceAccountEmail) => _call(
    () => _dio.post('/v1/play/setup/invite', data: {'developerId': developerId, 'serviceAccountEmail': serviceAccountEmail}, options: Options(receiveTimeout: const Duration(minutes: 7))),
    (d) => d as Map<String, dynamic>,
  );

  /// Six Play Store phone screenshots taken from the web preview.
  Future<Map<String, dynamic>> takeScreenshots(String projectId) => _call(
    () => _dio.post('/v1/projects/$projectId/screenshots', data: const <String, dynamic>{}, options: Options(receiveTimeout: const Duration(minutes: 10))),
    (d) => d as Map<String, dynamic>,
  );

  /// Uses a proposal as app icon, Play icon and feature graphic.
  Future<Map<String, dynamic>> applyLogo(String projectId, String logoId) =>
      _call(() => _dio.post('/v1/projects/$projectId/logos/$logoId/apply', data: const <String, dynamic>{}), (d) => d as Map<String, dynamic>);

  /// Fills the Play Console "Data safety" form from the exported CSV and uploads it.
  Future<Map<String, dynamic>> fillDataSafety(String projectId, String serviceAccount, {String? csv}) => _call(
    () => _dio.post('/v1/projects/$projectId/play/data-safety', data: {'serviceAccount': serviceAccount, 'csv': ?csv}, options: Options(receiveTimeout: const Duration(minutes: 12))),
    (d) => d as Map<String, dynamic>,
  );

  /// Pushes the app's source to a GitHub repository the user owns.
  Future<Map<String, dynamic>> saveToGitHub(String projectId, String token, {String? repo, bool private = true, String? message}) => _call(
    () => _dio.post(
      '/v1/projects/$projectId/github',
      data: {'token': token, 'private': private, if (repo != null && repo.isNotEmpty) 'repo': repo, if (message != null && message.isNotEmpty) 'message': message},
      options: Options(receiveTimeout: const Duration(minutes: 12)),
    ),
    (d) => d as Map<String, dynamic>,
  );

  /// Apple: sends the build, writes the store page in every language, sets the
  /// privacy answers and (when asked) submits the version for review.
  Future<Map<String, dynamic>> publishToAppStore(String projectId, Map<String, dynamic> body) => _call(
    () => _dio.post('/v1/projects/$projectId/appstore/publish', data: body, options: Options(receiveTimeout: const Duration(minutes: 40))),
    (d) => d as Map<String, dynamic>,
  );

  /// The apps this GitHub account saved from Ember, from any computer.
  Future<List<Map<String, dynamic>>> githubApps(String token) => _call(
    () => _dio.post('/v1/github/apps', data: {'token': token}, options: Options(receiveTimeout: const Duration(minutes: 2))),
    (d) => ((d as Map<String, dynamic>)['apps'] as List).cast<Map<String, dynamic>>(),
  );

  /// Brings one saved app back onto this computer.
  Future<Project> restoreFromGitHub(String workspaceId, String token, String repo, {String? owner}) => _call(
    () => _dio.post(
      '/v1/workspaces/$workspaceId/github/restore',
      data: {'token': token, 'repo': repo, if (owner != null && owner.isNotEmpty) 'owner': owner},
      options: Options(receiveTimeout: const Duration(minutes: 15)),
    ),
    (d) => Project.fromJson((d as Map<String, dynamic>)['project'] as Map<String, dynamic>),
  );

  /// Copies the app's upload key and password to the user's Google Drive.
  Future<Map<String, dynamic>> backupSigningKey(String projectId) => _call(
    () => _dio.post('/v1/projects/$projectId/signing/backup', data: const <String, dynamic>{}, options: Options(receiveTimeout: const Duration(minutes: 6))),
    (d) => d as Map<String, dynamic>,
  );

  /// Answers the Play Console "App content" questions in a Chrome window.
  Future<Map<String, dynamic>> fillPlayAppContent(String projectId, {required String developerId, required String appId, int userIndex = 0, bool save = true}) => _call(
    () => _dio.post(
      '/v1/projects/$projectId/play/app-content',
      data: {'developerId': developerId, 'appId': appId, 'userIndex': userIndex, 'save': save},
      options: Options(receiveTimeout: const Duration(minutes: 20)),
    ),
    (d) => d as Map<String, dynamic>,
  );

  /// Hands this app's facts to the browser helper waiting on Play Console.
  Future<Map<String, dynamic>> sendToHelper(String projectId) =>
      _call(() => _dio.post('/v1/projects/$projectId/helper', data: const <String, dynamic>{}), (d) => d as Map<String, dynamic>);

  /// The phones plugged into the Runner's computer, and its address on the network.
  Future<Map<String, dynamic>> devicesAndNetwork() => _call(() => _dio.get('/v1/devices'), (d) => d as Map<String, dynamic>);

  /// Installs the built APK on a phone and opens it.
  Future<Map<String, dynamic>> runOnDevice(String projectId, {String? deviceId}) => _call(
    () => _dio.post(
      '/v1/projects/$projectId/run-on-device',
      data: {'deviceId': ?deviceId},
      options: Options(receiveTimeout: const Duration(minutes: 12)),
    ),
    (d) => d as Map<String, dynamic>,
  );

  /// What is missing for this app to work, checked in the project and on Google.
  Future<Map<String, dynamic>> checkApp(String projectId, {String? previewUrl}) => _call(
    () => _dio.get(
      '/v1/projects/$projectId/check',
      queryParameters: {if (previewUrl != null && previewUrl.isNotEmpty) 'previewUrl': previewUrl},
      options: Options(receiveTimeout: const Duration(minutes: 3)),
    ),
    (d) => d as Map<String, dynamic>,
  );

  /// Puts right the things the check found, once the user has agreed.
  Future<Map<String, dynamic>> fixApp(String projectId, List<String> ids) => _call(
    () => _dio.post('/v1/projects/$projectId/check/fix', data: {'ids': ids}, options: Options(receiveTimeout: const Duration(minutes: 10))),
    (d) => d as Map<String, dynamic>,
  );

  /// Ember's answer for every Play Console "App content" declaration.
  Future<Map<String, dynamic>> appContent(String projectId) =>
      _call(() => _dio.get('/v1/projects/$projectId/app-content'), (d) => d as Map<String, dynamic>);

  /// Creates and activates in-app products / subscriptions on Google Play.
  Future<Map<String, dynamic>> syncPlayProducts(String projectId, String serviceAccount, List<Map<String, dynamic>> products) => _call(
    () => _dio.post('/v1/projects/$projectId/play/products', data: {'serviceAccount': serviceAccount, 'products': products}, options: Options(receiveTimeout: const Duration(minutes: 5))),
    (d) => d as Map<String, dynamic>,
  );

  Future<Map<String, dynamic>> publishToPlay(String projectId, Map<String, dynamic> body) => _call(
    () => _dio.post('/v1/projects/$projectId/play/publish', data: body, options: Options(receiveTimeout: const Duration(minutes: 15), sendTimeout: const Duration(minutes: 2))),
    (d) => d as Map<String, dynamic>,
  );

  /// Stores the privacy policy and returns its public path.
  /// Saves the policy and publishes it; `publicUrl` is the address to give Google, when it could be made.
  Future<({String path, String? publicUrl})> savePrivacyPolicy(String projectId, String markdown, String appName, {String? email}) => _call(
    () => _dio.put('/v1/projects/$projectId/store/privacy', data: {'markdown': markdown, 'appName': appName, 'email': ?email}),
    (d) => (path: d['path'] as String, publicUrl: d['publicUrl'] as String?),
  );

  Future<String> jobLog(String jobId) =>
      _call(() => _dio.get('/v1/jobs/$jobId'), (d) => d['log'] as String? ?? '');
}
