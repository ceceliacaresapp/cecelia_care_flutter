// lib/screens/settings/dashboard_settings_screen.dart
//
// Lets the user reorder and hide/show dashboard sections.
// Persists to SharedPreferences as a JSON string.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

/// Key used in SharedPreferences.
const String kDashboardSectionsKey = 'dashboard_sections_config';

/// Default section order and visibility.
const List<Map<String, dynamic>> kDefaultSections = [
  {'key': 'orientationBoard', 'label': 'Orientation Board', 'icon': 0xe8df, 'visible': true},
  {'key': 'weeklyTeamSummary', 'label': 'Weekly Team Summary', 'icon': 0xe7fb, 'visible': true},
  {'key': 'wellness', 'label': 'Wellness Summary', 'icon': 0xe559, 'visible': true},
  {'key': 'quickMeds', 'label': 'Quick Meds', 'icon': 0xf0575, 'visible': true},
  {'key': 'careLog', 'label': "Today's Care Log", 'icon': 0xe873, 'visible': true},
  {'key': 'achievements', 'label': 'Achievements', 'icon': 0xe545, 'visible': true},
  {'key': 'journal', 'label': 'My Journal', 'icon': 0xf584, 'visible': true},
  {'key': 'quickLog', 'label': 'Quick Log', 'icon': 0xe145, 'visible': true},
  {'key': 'taskSummary', 'label': 'Tasks', 'icon': 0xe065, 'visible': true},
  {'key': 'insights', 'label': 'Symptom Insights', 'icon': 0xe3a1, 'visible': true},
  {'key': 'medSchedule', 'label': 'Med Schedule', 'icon': 0xf0575, 'visible': true},
  {'key': 'dutyTimer', 'label': 'Duty Timer', 'icon': 0xe425, 'visible': true},
  {'key': 'weightTrend', 'label': 'Weight Trend', 'icon': 0xe3ba, 'visible': true},
  {'key': 'adherenceSummary', 'label': 'Med Adherence', 'icon': 0xe3ec, 'visible': true},
  {'key': 'hydrationProgress', 'label': 'Hydration', 'icon': 0xe3e0, 'visible': true},
];

/// Reads the saved config from SharedPreferences, falling back to defaults.
Future<List<Map<String, dynamic>>> loadDashboardSections() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(kDashboardSectionsKey);
  if (raw == null) return List<Map<String, dynamic>>.from(kDefaultSections);

  try {
    final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
    final saved = decoded.cast<Map<String, dynamic>>();

    // Merge with defaults so newly added sections appear at the end.
    final savedKeys = saved.map((s) => s['key'] as String).toSet();
    final merged = List<Map<String, dynamic>>.from(saved);
    for (final d in kDefaultSections) {
      if (!savedKeys.contains(d['key'])) merged.add(Map<String, dynamic>.from(d));
    }
    return merged;
  } catch (_) {
    return List<Map<String, dynamic>>.from(kDefaultSections);
  }
}

/// Saves the config to SharedPreferences.
Future<void> saveDashboardSections(List<Map<String, dynamic>> sections) async {
  final prefs = await SharedPreferences.getInstance();
  // Only persist key + visible — label/icon are cosmetic and come from defaults.
  final toSave = sections.map((s) => {
    'key': s['key'],
    'visible': s['visible'],
  }).toList();
  await prefs.setString(kDashboardSectionsKey, jsonEncode(toSave));
}

class DashboardSettingsScreen extends StatefulWidget {
  const DashboardSettingsScreen({super.key});

  @override
  State<DashboardSettingsScreen> createState() => _DashboardSettingsScreenState();
}

class _DashboardSettingsScreenState extends State<DashboardSettingsScreen> {
  List<Map<String, dynamic>> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sections = await loadDashboardSections();
    if (mounted) setState(() { _sections = sections; _isLoading = false; });
  }

  Future<void> _save() async {
    await saveDashboardSections(_sections);
  }

  void _moveUp(int index) {
    if (index <= 0) return;
    setState(() {
      final item = _sections.removeAt(index);
      _sections.insert(index - 1, item);
    });
    _save();
  }

  void _moveDown(int index) {
    if (index >= _sections.length - 1) return;
    setState(() {
      final item = _sections.removeAt(index);
      _sections.insert(index + 1, item);
    });
    _save();
  }

  void _toggleVisibility(int index) {
    setState(() {
      _sections[index] = {
        ..._sections[index],
        'visible': !(_sections[index]['visible'] as bool),
      };
    });
    _save();
  }

  Future<void> _resetDefaults() async {
    setState(() {
      _sections = List<Map<String, dynamic>>.from(
          kDefaultSections.map((s) => Map<String, dynamic>.from(s)));
    });
    await _save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard reset to defaults'), backgroundColor: Colors.green),
      );
    }
  }

  /// Resolve icon from the default list by key.
  IconData _iconForKey(String key) {
    switch (key) {
      case 'orientationBoard': return Icons.today_outlined;
      case 'weeklyTeamSummary': return Icons.celebration_outlined;
      case 'wellness': return Icons.favorite_border;
      case 'quickMeds': return Icons.medication_outlined;
      case 'careLog': return Icons.assignment_outlined;
      case 'achievements': return Icons.emoji_events_outlined;
      case 'journal': return Icons.menu_book_outlined;
      case 'quickLog': return Icons.add_circle_outline;
      case 'taskSummary': return Icons.task_alt_outlined;
      case 'insights': return Icons.insights_outlined;
      case 'medSchedule': return Icons.schedule_outlined;
      case 'dutyTimer': return Icons.timer_outlined;
      case 'weightTrend': return Icons.monitor_weight_outlined;
      case 'adherenceSummary': return Icons.medication_outlined;
      case 'hydrationProgress': return Icons.local_drink_outlined;
      default: return Icons.widgets_outlined;
    }
  }

  /// Resolve label from the default list by key (in case saved data only has key+visible).
  String _labelForKey(String key) {
    for (final d in kDefaultSections) {
      if (d['key'] == key) return d['label'] as String;
    }
    return key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Dashboard'),
        actions: [
          TextButton(
            onPressed: _resetDefaults,
            child: const Text('Reset'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Explanation
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  color: AppTheme.primaryColor.withOpacity(0.04),
                  child: const Text(
                    'Choose which sections appear on your dashboard and their order. '
                    'The greeting card always appears at the top.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
                  ),
                ),
                const Divider(height: 1),
                // Section list
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _sections.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                    itemBuilder: (context, i) {
                      final section = _sections[i];
                      final key = section['key'] as String;
                      final visible = section['visible'] as bool;
                      final label = section['label'] as String? ?? _labelForKey(key);
                      final icon = _iconForKey(key);

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            // Reorder arrows
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    Icons.arrow_drop_up,
                                    color: i > 0
                                        ? AppTheme.textPrimary
                                        : AppTheme.textLight,
                                  ),
                                  onPressed: i > 0 ? () => _moveUp(i) : null,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.arrow_drop_down,
                                    color: i < _sections.length - 1
                                        ? AppTheme.textPrimary
                                        : AppTheme.textLight,
                                  ),
                                  onPressed: i < _sections.length - 1 ? () => _moveDown(i) : null,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                                ),
                              ],
                            ),
                            const SizedBox(width: 4),
                            // Icon badge
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: visible
                                    ? AppTheme.primaryColor.withOpacity(0.1)
                                    : AppTheme.backgroundGray,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                size: 20,
                                color: visible
                                    ? AppTheme.primaryColor
                                    : AppTheme.textLight,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Label
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: visible
                                      ? AppTheme.textPrimary
                                      : AppTheme.textLight,
                                  decoration: visible
                                      ? null
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            ),
                            // Visibility toggle
                            Switch(
                              value: visible,
                              onChanged: (_) => _toggleVisibility(i),
                              activeColor: AppTheme.primaryColor,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
