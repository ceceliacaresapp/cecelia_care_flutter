// lib/screens/sensory_preferences_screen.dart
//
// Sensory Preference Matrix — profiles the care recipient's sensory
// sensitivities so every caregiver on the team knows their comfort zone.
// Critical for IDD/autism care and late-stage dementia.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const _kAccent = AppTheme.tileTeal;

/// The 6 sensory dimensions with their icons, labels, and option presets.
class _SensoryDimension {
  final String key;
  final String label;
  final IconData icon;
  final List<String> presets;
  final String hint;

  const _SensoryDimension({
    required this.key,
    required this.label,
    required this.icon,
    required this.presets,
    required this.hint,
  });
}

const _dimensions = [
  _SensoryDimension(
    key: 'light',
    label: 'Light',
    icon: Icons.light_mode_outlined,
    presets: ['Dim', 'Normal', 'Bright', 'No fluorescent', 'Natural only'],
    hint: 'e.g., Prefers dim lighting, no overhead fluorescent',
  ),
  _SensoryDimension(
    key: 'sound',
    label: 'Sound',
    icon: Icons.volume_up_outlined,
    presets: [
      'Quiet',
      'Moderate',
      'Music helps',
      'No sudden noises',
      'White noise',
    ],
    hint: 'e.g., Calm with soft music, startled by sudden sounds',
  ),
  _SensoryDimension(
    key: 'texture',
    label: 'Texture',
    icon: Icons.touch_app_outlined,
    presets: [
      'Soft fabrics only',
      'No tags or seams',
      'Weighted blanket',
      'Loose clothing',
      'No wool or rough textures',
    ],
    hint: 'e.g., Only tolerates soft cotton, needs tags removed',
  ),
  _SensoryDimension(
    key: 'foodTemp',
    label: 'Food Temperature',
    icon: Icons.thermostat_outlined,
    presets: [
      'Room temperature',
      'Warm only',
      'Cold preferred',
      'No hot liquids',
      'Lukewarm',
    ],
    hint: 'e.g., Refuses hot food, prefers lukewarm drinks',
  ),
  _SensoryDimension(
    key: 'smell',
    label: 'Smell',
    icon: Icons.air_outlined,
    presets: [
      'Sensitive to perfume',
      'No cleaning chemicals',
      'Calmed by lavender',
      'Nauseated by cooking smells',
      'No air fresheners',
    ],
    hint: 'e.g., Strong scents cause agitation, likes vanilla',
  ),
  _SensoryDimension(
    key: 'touch',
    label: 'Touch Tolerance',
    icon: Icons.pan_tool_outlined,
    presets: [
      'Prefers gentle touch',
      'No unexpected contact',
      'Likes hand-holding',
      'Dislikes being moved',
      'Deep pressure calms',
      'Light touch irritates',
    ],
    hint: 'e.g., Must announce touch first, responds well to deep pressure',
  ),
];

class SensoryPreferencesScreen extends StatefulWidget {
  const SensoryPreferencesScreen({super.key});

  @override
  State<SensoryPreferencesScreen> createState() =>
      _SensoryPreferencesScreenState();
}

class _SensoryPreferencesScreenState extends State<SensoryPreferencesScreen> {
  late Map<String, String> _prefs;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final elder =
        Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
    _prefs = Map<String, String>.from(elder?.sensoryPreferences ?? {});
    for (final d in _dimensions) {
      _controllers[d.key] = TextEditingController(text: _prefs[d.key] ?? '');
      _controllers[d.key]!.addListener(_markChanged);
    }
  }

  void _markChanged() {
    if (!_hasChanges && mounted) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final elder =
        Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
    if (elder == null) return;

    // Build the map from controllers.
    final updated = <String, String>{};
    for (final d in _dimensions) {
      final val = _controllers[d.key]!.text.trim();
      if (val.isNotEmpty) updated[d.key] = val;
    }

    try {
      await context.read<FirestoreService>().updateElderProfile(
        elder.id,
        {'sensoryPreferences': updated},
      );
      HapticUtils.success();
      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sensory preferences saved.'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      debugPrint('SensoryPreferences save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;

    if (elder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sensory Preferences')),
        body: const Center(child: Text('No care recipient selected.')),
      );
    }

    final name = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName!
        : elder.profileName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensory Preferences'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.sensors_outlined, color: _kAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Document $name\'s sensory sensitivities so every '
                    'caregiver knows their comfort zone.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Dimension cards
          for (final dim in _dimensions) ...[
            _DimensionCard(
              dimension: dim,
              controller: _controllers[dim.key]!,
              onPresetTap: (preset) {
                final ctrl = _controllers[dim.key]!;
                final current = ctrl.text.trim();
                if (current.isEmpty) {
                  ctrl.text = preset;
                } else if (!current.contains(preset)) {
                  ctrl.text = '$current, $preset';
                }
              },
            ),
            const SizedBox(height: 12),
          ],

          // Save button at bottom
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _hasChanges && !_isSaving ? _save : null,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Sensory Preferences'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                backgroundColor: _kAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DimensionCard extends StatelessWidget {
  const _DimensionCard({
    required this.dimension,
    required this.controller,
    required this.onPresetTap,
  });

  final _SensoryDimension dimension;
  final TextEditingController controller;
  final void Function(String preset) onPresetTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusM)),
            ),
            child: Row(
              children: [
                Icon(dimension.icon, size: 18, color: _kAccent),
                const SizedBox(width: 8),
                Text(
                  dimension.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: _kAccent,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick-select preset chips
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: dimension.presets.map((preset) {
                    return GestureDetector(
                      onTap: () => onPresetTap(preset),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundGray,
                          borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                          border: Border.all(
                              color: AppTheme.textLight.withValues(alpha: 0.3)),
                        ),
                        child: Text(preset,
                            style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
                // Free-text input
                TextField(
                  controller: controller,
                  maxLines: 2,
                  minLines: 1,
                  decoration: InputDecoration(
                    hintText: dimension.hint,
                    hintStyle: TextStyle(fontSize: 12, color: AppTheme.textLight),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
