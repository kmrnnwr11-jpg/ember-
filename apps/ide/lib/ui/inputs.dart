import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'theme.dart';
import 'tokens.dart';

/// A field for a key, a token or a password: hidden by default, with paste
/// and show/hide, and an optional link to where the secret is obtained.
class SecretField extends StatefulWidget {
  const SecretField({
    super.key,
    required this.controller,
    required this.label,
    this.helper,
    this.hint,
    this.getUrl,
    this.getLabel,
    this.maxLines = 1,
    this.obscure = true,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String label;
  final String? helper;
  final String? hint;

  /// Where to get the secret; shows a link under the field.
  final String? getUrl;
  final String? getLabel;

  /// More than one line (certificates, JSON keys) is never obscured.
  final int maxLines;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  @override
  State<SecretField> createState() => _SecretFieldState();
}

class _SecretFieldState extends State<SecretField> {
  bool _show = false;

  bool get _canHide => widget.obscure && widget.maxLines == 1;

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    widget.controller.text = text;
    widget.onChanged?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: widget.controller,
          enabled: widget.enabled,
          obscureText: _canHide && !_show,
          maxLines: widget.maxLines,
          minLines: widget.maxLines > 1 ? 2 : null,
          autocorrect: false,
          enableSuggestions: false,
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
          style: widget.maxLines > 1 ? kMono : null,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            helperText: widget.helper,
            helperMaxLines: 4,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(tooltip: l.paste, icon: const Icon(Icons.content_paste_outlined), onPressed: widget.enabled ? _paste : null),
                if (_canHide)
                  IconButton(
                    tooltip: _show ? l.hideSecret : l.showSecret,
                    icon: Icon(_show ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    onPressed: () => setState(() => _show = !_show),
                  ),
                Gap.hXs,
              ],
            ),
          ),
        ),
        if (widget.getUrl != null && widget.getLabel != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => launchUrl(Uri.parse(widget.getUrl!), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(widget.getLabel!),
            ),
          ),
      ],
    );
  }
}
