import 'package:flutter/material.dart';

import 'tokens.dart';

/// The one accent colour of the app.
const emberRed = Color(0xFFFF1A2E);
const emberBlood = Color(0xFFB00018);

/// Colours the Material scheme has no role for.
@immutable
class EmberColors extends ThemeExtension<EmberColors> {
  const EmberColors({
    required this.success,
    required this.warning,
    required this.codeSurface,
    required this.onCodeSurface,
    required this.codeMuted,
    required this.scrim,
  });

  /// Something is done or works.
  final Color success;

  /// Something needs attention but is not broken.
  final Color warning;

  /// Logs, terminals, code and full-screen previews: dark in both themes.
  final Color codeSurface;
  final Color onCodeSurface;
  final Color codeMuted;

  /// Dim layer behind controls drawn over a preview.
  final Color scrim;

  static const dark = EmberColors(
    success: Color(0xFF3DD68C),
    warning: Color(0xFFF5A524),
    codeSurface: Color(0xFF121214),
    onCodeSurface: Color(0xFFE6E6EA),
    codeMuted: Color(0xFF8B8B94),
    scrim: Color(0xB3000000),
  );

  static const light = EmberColors(
    success: Color(0xFF1B8A54),
    warning: Color(0xFFB26A00),
    codeSurface: Color(0xFF121214),
    onCodeSurface: Color(0xFFE6E6EA),
    codeMuted: Color(0xFF8B8B94),
    scrim: Color(0xB3000000),
  );

  @override
  EmberColors copyWith({Color? success, Color? warning, Color? codeSurface, Color? onCodeSurface, Color? codeMuted, Color? scrim}) => EmberColors(
    success: success ?? this.success,
    warning: warning ?? this.warning,
    codeSurface: codeSurface ?? this.codeSurface,
    onCodeSurface: onCodeSurface ?? this.onCodeSurface,
    codeMuted: codeMuted ?? this.codeMuted,
    scrim: scrim ?? this.scrim,
  );

  @override
  EmberColors lerp(EmberColors? other, double t) {
    if (other == null) return this;
    return EmberColors(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      codeSurface: Color.lerp(codeSurface, other.codeSurface, t)!,
      onCodeSurface: Color.lerp(onCodeSurface, other.onCodeSurface, t)!,
      codeMuted: Color.lerp(codeMuted, other.codeMuted, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension EmberTheme on BuildContext {
  ColorScheme get scheme => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  EmberColors get ember => Theme.of(this).extension<EmberColors>() ?? EmberColors.dark;
}

/// Monospace text for logs and code.
const TextStyle kMono = TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4);

const _display = 'ChakraPetch';

ColorScheme _scheme(Brightness b) {
  final seed = ColorScheme.fromSeed(seedColor: emberRed, brightness: b, dynamicSchemeVariant: DynamicSchemeVariant.fidelity);
  // Neutral surfaces; red is only the accent.
  if (b == Brightness.dark) {
    return seed.copyWith(
      primary: emberRed,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF2A1519),
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFFC9C9D1),
      onSecondary: const Color(0xFF17171A),
      secondaryContainer: const Color(0xFF26262B),
      onSecondaryContainer: Colors.white,
      tertiary: EmberColors.dark.warning,
      onTertiary: const Color(0xFF1F1400),
      tertiaryContainer: const Color(0xFF2B2110),
      onTertiaryContainer: const Color(0xFFFFDDA6),
      errorContainer: const Color(0xFF2A1416),
      onErrorContainer: const Color(0xFFFFB4BD),
      surface: const Color(0xFF0E0E10),
      onSurface: const Color(0xFFECECEE),
      onSurfaceVariant: const Color(0xFFA5A5AD),
      surfaceContainerLowest: const Color(0xFF0A0A0B),
      surfaceContainerLow: const Color(0xFF151517),
      surfaceContainer: const Color(0xFF1A1A1D),
      surfaceContainerHigh: const Color(0xFF202024),
      surfaceContainerHighest: const Color(0xFF29292E),
      outline: const Color(0xFF4A4A52),
      outlineVariant: const Color(0xFF2C2C31),
      surfaceTint: Colors.transparent,
    );
  }
  return seed.copyWith(
    primary: emberBlood,
    onPrimary: Colors.white,
    primaryContainer: const Color(0xFFFDE3E6),
    onPrimaryContainer: const Color(0xFF5A000C),
    secondary: const Color(0xFF55555E),
    onSecondary: Colors.white,
    secondaryContainer: const Color(0xFFE9E9ED),
    onSecondaryContainer: const Color(0xFF17171A),
    tertiary: EmberColors.light.warning,
    onTertiary: Colors.white,
    tertiaryContainer: const Color(0xFFFFEFD2),
    onTertiaryContainer: const Color(0xFF4A2C00),
    surface: const Color(0xFFFBFBFC),
    onSurface: const Color(0xFF17171A),
    onSurfaceVariant: const Color(0xFF5C5C66),
    surfaceContainerLowest: Colors.white,
    surfaceContainerLow: const Color(0xFFF5F5F7),
    surfaceContainer: const Color(0xFFEFEFF2),
    surfaceContainerHigh: const Color(0xFFE9E9ED),
    surfaceContainerHighest: const Color(0xFFE2E2E7),
    outline: const Color(0xFF8A8A93),
    outlineVariant: const Color(0xFFD6D6DC),
    surfaceTint: Colors.transparent,
  );
}

/// The whole look of the app, for one brightness.
ThemeData emberTheme(Brightness b) {
  final scheme = _scheme(b);
  final base = ThemeData(colorScheme: scheme, visualDensity: VisualDensity.standard);
  const display = TextStyle(fontFamily: _display, fontWeight: FontWeight.w700, letterSpacing: 0.2);
  final text = base.textTheme.copyWith(
    headlineMedium: base.textTheme.headlineMedium?.merge(display),
    headlineSmall: base.textTheme.headlineSmall?.merge(display),
    titleLarge: base.textTheme.titleLarge?.merge(display),
    titleMedium: base.textTheme.titleMedium?.merge(display.copyWith(fontWeight: FontWeight.w600)),
    bodySmall: base.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant, height: 1.4),
  );
  const label = TextStyle(fontFamily: _display, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3);
  const buttonShape = RoundedRectangleBorder(borderRadius: Radii.mdAll);
  const buttonPadding = EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md);
  OutlineInputBorder field(Color c, [double w = 1]) => OutlineInputBorder(borderRadius: Radii.mdAll, borderSide: BorderSide(color: c, width: w));

  return base.copyWith(
    extensions: [b == Brightness.dark ? EmberColors.dark : EmberColors.light],
    scaffoldBackgroundColor: scheme.surface,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge?.copyWith(fontSize: 18),
    ),
    // A visible scrollbar you can drag with the mouse, on every scrollable page.
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: const WidgetStatePropertyAll(true),
      interactive: true,
      thickness: const WidgetStatePropertyAll(8),
      radius: const Radius.circular(Radii.sm),
      thumbColor: WidgetStatePropertyAll(scheme.onSurfaceVariant.withValues(alpha: 0.4)),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLow,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: Radii.lgAll, side: BorderSide(color: scheme.outlineVariant)),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      border: field(scheme.outlineVariant),
      enabledBorder: field(scheme.outlineVariant),
      focusedBorder: field(scheme.primary, 1.6),
      errorBorder: field(scheme.error),
      focusedErrorBorder: field(scheme.error, 1.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg, vertical: Gap.md),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: scheme.primaryContainer,
      side: BorderSide(color: scheme.outlineVariant),
      shape: const RoundedRectangleBorder(borderRadius: Radii.smAll),
    ),
    filledButtonTheme: FilledButtonThemeData(
      // No colours here: they would also paint the tonal variant red.
      style: FilledButton.styleFrom(
        textStyle: label,
        shape: buttonShape,
        padding: buttonPadding,
        minimumSize: const Size(0, kTapTarget),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline),
        shape: buttonShape,
        padding: buttonPadding,
        minimumSize: const Size(0, 44),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: scheme.primary, shape: buttonShape, minimumSize: const Size(0, 44)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(selectedBackgroundColor: scheme.primaryContainer, selectedForegroundColor: scheme.onPrimaryContainer),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.lgAll, side: BorderSide(color: scheme.outlineVariant)),
      titleTextStyle: text.titleLarge?.copyWith(fontSize: 20),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.lg))),
    ),
    drawerTheme: DrawerThemeData(backgroundColor: scheme.surfaceContainerLow, surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.surfaceContainerHighest,
      contentTextStyle: TextStyle(color: scheme.onSurface),
      actionTextColor: scheme.primary,
      shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
    ),
    listTileTheme: ListTileThemeData(
      shape: const RoundedRectangleBorder(borderRadius: Radii.mdAll),
      iconColor: scheme.onSurfaceVariant,
      selectedColor: scheme.onSurface,
      selectedTileColor: scheme.primaryContainer,
    ),
    navigationBarTheme: NavigationBarThemeData(backgroundColor: scheme.surfaceContainerLow, indicatorColor: scheme.primaryContainer),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary, linearTrackColor: scheme.outlineVariant, circularTrackColor: Colors.transparent),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: Radii.smAll, border: Border.all(color: scheme.outlineVariant)),
      textStyle: TextStyle(color: scheme.onSurface, fontSize: 12),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainer,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.mdAll, side: BorderSide(color: scheme.outlineVariant)),
    ),
  );
}
