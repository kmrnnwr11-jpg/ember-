import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:ide_core/ide_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

enum SocketState { connecting, connected, disconnected }

/// Persistent WebSocket to the Runner (§5D): request/response correlation,
/// app-level heartbeat, exponential reconnect, and re-subscription of
/// `fs.watch` after reconnect. Requests made while offline wait for the
/// connection up to [requestTimeout].
class RunnerSocket {
  RunnerSocket({
    required String runnerUrl,
    required Future<String?> Function() tokenProvider,
    this.requestTimeout = const Duration(seconds: 20),
    @visibleForTesting WebSocketChannel Function(Uri uri)? connector,
  }) : _baseUri = Uri.parse(runnerUrl),
       _tokenProvider = tokenProvider,
       _connector = connector ?? WebSocketChannel.connect;

  final Uri _baseUri;
  final Future<String?> Function() _tokenProvider;
  final WebSocketChannel Function(Uri uri) _connector;
  final Duration requestTimeout;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  int _attempt = 0;
  int _seq = 0;
  bool _disposed = false;

  final _pending = <String, Completer<Map<String, dynamic>>>{};
  final _events = StreamController<WsFrame>.broadcast();
  final _watched = <String>{};
  final state = ValueNotifier(SocketState.disconnected);
  Completer<void> _connected = Completer<void>();

  Stream<WsFrame> get events => _events.stream;

  Stream<WsFrame> eventsOf(String type) => events.where((f) => f.type == type);

  Uri _wsUri(String token) => _baseUri.replace(
    scheme: _baseUri.scheme == 'https' ? 'wss' : 'ws',
    path: '${_baseUri.path.replaceAll(RegExp(r'/+$'), '')}/v1/ws',
    queryParameters: {'token': token},
  );

  Future<void> connect() async {
    if (_disposed || state.value != SocketState.disconnected) return;
    state.value = SocketState.connecting;
    try {
      final token = await _tokenProvider();
      if (token == null) throw const RunnerException('unauthorized', 'not signed in');
      final channel = _connector(_wsUri(token));
      await channel.ready;
      _channel = channel;
      _sub = channel.stream.listen(_onData, onDone: _onClosed, onError: (_) => _onClosed());
      _attempt = 0;
      state.value = SocketState.connected;
      if (!_connected.isCompleted) _connected.complete();
      _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) => _send(const WsFrame(type: MsgType.ping)));
      for (final projectId in _watched) {
        unawaited(request(MsgType.fsWatch, {'projectId': projectId}).catchError((_) => <String, dynamic>{}));
      }
    } catch (_) {
      _onClosed();
    }
  }

  void _onData(dynamic raw) {
    final WsFrame frame;
    try {
      frame = WsFrame.decode(raw as String);
    } catch (_) {
      return;
    }
    final id = frame.id;
    if (frame.isResponse && id != null) {
      final c = _pending.remove(id);
      if (c == null) return;
      if (frame.type == MsgType.ok) {
        c.complete(frame.payload);
      } else {
        c.completeError(RunnerException.fromPayload(frame.payload));
      }
      return;
    }
    _events.add(frame);
  }

  void _onClosed() {
    final closeCode = _channel?.closeCode;
    _heartbeat?.cancel();
    unawaited(_sub?.cancel());
    _sub = null;
    _channel = null;
    if (_connected.isCompleted) _connected = Completer<void>();
    state.value = SocketState.disconnected;
    for (final c in _pending.values) {
      c.completeError(const RunnerException('disconnected', 'connection lost'));
    }
    _pending.clear();
    if (_disposed || closeCode == 4401) return;
    final delay = Duration(milliseconds: min(30000, 500 * pow(2, _attempt++).toInt()));
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, connect);
  }

  void _send(WsFrame f) => _channel?.sink.add(f.encode());

  /// Sends a request and returns the `ok` payload; throws [RunnerException].
  Future<Map<String, dynamic>> request(String type, Map<String, dynamic> payload) async {
    if (state.value != SocketState.connected) {
      if (state.value == SocketState.disconnected) unawaited(connect());
      await _connected.future.timeout(
        requestTimeout,
        onTimeout: () => throw const RunnerException('disconnected', 'Runner unreachable'),
      );
    }
    final id = 'c${++_seq}';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _send(WsFrame(id: id, type: type, payload: payload));
    return completer.future.timeout(requestTimeout, onTimeout: () {
      _pending.remove(id);
      throw RunnerException('timeout', '$type timed out');
    });
  }

  Future<void> watch(String projectId) async {
    _watched.add(projectId);
    await request(MsgType.fsWatch, {'projectId': projectId});
  }

  Future<void> unwatch(String projectId) async {
    if (!_watched.remove(projectId)) return;
    if (state.value == SocketState.connected) {
      await request(MsgType.fsWatch, {'projectId': projectId, 'enabled': false});
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _reconnectTimer?.cancel();
    _heartbeat?.cancel();
    await _channel?.sink.close();
    await _sub?.cancel();
    await _events.close();
    state.dispose();
  }
}
