import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'http_client_stub.dart' if (dart.library.js_interop) 'http_client_web.dart' as platform;
import 'types.dart';

/// Where requests go and how they authenticate.
///
/// - [AiEndpoint.direct]: straight to the provider with the user's key.
///   Not usable from browsers for most providers (CORS, key exposure).
/// - [AiEndpoint.proxy]: through the FlutterCursor Runner
///   (`/v1/ai/proxy/<provider>`), which injects the key server-side per request.
class AiEndpoint {
  const AiEndpoint.direct({required this.apiKey, String? baseUrl})
    : proxied = false,
      _baseUrl = baseUrl,
      runnerUrl = null,
      runnerToken = null,
      proxyPath = null;

  const AiEndpoint.proxy({
    required this.apiKey,
    required String this.runnerUrl,
    required this.runnerToken,
    String? baseUrl,
    this.proxyPath,
  }) : proxied = true,
       _baseUrl = baseUrl;

  final String apiKey;
  final bool proxied;
  final String? runnerUrl;
  final String? runnerToken;

  /// Runner path replacing `proxy/<provider>` (e.g. `assistant` for the free server-key assistant).
  final String? proxyPath;

  /// Upstream base URL override (required for OpenAI-compatible providers).
  final String? _baseUrl;
  String? get upstreamBaseUrl => _baseUrl;

  static const defaultBaseUrls = {
    AiProviderId.anthropic: 'https://api.anthropic.com',
    AiProviderId.openai: 'https://api.openai.com',
    AiProviderId.gemini: 'https://generativelanguage.googleapis.com',
    AiProviderId.xai: 'https://api.x.ai',
  };

  String baseFor(AiProviderId provider) {
    if (proxied) return '${runnerUrl!.replaceAll(RegExp(r'/+$'), '')}/v1/ai/${proxyPath ?? 'proxy/${provider.name}'}';
    final base = _baseUrl ?? defaultBaseUrls[provider];
    if (base == null) throw const AiException('baseUrl is required for OpenAI-compatible providers');
    return base.replaceAll(RegExp(r'/+$'), '');
  }

  /// Headers for [provider]; [directAuth] are the provider's own auth headers.
  Map<String, String> headers(Map<String, String> directAuth) => {
    'content-type': 'application/json',
    if (proxied) ...{
      'authorization': 'Bearer $runnerToken',
      'x-provider-key': apiKey,
      if (_baseUrl != null) 'x-provider-base-url': _baseUrl,
    } else
      ...directAuth,
  };
}

/// Creates a streaming-capable HTTP client for the current platform.
http.Client createStreamingClient() => platform.createClient();

/// One Server-Sent Event.
class SseEvent {
  const SseEvent(this.event, this.data);
  final String? event;
  final String data;
}

/// Parses an SSE byte stream (handles CRLF, multi-line data, comments).
Stream<SseEvent> parseSse(Stream<List<int>> bytes) async* {
  String? event;
  final data = StringBuffer();
  var hasData = false;
  await for (final line in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (hasData) yield SseEvent(event, data.toString());
      event = null;
      data.clear();
      hasData = false;
      continue;
    }
    if (line.startsWith(':')) continue;
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        event = value;
      case 'data':
        if (hasData) data.write('\n');
        data.write(value);
        hasData = true;
    }
  }
  if (hasData) yield SseEvent(event, data.toString());
}

/// POSTs JSON and returns the streamed response, throwing [AiException] on HTTP errors.
Future<http.StreamedResponse> postStream(http.Client client, Uri url, Map<String, String> headers, Object body) async {
  final req = http.Request('POST', url)
    ..headers.addAll(headers)
    ..body = jsonEncode(body);
  final res = await client.send(req);
  if (res.statusCode >= 400) {
    final text = await res.stream.bytesToString();
    throw AiException(extractErrorMessage(text), statusCode: res.statusCode);
  }
  return res;
}

Future<Map<String, dynamic>> postJson(http.Client client, Uri url, Map<String, String> headers, Object body) async {
  final res = await client.post(url, headers: headers, body: jsonEncode(body));
  if (res.statusCode >= 400) throw AiException(extractErrorMessage(res.body), statusCode: res.statusCode);
  return jsonDecode(res.body) as Map<String, dynamic>;
}

/// Pulls a human-readable message out of the providers' error JSON shapes.
String extractErrorMessage(String body) {
  try {
    final j = jsonDecode(body);
    if (j is Map) {
      final e = j['error'];
      if (e is Map && e['message'] is String) return e['message'] as String;
      if (e is String) return e;
      if (j['message'] is String) return j['message'] as String;
    }
    if (j is List && j.isNotEmpty && j.first is Map) {
      final e = (j.first as Map)['error'];
      if (e is Map && e['message'] is String) return e['message'] as String;
    }
  } catch (_) {
    // not JSON
  }
  return body.length > 500 ? '${body.substring(0, 500)}…' : body;
}

/// Maps transport failures into [AiError] events so chat streams never throw.
///
/// Note: errors from a `yield*`-ed stream are forwarded, not thrown into a
/// surrounding try/catch, so they are converted with a transformer instead.
Stream<AiEvent> guardStream(Stream<AiEvent> Function() body) {
  Stream<AiEvent> source;
  try {
    source = body();
  } catch (e) {
    source = Stream.error(e);
  }
  var failed = false;
  return source.transform(StreamTransformer.fromHandlers(
    handleData: (event, sink) {
      if (!failed) sink.add(event);
    },
    handleError: (error, stack, sink) {
      if (failed) return;
      failed = true;
      sink.add(switch (error) {
        AiException(:final message, :final statusCode) => AiError(message, statusCode: statusCode),
        http.ClientException(:final message) => AiError('Network error: $message'),
        FormatException(:final message) => AiError('Malformed response: $message'),
        _ => AiError(error.toString()),
      });
    },
  ));
}
