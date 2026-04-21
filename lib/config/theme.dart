import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand
  static const Color brandPrimary = Color(0xFF81251D);
  static const Color brandHighlight = Color(0xFFD5B251);

  // Core palette - dark premium
  static const Color black = Color(0xFF000000);
  static const Color darkGray = Color(0xFF1C1C1E);
  static const Color gray = Color(0xFF8E8E93);
  static const Color lightGray = Color(0xFFF2F2F7);
  static const Color white = Color(0xFFFFFFFF);
  static const Color separator = Color(0xFFE5E5EA);

  // Status
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color info = Color(0xFF007AFF);

  // Glass effect colors
  static const Color glassBg = Color(0xF2FFFFFF); // 95% white
  static const Color glassStroke = Color(0x30000000); // 19% black
  static const Color surfaceBg = Color(0xFFF5F5F7);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: surfaceBg,
      colorScheme: const ColorScheme.light(
        primary: black,
        onPrimary: white,
        secondary: gray,
        surface: white,
        onSurface: black,
        error: error,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.inter(fontSize: 34, fontWeight: FontWeight.w700, color: black, letterSpacing: -0.5),
        headlineMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w700, color: black, letterSpacing: -0.3),
        headlineSmall: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600, color: black),
        titleLarge: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: black),
        titleMedium: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: black),
        titleSmall: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: black),
        bodyLarge: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w400, color: darkGray),
        bodyMedium: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: darkGray),
        bodySmall: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400, color: gray),
        labelLarge: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: black),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: black,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: black),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: separator.withValues(alpha: 0.5))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: separator.withValues(alpha: 0.5))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: black, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: error, width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(fontSize: 15, color: gray),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: black,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: black,
        unselectedItemColor: gray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      dividerTheme: const DividerThemeData(color: separator, thickness: 0.5),
    );
  }
}

/// Glass card widget - frosted glass effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double borderRadius;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: color ?? AppTheme.glassBg,
        border: Border.all(color: AppTheme.glassStroke, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Gradient background for pages
class GradientBg extends StatelessWidget {
  final Widget child;
  const GradientBg({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFEEF0F4),
            Color(0xFFF0ECE6),
          ],
        ),
      ),
      child: child,
    );
  }
}
