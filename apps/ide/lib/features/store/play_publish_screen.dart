import 'package:ai_connect/ai_connect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ide_core/ide_core.dart';

import '../../core/session.dart';
import '../../core/settings_store.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/ui.dart';
import '../mockups/mockup_controller.dart' show CompleteText;
import 'default_policy.dart';
import 'listing_ai.dart';
import 'listing_form.dart';
import 'listing_languages.dart';
import 'listing_languages_sheet.dart';
import 'play_links.dart';
import 'publish_job.dart';
import 'publish_steps.dart';

// The pieces of this screen live in their own files; whoever imported them
// from here still finds them.
export 'listing_ai.dart';
export 'listing_form.dart';
export 'listing_languages.dart';
export 'listing_languages_sheet.dart';
export 'publish_job.dart';
export 'publish_steps.dart';

/// Guided "Publish to Google Play" flow after a signed AAB is ready.
class PlayPublishScreen extends ConsumerStatefulWidget {
  const PlayPublishScreen({super.key, required this.projectId, required this.appDescription, this.initialStep = 0});

  /// Opened from the Ember publishing chat at the listing step, when everything before is done.
  final int initialStep;
  final String projectId;
  final String appDescription;

  @override
  ConsumerState<PlayPublishScreen> createState() => _PlayPublishScreenState();
}

class _PlayPublishScreenState extends ConsumerState<PlayPublishScreen> {
  PlayConsoleLink _console = const PlayConsoleLink();
  late int _step = widget.initialStep;
  late bool _hasAccount = widget.initialStep > 0;
  late bool _appCreated = widget.initialStep > 1;
  String? _packageName;

  /// What the app calls itself, read from the project rather than guessed
  /// from the folder or the package.
  String? _appLabel;
  final _sa = TextEditingController();
  final _title = TextEditingController();
  final _short = TextEditingController();
  final _full = TextEditingController();
  final _notes = TextEditingController();
  final _email = TextEditingController();
  final _privacyLink = TextEditingController();
  final _consoleLink = TextEditingController();
  String _privacy = '';
  String _dataSafety = '';
  String _contentRating = '';
  String _otherDeclarations = '';
  String _track = 'internal';

  /// The words of the language Ember is shown in, kept here because the work
  /// goes on after the screen is closed, when there is no context to ask.
  late AppLocalizations _l;

  // The long work (writing, translating, uploading) lives in a job that
  // outlives this screen: leaving does not stop it, coming back shows it.
  late final PublishJob _job = PublishJob.of(widget.projectId);
  bool get _generating => _job.generating;
  set _generating(bool v) => _job.generating = v;
  bool get _publishing => _job.publishing;
  set _publishing(bool v) => _job.publishing = v;
  String? get _error => _job.error;
  set _error(String? v) => _job.error = v;
  Map<String, dynamic>? get _result => _job.result;
  set _result(Map<String, dynamic>? v) => _job.result = v;
  Set<String> get _languages => _job.languages;
  Map<String, Map<String, String>> get _translations => _job.translations;
  set _translations(Map<String, Map<String, String>> v) => _job.translations = v;
  bool get _translating => _job.translating;
  set _translating(bool v) => _job.translating = v;
  set _translatedFrom(String? v) => _job.translatedFrom = v;
  String get _source => '${_title.text.trim()}\u0001${_short.text.trim()}\u0001${_full.text.trim()}';
  bool get _translationsStale => _job.staleFor(_source);

  /// Changes job state and shows it here (and on this screen if reopened).
  void _update([VoidCallback? change]) {
    change?.call();
    _job.changed();
  }

  void _onJob() {
    if (!mounted) return;
    setState(() {
      if (_result != null && _step < 4) _step = 4;
    });
  }

  /// An error in words the user can read.
  String _say(Object e) => switch (e) {
    RunnerException(:final message) => message,
    AiException(:final message) => message,
    BadAiAnswer() => _l.plAiBadAnswer,
    _ => e.toString(),
  };

  static const _saKey = 'play_service_account';

  @override
  void initState() {
    super.initState();
    _job.addListener(_onJob);
    if (_result != null) _step = 4;
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l = AppLocalizations.of(context);
  }

  Future<void> _load() async {
    _console = await PlayConsoleLink.load();
    _consoleLink.text = _console.developerId == null ? '' : _console.appList();
    if (mounted) setState(() {});
    final saved = await ref.read(settingsStoreProvider).read(_saKey);
    if (saved != null) _sa.text = saved;
    try {
      final listing = (await (await ref.read(runnerApiProvider.future)).storeState(widget.projectId))['listing'] as Map<String, dynamic>?;
      if (listing != null && mounted) {
        setState(() {
          _title.text = '${listing['title'] ?? ''}';
          _short.text = '${listing['shortDescription'] ?? ''}';
          _full.text = '${listing['fullDescription'] ?? ''}';
          _notes.text = '${listing['releaseNotes'] ?? ''}';
          _email.text = '${listing['contactEmail'] ?? ''}';
          _privacyLink.text = '${listing['privacyUrl'] ?? ''}';
          _dataSafety = '${listing['dataSafety'] ?? ''}';
          _contentRating = '${listing['contentRating'] ?? ''}';
          _otherDeclarations = '${listing['otherDeclarations'] ?? ''}';
          // Reopened while Ember works on it: the job holds the newer state.
          if (!_job.loaded) _job.loadSaved('${listing['translations'] ?? ''}', source: _source, title: _title.text);
          _job.loaded = true;
        });
      }
    } catch (_) {}
    try {
      final info = await (await ref.read(runnerApiProvider.future)).androidInfo(widget.projectId);
      if (mounted) {
        setState(() {
          _packageName = info['applicationId'] as String?;
          _appLabel = (info['appLabel'] as String?)?.trim();
        });
      }
    } catch (_) {}
    // An app with nothing written yet gets its listing written now: the user came
    // here to publish, not to face five empty boxes.
    if (mounted && _title.text.trim().isEmpty && !_generating) await _generate();
  }

  @override
  void dispose() {
    _job.removeListener(_onJob);
    for (final c in [_sa, _title, _short, _full, _notes, _email, _privacyLink, _consoleLink]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<CompleteText> _completer() => listingCompleter(ref, noAi: _l.plNoAi);

  Future<void> _generate() async {
    _update(() {
      _generating = true;
      _error = null;
    });
    try {
      final complete = _job.complete = await _completer();
      _job.api ??= await ref.read(runnerApiProvider.future);
      final typedTitle = _title.text.trim();
      final res = await complete(
        storeKitSystemPrompt,
        storeKitPrompt(typedTitle: typedTitle, appLabel: _appLabel, packageName: _packageName, appDescription: widget.appDescription),
      );
      final j = aiJsonObject(res.text);
      _title.text = typedTitle.isNotEmpty ? typedTitle : '${j['title'] ?? ''}';
      _short.text = '${j['shortDescription'] ?? ''}';
      _full.text = '${j['fullDescription'] ?? ''}';
      _notes.text = '${j['releaseNotes'] ?? ''}';
      _privacy = '${j['privacyPolicyMarkdown'] ?? ''}';
      _dataSafety = '${j['dataSafetyGuide'] ?? ''}';
      _contentRating = '${j['contentRatingGuide'] ?? ''}';
      _otherDeclarations = '${j['otherDeclarationsGuide'] ?? ''}';
      final api = _job.api!;
      // Google will not take an app without a policy at a public address, so a
      // model that answered everything else and skipped this one must not cost
      // the upload: write a true one from what the app actually does.
      if (_privacy.trim().length < 50) {
        // What the app actually ships with, recorded by the build: a policy
        // must not claim ads or purchases the app does not have, nor stay
        // silent about the ones it does.
        final built = await whatWasBuilt(widget.projectId);
        _privacy = defaultPrivacyPolicy(
          appName: _title.text,
          email: _email.text.trim(),
          ads: built.ads,
          purchases: built.purchases,
        );
      }
      // Its own try: publishing the policy can fail on its own (GitHub not
      // signed in, network down) and that must not throw away the listing the
      // model just wrote, which was the whole point of the step.
      try {
        final saved = await api.savePrivacyPolicy(widget.projectId, _privacy, _title.text, email: _email.text.trim());
        final session = ref.read(sessionProvider).value!;
        // The published page is what Google can open; the local one only works on this computer.
        final privacyUrl = saved.publicUrl ?? '${session.runnerUrl}${saved.path}';
        final current = _privacyLink.text.trim();
        if (current.isEmpty || current.contains('localhost') || current.contains('127.0.0.1')) _privacyLink.text = privacyUrl;
        // A local address is not an address Google can open: say so here
        // rather than letting the upload fail at review.
        if (saved.publicUrl == null) _error = _l.plPrivacyLocalOnly;
      } catch (e) {
        _error = _l.plPrivacyNotPublished(e is RunnerException ? e.message : '$e');
      }
      // A new listing means new translations: the old ones describe other words.
      _translations = {};
      await _saveListing();
    } catch (e) {
      _error = _say(e);
    }
    _update(() => _generating = false);
    await _translate();
  }

  /// Writes the listing in the chosen languages, from the English one on screen.
  ///
  /// One call for all of them: the same model keeps the same tone and the same
  /// app name in every language, which separate calls tend not to.
  Future<void> _translate() async {
    // The English text changed since the translations were written: they are redone.
    if (_translationsStale) _translations = {};
    if (_title.text.trim().isNotEmpty) _translatedFrom = _source;
    // English pages for other countries say what the main page says.
    if (_title.text.trim().isNotEmpty) {
      for (final l in _languages.where((l) => copiesMainLanguage(l) && !_translations.containsKey(l)).toList()) {
        _translations[l] = {'title': _title.text.trim(), 'shortDescription': _short.text.trim(), 'fullDescription': _full.text.trim()};
      }
    }
    final wanted = _languages.where((l) => !_translations.containsKey(l)).toList();
    if (wanted.isEmpty || _title.text.trim().isEmpty) return;
    _update(() => _translating = true);
    try {
      final complete = _job.complete ?? (_job.complete = await _completer());
      final batches = translateBatches(wanted);
      String? lastError;
      for (var i = 0; i < batches.length; i += translateGroupsAtOnce) {
        final results = await Future.wait(
          batches.skip(i).take(translateGroupsAtOnce).map((langs) => _translateGroup(complete, langs).then<Object?>((_) => null, onError: (Object e) => e)),
        );
        for (final r in results) {
          if (r != null) lastError = _say(r);
        }
        await _saveListing();
        _update(() {});
      }
      if (lastError != null && wanted.any((l) => !_translations.containsKey(l))) _error = lastError;
    } catch (e) {
      _error = _say(e);
    }
    _update(() => _translating = false);
  }

  Future<void> _translateGroup(CompleteText complete, List<String> langs) async {
    final res = await complete(
      translateSystemPrompt,
      translatePrompt(langs: langs, title: _title.text.trim(), short: _short.text.trim(), full: _full.text.trim()),
    );
    _translations.addAll(translatedPages(res.text, langs: langs, title: _title.text.trim()));
  }

  /// One store page in one language: the name (the same everywhere), the
  /// two descriptions as they will appear, editable, and whether this
  /// language goes on Google Play at all.
  Future<void> _openLanguage(String code, String name) async {
    final page = _translations[code];
    final edit = await showLanguagePage(context, code: code, name: name, page: page, title: _title.text.trim(), included: _languages.contains(code));
    if (edit == null || !mounted) return;
    _update(() {
      edit.included ? _languages.add(code) : _languages.remove(code);
      if (page != null) {
        _translations[code] = {
          'title': _title.text.trim(),
          'shortDescription': edit.short,
          'fullDescription': edit.full,
        };
      }
    });
    await _saveListing();
    // Switched on and not written yet: write it now.
    if (edit.included && page == null && !_translating) await _translate();
  }

  /// The switch of a language in the list: the same as opening its page,
  /// changing "publish this language" and saving.
  Future<void> _setLanguage(String code, bool on) async {
    _update(() => on ? _languages.add(code) : _languages.remove(code));
    await _saveListing();
    // Switched on and not written yet: write it now.
    if (on && !_translations.containsKey(code) && !_translating) await _translate();
  }

  void _manageLanguages() {
    showListingLanguagesSheet(context, job: _job, isStale: () => _translationsStale, onToggle: _setLanguage, onOpen: _openLanguage);
  }

  Future<void> _saveListing() async {
    try {
      var api = _job.api;
      if (api == null) {
        api = await ref.read(runnerApiProvider.future);
        _job.api = api;
      }
      await api!.saveListing(widget.projectId, {
        'title': _title.text.trim(),
        'shortDescription': _short.text.trim(),
        'fullDescription': _full.text.trim(),
        'releaseNotes': _notes.text.trim(),
        'contactEmail': _email.text.trim(),
        'privacyUrl': _privacyLink.text.trim(),
        'dataSafety': _dataSafety,
        'contentRating': _contentRating,
        'otherDeclarations': _otherDeclarations,
        'translations': _job.savedForm(),
      });
    } catch (_) {}
  }

  Future<void> _publish({bool listingOnly = false}) async {
    _update(() {
      _publishing = true;
      _error = null;
    });
    final store = ref.read(settingsStoreProvider);
    _job.api ??= await ref.read(runnerApiProvider.future);
    _job.complete ??= await _completer().then<CompleteText?>((c) => c, onError: (Object _) => null);
    // Languages switched on after the listing was written still need their page.
    await _translate();
    await _saveListing();
    try {
      await store.write(_saKey, _sa.text.trim());
      final api = _job.api!;
      _result = await api.publishToPlay(
        widget.projectId,
        _job.uploadRequest(serviceAccount: _sa.text.trim(), track: _track, title: _title.text.trim(), short: _short.text.trim(), full: _full.text.trim(), notes: _notes.text.trim(), email: _email.text.trim(), listingOnly: listingOnly),
      );
      if (mounted) _step = 4;
    } catch (e) {
      _error = _say(e);
    }
    _update(() => _publishing = false);
  }

  /// Saves the pasted Play Console address so every button opens the user's own account.
  Future<void> _saveConsoleLink(String url) async {
    final parsed = PlayConsoleLink.parse(url);
    if (parsed == null) return;
    final link = parsed.merge(await PlayConsoleLink.load());
    await link.save();
    if (mounted) setState(() => _console = link);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final saValid = _sa.text.contains('"service_account"') && _sa.text.contains('private_key');
    final consoleUrl = _console.appList(_packageName);
    final consoleField = ConsoleLinkField(controller: _consoleLink, developerId: _console.developerId, onSave: _saveConsoleLink);
    void refresh([String? _]) => setState(() {});
    // Going back hands the upload result (or null) to the publishing chat.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_result);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.playPublishTitle),
          leading: BackButton(onPressed: () => Navigator.of(context).pop(_result)),
        ),
        // The reading column: centred, never wider than a page.
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: Widths.page),
            child: Stepper(
              currentStep: _step,
              onStepTapped: (i) => setState(() => _step = i),
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              steps: [
                Step(
                  title: Text(l.playStepAccount),
                  isActive: _step >= 0,
                  state: _hasAccount ? StepState.complete : StepState.indexed,
                  content: AccountStep(
                    hasAccount: _hasAccount,
                    onHasAccount: (v) => setState(() => _hasAccount = v),
                    onNext: () => setState(() => _step = 1),
                  ),
                ),
                Step(
                  title: Text(l.playStepCreateApp),
                  isActive: _step >= 1,
                  state: _appCreated ? StepState.complete : StepState.indexed,
                  content: CreateAppStep(
                    packageName: _packageName,
                    consoleUrl: consoleUrl,
                    consoleField: consoleField,
                    appCreated: _appCreated,
                    onAppCreated: (v) => setState(() => _appCreated = v),
                    onNext: () => setState(() => _step = 2),
                  ),
                ),
                Step(
                  title: Text(l.playStepConnect),
                  isActive: _step >= 2,
                  state: saValid ? StepState.complete : StepState.indexed,
                  content: ConnectStep(
                    serviceAccount: _sa,
                    valid: saValid,
                    consoleUrl: consoleUrl,
                    onChanged: refresh,
                    onNext: () => setState(() => _step = 3),
                  ),
                ),
                Step(
                  title: Text(l.playStepListing),
                  isActive: _step >= 3,
                  content: ListingForm(
                    title: _title,
                    short: _short,
                    full: _full,
                    notes: _notes,
                    email: _email,
                    privacyLink: _privacyLink,
                    generating: _generating,
                    translating: _translating,
                    publishing: _publishing,
                    stale: _translationsStale,
                    canUpload: saValid,
                    // "Translate again" has something to do: old pages, or languages with none.
                    canTranslateAgain: !_translating && (_translationsStale || _languages.any((c) => !_translations.containsKey(c))),
                    // English, always on, counts as one.
                    languagesOn: 1 + playStoreLanguages.keys.where(_languages.contains).length,
                    error: _error,
                    track: _track,
                    onTrack: (v) => setState(() => _track = v),
                    onChanged: refresh,
                    onManageLanguages: _manageLanguages,
                    onGenerate: _generate,
                    onTranslate: _translate,
                    onUpload: _publish,
                    onUpdateListingOnly: () => _publish(listingOnly: true),
                  ),
                ),
                Step(
                  title: Text(l.playStepFinish),
                  isActive: _step >= 4,
                  state: _result != null ? StepState.complete : StepState.indexed,
                  content: FinishStep(
                    result: _result,
                    privacyUrl: _privacyLink.text.trim(),
                    dataSafety: _dataSafety,
                    contentRating: _contentRating,
                    otherDeclarations: _otherDeclarations,
                    consoleUrl: consoleUrl,
                    consoleField: consoleField,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
