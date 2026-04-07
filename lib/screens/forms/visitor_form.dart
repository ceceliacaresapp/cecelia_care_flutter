// lib/screens/forms/visitor_form.dart
//
// Visitor & stimulus log: who visited, how long, and how the care recipient
// responded. Builds a record of which people calm vs. agitate — useful for
// dementia/sundowning management.

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

class VisitorForm extends StatefulWidget {
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const VisitorForm({
    super.key,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<VisitorForm> createState() => _VisitorFormState();
}

class _VisitorFormState extends State<VisitorForm> {
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _relationship;
  String? _duration;
  String? _response;
  final Set<String> _activities = {};
  TimeOfDay _visitTime = TimeOfDay.now();
  bool _isSaving = false;

  static const Color _accent = Color(0xFF6A1B9A);

  static const List<String> _relationships = [
    'Family',
    'Friend',
    'Neighbor',
    'Home health aide',
    'Therapist',
    'Clergy / spiritual',
    'Other',
  ];

  static const List<String> _durations = [
    '< 15 min',
    '15\u201330 min',
    '30\u201360 min',
    '1\u20132 hours',
    '2+ hours',
  ];

  static const List<_ResponseOption> _responses = [
    _ResponseOption('positive', 'Positive / engaged',
        'Smiled, talked, participated', Color(0xFF43A047)),
    _ResponseOption('neutral', 'Neutral / calm',
        'No change in demeanor', Color(0xFF1E88E5)),
    _ResponseOption('agitated', 'Agitated / anxious',
        'Restless, irritable, raised voice', Color(0xFFF57C00)),
    _ResponseOption('withdrawn', 'Withdrawn / unresponsive',
        'Shut down, would not engage', Color(0xFF757575)),
    _ResponseOption('confused', 'Confused / disoriented',
        'Did not recognize visitor', Color(0xFFEF6C00)),
  ];

  static const List<String> _activityOptions = [
    'Conversation',
    'Watched TV',
    'Played games',
    'Looked at photos',
    'Went outside',
    'Ate together',
    'Music / singing',
    'Just sat together',
  ];

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _relationship != null &&
      _duration != null &&
      _response != null;

  @override
  void dispose() {
    _nameCtrl.dispose();
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
        'visitorName': _nameCtrl.text.trim(),
        'relationship': _relationship,
        'duration': _duration,
        'response': _response,
        'activities': _activities.toList(),
        'note': _noteCtrl.text.trim(),
        'visitTime':
            '${_visitTime.hour.toString().padLeft(2, '0')}:${_visitTime.minute.toString().padLeft(2, '0')}',
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
      await journal.addJournalEntry('visitor', payload, user.uid);
      _showSnackBar('Visitor log saved.', Colors.green);
      HapticUtils.success();
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving visitor log: $e');
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
          const FormSheetHeader(title: 'Log Visitor'),
          const SizedBox(height: 20),

          // ── Visitor name ───────────────────────────────────
          _label('Visitor Name'),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. Aunt Susan',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          // ── Relationship ───────────────────────────────────
          _label('Relationship'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _relationships
                .map((r) => _chip(r, _relationship == r,
                    () => setState(() => _relationship = r)))
                .toList(),
          ),
          const SizedBox(height: 20),

          // ── Visit time ─────────────────────────────────────
          _label('Visit Time'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: _visitTime,
              );
              if (picked != null) setState(() => _visitTime = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 18, color: _accent),
                  const SizedBox(width: 8),
                  Text(_visitTime.format(context),
                      style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Duration ───────────────────────────────────────
          _label('Duration'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _durations
                .map((d) => _chip(d, _duration == d,
                    () => setState(() => _duration = d)))
                .toList(),
          ),
          const SizedBox(height: 20),

          // ── Response ───────────────────────────────────────
          _label('Recipient\'s Response'),
          const SizedBox(height: 8),
          Column(
            children: _responses.map(_responseRow).toList(),
          ),
          const SizedBox(height: 20),

          // ── Activities ─────────────────────────────────────
          _label('Activities (select all that apply)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _activityOptions.map((a) {
              final selected = _activities.contains(a);
              return _chip(a, selected, () {
                setState(() {
                  if (selected) {
                    _activities.remove(a);
                  } else {
                    _activities.add(a);
                  }
                });
              });
            }).toList(),
          ),
          const SizedBox(height: 20),

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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _responseRow(_ResponseOption r) {
    final isSelected = _response == r.id;
    return GestureDetector(
      onTap: () => setState(() => _response = r.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? r.color.withValues(alpha: 0.12)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? r.color : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: r.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: isSelected ? r.color : Colors.grey.shade800,
                      )),
                  Text(r.hint,
                      style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? r.color.withValues(alpha: 0.8)
                              : Colors.grey.shade600)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: r.color, size: 18),
          ],
        ),
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
          color: selected
              ? _accent.withValues(alpha: 0.12)
              : Colors.grey.shade100,
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

class _ResponseOption {
  final String id;
  final String label;
  final String hint;
  final Color color;
  const _ResponseOption(this.id, this.label, this.hint, this.color);
}
