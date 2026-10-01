import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/env.dart';
import 'core/locale.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'widgets/ember_logo.dart';
import 'widgets/keyboard_scroll.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Env.supabaseEnabled) {
    await Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabaseAnonKey);
  }
  runApp(const ProviderScope(child: FlutterCursorApp()));
}

class FlutterCursorApp extends ConsumerWidget {
  const FlutterCursorApp({super.key});

  static ThemeData _theme(Brightness b) {
    final dark = b == Brightness.dark;
    final scheme = ColorScheme.fromSeed(seedColor: emberRed, brightness: b, dynamicSchemeVariant: DynamicSchemeVariant.fidelity).copyWith(
      primary: dark ? emberRed : emberBlood,
      onPrimary: Colors.white,
      // Dark containers with white text: no large red surfaces (chat bubbles, selected items).
      primaryContainer: dark ? const Color(0xFF221114) : null,
      onPrimaryContainer: dark ? Colors.white : null,
      secondaryContainer: dark ? const Color(0xFF221114) : null,
      // Errors: dark card with a red edge, not a big red block.
      errorContainer: dark ? const Color(0xFF1F0B0E) : null,
      onErrorContainer: dark ? const Color(0xFFFFB4BD) : null,
      onSecondaryContainer: dark ? Colors.white : null,
      surface: dark ? const Color(0xFF0B0506) : null,
      surfaceContainerLow: dark ? const Color(0xFF120809) : null,
      surfaceContainer: dark ? const Color(0xFF160A0C) : null,
      surfaceContainerHigh: dark ? const Color(0xFF1D0E10) : null,
      surfaceContainerHighest: dark ? const Color(0xFF261316) : null,
      outline: dark ? const Color(0xFF5A2A30) : null,
      outlineVariant: dark ? const Color(0xFF34191C) : null,
    );
    final base = ThemeData(colorScheme: scheme, visualDensity: VisualDensity.adaptivePlatformDensity);
    const display = TextStyle(fontFamily: 'ChakraPetch', fontWeight: FontWeight.w700, letterSpacing: 0.4);
    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: base.textTheme.copyWith(
        headlineSmall: base.textTheme.headlineSmall?.merge(display),
        headlineMedium: base.textTheme.headlineMedium?.merge(display),
        titleLarge: base.textTheme.titleLarge?.merge(display),
        titleMedium: base.textTheme.titleMedium?.merge(display.copyWith(fontWeight: FontWeight.w600)),
      ),
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent),
      // Always-visible scrollbar you can drag with the mouse, on every scrollable page.
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: const WidgetStatePropertyAll(true),
        trackVisibility: const WidgetStatePropertyAll(true),
        interactive: true,
        thickness: const WidgetStatePropertyAll(10),
        radius: const Radius.circular(6),
        thumbColor: WidgetStatePropertyAll(scheme.primary.withValues(alpha: 0.55)),
        trackColor: WidgetStatePropertyAll(scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: scheme.outlineVariant)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: scheme.primary, width: 1.6)),
      ),
      chipTheme: base.chipTheme.copyWith(
        selectedColor: scheme.primary.withValues(alpha: 0.22),
        side: BorderSide(color: scheme.outline),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontFamily: 'ChakraPetch', fontWeight: FontWeight.w700, fontSize: 16, letterSpacing: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
      debugShowCheckedModeBanner: false,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ThemeMode.dark,
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
