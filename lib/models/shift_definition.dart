// lib/models/shift_definition.dart
//
// Data model for caregiver shift definitions with embedded weekly
// assignment patterns. Stored in elderProfiles/{elderId}/shiftDefinitions.
//
// Each document represents one shift type (e.g., "Morning") with its
// time range and a map of day → assigned caregiver UID for the week.

import 'package:flutter/material.dart';

class ShiftDefinition {
  final String? id;
  final String name;
  final String startTime; // '07:00'
  final String endTime;   // '15:00'
  final String colorHex;
  final String elderId;
  final String createdBy;

  /// Weekly pattern: day abbreviation → caregiver UID.
  /// Keys: 'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'.
  /// Empty string or missing key = unassigned.
  final Map<String, String> assignments;

  /// Denormalized display names keyed by UID.
  /// Avoids extra Firestore lookups when rendering the grid.
  final Map<String, String> assigneeNames;

  const ShiftDefinition({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.colorHex,
    required this.elderId,
    required this.createdBy,
    this.assignments = const {},
    this.assigneeNames = const {},
  });

  // ── Helpers ─────────────────────────────────────────────────────

  Color get color {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF1E88E5);
    }
  }

  String? assignedUidForDay(String dayKey) {
    final uid = assignments[dayKey];
    return (uid != null && uid.isNotEmpty) ? uid : null;
  }

  String assignedNameForDay(String dayKey) {
    final uid = assignedUidForDay(dayKey);
    if (uid == null) return '';
    return assigneeNames[uid] ?? '?';
  }

  /// Returns true if this shift is currently active based on time of day.
  /// Handles overnight shifts where endTime < startTime (e.g., 23:00–07:00).
  bool get isCurrentShift {
    final now = TimeOfDay.now();
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    if (start == null || end == null) return false;

    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes < endMinutes) {
      // Normal shift (e.g., 07:00–15:00)
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Overnight shift (e.g., 23:00–07:00)
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  /// Returns the day key for today ('mon', 'tue', etc.)
  static String todayKey() {
    const keys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    // DateTime.weekday: 1 = Monday, 7 = Sunday
    return keys[DateTime.now().weekday - 1];
  }

  /// All valid day keys in order.
  static const List<String> dayKeys = [
    'mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun',
  ];

  static const List<String> dayLabels = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  static TimeOfDay? _parseTime(String time) {
    try {
      final parts = time.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: parts.length > 1 ? int.parse(parts[1]) : 0,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Firestore serialization ─────────────────────────────────────

  factory ShiftDefinition.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return ShiftDefinition(
      id: docId,
      name: data['name'] as String? ?? 'Unnamed Shift',
      startTime: data['startTime'] as String? ?? '08:00',
      endTime: data['endTime'] as String? ?? '16:00',
      colorHex: data['colorHex'] as String? ?? '#1E88E5',
      elderId: data['elderId'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      assignments: Map<String, String>.from(
        (data['assignments'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
      ),
      assigneeNames: Map<String, String>.from(
        (data['assigneeNames'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v.toString())) ??
            {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'colorHex': colorHex,
        'elderId': elderId,
        'createdBy': createdBy,
        'assignments': assignments,
        'assigneeNames': assigneeNames,
      };

  ShiftDefinition copyWith({
    String? id,
    String? name,
    String? startTime,
    String? endTime,
    String? colorHex,
    String? elderId,
    String? createdBy,
    Map<String, String>? assignments,
    Map<String, String>? assigneeNames,
  }) =>
      ShiftDefinition(
        id: id ?? this.id,
        name: name ?? this.name,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        colorHex: colorHex ?? this.colorHex,
        elderId: elderId ?? this.elderId,
        createdBy: createdBy ?? this.createdBy,
        assignments: assignments ?? this.assignments,
        assigneeNames: assigneeNames ?? this.assigneeNames,
      );

  // ── Preset templates for quick setup ────────────────────────────

  static List<ShiftDefinition> presets(String elderId, String createdBy) => [
        ShiftDefinition(
          name: 'Morning',
          startTime: '07:00',
          endTime: '15:00',
          colorHex: '#1E88E5',
          elderId: elderId,
          createdBy: createdBy,
        ),
        ShiftDefinition(
          name: 'Afternoon',
          startTime: '15:00',
          endTime: '23:00',
          colorHex: '#F57C00',
          elderId: elderId,
          createdBy: createdBy,
        ),
        ShiftDefinition(
          name: 'Overnight',
          startTime: '23:00',
          endTime: '07:00',
          colorHex: '#5C6BC0',
          elderId: elderId,
          createdBy: createdBy,
        ),
      ];

  static const List<String> kShiftColors = [
    '#1E88E5', '#F57C00', '#5C6BC0',
    '#00897B', '#E53935', '#8E24AA',
  ];
}
