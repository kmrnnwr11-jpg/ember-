import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../widgets/ember_logo.dart';
import 'theme.dart';
import 'tokens.dart';

/// A page or panel that is still loading.
class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.text});
  final String? text;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (text != null) ...[Gap.vMd, Text(text!, style: context.text.bodySmall)],
      ],
    ),
  );
}

/// Nothing here yet: what this place is for and, when there is one, what to do.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.icon, required this.text, this.action, this.compact = false});

  /// Null shows the Ember mark.
  final IconData? icon;
  final String text;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(compact ? Gap.lg : Gap.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: compact ? 28 : 40, color: context.scheme.onSurfaceVariant)
          else
            ExcludeSemantics(child: EmberMark(size: compact ? 48 : 72)),
          Gap.vMd,
          Text(text, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
          if (action != null) ...[Gap.vMd, action!],
        ],
      ),
    ),
  );
}

/// Something failed: say it plainly and offer to try again.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry, this.retryLabel});
  final String message;
  final VoidCallback? onRetry;
  final String? retryLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Gap.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 40, color: context.scheme.error),
          Gap.vMd,
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Widths.form),
            child: SelectableText(message, textAlign: TextAlign.center),
          ),
          if (onRetry != null) ...[
            Gap.vMd,
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel ?? AppLocalizations.of(context).retry),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Asks before doing something. Returns true when confirmed.
Future<bool> showConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  String? cancelLabel,
  bool destructive = false,
}) async {
  final l = AppLocalizations.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(cancelLabel ?? l.cancel)),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: c.scheme.error, foregroundColor: c.scheme.onError) : null,
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel ?? l.ok),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// A short message at the bottom of the screen. Errors stay longer.
void showEmberSnack(BuildContext context, String text, {bool error = false, SnackBarAction? action}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (error) ...[Icon(Icons.error_outline, size: 18, color: context.scheme.error), Gap.hSm],
            Expanded(child: Text(text)),
          ],
        ),
        duration: Duration(seconds: error ? 6 : 3),
        action: action,
      ),
    );
}

/// The reading column of a page: centred, never wider than [maxWidth].
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = Widths.page, this.controller, this.padding = const EdgeInsets.all(Gap.lg)});
  final List<Widget> children;
  final double maxWidth;
  final ScrollController? controller;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ListView(controller: controller, padding: padding, children: children),
    ),
  );
}
