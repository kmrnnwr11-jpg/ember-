import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../../ui/ui.dart';
import '../app_builder.dart';
import 'appstore_categories.dart';

/// 1. The App Store Connect key. Once saved it is one line and a way to change
/// it: a returning user is not shown the form again.
class AppStoreConnectionSection extends StatelessWidget {
  const AppStoreConnectionSection({
    super.key,
    required this.loading,
    required this.hasKey,
    required this.editingKey,
    required this.p8File,
    required this.busy,
    required this.verifying,
    required this.keyId,
    required this.issuer,
    required this.team,
    required this.p8,
    required this.onIdChanged,
    required this.onEditKey,
    required this.onLoadFile,
    required this.onSaveKey,
    required this.onVerify,
    required this.onForget,
    this.saved,
    this.message,
    this.error = false,
  });

  final bool loading;
  final bool hasKey;
  final bool editingKey;
  final String p8File;
  final bool busy;
  final bool verifying;
  final TextEditingController keyId;
  final TextEditingController issuer;
  final TextEditingController team;
  final TextEditingController p8;
  final VoidCallback onIdChanged;

  /// Opens (true) or closes (false) the key form when a key is already saved.
  final ValueChanged<bool> onEditKey;
  final VoidCallback onLoadFile;
  final VoidCallback onSaveKey;
  final VoidCallback onVerify;
  final VoidCallback onForget;

  /// "Saved", shown for a moment after a save.
  final String? saved;
  final String? message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      icon: Icons.key_outlined,
      title: l.asConnTitle,
      hint: l.asConnHint,
      children: [
        if (loading) ...[
          Gap.vMd,
          BusyRow(l.ascWorking),
        ] else if (hasKey && !editingKey) ...[
          Gap.vSm,
          StatusRow(
            done: true,
            text: l.asKeySaved(p8File),
            trailing: TextButton(onPressed: busy ? null : () => onEditKey(true), child: Text(l.asChangeKey)),
          ),
        ] else ...[
          if (!hasKey) ...[
            Gap.vSm,
            Text(l.ascKeyHelp, style: context.text.bodySmall),
          ],
          Gap.vMd,
          TextField(
            controller: keyId,
            autocorrect: false,
            onChanged: (_) => onIdChanged(),
            decoration: InputDecoration(labelText: l.ascKeyId),
          ),
          Gap.vMd,
          TextField(
            controller: issuer,
            autocorrect: false,
            onChanged: (_) => onIdChanged(),
            decoration: InputDecoration(labelText: l.ascIssuerId),
          ),
          Gap.vMd,
          TextField(
            controller: team,
            autocorrect: false,
            onChanged: (_) => onIdChanged(),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(labelText: l.asTeamId, helperText: l.asTeamIdHelp, helperMaxLines: 3),
          ),
          Gap.vMd,
          SecretField(controller: p8, label: l.ascPrivateKey, helper: hasKey ? l.asP8KeepHelp : null, maxLines: 6),
          Gap.vMd,
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              // Tonal: the one primary button of the page is Publish.
              FilledButton.tonalIcon(onPressed: busy ? null : onSaveKey, icon: const Icon(Icons.save_outlined), label: Text(l.asSaveKey)),
              OutlinedButton.icon(onPressed: busy ? null : onLoadFile, icon: const Icon(Icons.upload_file_outlined), label: Text(l.asLoadP8)),
              if (hasKey) TextButton(onPressed: busy ? null : () => onEditKey(false), child: Text(l.cancel)),
            ],
          ),
        ],
        if (saved != null) ...[
          Gap.vSm,
          StatusRow(done: true, text: saved!),
        ],
        if (verifying) ...[
          Gap.vMd,
          BusyRow(l.ascWorking),
        ],
        if (message != null) ...[
          Gap.vMd,
          InlineMessage(message!, error: error),
        ],
        if (!loading && hasKey) ...[
          Gap.vSm,
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.sm,
            children: [
              OutlinedButton.icon(onPressed: (busy || verifying) ? null : onVerify, icon: const Icon(Icons.wifi_tethering), label: Text(l.asVerify)),
              TextButton(onPressed: busy ? null : onForget, child: Text(l.ascForget)),
            ],
          ),
        ],
      ],
    );
  }
}

/// 2. The chores Ember does on App Store Connect, and the few choices they need.
class AppStoreFillSection extends StatelessWidget {
  const AppStoreFillSection({
    super.key,
    required this.busy,
    required this.category,
    required this.free,
    required this.screenshots,
    required this.uploadBuild,
    required this.submit,
    required this.onCategory,
    required this.onFree,
    required this.onScreenshots,
    required this.onUploadBuild,
    required this.onSubmit,
    required this.reviewEmail,
    required this.reviewPhone,
    required this.marketingUrl,
    required this.reviewNotes,
    required this.demoUser,
    required this.demoPass,
  });

  final bool busy;

  /// App Store category id, e.g. "UTILITIES"; null leaves it as it is on Apple.
  final String? category;
  final bool free;
  final bool screenshots;
  final bool uploadBuild;
  final bool submit;
  final ValueChanged<String?> onCategory;
  final ValueChanged<bool> onFree;
  final ValueChanged<bool> onScreenshots;
  final ValueChanged<bool> onUploadBuild;
  final ValueChanged<bool> onSubmit;
  final TextEditingController reviewEmail;
  final TextEditingController reviewPhone;
  final TextEditingController marketingUrl;
  final TextEditingController reviewNotes;
  final TextEditingController demoUser;
  final TextEditingController demoPass;

  Widget _check(String key, bool value, ValueChanged<bool> onChanged, String title, {String? subtitle}) => CheckboxListTile(
    key: Key(key),
    contentPadding: EdgeInsets.zero,
    value: value,
    onChanged: busy ? null : (v) => onChanged(v ?? false),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle),
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SectionCard(
      icon: Icons.auto_awesome_outlined,
      title: l.asFillTitle,
      hint: l.asFillHint,
      children: [
        Gap.vMd,
        DropdownButtonFormField<String>(
          initialValue: category,
          isExpanded: true,
          decoration: InputDecoration(labelText: l.asCategory),
          items: [
            DropdownMenuItem<String>(value: null, child: Text(l.asCategoryNone)),
            for (final (id, label) in appStoreCategories(l)) DropdownMenuItem<String>(value: id, child: Text(label)),
          ],
          onChanged: busy ? null : onCategory,
        ),
        Gap.vSm,
        _check('ascFree', free, onFree, l.asFree),
        _check('ascScreenshots', screenshots, onScreenshots, l.asScreenshots, subtitle: l.asScreenshotsHelp),
        _check('ascUploadBuild', uploadBuild, onUploadBuild, l.ascUploadBuild),
        _check('ascSubmit', submit, onSubmit, l.ascSubmit),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: Gap.sm, bottom: Gap.sm),
          shape: const Border(),
          collapsedShape: const Border(),
          title: Text(l.advanced),
          subtitle: Text(l.asReviewTitle),
          children: [
            TextField(
              controller: reviewEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l.asReviewEmail, helperText: l.asReviewEmailHelp, helperMaxLines: 3),
            ),
            Gap.vMd,
            TextField(
              controller: reviewPhone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(labelText: l.asReviewPhone, helperText: l.asReviewPhoneHelp, helperMaxLines: 4),
            ),
            Gap.vMd,
            TextField(
              controller: marketingUrl,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: l.asMarketingUrl, helperText: l.asMarketingUrlHelp, helperMaxLines: 3),
            ),
            Gap.vMd,
            TextField(
              controller: reviewNotes,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(labelText: l.asReviewNotes),
            ),
            Gap.vMd,
            TextField(controller: demoUser, autocorrect: false, decoration: InputDecoration(labelText: l.asDemoUser)),
            Gap.vMd,
            SecretField(controller: demoPass, label: l.asDemoPass),
          ],
        ),
      ],
    );
  }
}

/// 3. "Before sending": what Apple would reject, or is worth fixing first.
class AppStoreChecksSection extends StatelessWidget {
  const AppStoreChecksSection({
    super.key,
    required this.checks,
    required this.checking,
    required this.busy,
    required this.onRefresh,
    required this.onFix,
    this.builder,
    this.message,
    this.error = false,
  });

  final List<Map<String, dynamic>> checks;
  final bool checking;
  final bool busy;
  final VoidCallback onRefresh;
  final VoidCallback onFix;

  /// The engine that wrote the app: it fixes the findings made of code.
  final AppBuilder? builder;
  final String? message;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final blocks = checks.where((f) => f['severity'] == 'block').length;
    final fixable = checks.where((f) => f['fixable'] == true).length;
    final b = builder;
    return SectionCard(
      icon: blocks > 0 ? Icons.gpp_bad_outlined : Icons.gpp_good_outlined,
      title: l.asChecksTitle,
      hint: checks.isEmpty
          ? l.asChecksNone
          : blocks > 0
          ? l.asChecksBlock(blocks)
          : l.asChecksWarn,
      trailing: IconButton(
        tooltip: l.checkAgain,
        onPressed: checking ? null : onRefresh,
        icon: checking ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh, size: 20),
      ),
      children: [
        for (final f in checks) ...[
          Gap.vMd,
          FindingTile(
            title: '${f['title']}',
            detail: '${f['detail']}',
            fixable: f['fixable'] == true,
            action: Padding(
              padding: const EdgeInsets.only(top: Gap.xs),
              child: Wrap(
                spacing: Gap.sm,
                runSpacing: Gap.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Said in words, not only by colour: it blocks, or it is advice.
                  if (f['severity'] == 'block') Pill(l.asBlocks, icon: Icons.error_outline, tone: Tone.error) else Pill(l.asWarning, icon: Icons.warning_amber_rounded, tone: Tone.attention),
                  if ('${f['ask'] ?? ''}'.isNotEmpty && b != null)
                    TextButton.icon(
                      onPressed: b.running ? null : () => b.improve('${f['ask']}', display: '${f['title']}').then((_) => onRefresh()),
                      icon: const Icon(Icons.auto_fix_high_outlined, size: 16),
                      label: Text(l.checkAskEmber),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (message != null) ...[
          Gap.vMd,
          InlineMessage(message!, error: error),
        ],
        if (fixable > 0) ...[
          Gap.vMd,
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: OutlinedButton.icon(
              onPressed: checking || busy ? null : onFix,
              icon: const Icon(Icons.build_circle_outlined),
              label: Text(l.checkFixNow(fixable)),
            ),
          ),
        ],
      ],
    );
  }
}

/// 4. The one button that publishes, what it is doing and how it ended.
class AppStorePublishSection extends StatelessWidget {
  const AppStorePublishSection({
    super.key,
    required this.busy,
    required this.onPublish,
    this.auto,
    this.message,
    this.error = false,
    this.notes = const [],
  });

  /// Phases of the one-press publish in which the Runner is still working.
  static const runningPhases = {'building', 'publishing', 'waiting'};

  final bool busy;
  final VoidCallback onPublish;

  /// Last status of the one-press publish running on the Runner.
  final Map<String, dynamic>? auto;
  final String? message;
  final bool error;
  final List<String> notes;

  /// The live steps of the one-press publish.
  List<Widget> _progress(BuildContext context, AppLocalizations l, Map<String, dynamic> a) {
    // 'Parto' is the Runner's own first step ("starting"): nothing done yet.
    final steps = ((a['steps'] as List?) ?? const []).map((s) => '$s').where((s) => s != 'Parto');
    final started = DateTime.tryParse('${a['startedAt']}');
    final minutes = started == null ? 0 : DateTime.now().difference(started).inMinutes;
    return [
      Gap.vSm,
      for (final s in steps) StatusRow(done: true, text: s),
      Gap.vSm,
      BusyRow('${a['message']}'),
      Gap.vSm,
      Text(a['phase'] == 'waiting' ? l.asCanClose(minutes) : l.asRunningFor(minutes), style: context.text.bodySmall),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final a = auto;
    return SectionCard(
      icon: Icons.cloud_upload_outlined,
      title: l.ascTitle,
      hint: l.ascHint,
      children: [
        if (a != null && runningPhases.contains(a['phase']))
          ..._progress(context, l, a)
        else if (busy) ...[
          Gap.vMd,
          BusyRow(l.ascWorking),
        ],
        if (message != null) ...[
          Gap.vMd,
          InlineMessage(message!, error: error),
        ],
        if (notes.isNotEmpty) Gap.vXs,
        for (final note in notes)
          Padding(
            padding: const EdgeInsets.only(top: Gap.xs),
            child: Text('• $note', style: context.text.bodySmall),
          ),
        Gap.vMd,
        Wrap(
          spacing: Gap.sm,
          runSpacing: Gap.sm,
          children: [
            FilledButton.icon(key: const Key('ascPublish'), onPressed: busy ? null : onPublish, icon: const Icon(Icons.apple), label: Text(l.ascPublish)),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse('https://appstoreconnect.apple.com/apps'), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new),
              label: Text(l.ascOpen),
            ),
          ],
        ),
      ],
    );
  }
}
