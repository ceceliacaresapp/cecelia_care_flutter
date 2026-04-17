// lib/screens/forms/incontinence_form.dart
//
// Clinical incontinence tracker: type, severity, skin condition check,
// clothing/bedding changed toggle, and notes. Follows the pain_form pattern.

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/form_section_divider.dart';
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
  int? _bristolType; // 1-7
  String? _urineColor; // see _urineSwatches keys
  bool _changed = true;
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;

  static const Color _accentColor = AppTheme.tileBrown;

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
        if (_bristolType != null) 'bristolType': _bristolType,
        if (_urineColor != null) 'urineColor': _urineColor,
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
      Navigator.of(context, rootNavigator: true).pop();
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
          FormSectionHeader(label: 'Type', color: _accentColor),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Urinary', 'urinary', _selectedType,
                  Icons.water_drop_outlined, AppTheme.tileBlue),
              _chip('Bowel', 'bowel', _selectedType,
                  Icons.circle, AppTheme.tileBrown),
              _chip('Both', 'both', _selectedType,
                  Icons.warning_amber_outlined, AppTheme.tileOrange),
            ],
          ),
          const FormSectionDivider(),

          // ── Bristol Stool Scale (bowel/both) ───────────────
          if (_selectedType == 'bowel' || _selectedType == 'both') ...[
            FormSectionHeader(label: 'Bristol Stool Scale', color: _accentColor),
            const SizedBox(height: 8),
            ..._bristolEntries.map(_bristolRow),
            const SizedBox(height: 20),
          ],

          // ── Urine Color (urinary/both) ─────────────────────
          if (_selectedType == 'urinary' || _selectedType == 'both') ...[
            FormSectionHeader(label: 'Urine Color', color: _accentColor),
            const SizedBox(height: 8),
            SizedBox(
              height: 76,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _urineSwatches.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _urineSwatch(_urineSwatches[i]),
              ),
            ),
            if (_urineColor != null) ...[
              const SizedBox(height: 6),
              Builder(builder: (_) {
                final s = _urineSwatches
                    .firstWhere((e) => e.id == _urineColor);
                final isAlert = s.isWarning;
                return Row(
                  children: [
                    if (isAlert)
                      Icon(Icons.warning_amber,
                          size: 14, color: AppTheme.dangerColor),
                    if (isAlert) const SizedBox(width: 4),
                    Text(
                      s.meaning,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isAlert
                            ? AppTheme.dangerColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ],
            const SizedBox(height: 20),
          ],

          // ── Severity ───────────────────────────────────────
          const FormSectionDivider(),
          FormSectionHeader(label: 'Severity', color: _accentColor),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _severityChip('Light', 'light', 'Pad change',
                  AppTheme.statusGreen),
              _severityChip('Moderate', 'moderate', 'Clothing change',
                  AppTheme.tileOrange),
              _severityChip('Heavy', 'heavy', 'Full change',
                  AppTheme.statusRed),
            ],
          ),
          const SizedBox(height: 20),

          // ── Skin Check ─────────────────────────────────────
          const FormSectionDivider(),
          FormSectionHeader(label: 'Skin Check', color: _accentColor),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _skinChip('Healthy', 'healthy', AppTheme.statusGreen),
              _skinChip('Pink / Red', 'irritated', AppTheme.tileOrange),
              _skinChip('Broken / Sore', 'broken', AppTheme.statusRed),
              _skinChip('Not Checked', 'notChecked', Colors.grey),
            ],
          ),
          const SizedBox(height: 20),

          // ── Changed toggle ─────────────────────────────────
          const FormSectionDivider(),
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
          const FormSectionDivider(),
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

          // ── Cancel + Save buttons ──────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSaving
                      ? null
                      : () => Navigator.of(context, rootNavigator: true).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.textSecondary,
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _canSave && !_isSaving ? _handleSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusM)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
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
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
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
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
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

  // ── Bristol scale ──────────────────────────────────────────────

  static const List<_BristolEntry> _bristolEntries = [
    _BristolEntry(1, 'Hard lumps', 'Separate hard lumps (severe constipation)', AppTheme.tileOrangeDeep),
    _BristolEntry(2, 'Lumpy sausage', 'Lumpy and sausage-shaped (mild constipation)', AppTheme.tileOrange),
    _BristolEntry(3, 'Cracked sausage', 'Sausage with cracks on surface (normal)', Color(0xFF66BB6A)),
    _BristolEntry(4, 'Smooth snake', 'Smooth and soft (normal, ideal)', AppTheme.statusGreen),
    _BristolEntry(5, 'Soft blobs', 'Soft blobs with clear edges (lacking fiber)', Color(0xFFFFB300)),
    _BristolEntry(6, 'Mushy', 'Fluffy, mushy with ragged edges (mild diarrhea)', Color(0xFFEF6C00)),
    _BristolEntry(7, 'Liquid', 'Entirely liquid, no solid pieces (severe diarrhea)', AppTheme.statusRed),
  ];

  Widget _bristolRow(_BristolEntry e) {
    final isSelected = _bristolType == e.type;
    return GestureDetector(
      onTap: () => setState(() => _bristolType = e.type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? e.color.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(
            color: isSelected ? e.color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: e.color,
                shape: BoxShape.circle,
              ),
              child: Text('${e.type}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  )),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? e.color : Colors.grey.shade800,
                      )),
                  Text(e.description,
                      style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? e.color.withValues(alpha: 0.8)
                              : Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: e.color, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Urine color chart ──────────────────────────────────────────

  static const List<_UrineSwatch> _urineSwatches = [
    _UrineSwatch('clear', 'Clear', Color(0xFFF5F5F0), 'Well hydrated'),
    _UrineSwatch('paleYellow', 'Pale yellow', Color(0xFFFFFDE7), 'Normal'),
    _UrineSwatch('yellow', 'Yellow', Color(0xFFFFF9C4), 'Normal'),
    _UrineSwatch('darkYellow', 'Dark yellow', Color(0xFFFFEB3B), 'Mild dehydration'),
    _UrineSwatch('amber', 'Amber', AppTheme.tileGold, 'Dehydrated'),
    _UrineSwatch('orange', 'Orange', Color(0xFFFF9800), 'Very dehydrated'),
    _UrineSwatch('pink', 'Pink / red', Color(0xFFEF9A9A), 'Blood — contact doctor', isWarning: true),
    _UrineSwatch('brown', 'Brown', AppTheme.tileBrown, 'Liver/kidney concern — contact doctor', isWarning: true),
  ];

  Widget _urineSwatch(_UrineSwatch s) {
    final isSelected = _urineColor == s.id;
    return GestureDetector(
      onTap: () => setState(() => _urineColor = s.id),
      child: SizedBox(
        width: 60,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: s.color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade400,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check, color: Colors.white, size: 22),
                if (s.isWarning && !isSelected)
                  Positioned(
                    top: 0,
                    right: 4,
                    child: Icon(Icons.warning_amber,
                        size: 14, color: AppTheme.dangerColor),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              s.label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryColor
                    : Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _BristolEntry {
  final int type;
  final String label;
  final String description;
  final Color color;
  const _BristolEntry(this.type, this.label, this.description, this.color);
}

class _UrineSwatch {
  final String id;
  final String label;
  final Color color;
  final String meaning;
  final bool isWarning;
  const _UrineSwatch(this.id, this.label, this.color, this.meaning,
      {this.isWarning = false});
}

// _SectionLabel removed — replaced by shared FormSectionHeader
