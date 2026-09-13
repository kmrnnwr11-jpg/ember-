import 'dart:convert';

/// Message types of the Runner WebSocket protocol (docs/API.md §WebSocket).
abstract final class MsgType {
  // Requests
  static const fsList = 'fs.list';
  static const fsRead = 'fs.read';
  static const fsWrite = 'fs.write';
  static const fsRename = 'fs.rename';
  static const fsDelete = 'fs.delete';
  static const fsMkdir = 'fs.mkdir';
  static const fsWatch = 'fs.watch';
  static const ptyOpen = 'pty.open';
  static const ptyInput = 'pty.input';
  static const ptyResize = 'pty.resize';
  static const ptyClose = 'pty.close';
  static const jobStart = 'job.start';
  static const jobCancel = 'job.cancel';
  static const analyzeRun = 'analyze.run';
  static const previewStart = 'preview.start';
  static const previewReload = 'preview.reload';
  static const previewStop = 'preview.stop';
  static const previewStatus = 'preview.status';
  static const agentStart = 'agent.start';
  static const agentCancel = 'agent.cancel';
  static const agentComplete = 'agent.complete';
  static const agentGet = 'agent.get';
  static const jobGet = 'job.get';
  static const ping = 'ping';

  // Responses
  static const ok = 'ok';
  static const error = 'error';

  // Server events
  static const fsChanged = 'fs.changed';
  static const ptyOutput = 'pty.output';
  static const ptyExit = 'pty.exit';
  static const previewReady = 'preview.ready';
  static const previewBuilding = 'preview.building';
  static const previewFailed = 'preview.failed';
  static const jobLog = 'job.log';
  static const jobStatus = 'job.status';
  static const analyzeResult = 'analyze.result';
  static const agentEvent = 'agent.event';
  static const agentStatus = 'agent.status';
  static const pong = 'pong';
}

/// A single protocol frame: `{id, type, payload}`.
///
/// Requests carry a client-generated [id]; the matching `ok`/`error`
/// response echoes it. Server-pushed events have a null [id].
class WsFrame {
  const WsFrame({this.id, required this.type, this.payload = const {}});

  final String? id;
  final String type;
  final Map<String, dynamic> payload;

  bool get isResponse => type == MsgType.ok || type == MsgType.error;

  factory WsFrame.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type is! String || type.isEmpty) {
      throw const FormatException('WsFrame: missing "type"');
    }
    final payload = json['payload'];
    return WsFrame(
      id: json['id'] as String?,
      type: type,
      payload: payload is Map<String, dynamic> ? payload : const {},
    );
  }

  factory WsFrame.decode(String raw) =>
      WsFrame.fromJson(jsonDecode(raw) as Map<String, dynamic>);

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'type': type,
    'payload': payload,
  };

  String encode() => jsonEncode(toJson());

  @override
  String toString() => 'WsFrame($type, id: $id)';
}

/// Error returned by the Runner for a failed request.
class RunnerException implements Exception {
  const RunnerException(this.code, this.message);

  final String code;
  final String message;

  factory RunnerException.fromPayload(Map<String, dynamic> p) => RunnerException(
    (p['code'] as String?) ?? 'unknown',
    (p['message'] as String?) ?? 'Unknown error',
  );

  @override
  String toString() => 'RunnerException($code): $message';
}
