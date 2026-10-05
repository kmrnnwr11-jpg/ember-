import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

const _kLocale = 'app_locale';

/// Languages offered in the picker, with their native names.
const appLanguages = <(String, String)>[
  ('en', 'English'),
  ('it', 'Italiano'),
  ('es', 'Español'),
  ('fr', 'Français'),
  ('ar', 'العربية'),
];

/// The UI language: the device's own when Ember speaks it, English otherwise;
/// the user's choice is saved.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    _load();
    final device = PlatformDispatcher.instance.locale.languageCode;
    return Locale(appLanguages.any((l) => l.$1 == device) ? device : 'en');
  }

  Future<void> _load() async {
    try {
      final code = (await SharedPreferences.getInstance()).getString(_kLocale);
      if (code != null && appLanguages.any((l) => l.$1 == code)) state = Locale(code);
    } catch (_) {
      // keep the default
    }
  }

  Future<void> set(String code) async {
    state = Locale(code);
    try {
      await (await SharedPreferences.getInstance()).setString(_kLocale, code);
    } catch (_) {}
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// Strings for code outside the widget tree (e.g. build logs).
final stringsProvider = Provider<AppLocalizations>((ref) => lookupAppLocalizations(ref.watch(localeProvider)));

/// App bar button to switch language.
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider).languageCode;
    return PopupMenuButton<String>(
      icon: const Icon(Icons.translate),
      tooltip: AppLocalizations.of(context).language,
      initialValue: current,
      onSelected: (c) => ref.read(localeProvider.notifier).set(c),
      itemBuilder: (_) => [
        for (final (code, name) in appLanguages)
          CheckedPopupMenuItem(value: code, checked: code == current, child: Text(name)),
      ],
    );
  }
}
