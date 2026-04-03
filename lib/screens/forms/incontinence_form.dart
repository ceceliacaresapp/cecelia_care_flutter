// lib/screens/forms/incontinence_form.dart
//
// Clinical incontinence tracker: type, severity, skin condition check,
// clothing/bedding changed toggle, and notes. Follows the pain_form pattern.

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

class IncontinenceForm extends StatefulWidget {
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const IncontinenceForm({
    super.key,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<IncontinenceForm> createState() => _IncontinenceFormState();
}

class _IncontinenceFormState extends State<IncontinenceForm> {
  String? _selectedType; // 'urinary', 'bowel', 'both'
  String? _selectedSeverity; // 'light', 'moderate', 'heavy'
  String? _selectedSkin; // 'healthy', 'irritated', 'broken', 'notChecked'
  bool _changed = true;
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;

  static const Color _accentColor = Color(0xFF795548);

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _selectedType != null &&
      _selectedSeverity != null &&
      _selectedSkin != null;

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      final journal = context.read<JournalServiceProvider>();
      final user = AuthService.currentUser;
      if (user == null) {
        _showSnackBar('Not authenticated.', Colors.red);
        return;
      }
      final payload = <String, dynamic>{
        'incontinenceType': _selectedType,
        'severity': _selectedSeverity,
        'skinCondition': _selectedSkin,
        'changed': _changed,
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
      await journal.addJournalEntry('incontinence', payload, user.uid);
      _showSnackBar('Incontinence entry saved.', Colors.green);
      HapticUtils.success();
      Navigator.of(context).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving incontinence entry: $e');
      _showSnackBar('Failed to save. Please try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormSheetHeader(title: 'Log Incontinence'),
          const SizedBox(height: 20),

          // ── Type ───────────────────────────────────────────
          _SectionLabel('Type'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Urinary', 'urinary', _selectedType,
                  Icons.water_drop_outlined, const Color(0xFF1E88E5)),
              _chip('Bowel', 'bowel', _selectedType,
                  Icons.circle, const Color(0xFF795548)),
              _chip('Both', 'both', _selectedType,
                  Icons.warning_amber_outlined, const Color(0xFFF57C00)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Severity ───────────────────────────────────────
          _SectionLabel('Severity'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _severityChip('Light', 'light', 'Pad change',
                  const Color(0xFF43A047)),
              _severityChip('Moderate', 'moderate', 'Clothing change',
                  const Color(0xFFF57C00)),
              _severityChip('Heavy', 'heavy', 'Full change',
                  const Color(0xFFE53935)),
            ],
          ),
          const SizedBox(height: 20),

          // ── Skin Check ─────────────────────────────────────
          _SectionLabel('Skin Check'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _skinChip('Healthy', 'healthy', const Color(0xFF43A047)),
              _skinChip('Pink / Red', 'irritated', const Color(0xFFF57C00)),
              _skinChip('Broken / Sore', 'broken', const Color(0xFFE53935)),
              _skinChip('Not Checked', 'notChecked', Colors.grey),
            ],
          ),
          const SizedBox(height: 20),

          // ── Changed toggle ─────────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Clothing / bedding changed',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _changed,
            onChanged: (v) => setState(() => _changed = v),
            activeColor: _accentColor,
          ),
          const SizedBox(height: 8),

          // ── Notes ──────────────────────────────────────────
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Anything unusual to note...',
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // ── Save button ────────────────────────────────────
          ElevatedButton(
            onPressed: _canSave && !_isSaving ? _handleSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── Chip builders ───────────────────────────────────────────────

  Widget _chip(String label, String value, String? selected,
      IconData icon, Color color) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                )),
          ],
        ),
      ),
    );
  }

  Widget _severityChip(
      String label, String value, String hint, Color color) {
    final isSelected = _selectedSeverity == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSeverity = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                )),
            Text(hint,
                style: TextStyle(
                    fontSize: 10,
                    color: isSelected ? color.withValues(alpha: 0.7) : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _skinChip(String label, String value, Color color) {
    final isSelected = _selectedSkin == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedSkin = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (value == 'broken' && isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(Icons.warning_amber, size: 14, color: color),
              ),
            Text(label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                )),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ));
  }
}
