// lib/utils/entry_type_helpers.dart
//
// Shared accent color / icon / label helpers for the EntryType enum.
//
// Two color schemes are exposed:
//   • entryTypeColor()       — punchy single-color accent used by dashboard
//                              cards (icon + count chips).
//   • entryTypeStyle()       — accent + soft surface pair used by the
//                              timeline list rows (each row has a tinted
//                              background and a darker accent border).
//
// Keeping both maps in one file removes ~120 lines of duplicated switch
// statements that previously lived in dashboard_screen.dart and
// timeline_screen.dart.

import 'package:flutter/material.dart';

import 'package:cecelia_care_flutter/models/entry_types.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// Accent + surface pair used by timeline rows.
class EntryTypeStyle {
  final Color accent;
  final Color surface;
  const EntryTypeStyle({required this.accent, required this.surface});
}

// ─────────────────────────────────────────────────────────────
// Dashboard-style: single accent color
// ─────────────────────────────────────────────────────────────

Color entryTypeColor(EntryType t) {
  switch (t) {
    case EntryType.mood:
      return const Color(0xFFE91E63);
    case EntryType.medication:
      return const Color(0xFF1E88E5);
    case EntryType.sleep:
      return const Color(0xFF5C6BC0);
    case EntryType.meal:
      return const Color(0xFF43A047);
    case EntryType.pain:
      return const Color(0xFFE53935);
    case EntryType.activity:
      return const Color(0xFF00897B);
    case EntryType.vital:
      return const Color(0xFFF57C00);
    case EntryType.expense:
      return const Color(0xFF8E24AA);
    case EntryType.message:
      return const Color(0xFF546E7A);
    case EntryType.handoff:
      return const Color(0xFF00897B);
    case EntryType.incontinence:
      return const Color(0xFF795548);
    case EntryType.nightWaking:
      return const Color(0xFF283593);
    case EntryType.hydration:
      return const Color(0xFF0288D1);
    case EntryType.visitor:
      return const Color(0xFF6A1B9A);
    case EntryType.custom:
      return const Color(0xFF546E7A);
    default:
      return AppTheme.textSecondary;
  }
}

IconData entryTypeIcon(EntryType t) {
  switch (t) {
    case EntryType.mood:
      return Icons.sentiment_satisfied_outlined;
    case EntryType.medication:
      return Icons.medication_outlined;
    case EntryType.sleep:
      return Icons.bedtime_outlined;
    case EntryType.meal:
      return Icons.restaurant_outlined;
    case EntryType.pain:
      return Icons.healing_outlined;
    case EntryType.activity:
      return Icons.directions_walk_outlined;
    case EntryType.vital:
      return Icons.monitor_heart_outlined;
    case EntryType.expense:
      return Icons.receipt_long_outlined;
    case EntryType.message:
      return Icons.chat_bubble_outline;
    case EntryType.handoff:
      return Icons.swap_horiz_outlined;
    case EntryType.incontinence:
      return Icons.water_drop_outlined;
    case EntryType.nightWaking:
      return Icons.nightlight_outlined;
    case EntryType.hydration:
      return Icons.local_drink_outlined;
    case EntryType.visitor:
      return Icons.people_outline;
    case EntryType.custom:
      return Icons.extension_outlined;
    default:
      return Icons.note_outlined;
  }
}

String entryTypeShortLabel(EntryType t) {
  switch (t) {
    case EntryType.mood:
      return 'Mood';
    case EntryType.medication:
      return 'Meds';
    case EntryType.sleep:
      return 'Sleep';
    case EntryType.meal:
      return 'Meals';
    case EntryType.pain:
      return 'Pain';
    case EntryType.activity:
      return 'Activity';
    case EntryType.vital:
      return 'Vitals';
    case EntryType.expense:
      return 'Expenses';
    case EntryType.message:
      return 'Messages';
    case EntryType.handoff:
      return 'Handoff';
    case EntryType.incontinence:
      return 'Continence';
    case EntryType.nightWaking:
      return 'Night Waking';
    case EntryType.hydration:
      return 'Fluids';
    case EntryType.visitor:
      return 'Visitors';
    case EntryType.custom:
      return 'Custom';
    default:
      return t.name;
  }
}

// ─────────────────────────────────────────────────────────────
// Timeline-style: accent + soft surface tint
// ─────────────────────────────────────────────────────────────

EntryTypeStyle entryTypeTimelineStyle(EntryType type) {
  switch (type) {
    case EntryType.message:
      return const EntryTypeStyle(
          accent: AppTheme.accentColor, surface: Color(0xFFFFF3E0));
    case EntryType.caregiverJournal:
      return const EntryTypeStyle(
          accent: Color(0xFF546E7A), surface: Color(0xFFECEFF1));
    case EntryType.medication:
      return const EntryTypeStyle(
          accent: AppTheme.primaryColor, surface: Color(0xFFE8EAF6));
    case EntryType.sleep:
      return const EntryTypeStyle(
          accent: Color(0xFF1565C0), surface: Color(0xFFE3F2FD));
    case EntryType.meal:
      return const EntryTypeStyle(
          accent: Color(0xFF2E7D32), surface: Color(0xFFE8F5E9));
    case EntryType.mood:
      return const EntryTypeStyle(
          accent: Color(0xFF6A1B9A), surface: Color(0xFFF3E5F5));
    case EntryType.pain:
      return const EntryTypeStyle(
          accent: AppTheme.dangerColor, surface: Color(0xFFFFEBEE));
    case EntryType.activity:
      return const EntryTypeStyle(
          accent: Color(0xFF00695C), surface: Color(0xFFE0F2F1));
    case EntryType.vital:
      return const EntryTypeStyle(
          accent: Color(0xFF00838F), surface: Color(0xFFE0F7FA));
    case EntryType.expense:
      return const EntryTypeStyle(
          accent: Color(0xFF4E342E), surface: Color(0xFFEFEBE9));
    case EntryType.image:
      return const EntryTypeStyle(
          accent: Color(0xFF283593), surface: Color(0xFFE8EAF6));
    case EntryType.handoff:
      return const EntryTypeStyle(
          accent: Color(0xFF00897B), surface: Color(0xFFE0F2F1));
    case EntryType.incontinence:
      return const EntryTypeStyle(
          accent: Color(0xFF795548), surface: Color(0xFFEFEBE9));
    case EntryType.nightWaking:
      return const EntryTypeStyle(
          accent: Color(0xFF283593), surface: Color(0xFFE8EAF6));
    case EntryType.hydration:
      return const EntryTypeStyle(
          accent: Color(0xFF0288D1), surface: Color(0xFFE1F5FE));
    case EntryType.visitor:
      return const EntryTypeStyle(
          accent: Color(0xFF6A1B9A), surface: Color(0xFFF3E5F5));
    case EntryType.custom:
      return const EntryTypeStyle(
          accent: Color(0xFF546E7A), surface: AppTheme.backgroundGray);
    default:
      return const EntryTypeStyle(
          accent: Color(0xFF546E7A), surface: AppTheme.backgroundGray);
  }
}
