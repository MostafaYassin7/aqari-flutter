import 'package:flutter/material.dart';

/// Single source of truth for all colors in Aqar App.
/// Never use raw Color() values outside this file.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────
  static const Color primary = Color(0xFFF5A623);
  static const Color primaryDark = Color(0xFFE09400);
  static const Color primaryLight = Color(0xFFFFF3E0);

  // ── Semantic ───────────────────────────────────────────
  static const Color error = Color(0xFFFF5A5F);
  static const Color success = Color(0xFF00A699);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // ── Light theme ────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF7F7F7);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFEBEBEB);
  static const Color textPrimaryLight = Color(0xFF222222);
  static const Color textSecondaryLight = Color(0xFF717171);
  static const Color textHintLight = Color(0xFFB0B0B0);
  static const Color iconLight = Color(0xFF717171);
  static const Color shadowLight = Color(0x1A000000);

  // ── Dark theme ─────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);
  static const Color dividerDark = Color(0xFF3A3A3A);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textHintDark = Color(0xFF717171);
  static const Color iconDark = Color(0xFFB0B0B0);
  static const Color shadowDark = Color(0x40000000);

  // ── Utility ────────────────────────────────────────────
  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color overlay = Color(0x80000000);
}
