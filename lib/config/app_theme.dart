import 'package:flutter/material.dart';

class DZI {
  static const Color navy        = Color(0xFF0A1628);
  static const Color navyLight   = Color(0xFF1A2B45);
  static const Color orange      = Color(0xFFFF6B00);
  static const Color orangeLight = Color(0xFFFF8C38);
  static const Color orangePale  = Color(0xFFFFF0E6);

  static const Color success     = Color(0xFF00B37E);
  static const Color successPale = Color(0xFFE6FAF4);
  static const Color warning     = Color(0xFFF59E0B);
  static const Color warningPale = Color(0xFFFEF3C7);
  static const Color danger      = Color(0xFFEF4444);
  static const Color dangerPale  = Color(0xFFFEE2E2);
  static const Color info        = Color(0xFF0EA5E9);
  static const Color infoPale    = Color(0xFFE0F2FE);

  static const Color text1   = Color(0xFF1C1C1E);
  static const Color text2   = Color(0xFF6B7280);
  static const Color text3   = Color(0xFF9CA3AF);
  static const Color border  = Color(0xFFE5E7EB);
  static const Color bg      = Color(0xFFF7F8FA);
  static const Color card    = Color(0xFFFFFFFF);

  static const Color darkBg     = Color(0xFF0D0D0D);
  static const Color darkCard   = Color(0xFF1A1A1A);
  static const Color darkBorder = Color(0xFF2C2C2C);

  static bool isDark(BuildContext ctx) =>
      Theme.of(ctx).brightness == Brightness.dark;

  static Color surface(BuildContext ctx)       => isDark(ctx) ? darkBg     : bg;
  static Color cardColor(BuildContext ctx)     => isDark(ctx) ? darkCard   : card;
  static Color borderColor(BuildContext ctx)   => isDark(ctx) ? darkBorder : border;
  static Color textPrimary(BuildContext ctx)   => isDark(ctx) ? Colors.white : text1;
  static Color textSecondary(BuildContext ctx) => isDark(ctx) ? const Color(0xFF9CA3AF) : text2;
  static Color textTertiary(BuildContext ctx)  => isDark(ctx) ? const Color(0xFF6B7280) : text3;

  static List<BoxShadow> get cardShadow => [
    BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 12, offset: const Offset(0, 4)),
  ];
  static List<BoxShadow> get orangeShadow => [
    BoxShadow(color: orange.withAlpha(60), blurRadius: 16, offset: const Offset(0, 6)),
  ];

  static const double r4  = 4;
  static const double r8  = 8;
  static const double r12 = 12;
  static const double r16 = 16;
  static const double r20 = 20;
  static const double r24 = 24;

  static InputDecoration inputDeco(BuildContext ctx, String label,
      {IconData? icon, Widget? suffix}) {
    final dark = isDark(ctx);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: textSecondary(ctx), fontSize: 14),
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, size: 20, color: textSecondary(ctx)))
          : null,
      suffixIcon: suffix,
      filled: true,
      fillColor: dark ? darkCard : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r12),
        borderSide: BorderSide(color: borderColor(ctx)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r12),
        borderSide: BorderSide(color: borderColor(ctx)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r12),
        borderSide: const BorderSide(color: navy, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r12),
        borderSide: const BorderSide(color: danger, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r12),
        borderSide: const BorderSide(color: danger, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static ButtonStyle get primaryBtn => ElevatedButton.styleFrom(
    backgroundColor: navy,
    foregroundColor: Colors.white,
    elevation: 0,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r12)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  static ButtonStyle get accentBtn => ElevatedButton.styleFrom(
    backgroundColor: orange,
    foregroundColor: Colors.white,
    elevation: 0,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(r12)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );

  // Typography helpers
  static TextStyle h1(BuildContext ctx) => TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800,
    color: textPrimary(ctx), letterSpacing: -0.5, height: 1.2,
  );
  static TextStyle h2(BuildContext ctx) => TextStyle(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: textPrimary(ctx), letterSpacing: -0.3,
  );
  static TextStyle h3(BuildContext ctx) => TextStyle(
    fontSize: 17, fontWeight: FontWeight.w600,
    color: textPrimary(ctx),
  );
  static TextStyle body(BuildContext ctx) => TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: textSecondary(ctx), height: 1.5,
  );
  static TextStyle label(BuildContext ctx) => TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: textSecondary(ctx), letterSpacing: 0.2,
  );
  static TextStyle caption(BuildContext ctx) => TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400,
    color: textTertiary(ctx),
  );
}

// ── Theme data ──────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: DZI.bg,
    cardColor: DZI.card,
    colorScheme: const ColorScheme.light(
      primary: DZI.navy,
      secondary: DZI.orange,
      surface: DZI.card,
      error: DZI.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DZI.card,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: DZI.navy),
      titleTextStyle: TextStyle(
        color: DZI.text1, fontSize: 18, fontWeight: FontWeight.w700,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DZI.card,
      indicatorColor: DZI.orangePale,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: DZI.orange);
        }
        return const IconThemeData(color: DZI.text2);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: DZI.orange, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: DZI.text2, fontSize: 11, fontWeight: FontWeight.w400);
      }),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    dividerColor: DZI.border,
    // FIX: use CardThemeData not CardTheme
    cardTheme: CardThemeData(
      color: DZI.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DZI.r16),
        side: const BorderSide(color: DZI.border),
      ),
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: DZI.darkBg,
    cardColor: DZI.darkCard,
    colorScheme: const ColorScheme.dark(
      primary: DZI.orange,
      secondary: DZI.orange,
      surface: DZI.darkCard,
      error: DZI.danger,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: DZI.darkCard,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700,
      ),
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: DZI.darkCard,
      indicatorColor: Color(0x1AFF6B00),
      elevation: 0,
    ),
    dividerColor: DZI.darkBorder,
    // FIX: use CardThemeData not CardTheme
    cardTheme: CardThemeData(
      color: DZI.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DZI.r16),
        side: const BorderSide(color: DZI.darkBorder),
      ),
    ),
  );

  // Backward-compat helpers used in older screens
  static Color bgColor(BuildContext ctx)       => DZI.surface(ctx);
  static Color cardColor(BuildContext ctx)     => DZI.cardColor(ctx);
  static Color textColor(BuildContext ctx)     => DZI.textPrimary(ctx);
  static Color subTextColor(BuildContext ctx)  => DZI.textSecondary(ctx);
  static Color dividerColor(BuildContext ctx)  => DZI.borderColor(ctx);
  static Color appBarBg(BuildContext ctx)      => DZI.cardColor(ctx);
  static Color bottomNavBg(BuildContext ctx)   => DZI.cardColor(ctx);
  static const Color navyBlue = DZI.navy;
}