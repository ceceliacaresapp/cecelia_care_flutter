// lib/screens/forms/hydration_form.dart
//
// Quick-log form for fluid intake. Deliberately minimal for multiple
// daily uses. Volume presets + fluid type chips.

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/form_sheet_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HydrationForm extends StatefulWidget {
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const HydrationForm({
    super.key,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<HydrationForm> createState() => _HydrationFormState();
}

class _HydrationFormState extends State<HydrationForm> {
  final _volumeCtrl = TextEditingController();
  String _unit = 'oz';
  String? _fluidType;
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;

  static const Color _accent = Color(0xFF0288D1);

  static const List<int> _presetsOz = [4, 8, 12, 16];
  static const List<int> _presetsMl = [120, 240, 350, 480];

  static const List<String> _fluidTypes = [
    'Water', 'Juice', 'Coffee / Tea', 'Milk',
    'Broth / Soup', 'Thickened liquid', 'IV fluids', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadUnit();
  }

  Future<void> _loadUnit() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getString('hydration_unit');
    if (saved != null && mounted) setState(() => _unit = saved);
  }

  Future<void> _saveUnit(String unit) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('hydration_unit', unit);
  }

  @override
  void dispose() {
    _volumeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _volumeCtrl.text.trim().isNotEmpty &&
      double.tryParse(_volumeCtrl.text.trim()) != null &&
      _fluidType != null;

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      final journal = context.read<JournalServiceProvider>();
      final user = AuthService.currentUser;
      if (user == null) return;

      final volume = double.parse(_volumeCtrl.text.trim());
      final payload = <String, dynamic>{
        'volume': volume,
        'unit': _unit,
        'fluidType': _fluidType,
        'note': _noteCtrl.text.trim(),
        'stamp': Timestamp.now(),
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'date': widget.currentDate,
        'elderId': widget.activeElder.id,
        'loggedByUserId': user.uid,
        'loggedBy': user.displayName ?? user.email ?? 'Unknown',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
      };
      await journal.addJournalEntry('hydration', payload, user.uid);
      HapticUtils.success();
      Navigator.of(context, rootNavigator: true).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving hydration: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final presets = _unit == 'oz' ? _presetsOz : _presetsMl;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormSheetHeader(title: 'Log Fluid Intake'),
          const SizedBox(height: 16),

          // ── Volume presets ─────────────────────────────────
          Row(
            children: presets.map((v) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: v != presets.last ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => setState(() =>
                        _volumeCtrl.text = v.toString()),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _volumeCtrl.text == v.toString()
                            ? _accent.withValues(alpha: 0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _volumeCtrl.text == v.toString()
                              ? _accent
                              : Colors.grey.shade300,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$v $_unit',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _volumeCtrl.text == v.toString()
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _volumeCtrl.text == v.toString()
                              ? _accent
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          // ── Custom volume + unit ───────────────────────────
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _volumeCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Volume',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'oz', label: Text('oz')),
                  ButtonSegment(value: 'ml', label: Text('ml')),
                ],
                selected: {_unit},
                onSelectionChanged: (s) {
                  setState(() => _unit = s.first);
                  _saveUnit(s.first);
                },
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Fluid type ─────────────────────────────────────
          Text('Fluid Type',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _fluidTypes.map((t) {
              final selected = _fluidType == t;
              return GestureDetector(
                onTap: () => setState(() => _fluidType = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? _accent.withValues(alpha: 0.12)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? _accent : Colors.grey.shade300,
                      width: selected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(t,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? _accent : Colors.grey.shade700,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Notes ──────────────────────────────────────────
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'e.g., refused after 2 sips, used thickener',
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // ── Save ───────────────────────────────────────────
          ElevatedButton(
            onPressed: _canSave && !_isSaving ? _handleSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
