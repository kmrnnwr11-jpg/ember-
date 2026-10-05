import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import 'listing_languages.dart';
import 'publish_job.dart';

/// The other store pages in one line: how many languages are on, and the way
/// to the list. English is the page on screen, these are written from it.
class LanguagesRow extends StatelessWidget {
  const LanguagesRow({super.key, required this.count, required this.onManage});

  /// Languages that go on Google Play, English included.
  final int count;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ListTile(
      key: const Key('manageLanguages'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.translate),
      title: Text(l.plLanguagesOn(count)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.plManage, style: context.text.labelLarge?.copyWith(color: context.scheme.primary)),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: onManage,
    );
  }
}

/// Every language Google Play has, each with its switch. A tap on a row
/// opens that language's page ([onOpen]): read it, fix it, or leave the
/// language out. The list follows [job] while Ember writes the pages.
Future<void> showListingLanguagesSheet(
  BuildContext context, {
  required PublishJob job,
  required bool Function() isStale,
  required void Function(String code, bool on) onToggle,
  required void Function(String code, String name) onOpen,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  constraints: const BoxConstraints(maxWidth: Widths.page),
  builder: (_) => _LanguagesSheet(job: job, isStale: isStale, onToggle: onToggle, onOpen: onOpen),
);

class _LanguagesSheet extends StatefulWidget {
  const _LanguagesSheet({required this.job, required this.isStale, required this.onToggle, required this.onOpen});
  final PublishJob job;
  final bool Function() isStale;
  final void Function(String code, bool on) onToggle;
  final void Function(String code, String name) onOpen;

  @override
  State<_LanguagesSheet> createState() => _LanguagesSheetState();
}

class _LanguagesSheetState extends State<_LanguagesSheet> {
  final _search = TextEditingController();

  /// Languages that are on come first. The order is the one found on
  /// opening: a row that jumped away the moment its switch was touched
  /// would be lost from under the finger.
  late final List<String> _order = [
    ...playStoreLanguages.keys.where(widget.job.languages.contains),
    ...playStoreLanguages.keys.where((c) => !widget.job.languages.contains(c)),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// What the row says about its page, where there is something to say.
  Widget? _state(AppLocalizations l, String code, {required bool on, required bool stale}) {
    final translated = widget.job.translations.containsKey(code);
    if (translated && stale) return Pill(l.plLangOld, tone: Tone.attention);
    if (translated) return Icon(Icons.check, size: 18, color: context.ember.success, semanticLabel: l.plLangReady);
    if (!on) return null;
    return widget.job.translating ? Pill(l.plLangWriting) : Pill(l.plLangMissing, tone: Tone.attention);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final query = _search.text;
    final shown = [for (final code in _order) if (storeLanguageMatches(code, query)) code];
    final english = query.trim().isEmpty || 'english en-us ${l.plEnglish}'.toLowerCase().contains(query.trim().toLowerCase());
    return Padding(
      // The list stays above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.9,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: Gap.lg, end: Gap.sm),
              child: Row(
                children: [
                  Expanded(child: Text(l.playLanguages, style: context.text.titleLarge)),
                  IconButton(tooltip: l.close, icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(Gap.lg, Gap.xs, Gap.lg, Gap.md),
              child: Text(l.plLanguagesHint, style: context.text.bodySmall?.copyWith(color: context.scheme.onSurfaceVariant)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
              child: TextField(
                key: const Key('searchLanguages'),
                controller: _search,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(hintText: l.plSearchLanguage, prefixIcon: const Icon(Icons.search), isDense: true),
              ),
            ),
            Gap.vSm,
            Expanded(
              // Follows the job: pages appear here as Ember writes them.
              child: ListenableBuilder(
                listenable: widget.job,
                builder: (context, _) {
                  final stale = widget.isStale();
                  if (shown.isEmpty && !english) {
                    return Padding(
                      padding: const EdgeInsets.all(Gap.xl),
                      child: Text(l.plNoLanguageFound, textAlign: TextAlign.center, style: context.text.bodyMedium?.copyWith(color: context.scheme.onSurfaceVariant)),
                    );
                  }
                  final first = english ? 1 : 0;
                  return ListView.builder(
                    padding: const EdgeInsetsDirectional.only(bottom: Gap.lg),
                    itemCount: shown.length + first,
                    itemBuilder: (context, i) {
                      if (i < first) {
                        // The page on screen: always published, nothing to switch.
                        return ListTile(
                          title: Text(l.plEnglish),
                          subtitle: Text('${l.plMainLanguage} · $playMainLanguage'),
                          trailing: const Switch(value: true, onChanged: null),
                        );
                      }
                      final code = shown[i - first];
                      final name = playStoreLanguages[code]!;
                      final on = widget.job.languages.contains(code);
                      final state = _state(l, code, on: on, stale: stale);
                      final englishName = playLanguageEnglishNames[code];
                      return ListTile(
                        key: ValueKey('language-$code'),
                        title: Text(name),
                        subtitle: Text(englishName == null ? code : '$englishName · $code'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (state != null) ...[state, Gap.hSm],
                            Switch(value: on, onChanged: (v) => widget.onToggle(code, v)),
                          ],
                        ),
                        onTap: () => widget.onOpen(code, name),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What the user decided on one language's page.
typedef LanguagePageEdit = ({bool included, String short, String full});

/// One store page in one language: the name (the same everywhere), the two
/// descriptions as they will appear, editable, and whether this language
/// goes on Google Play at all. Null when closed without saving.
Future<LanguagePageEdit?> showLanguagePage(
  BuildContext context, {
  required String code,
  required String name,
  required Map<String, String>? page,
  required String title,
  required bool included,
}) => showDialog<LanguagePageEdit>(
  context: context,
  builder: (_) => _LanguagePageDialog(code: code, name: name, page: page, title: title, included: included),
);

class _LanguagePageDialog extends StatefulWidget {
  const _LanguagePageDialog({required this.code, required this.name, required this.page, required this.title, required this.included});
  final String code;
  final String name;

  /// Null while this language has not been written yet.
  final Map<String, String>? page;
  final String title;
  final bool included;

  @override
  State<_LanguagePageDialog> createState() => _LanguagePageDialogState();
}

class _LanguagePageDialogState extends State<_LanguagePageDialog> {
  late final _short = TextEditingController(text: widget.page?['shortDescription'] ?? '');
  late final _full = TextEditingController(text: widget.page?['fullDescription'] ?? '');
  late bool _included = widget.included;

  @override
  void dispose() {
    _short.dispose();
    _full.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final page = widget.page;
    // The text of a right-to-left language reads that way whatever language
    // Ember itself is in.
    final rtl = isRtlStoreLanguage(widget.code);
    return AlertDialog(
      title: Text('${widget.name}  ·  ${widget.code}'),
      content: SizedBox(
        width: Widths.page,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _included,
                onChanged: (v) => setState(() => _included = v),
                title: Text(l.playLanguageIncluded),
              ),
              if (page == null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Gap.md),
                  child: Text(l.playLanguageNotTranslated),
                )
              else ...[
                Gap.vSm,
                InputDecorator(
                  decoration: InputDecoration(labelText: l.playTitle),
                  child: Text(page['title'] ?? widget.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                Gap.vMd,
                TextField(
                  controller: _short,
                  maxLength: 80,
                  textDirection: rtl ? TextDirection.rtl : null,
                  decoration: InputDecoration(labelText: l.playShortDescription),
                ),
                TextField(
                  controller: _full,
                  maxLength: 4000,
                  minLines: 6,
                  maxLines: 16,
                  textDirection: rtl ? TextDirection.rtl : null,
                  decoration: InputDecoration(labelText: l.playFullDescription),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.of(context).pop((included: _included, short: _short.text.trim(), full: _full.text.trim())),
          child: Text(l.save),
        ),
      ],
    );
  }
}
