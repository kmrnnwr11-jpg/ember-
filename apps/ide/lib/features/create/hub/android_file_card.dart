import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/session.dart';
import '../../../l10n/app_localizations.dart';
import '../../../ui/ui.dart';
import '../app_builder.dart';

/// Makes and hands over the Android file of an app: the one to install on a
/// phone (`apk`) or the one for Google Play (`aab`). Both are signed.
class AndroidFileCard extends ConsumerWidget {
  const AndroidFileCard({super.key, required this.builder, required this.projectId, required this.kind}) : assert(kind == 'apk' || kind == 'aab');
  final AppBuilder builder;
  final String projectId;
  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final b = builder;
    final apk = kind == 'apk';
    final session = ref.watch(sessionProvider).value;
    // The builder makes one file at a time: this card shows it only when it is its own kind.
    final mine = b.androidKind == kind;
    return SectionCard(
      icon: apk ? Icons.android_outlined : Icons.shop_outlined,
      title: apk ? l.installFileTitle : l.storeFileTitle,
      hint: apk ? l.installFileHint : l.storeFileHint,
      children: [
        if (b.androidBuilding && mine) ...[
          Gap.vMd,
          const LinearProgressIndicator(),
          Gap.vSm,
          Text(l.androidBuilding(kind.toUpperCase())),
        ],
        if (mine && b.androidStatus == 'ready' && session != null && b.androidPath != null) ...[
          Gap.vMd,
          Text(apk ? l.apkInstallHint : l.aabHint, style: context.text.bodySmall),
        ],
        if (mine && b.androidStatus == 'failed') ...[
          Gap.vMd,
          InlineMessage(l.androidFailed, error: true),
          if (b.androidError != null) ...[
            Gap.vSm,
            LogSurface(child: SelectableText(b.androidError!, maxLines: 10)),
          ],
        ],
        Gap.vMd,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            if (mine && b.androidStatus == 'ready' && session != null && b.androidPath != null)
              FilledButton.icon(
                key: const Key('downloadAndroid'),
                onPressed: () => launchUrl(Uri.parse('${session.runnerUrl}${b.androidPath}'), mode: LaunchMode.externalApplication),
                icon: const Icon(Icons.download_outlined),
                label: Text(apk ? l.downloadApk : l.downloadAab),
              ),
            FilledButton.tonalIcon(
              key: Key(apk ? 'buildApk' : 'buildAab'),
              onPressed: b.androidBuilding || b.running ? null : () => b.buildAndroid(kind),
              icon: const Icon(Icons.build_outlined),
              label: Text(l.makeFile),
            ),
          ],
        ),
      ],
    );
  }
}

/// The key that signs the app: without it a published app can never be updated.
class SigningKeyCard extends ConsumerWidget {
  const SigningKeyCard({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(sessionProvider).value;
    return SectionCard(
      icon: Icons.key_outlined,
      title: l.backupSigningKey,
      hint: l.backupSigningKeyHint,
      children: [
        Gap.vMd,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('backupKey'),
            onPressed: session == null ? null : () => showKeyBackup(context, ref, projectId, session.runnerUrl),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(l.backupSigningKey),
          ),
        ),
      ],
    );
  }
}

/// Shows the signing key's alias and password, and saves the key file to
/// Google Drive or to the device.
Future<void> showKeyBackup(BuildContext context, WidgetRef ref, String projectId, String runnerUrl) async {
  final l = AppLocalizations.of(context);
  try {
    final info = await (await ref.read(runnerApiProvider.future)).signingLink(projectId);
    if (!context.mounted) return;
    String? driveMessage;
    String? driveFolder;
    bool saving = false;
    await showDialog<void>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setState) => AlertDialog(
          title: Text(l.backupSigningKey),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Widths.form),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.backupSigningKeyHint),
                Gap.vMd,
                SelectableText('Alias: ${info['alias']}'),
                Row(
                  children: [
                    Expanded(child: SelectableText('Password: ${info['password']}')),
                    IconButton(
                      tooltip: l.copy,
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      onPressed: () => Clipboard.setData(ClipboardData(text: info['password'] as String)),
                    ),
                  ],
                ),
                Gap.vMd,
                if (saving) BusyRow(l.driveSaving),
                if (driveMessage != null) SelectableText(driveMessage!),
                if (driveFolder != null)
                  TextButton.icon(
                    onPressed: () => launchUrl(Uri.parse(driveFolder!), mode: LaunchMode.externalApplication),
                    icon: const Icon(Icons.folder_open_outlined, size: 18),
                    label: Text(l.driveOpenFolder),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d), child: Text(l.close)),
            OutlinedButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      setState(() {
                        saving = true;
                        driveMessage = null;
                      });
                      try {
                        final res = await (await ref.read(runnerApiProvider.future)).backupSigningKey(projectId);
                        setState(() {
                          driveMessage = l.driveSaved;
                          driveFolder = res['folderUrl'] as String?;
                        });
                      } on RunnerException catch (e) {
                        setState(() => driveMessage = e.message);
                      } finally {
                        setState(() => saving = false);
                      }
                    },
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(l.driveBackup),
            ),
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse('$runnerUrl${info['path']}'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.download_outlined),
              label: Text(l.downloadKeystore),
            ),
          ],
        ),
      ),
    );
  } on RunnerException catch (e) {
    if (context.mounted) showEmberSnack(context, l.error(e.message), error: true);
  }
}
