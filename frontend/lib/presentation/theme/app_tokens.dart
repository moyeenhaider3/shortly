import 'package:flutter/material.dart';

/// 4pt spacing scale.
abstract final class Space {
  static const double s1 = 4;
  static const double s2 = 8;
  static const double s3 = 12;
  static const double s4 = 16;
  static const double s5 = 20;
  static const double s6 = 24;
  static const double s8 = 32;
  static const double s10 = 40;
  static const double s12 = 48;
}

abstract final class Radii {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
}

abstract final class Motion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 200);
  static const Curve curve = Curves.easeOut;
}

/// Shadows are reserved for floating surfaces (menus, popovers, dialogs).
/// Cards stay flat with a 1px border.
abstract final class Elevation {
  static List<BoxShadow> popover(Brightness brightness) => [
    BoxShadow(
      color: const Color(0xFF000000).withValues(alpha: brightness == Brightness.dark ? 0.4 : 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}

abstract final class Layout {
  static const double sidebarWidth = 240;
  static const double railWidth = 72;
  static const double contentMaxWidth = 1200;
  static const double contentMaxWidthLarge = 1320;
  static const double controlHeightDesktop = 36;
  static const double controlHeightTouch = 44;
}
