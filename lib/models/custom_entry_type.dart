// lib/models/custom_entry_type.dart
//
// Data model for user-created custom care log categories.
// Stored in Firestore: elderProfiles/{elderId}/customEntryTypes/{typeId}

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// CustomField — a single form field within a custom entry type
// ---------------------------------------------------------------------------
class CustomField {
  final String key;
  final String label;
  final String fieldType; // 'text', 'number', 'dropdown', 'toggle', 'longtext'
  final bool required;
  final List<String>? options; // for dropdown only

  const CustomField({
    required this.key,
    required this.label,
    this.fieldType = 'text',
    this.required = false,
    this.options,
  });

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      fieldType: json['fieldType'] as String? ?? 'text',
      required: json['required'] as bool? ?? false,
      options: (json['options'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'fieldType': fieldType,
        'required': required,
        if (options != null) 'options': options,
      };

  CustomField copyWith({
    String? key,
    String? label,
    String? fieldType,
    bool? required,
    List<String>? options,
  }) =>
      CustomField(
        key: key ?? this.key,
        label: label ?? this.label,
        fieldType: fieldType ?? this.fieldType,
        required: required ?? this.required,
        options: options ?? this.options,
      );
}

// ---------------------------------------------------------------------------
// CustomEntryType — the full type definition
// ---------------------------------------------------------------------------
class CustomEntryType {
  final String? id;
  final String name;
  final String iconName;
  final String colorHex;
  final List<CustomField> fields;
  final String createdBy;
  final String elderId;

  const CustomEntryType({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.fields,
    required this.createdBy,
    required this.elderId,
  });

  IconData get iconData => kAvailableIcons[iconName] ?? Icons.note_outlined;

  Color get color {
    try {
      final hex = colorHex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF546E7A);
    }
  }

  factory CustomEntryType.fromFirestore(
    String docId,
    Map<String, dynamic> data,
  ) {
    return CustomEntryType(
      id: docId,
      name: data['name'] as String? ?? 'Untitled',
      iconName: data['iconName'] as String? ?? 'note',
      colorHex: data['colorHex'] as String? ?? '#546E7A',
      fields: (data['fields'] as List<dynamic>?)
              ?.map((f) =>
                  CustomField.fromJson(Map<String, dynamic>.from(f as Map)))
              .toList() ??
          [],
      createdBy: data['createdBy'] as String? ?? '',
      elderId: data['elderId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'iconName': iconName,
        'colorHex': colorHex,
        'fields': fields.map((f) => f.toJson()).toList(),
        'createdBy': createdBy,
        'elderId': elderId,
      };

  CustomEntryType copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    List<CustomField>? fields,
    String? createdBy,
    String? elderId,
  }) =>
      CustomEntryType(
        id: id ?? this.id,
        name: name ?? this.name,
        iconName: iconName ?? this.iconName,
        colorHex: colorHex ?? this.colorHex,
        fields: fields ?? this.fields,
        createdBy: createdBy ?? this.createdBy,
        elderId: elderId ?? this.elderId,
      );

  // ── Curated icon set ────────────────────────────────────────────
  static const Map<String, IconData> kAvailableIcons = {
    'note': Icons.note_outlined,
    'healing': Icons.healing_outlined,
    'thermostat': Icons.thermostat_outlined,
    'water_drop': Icons.water_drop_outlined,
    'visibility': Icons.visibility_outlined,
    'accessibility': Icons.accessibility_new_outlined,
    'bathtub': Icons.bathtub_outlined,
    'local_hospital': Icons.local_hospital_outlined,
    'psychology': Icons.psychology_outlined,
    'bloodtype': Icons.bloodtype_outlined,
    'air': Icons.air_outlined,
    'fitness': Icons.fitness_center_outlined,
    'mood': Icons.mood_outlined,
    'hearing': Icons.hearing_outlined,
    'volunteer': Icons.volunteer_activism_outlined,
    'hygiene': Icons.clean_hands_outlined,
    'toilet': Icons.wc_outlined,
    'transfer': Icons.transfer_within_a_station_outlined,
    'checkup': Icons.health_and_safety_outlined,
    'therapy': Icons.self_improvement_outlined,
  };

  // ── Curated color set ───────────────────────────────────────────
  static const List<String> kAvailableColors = [
    '#E91E63', // pink
    '#E53935', // red
    '#F57C00', // orange
    '#FFC107', // amber
    '#43A047', // green
    '#00897B', // teal
    '#1E88E5', // blue
    '#5C6BC0', // indigo
    '#8E24AA', // purple
    '#546E7A', // blue-grey
  ];
}
