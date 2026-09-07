import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand colors sampled from `assets/images/IzShowTimeTitle.png`.
class AppTheme {
  static const Color _brandYellow = Color(0xFFFDDC15);
  static const Color _brandGold = Color(0xFFFEB40E);
  static const Color _brandInk = Color(0xFF01000C);
  static const Color _brandOffWhite = Color(0xFFFCFAF8);

  /// Deep gold for light UI chrome — ~5.1:1 on off-white (WCAG AA).
  static const Color _lightPrimary = Color(0xFF8A6500);

  /// Slightly warmer deep gold for secondary actions / accents.
  static const Color _lightSecondary = Color(0xFF9A5A00);

  static const Color _lightScaffold = Color(0xFFF3F0EC);
  static const Color _lightSurfaceContainer = Color(0xFFEEEAE4);
  static const Color _lightOutline = Color(0xFF7A7468);

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: _lightPrimary,
      onPrimary: _brandOffWhite,
      primaryContainer: _brandYellow,
      onPrimaryContainer: _brandInk,
      secondary: _lightSecondary,
      onSecondary: _brandOffWhite,
      secondaryContainer: _brandGold,
      onSecondaryContainer: _brandInk,
      tertiary: _brandGold,
      onTertiary: _brandInk,
      tertiaryContainer: Color(0xFFFFE08A),
      onTertiaryContainer: _brandInk,
      error: Color(0xFFB3261E),
      onError: _brandOffWhite,
      surface: _brandOffWhite,
      onSurface: _brandInk,
      onSurfaceVariant: Color(0xFF4A463C),
      surfaceContainerHighest: _lightSurfaceContainer,
      outline: _lightOutline,
      outlineVariant: Color(0xFFCAC4B8),
      shadow: _brandInk,
      scrim: _brandInk,
      inverseSurface: Color(0xFF1C1B1A),
      onInverseSurface: _brandOffWhite,
      inversePrimary: _brandYellow,
    ),
    textTheme: _textThemeWithPrimarySectionTitles(
      GoogleFonts.robotoTextTheme(),
      _lightPrimary,
    ),
    scaffoldBackgroundColor: _lightScaffold,
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: _brandYellow.withValues(alpha: 0.55),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? _lightPrimary : _lightOutline,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? _lightPrimary : _lightOutline,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: _brandOffWhite,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _lightPrimary,
      foregroundColor: _brandOffWhite,
    ),
  );

  // Dark Theme — bright brand yellow reads well on dark surfaces.
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: _brandYellow,
      onPrimary: _brandInk,
      primaryContainer: Color(0xFF5C4A00),
      onPrimaryContainer: _brandYellow,
      secondary: _brandGold,
      onSecondary: _brandInk,
      secondaryContainer: Color(0xFF5C4000),
      onSecondaryContainer: _brandGold,
      tertiary: _brandGold,
      onTertiary: _brandInk,
      tertiaryContainer: Color(0xFF4A3800),
      onTertiaryContainer: Color(0xFFFFE08A),
      error: Color(0xFFF2B8B5),
      onError: Color(0xFF601410),
      surface: Color(0xFF1C1B1A),
      onSurface: _brandOffWhite,
      onSurfaceVariant: Color(0xFFCAC4B8),
      surfaceContainerHighest: Color(0xFF2C2A27),
      outline: Color(0xFF958F84),
      outlineVariant: Color(0xFF4A463C),
      shadow: _brandInk,
      scrim: _brandInk,
      inverseSurface: _brandOffWhite,
      onInverseSurface: _brandInk,
      inversePrimary: _lightPrimary,
    ),
    textTheme: _textThemeWithPrimarySectionTitles(
      GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
      _brandYellow,
    ),
    scaffoldBackgroundColor: const Color(0xFF121110),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: _brandYellow.withValues(alpha: 0.28),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? _brandYellow : const Color(0xFFCAC4B8),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? _brandYellow : const Color(0xFFCAC4B8),
        );
      }),
    ),
  );

  /// Section headers (`titleLarge`) inherit brand primary for consistency.
  static TextTheme _textThemeWithPrimarySectionTitles(
    TextTheme base,
    Color primary,
  ) {
    return base.copyWith(
      titleLarge: base.titleLarge?.copyWith(
        color: primary,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // Extended color palette (brand reference hex strings)
  static const String primaryColor = '#8A6500';
  static const String accentColor = '#FEB40E';
  static const String warningColor = '#FB7185';
  static const String successColor = '#34D399';

  /// Parses a persisted theme preference. Unknown / missing → [ThemeMode.system].
  static ThemeMode themeModeFromStorage(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  static String themeModeToStorage(ThemeMode mode) => mode.name;
}
