import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:ide_core/ide_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';

/// Where each store makes its keys, in case the Runner did not say.
const fallbackLinks = {
  'playConsole': 'https://play.google.com/console/developers',
  'googleCloudKeys': 'https://console.cloud.google.com/iam-admin/serviceaccounts',
  'appStoreKeys': 'https://appstoreconnect.apple.com/access/integrations/api',
};

/// A window over the page for connecting one store: tall enough to scroll, never wider than a page.
Future<bool?> showConnectSheet(BuildContext context, WidgetBuilder builder) => showModalBottomSheet<bool>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (c) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
    child: Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: Widths.page), child: builder(c)),
    ),
  ),
);

/// The key file the owner chose: its name, for the screen, and its text, for the Runner.
class PickedKey {
  const PickedKey(this.name, this.text);
  final String name;
  final String text;
}

/// Asks for a file with one of [extensions] and reads it as text. Null when the owner backs out.
Future<PickedKey?> pickKeyFile(String label, List<String> extensions) async {
  final file = await openFile(acceptedTypeGroups: [XTypeGroup(label: label, extensions: extensions)]);
  if (file == null) return null;
  return PickedKey(file.name, (await file.readAsString()).trim());
}

Future<void> openLink(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

/// What went wrong in the owner's words; the Runner's own sentence only as a hint under it.
String connectFailure(AppLocalizations l, Object e) {
  if (e is! RunnerException) return l.error('$e');
  final why = switch (e.code) {
    'bad_key' => l.fxcWhyBadKey,
    'key_refused' => l.fxcWhyRefused,
    'no_permission' => l.fxcWhyNoRole,
    'offline' => l.fxcWhyOffline,
    'bad_developer_id' => l.fxcWhyDeveloperId,
    _ => '',
  };
  return why.isEmpty ? l.error(e.message) : '$why\n${e.message}';
}

/// The frame of both windows: a title, the steps, the form, the buttons.
class ConnectSheetFrame extends StatelessWidget {
  const ConnectSheetFrame({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(Gap.lg, 0, Gap.lg, Gap.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [Text(title, style: context.text.titleLarge), Gap.vMd, ...children],
    ),
  );
}

/// "Choose the file": the button, and below it the name of the file once chosen.
class KeyFileRow extends StatelessWidget {
  const KeyFileRow({super.key, required this.buttonKey, required this.label, required this.picked, required this.onPick, this.enabled = true});
  final Key buttonKey;
  final String label;
  final String? picked;
  final VoidCallback onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Under the button, not beside it: a long label or file name never has to share a line.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton.icon(key: buttonKey, onPressed: enabled ? onPick : null, icon: const Icon(Icons.attach_file), label: Text(label)),
        if (picked != null)
          Padding(
            padding: const EdgeInsets.only(top: Gap.sm),
            child: Row(
              children: [
                Icon(Icons.check_circle_outline, size: 18, color: context.ember.success),
                Gap.hXs,
                Expanded(child: Text(l.fxcFileChosen(picked!), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
      ],
    );
  }
}
