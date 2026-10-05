import 'package:flutter/widgets.dart';

/// Spacing scale. Every gap and padding in the app is one of these.
abstract final class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  static const SizedBox vXs = SizedBox(height: xs);
  static const SizedBox vSm = SizedBox(height: sm);
  static const SizedBox vMd = SizedBox(height: md);
  static const SizedBox vLg = SizedBox(height: lg);
  static const SizedBox vXl = SizedBox(height: xl);
  static const SizedBox hXs = SizedBox(width: xs);
  static const SizedBox hSm = SizedBox(width: sm);
  static const SizedBox hMd = SizedBox(width: md);
  static const SizedBox hLg = SizedBox(width: lg);
}

/// Corner radii.
abstract final class Radii {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Animation timing: three durations, one curve.
abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Curve curve = Curves.easeOutCubic;

  /// Zero when the system asks for reduced motion.
  static Duration of(BuildContext context, [Duration d = base]) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : d;
}

/// Window widths: below [medium] one column, from [medium] one side panel,
/// from [expanded] two.
abstract final class Breakpoints {
  static const double medium = 840;
  static const double expanded = 1100;

  static bool isMedium(BuildContext context) => MediaQuery.sizeOf(context).width >= medium;
  static bool isExpanded(BuildContext context) => MediaQuery.sizeOf(context).width >= expanded;
}

/// Content and panel widths.
abstract final class Widths {
  /// Forms and narrow dialogs.
  static const double form = 420;

  /// Reading column of a page.
  static const double page = 720;

  /// Side panels (history, assistant).
  static const double rail = 260;
  static const double panel = 380;
}

/// Smallest comfortable touch target.
const double kTapTarget = 48;
