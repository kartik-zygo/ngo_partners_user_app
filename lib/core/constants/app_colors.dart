import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Primary (Azure) ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySurface = Color(0xFFEFF6FF);

  // ── Brand Secondary (Emerald - NGO/Growth) ────────────────────────────────
  static const Color secondary = Color(0xFF10B981);
  static const Color secondaryLight = Color(0xFF6EE7B7);
  static const Color secondaryDark = Color(0xFF059669);
  static const Color secondarySurface = Color(0xFFECFDF5);

  // ── Accent (Amber - Action/Pricing) ────────────────────────────────────────
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFCD34D);
  static const Color accentDark = Color(0xFFD97706);
  static const Color accentSurface = Color(0xFFFFFBEB);

  // ── Legacy aliases (kept for backward compat) ─────────────────────────────
  static const Color gold = Color(0xFFF59E0B);
  static const Color goldLight = Color(0xFFFCD34D);
  static const Color goldDark = Color(0xFFD97706);

  // ── Background ────────────────────────────────────────────────────────────
  static const Color bgDeep = Color(0xFFF0F4FF);
  static const Color bgDark = Color(0xFFF9FAFB);
  static const Color bgMid = Color(0xFFF3F4F6);
  static const Color bgCard = Color(0xFFFFFFFF);

  // ── Surface ────────────────────────────────────────────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF8FAFF);

  // ── Glass / Overlay ───────────────────────────────────────────────────────
  static const Color glassSurface = Color(0xFFFFFFFF);
  static const Color glassBorder = Color(0xFFDCE8FF);
  static const Color glassCardBg = Color(0xFFFFFFFF);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color textGold = Color(0xFFF59E0B);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Status ────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444);
  static const Color errorBg = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoBg = Color(0xFFEFF6FF);
  static const Color pending = Color(0xFFF59E0B);
  static const Color pendingBg = Color(0xFFFFFBEB);

  // ── Role Colors ───────────────────────────────────────────────────────────
  static const Color roleUser = Color(0xFF3B82F6);
  static const Color roleUserBg = Color(0xFFEFF6FF);
  static const Color roleNGO = Color(0xFF10B981);
  static const Color roleNGOBg = Color(0xFFECFDF5);

  // ── Divider / Border ─────────────────────────────────────────────────────
  static const Color divider = Color(0xFFE5E7EB);
  static const Color borderSubtle = Color(0xFFE5E7EB);
  static const Color borderGold = Color(0xFFFDE68A);
  static const Color borderPrimary = Color(0xFFC7D2FE);

  // ── Extended Accent Palette ────────────────────────────────────────────────
  static const Color primaryIndigo = Color(0xFF2563EB);
  static const Color primaryIndigoLight = Color(0xFF60A5FA);
  static const Color accentCyan = Color(0xFF06B6D4);
  static const Color accentCyanLight = Color(0xFF67E8F9);
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color accentPurple = Color(0xFFA855F7);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient goldGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanGradient = LinearGradient(
    colors: [accentCyan, primaryIndigo],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [accentEmerald, accentCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFFEFF6FF), Color(0xFFF7FBFF), Color(0xFFFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient heroPrimaryGradient = LinearGradient(
    colors: [primary, Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroEmeraldGradient = LinearGradient(
    colors: [secondary, Color(0xFF34D399)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8FAFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
