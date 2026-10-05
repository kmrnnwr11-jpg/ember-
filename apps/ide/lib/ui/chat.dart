import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'theme.dart';
import 'tokens.dart';

/// One message in a conversation. The user's messages sit at the end side.
class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.child, this.isUser = false, this.dimmed = false, this.avatar, this.maxWidth = 680});

  /// A bubble with plain selectable text.
  ChatBubble.text(String text, {super.key, this.isUser = false, this.dimmed = false, this.avatar, this.maxWidth = 680}) : child = SelectableText(text);

  final Widget child;
  final bool isUser;

  /// An older step that no longer needs attention.
  final bool dimmed;

  /// Shown before the assistant's bubbles.
  final Widget? avatar;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = context.scheme;
    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: isUser ? scheme.primaryContainer : scheme.surfaceContainerHigh,
        borderRadius: Radii.mdAll,
        border: isUser ? null : Border.all(color: scheme.outlineVariant),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: isUser ? scheme.onPrimaryContainer : scheme.onSurface),
        child: child,
      ),
    );
    return Opacity(
      opacity: dimmed ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Gap.xs),
        child: Align(
          alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: avatar == null || isUser
              ? bubble
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [avatar!, Gap.hSm, Flexible(child: bubble)],
                ),
        ),
      ),
    );
  }
}

/// Where the user writes the next message. Ctrl/Cmd+Enter sends.
class ChatComposer extends StatelessWidget {
  const ChatComposer({
    super.key,
    required this.controller,
    required this.hint,
    required this.onSend,
    required this.sendTooltip,
    this.onStop,
    this.stopTooltip,
    this.busy = false,
    this.enabled = true,
    this.leading = const [],
    this.trailing = const [],
    this.above,
    this.focusNode,
    this.fieldKey,
    this.sendKey,
    this.maxLines = 5,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  final String sendTooltip;

  /// Shown instead of send while [busy].
  final VoidCallback? onStop;
  final String? stopTooltip;
  final bool busy;
  final bool enabled;

  /// Buttons before the field (attach) and between field and send.
  final List<Widget> leading;
  final List<Widget> trailing;

  /// Chips or previews for what is attached.
  final Widget? above;
  final FocusNode? focusNode;
  final Key? fieldKey;
  final Key? sendKey;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    void send() {
      if (!enabled || busy) return;
      onSend();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (above != null) Padding(padding: const EdgeInsets.only(bottom: Gap.sm), child: above),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ...leading,
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter, control: true): send,
                  const SingleActivator(LogicalKeyboardKey.enter, meta: true): send,
                },
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  focusNode: focusNode,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: maxLines,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(hintText: hint),
                ),
              ),
            ),
            ...trailing,
            Gap.hSm,
            if (busy && onStop != null)
              IconButton.filledTonal(tooltip: stopTooltip, onPressed: onStop, icon: const Icon(Icons.stop_outlined))
            else
              IconButton.filled(key: sendKey, tooltip: sendTooltip, onPressed: enabled && !busy ? onSend : null, icon: const Icon(Icons.arrow_upward)),
          ],
        ),
      ],
    );
  }
}

/// A dark, monospace surface for logs, consoles and code. Dark in both themes.
class LogSurface extends StatelessWidget {
  const LogSurface({super.key, required this.child, this.height, this.padding = const EdgeInsets.all(Gap.md), this.radius = Radii.smAll});
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry padding;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    final ember = context.ember;
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(color: ember.codeSurface, borderRadius: radius),
      child: DefaultTextStyle.merge(
        style: kMono.copyWith(color: ember.onCodeSurface),
        child: IconTheme.merge(data: IconThemeData(color: ember.codeMuted, size: 14), child: child),
      ),
    );
  }
}

/// A round button drawn over a preview or another always-dark surface.
class OverlayButton extends StatelessWidget {
  const OverlayButton({super.key, required this.icon, required this.tooltip, required this.onPressed});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ember = context.ember;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: ember.scrim,
        foregroundColor: ember.onCodeSurface,
        disabledForegroundColor: ember.codeMuted,
        minimumSize: const Size.square(kTapTarget),
      ),
    );
  }
}
