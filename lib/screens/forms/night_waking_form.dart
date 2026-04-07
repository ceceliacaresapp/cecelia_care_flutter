// lib/screens/forms/night_waking_form.dart
//
// Night waking log: time woke, duration, cause, intervention, returned to
// sleep. Critical for dementia/Alzheimer's tracking.

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

class NightWakingForm extends StatefulWidget {
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const NightWakingForm({
    super.key,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<NightWakingForm> createState() => _NightWakingFormState();
}

class _NightWakingFormState extends State<NightWakingForm> {
  TimeOfDay _timeWoke = TimeOfDay.now();
  String? _duration;
  String? _cause;
  final Set<String> _interventions = {};
  bool _returnedToSleep = true;
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;

  static const Color _accent = Color(0xFF283593);

  static const List<String> _durationOptions = [
    '< 15 min', '15\u201330 min', '30\u201360 min', '1\u20132 hours', '2+ hours',
  ];

  static const List<String> _causeOptions = [
    'Confusion / disorientation',
    'Pain / discomfort',
    'Bathroom',
    'Hunger / thirst',
    'Nightmare / agitation',
    'Noise / environment',
    'Unknown',
  ];

  static const List<String> _interventionOptions = [
    'Verbal reassurance',
    'Bathroom assist',
    'Repositioned',
    'Medication given',
    'Walked with them',
    'Sat with them',
    'Offered water / snack',
    'None needed',
  ];

  bool get _canSave => _duration != null && _cause != null;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

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
        'timeWoke': '${_timeWoke.hour.toString().padLeft(2, '0')}:${_timeWoke.minute.toString().padLeft(2, '0')}',
        'duration': _duration,
        'cause': _cause,
        'interventions': _interventions.toList(),
        'returnedToSleep': _returnedToSleep,
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
      await journal.addJournalEntry('nightWaking', payload, user.uid);
      _showSnackBar('Night waking entry saved.', Colors.green);
      HapticUtils.success();
      Navigator.of(context, rootNavigator: true).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving night waking: $e');
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          24, 8, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormSheetHeader(title: 'Log Night Waking'),
          const SizedBox(height: 20),

          // ── Time Woke ──────────────────────────────────────
          _label('Time Woke'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _timeWoke,
              );
              if (picked != null) setState(() => _timeWoke = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: _accent),
                  const SizedBox(width: 8),
                  Text(
                    _timeWoke.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Duration ───────────────────────────────────────
          _label('Duration Awake'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _durationOptions.map((d) => _chip(
                d, _duration == d, () => setState(() => _duration = d))).toList(),
          ),
          const SizedBox(height: 20),

          // ── Cause ──────────────────────────────────────────
          _label('Cause'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _causeOptions.map((c) => _chip(
                c, _cause == c, () => setState(() => _cause = c))).toList(),
          ),
          const SizedBox(height: 20),

          // ── Intervention ───────────────────────────────────
          _label('Intervention (select all that apply)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _interventionOptions.map((i) {
              final selected = _interventions.contains(i);
              return _chip(i, selected, () {
                setState(() {
                  if (selected) _interventions.remove(i);
                  else _interventions.add(i);
                });
              });
            }).toList(),
          ),
          const SizedBox(height: 20),

          // ── Returned to sleep ──────────────────────────────
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Returned to sleep',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            value: _returnedToSleep,
            onChanged: (v) => setState(() => _returnedToSleep = v),
            activeColor: _accent,
          ),
          const SizedBox(height: 8),

          // ── Notes ──────────────────────────────────────────
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Any observations...',
            ),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),

          // ── Cancel + Save ──────────────────────────────────
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
                        borderRadius: BorderRadius.circular(12)),
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
                    backgroundColor: _accent,
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

  Widget _label(String text) => Text(text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ));

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? _accent : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? _accent : Colors.grey.shade700,
            )),
      ),
    );
  }
}
