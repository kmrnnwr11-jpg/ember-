import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'listing_languages_sheet.dart';

enum _More { listingOnly, translateAgain }

/// The store page of the app (in English, the main language) and the one
/// button that sends it to Google Play. The texts live in the controllers of
/// the screen; this only shows them.
class ListingForm extends StatelessWidget {
  const ListingForm({
    super.key,
    required this.title,
    required this.short,
    required this.full,
    required this.notes,
    required this.email,
    required this.privacyLink,
    required this.generating,
    required this.translating,
    required this.publishing,
    required this.stale,
    required this.canUpload,
    required this.canTranslateAgain,
    required this.languagesOn,
    required this.error,
    required this.track,
    required this.onTrack,
    required this.onChanged,
    required this.onManageLanguages,
    required this.onGenerate,
    required this.onTranslate,
    required this.onUpload,
    required this.onUpdateListingOnly,
  });

  final TextEditingController title;
  final TextEditingController short;
  final TextEditingController full;
  final TextEditingController notes;
  final TextEditingController email;
  final TextEditingController privacyLink;
  final bool generating;
  final bool translating;
  final bool publishing;

  /// The English text changed after the other languages were written.
  final bool stale;

  /// Google Play is connected: there is a key to upload with.
  final bool canUpload;
  final bool canTranslateAgain;
  final int languagesOn;
  final String? error;
  final String track;
  final ValueChanged<String> onTrack;

  /// A text the rest of the screen depends on was edited.
  final ValueChanged<String> onChanged;
  final VoidCallback onManageLanguages;
  final VoidCallback onGenerate;
  final VoidCallback onTranslate;
  final VoidCallback onUpload;
  final VoidCallback onUpdateListingOnly;

  Future<void> _pastePrivacy() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text == null || text.isEmpty) return;
    privacyLink.text = text;
    onChanged(text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final written = title.text.trim().isNotEmpty;
    final local = privacyLink.text.contains('localhost') || privacyLink.text.contains('127.0.0.1');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A listing written once is kept (store/listing.json, shared by
        // Google Play and the App Store): an update only needs Upload.
        if (generating) BusyRow(l.plGenerating) else if (written) StatusRow(done: true, text: l.playListingSaved),
        LanguagesRow(count: languagesOn, onManage: onManageLanguages),
        if (stale && !translating) Text(l.playTranslationsStale, style: context.text.bodySmall?.copyWith(color: context.ember.warning)),
        if (translating) BusyRow(l.playTranslating),
        Gap.vSm,
        // Writing is secondary once there is a text: the one main action of
        // this step is Upload, at the bottom.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            key: const Key('generateListing'),
            onPressed: generating ? null : onGenerate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(written ? l.playRewriteWithAi : l.playGenerateWithAi),
          ),
        ),
        Gap.vMd,
        TextField(
          controller: title,
          onChanged: onChanged,
          maxLength: 30,
          decoration: InputDecoration(labelText: l.playTitle),
        ),
        TextField(
          controller: short,
          onChanged: onChanged,
          maxLength: 80,
          decoration: InputDecoration(labelText: l.playShortDescription),
        ),
        TextField(
          controller: full,
          onChanged: onChanged,
          maxLength: 4000,
          minLines: 4,
          maxLines: 12,
          decoration: InputDecoration(labelText: l.playFullDescription),
        ),
        TextField(
          controller: notes,
          maxLength: 500,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(labelText: l.playReleaseNotes),
        ),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l.playContactEmail),
        ),
        Gap.vMd,
        TextField(
          controller: privacyLink,
          keyboardType: TextInputType.url,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: l.playPrivacyUrl,
            hintText: 'https://…',
            helperText: local ? l.privacyLocalWarning : l.privacyPublicHint,
            helperMaxLines: 3,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(tooltip: l.paste, icon: const Icon(Icons.content_paste_outlined), onPressed: _pastePrivacy),
                IconButton(
                  tooltip: l.copy,
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: privacyLink.text));
                    showEmberSnack(context, l.copied);
                  },
                ),
                Gap.hXs,
              ],
            ),
          ),
        ),
        Gap.vSm,
        DropdownButtonFormField<String>(
          initialValue: track,
          // Long names (Italian, Arabic) are cut rather than pushed out of a narrow window.
          isExpanded: true,
          decoration: InputDecoration(labelText: l.playTrack),
          items: [
            DropdownMenuItem(value: 'internal', child: Text(l.playTrackInternal, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: 'alpha', child: Text(l.playTrackClosed, overflow: TextOverflow.ellipsis)),
            DropdownMenuItem(value: 'production', child: Text(l.playTrackProduction, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) => onTrack(v ?? 'internal'),
        ),
        Gap.vLg,
        if (publishing) ...[BusyRow(l.upUploading), Gap.vSm],
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('publishToPlay'),
                onPressed: publishing || !canUpload ? null : onUpload,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(l.playUpload),
              ),
            ),
            Gap.hXs,
            PopupMenuButton<_More>(
              key: const Key('listingMore'),
              tooltip: l.more,
              icon: const Icon(Icons.more_horiz),
              onSelected: (choice) => switch (choice) {
                _More.listingOnly => onUpdateListingOnly(),
                _More.translateAgain => onTranslate(),
              },
              itemBuilder: (context) => [
                // For apps already on Google Play: new languages, new texts or
                // graphics go live without building and sending a new version.
                PopupMenuItem(
                  key: const Key('updateListingOnly'),
                  value: _More.listingOnly,
                  enabled: !publishing && canUpload,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: Gap.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l.playUpdateListingOnly),
                          Text(l.playUpdateListingOnlyHint, style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
                PopupMenuItem(
                  key: const Key('translateAgain'),
                  value: _More.translateAgain,
                  enabled: canTranslateAgain,
                  child: Text(l.playTranslateAgain),
                ),
              ],
            ),
          ],
        ),
        if (error != null) ...[
          Gap.vSm,
          InlineMessage(error!, error: true),
        ],
      ],
    );
  }
}
