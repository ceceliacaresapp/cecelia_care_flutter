// lib/screens/forms/handoff_form.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/widgets/form_sheet_header.dart';

const _kHandoffColor = Color(0xFF00897B);

class HandoffForm extends StatefulWidget {
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const HandoffForm({
    super.key,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<HandoffForm> createState() => _HandoffFormState();
}

class _HandoffFormState extends State<HandoffForm> {
  final _formKey = GlobalKey<FormState>();

  final _completedCtrl = TextEditingController();
  final _pendingCtrl = TextEditingController();
  final _concernsCtrl = TextEditingController();

  String? _shift; // null = not selected
  bool _isSaving = false;

  static const _shiftOptions = [
    'Morning',
    'Afternoon',
    'Evening',
    'Overnight',
  ];

  @override
  void dispose() {
    _completedCtrl.dispose();
    _pendingCtrl.dispose();
    _concernsCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final journal = context.read<JournalServiceProvider>();
      final user = AuthService.currentUser;
      if (user == null) {
        _showSnackBar('Not authenticated.', Colors.red);
        return;
      }
      final payload = <String, dynamic>{
        'shift': _shift ?? '',
        'completed': _completedCtrl.text.trim(),
        'pending': _pendingCtrl.text.trim(),
        'concerns': _concernsCtrl.text.trim(),
        'stamp': Timestamp.now(),
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'date': widget.currentDate,
        'elderId': widget.activeElder.id,
        'loggedByUserId': user.uid,
        'loggedBy': user.displayName ?? user.email ?? 'Unknown',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
      };
      await journal.addJournalEntry('handoff', payload, user.uid);
      HapticUtils.success();
      if (mounted) {
        _showSnackBar('Handoff note saved.', Colors.green);
        Navigator.of(context, rootNavigator: true).pop();
        widget.onClose?.call();
      }
    } catch (e) {
      debugPrint('Error saving handoff note: $e');
      if (mounted) _showSnackBar('Failed to save. Please try again.', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSheetHeader(
          title: 'Shift Handoff',
          isSaving: _isSaving,
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shift selector
                  _SectionLabel('Shift (optional)', theme),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _shift,
                    decoration: const InputDecoration(
                      hintText: 'Select shift',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wb_sunny_outlined,
                          color: _kHandoffColor),
                    ),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('— Not specified —')),
                      ..._shiftOptions.map((s) =>
                          DropdownMenuItem(value: s, child: Text(s))),
                    ],
                    onChanged: (val) => setState(() => _shift = val),
                  ),

                  const SizedBox(height: 20),

                  // Tasks completed
                  _SectionLabel('Tasks Completed *', theme),
                  const SizedBox(height: 4),
                  Text(
                    'What was done during this shift',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _completedCtrl,
                    maxLines: 4,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Gave morning meds, assisted with breakfast, helped with shower…',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please describe what was completed.'
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // Tasks pending
                  _SectionLabel('Tasks Pending *', theme),
                  const SizedBox(height: 4),
                  Text(
                    'What still needs to be done',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pendingCtrl,
                    maxLines: 4,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Evening meds at 8 pm, bedtime routine, laundry in dryer…',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please list pending tasks.'
                        : null,
                  ),

                  const SizedBox(height: 20),

                  // Concerns / Notes
                  _SectionLabel('Concerns / Notes *', theme),
                  const SizedBox(height: 4),
                  Text(
                    'Anything the next caregiver should know',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _concernsCtrl,
                    maxLines: 4,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'e.g. Seemed more confused than usual, refused lunch, visitor coming tomorrow at 2 pm…',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please add at least one concern or note.'
                        : null,
                  ),

                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Btn(
                        title: 'Cancel',
                        variant: BtnVariant.secondaryOutline,
                        onPressed: _isSaving
                            ? null
                            : () {
                                Navigator.of(context, rootNavigator: true).pop();
                                widget.onClose?.call();
                              },
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      const SizedBox(width: 12),
                      Btn(
                        title: 'Save Handoff',
                        onPressed: _isSaving ? null : _handleSave,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.theme);
  final String text;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: theme.textTheme.bodyLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: _kHandoffColor,
      ),
    );
  }
}
