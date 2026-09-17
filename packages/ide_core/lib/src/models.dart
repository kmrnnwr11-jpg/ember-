import 'package:meta/meta.dart';

@immutable
class Workspace {
  const Workspace({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String name;

  /// `stopped` | `starting` | `running` | `error`.
  final String status;
  final DateTime createdAt;

  factory Workspace.fromJson(Map<String, dynamic> j) => Workspace(
    id: j['id'] as String,
    name: j['name'] as String,
    status: j['status'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

@immutable
class Project {
  const Project({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.template,
    required this.status,
    required this.createdAt,
    this.lastModel,
    this.title,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String template;

  /// The name the app carries on the store, once the listing is written.
  final String? title;

  /// What to call the app: its store name, or the folder name until there is one.
  String get displayName => (title ?? '').trim().isEmpty ? name : title!.trim();

  /// `creating` | `ready` | `error`.
  final String status;
  final DateTime createdAt;
  final String? lastModel;

  bool get isReady => status == 'ready';

  factory Project.fromJson(Map<String, dynamic> j) => Project(
    id: j['id'] as String,
    workspaceId: j['workspaceId'] as String,
    name: j['name'] as String,
    template: j['template'] as String,
    status: j['status'] as String,
    createdAt: DateTime.parse(j['createdAt'] as String),
    lastModel: j['lastModel'] as String?,
    title: j['title'] as String?,
  );
}

@immutable
class FsEntry {
  const FsEntry({
    required this.path,
    required this.name,
    required this.isDir,
    this.size = 0,
  });

  /// Project-relative POSIX path, e.g. `lib/main.dart`.
  final String path;
  final String name;
  final bool isDir;
  final int size;

  factory FsEntry.fromJson(Map<String, dynamic> j) => FsEntry(
    path: j['path'] as String,
    name: j['name'] as String,
    isDir: j['isDir'] as bool,
    size: (j['size'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      other is FsEntry && other.path == path && other.isDir == isDir;

  @override
  int get hashCode => Object.hash(path, isDir);
}

@immutable
class PreviewInfo {
  const PreviewInfo({
    required this.projectId,
    required this.path,
    required this.built,
    required this.autoRebuild,
    required this.building,
    this.url,
    this.builtAt,
  });

  final String projectId;

  /// Absolute preview URL when the Runner has a preview domain.
  final String? url;

  /// Path on the Runner host, used when [url] is null.
  final String path;
  final bool built;
  final DateTime? builtAt;
  final bool autoRebuild;
  final bool building;

  /// Public URL of the preview given the Runner base URL.
  String resolve(String runnerUrl) =>
      url ?? '${runnerUrl.replaceAll(RegExp(r'/+$'), '')}$path';

  factory PreviewInfo.fromJson(Map<String, dynamic> j) => PreviewInfo(
    projectId: j['projectId'] as String,
    url: j['url'] as String?,
    path: j['path'] as String,
    built: j['built'] as bool? ?? false,
    builtAt: j['builtAt'] == null ? null : DateTime.parse(j['builtAt'] as String),
    autoRebuild: j['autoRebuild'] as bool? ?? false,
    building: j['building'] as bool? ?? false,
  );
}

@immutable
class JobStatus {
  const JobStatus({
    required this.jobId,
    required this.kind,
    required this.status,
    this.exitCode,
  });

  final String jobId;
  final String kind;

  /// `queued` | `running` | `succeeded` | `failed` | `cancelled`.
  final String status;
  final int? exitCode;

  bool get isDone =>
      status == 'succeeded' || status == 'failed' || status == 'cancelled';

  factory JobStatus.fromJson(Map<String, dynamic> j) => JobStatus(
    jobId: j['jobId'] as String,
    kind: j['kind'] as String,
    status: j['status'] as String,
    exitCode: (j['exitCode'] as num?)?.toInt(),
  );
}
