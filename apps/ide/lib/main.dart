import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/locale.dart';
import 'core/theme_mode.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'ui/theme.dart';
import 'widgets/keyboard_scroll.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.supabaseEnabled) {
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
  }
  runApp(const ProviderScope(child: EmberApp()));
}

class EmberApp extends ConsumerWidget {
  const EmberApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: emberTheme(Brightness.light),
      darkTheme: emberTheme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scrollBehavior: const MaterialScrollBehavior().copyWith(scrollbars: true, dragDevices: PointerDeviceKind.values.toSet()),
      routerConfig: ref.watch(routerProvider),
      // Arrow keys and Page Up/Down scroll every screen, no mouse drag needed.
      builder: (BuildContext context, Widget? child) => KeyboardScroll(child: child ?? const SizedBox.shrink()),
    );
  }
}
