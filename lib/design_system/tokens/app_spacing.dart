library app_spacing;

/// 4pt spacing scale. Screen horizontal padding: [screenPaddingPhone] on
/// phone (`< 600`), [screenPaddingTablet] on tablet/desktop (`>= 600`) —
/// see CLAUDE.md responsive breakpoints. Grid gutter: [gridGutter].
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;

  static const double screenPaddingPhone = lg; // 16
  static const double screenPaddingTablet = xxxl; // 32
  static const double gridGutter = md; // 12
}
