import 'dart:async';

import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/foundation.dart';
import 'package:ide_core/ide_core.dart';

class ChatEntry {
  ChatEntry({
    required this.role,
    required this.text,
    this.model,
    this.contextPath,
    this.error,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.stopReason,
    this.costUsd,
    DateTime? at,
  }) : at = at ?? DateTime.now();

  double? costUsd;

  final AiRole role;
  String text;
  final String? model;

  /// File attached as context when the user sent this message.
  final String? contextPath;
  String? error;
  int inputTokens;
  int outputTokens;
  String? stopReason;
  final DateTime at;
  bool streaming = false;

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'text': text,
    'model': model,
    'contextPath': contextPath,
    'error': error,
    'in': inputTokens,
    'out': outputTokens,
    'stop': stopReason,
    'cost': costUsd,
    'at': at.toIso8601String(),
  };

  factory ChatEntry.fromJson(Map<String, dynamic> j) => ChatEntry(
    role: AiRole.values.byName(j['role'] as String),
    text: j['text'] as String? ?? '',
    model: j['model'] as String?,
    contextPath: j['contextPath'] as String?,
    error: j['error'] as String?,
    inputTokens: j['in'] as int? ?? 0,
    outputTokens: j['out'] as int? ?? 0,
    stopReason: j['stop'] as String?,
    costUsd: (j['cost'] as num?)?.toDouble(),
    at: DateTime.tryParse(j['at'] as String? ?? ''),
  );
}

/// The file the user is looking at, sent as context (§1.3).
class ChatFileContext {
  const ChatFileContext(this.path, this.content);
  final String path;
  final String content;
}

typedef ProviderResolver = Future<AiProvider> Function(AiModel model);

const chatSystemPrompt = '''
You are the AI assistant inside FlutterCursor, an IDE for building Flutter apps.
Answer in the user's language. Be concise and concrete.
When you propose changes to a file, return the COMPLETE new file content in a fenced
code block whose info string has the language and the project-relative path, for example:
```dart lib/main.dart
// full file here
```
Use one block per file. For snippets that are not whole files, omit the path.''';

/// Max characters of the open file attached as context. Larger files are not
/// silently truncated: the user is told the file was too large to attach.
const maxContextChars = 200000;

/// Project-scoped chat session with streaming, stop and persistence.
class ChatController extends ChangeNotifier {
  ChatController({
    required this.projectId,
    required ProviderResolver resolveProvider,
    Future<List<Map<String, dynamic>>> Function()? loadHistory,
    Future<void> Function(List<Map<String, dynamic>>)? saveHistory,
  }) : _resolve = resolveProvider,
       _save = saveHistory {
    if (loadHistory != null) {
      loadHistory().then((rows) {
        if (entries.isEmpty) {
          entries.addAll(rows.map(ChatEntry.fromJson));
          notifyListeners();
        }
      });
    }
  }

  final String projectId;
  final ProviderResolver _resolve;
  final Future<void> Function(List<Map<String, dynamic>>)? _save;

  final List<ChatEntry> entries = [];
  AiModel? model;
  bool attachOpenFile = true;
  StreamSubscription<AiEvent>? _sub;
  Completer<void>? _done;

  bool get busy => _sub != null;

  /// Estimated USD spent in this chat (each reply priced with its own model).
  double get sessionCost => entries.fold(0.0, (sum, e) => sum + (e.costUsd ?? 0));

  void selectModel(AiModel m) {
    model = m;
    notifyListeners();
  }

  void toggleAttach() {
    attachOpenFile = !attachOpenFile;
    notifyListeners();
  }

  /// Builds the provider message list from history plus the new turn.
  @visibleForTesting
  static List<AiMessage> buildMessages(List<ChatEntry> history, String userText, ChatFileContext? file) {
    final msgs = <AiMessage>[
      for (final e in history)
        if (e.error == null && e.text.isNotEmpty && (e.role == AiRole.user || e.role == AiRole.assistant))
          AiMessage(e.role, e.text),
    ];
    var content = userText;
    if (file != null) {
      content = file.content.length > maxContextChars
          ? '(The open file ${file.path} is too large to attach: ${file.content.length} characters.)\n\n$userText'
          : 'Open file: ${file.path}\n```${ProjectPath.languageOf(file.path)} ${file.path}\n${file.content}\n```\n\n$userText';
    }
    msgs.add(AiMessage.user(content));
    return msgs;
  }

  Future<void> send(String text, {ChatFileContext? openFile}) async {
    final m = model;
    if (m == null || text.trim().isEmpty || busy) return;
    final file = attachOpenFile ? openFile : null;
    final history = List<ChatEntry>.of(entries);
    entries.add(ChatEntry(role: AiRole.user, text: text.trim(), contextPath: file?.path));
    final reply = ChatEntry(role: AiRole.assistant, text: '', model: m.key)..streaming = true;
    entries.add(reply);
    notifyListeners();

    final AiProvider provider;
    try {
      provider = await _resolve(m);
    } catch (e) {
      reply
        ..streaming = false
        ..error = e is AiException ? e.message : e.toString();
      notifyListeners();
      await _persist();
      return;
    }

    final done = _done = Completer<void>();
    _sub = provider
        .chat(model: m.id, system: chatSystemPrompt, messages: buildMessages(history, text.trim(), file))
        .listen(
          (event) {
            switch (event) {
              case AiTextDelta(:final text):
                reply.text += text;
              case AiUsage(:final inputTokens, :final outputTokens):
                if (inputTokens > 0) reply.inputTokens = inputTokens;
                if (outputTokens > 0) reply.outputTokens = outputTokens;
              case AiStop(:final reason):
                reply.stopReason = reason;
              case AiError(:final message):
                reply.error = message;
              case AiToolCall():
                break; // tools are used by the Agent (Phase 5), not plain chat
            }
            notifyListeners();
          },
          onError: (Object e) => reply.error = e.toString(),
          onDone: () {
            if (!done.isCompleted) done.complete();
          },
          cancelOnError: true,
        );
    await done.future;
    if (_sub == null) return; // stopped: already finished by stop()
    reply.costUsd = m.estimateCost(reply.inputTokens, reply.outputTokens);
    _finish(reply);
  }

  void _finish(ChatEntry reply) {
    reply.streaming = false;
    _sub = null;
    notifyListeners();
    unawaited(_persist());
  }

  /// Stops the current response, keeping what streamed so far.
  Future<void> stop() async {
    final sub = _sub;
    if (sub == null) return;
    _sub = null;
    // Don't await: cancel() waits for a stalled upstream (e.g. hung network)
    // to reach its next event, which would freeze the Stop button.
    unawaited(sub.cancel());
    final reply = entries.lastWhere((e) => e.streaming, orElse: () => entries.last);
    reply.stopReason = 'stopped';
    _finish(reply);
    // cancel() does not fire onDone; release the pending send().
    if (_done?.isCompleted == false) _done!.complete();
  }

  Future<void> clear() async {
    await stop();
    entries.clear();
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async => _save?.call([for (final e in entries) e.toJson()]);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
