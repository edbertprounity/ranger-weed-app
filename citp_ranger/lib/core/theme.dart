import 'package:flutter/material.dart';

/// Field-app dark surfaces. Green is reserved for the primary action.
const ink = Color(0xFFE8E8E8);
const paper = Color(0xFF121212);
const panel = Color(0xFF1E1E1E);
const raised = Color(0xFF2C2C2C);
const muted = Color(0xFF9E9E9E);
const line = Color(0xFF2C2C2C);
const accent = Color(0xFF3E6B4F);

const overdueFill = Color(0xFF3A2424);
const overdueInk = Color(0xFFF2B8B5);
const pendingFill = Color(0xFF3A2E1A);
const pendingInk = Color(0xFFE8C27A);
const clearFill = Color(0xFF1C3328);
const clearInk = Color(0xFFA9D4B5);
const pinOverdue = Color(0xFFE07A6A);
const pinPending = Color(0xFFE0B15A);
const pinClear = Color(0xFF7DBF93);

ThemeData buildRangerTheme() {
  const scheme = ColorScheme.dark(
    surface: paper,
    primary: accent,
    onPrimary: ink,
    onSurface: ink,
    outline: line,
  );
  const border = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
    borderSide: BorderSide(color: line),
  );
  return ThemeData(
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: paper,
    canvasColor: paper,
    useMaterial3: true,
    dividerColor: line,
    appBarTheme: const AppBarTheme(
      backgroundColor: paper,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: accent,
        foregroundColor: ink,
        minimumSize: const Size.fromHeight(48),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: const BorderSide(color: raised),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: ink),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: panel,
      labelStyle: TextStyle(color: muted),
      hintStyle: TextStyle(color: muted),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: accent),
      ),
    ),
    cardTheme: const CardThemeData(
      color: panel,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: raised),
      ),
    ),
    listTileTheme: const ListTileThemeData(textColor: ink, iconColor: ink),
    iconTheme: const IconThemeData(color: ink),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: accent),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 20),
      headlineSmall: TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 16),
      titleLarge: TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 16),
      titleMedium: TextStyle(color: ink, fontWeight: FontWeight.w600, fontSize: 14),
      bodyMedium: TextStyle(color: ink, height: 1.35, fontSize: 14),
      bodySmall: TextStyle(color: muted, fontSize: 12),
    ),
  );
}
