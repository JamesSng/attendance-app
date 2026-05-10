import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central theme for the CBC Attendance app.
///
/// The deep-purple seed remains the brand. The refresh tones down the
/// previous wall-of-purple by:
///   - pinning AppBar to a neutral surface (no more washed-lavender chrome)
///   - reserving the accent purple for one primary action per screen
///   - replacing FilledButton list rows with hairline-bordered tiles
class AppTheme {
  static const Color seed = Color(0xFF673AB7); // Material deep-purple 500
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final TextTheme textTheme = _buildTextTheme(brightness, scheme);

    final Color outline = brightness == Brightness.light
        ? scheme.outlineVariant.withValues(alpha: 0.6)
        : scheme.outlineVariant.withValues(alpha: 0.4);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      dividerColor: outline,
      dividerTheme: DividerThemeData(
        color: outline,
        thickness: 0.6,
        space: 1,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        // Material 3 "Large" top app bar title size. Stays on the M3 type
        // scale (28sp / headlineMedium) instead of inventing a custom px
        // value, so the title is visually prominent yet still consistent
        // with the rest of the typography.
        toolbarHeight: 72,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: scheme.onSurface,
        ),
        systemOverlayStyle: brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: scheme.primary);
          }
          return IconThemeData(color: scheme.onSurfaceVariant);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: scheme.primary.withValues(alpha: 0.14),
        selectedIconTheme: IconThemeData(color: scheme.primary),
        unselectedIconTheme: IconThemeData(color: scheme.onSurfaceVariant),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        useIndicator: true,
        labelType: NavigationRailLabelType.all,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: outline),
          foregroundColor: scheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(color: scheme.primary, width: 1.4),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: scheme.onSurfaceVariant,
        suffixIconColor: scheme.onSurfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        elevation: 2,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: scheme.onSurfaceVariant, width: 1.4),
      ),
      chipTheme: ChipThemeData(
        labelStyle: textTheme.labelMedium,
        side: BorderSide(color: outline),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
        iconColor: scheme.onSurfaceVariant,
      ),
    );
  }

  /// Builds the app-wide [TextTheme] with weights and tracking baked in so
  /// that views can simply reference `Theme.of(context).textTheme.titleLarge`
  /// without sprinkling `copyWith(fontWeight: ...)` calls.
  ///
  /// Token usage convention:
  ///   - displaySmall  -> hero stat numbers
  ///   - headlineSmall -> AppBar title, page heading
  ///   - titleLarge    -> hero/card title, dialog title
  ///   - titleMedium   -> profile / important card title
  ///   - titleSmall    -> list-tile title, secondary card title
  ///   - labelLarge    -> button text
  ///   - labelMedium   -> nav labels, chip labels
  ///   - labelSmall    -> uppercase section header
  ///   - bodyLarge     -> emphasised body
  ///   - bodyMedium    -> default body
  ///   - bodySmall     -> caption / metadata
  static TextTheme _buildTextTheme(Brightness brightness, ColorScheme scheme) {
    // The Material 3 type-scale GEOMETRY (font sizes, weights, line heights,
    // letter spacing) lives in `Typography.englishLike2021` — *not* in the
    // colour-carrying themes such as `Typography.material2021().black`.
    // Flutter normally merges them at `Theme.of(context)` time via
    // `ThemeData.localize`, so reading `ThemeData(...).textTheme` directly
    // returns size-less styles and the AppBar etc. silently fall back to
    // the body text size. We do the merge here explicitly so the M3 sizes
    // (e.g. headlineMedium = 28sp) are actually applied.
    final TextTheme geometry = Typography.englishLike2021;
    final TextTheme src = GoogleFonts.interTextTheme(geometry).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return src.copyWith(
      displayLarge: src.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      displayMedium: src.displayMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
      ),
      displaySmall: src.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      headlineLarge: src.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      headlineMedium: src.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      headlineSmall: src.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleLarge: src.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: src.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      titleSmall: src.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      labelLarge: src.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      labelMedium: src.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      labelSmall: src.labelSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}
