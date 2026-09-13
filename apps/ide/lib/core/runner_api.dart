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

  Future<String> jobLog(String jobId) =>
      _call(() => _dio.get('/v1/jobs/$jobId'), (d) => d['log'] as String? ?? '');
}
