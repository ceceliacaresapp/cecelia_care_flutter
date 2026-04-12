// lib/screens/behavioral_log_screen.dart
//
// Log and review observable dementia-related behaviors with clinical detail:
// type, severity, triggers, de-escalation techniques, and outcomes.

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/models/behavioral_entry.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/skeleton_loaders.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/form_sheet_header.dart';
import 'package:cecelia_care_flutter/widgets/empty_state_widget.dart';

class BehavioralLogScreen extends StatefulWidget {
  const BehavioralLogScreen({super.key});

  @override
  State<BehavioralLogScreen> createState() => _BehavioralLogScreenState();
}

class _BehavioralLogScreenState extends State<BehavioralLogScreen> {
  final FirestoreService _firestore = FirestoreService();

  void _openLogForm() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.92,
        ),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _BehavioralLogForm(firestore: _firestore),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final elderId =
        context.watch<ActiveElderProvider>().activeElder?.id ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Behavioral Log')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openLogForm,
        backgroundColor: AppTheme.tileOrangeDeep,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: elderId.isEmpty
          ? const Center(child: Text('No care recipient selected.'))
          : _buildHistory(elderId),
    );
  }

  Widget _buildHistory(String elderId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestore.getBehavioralEntriesStream(elderId),
      builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Something went wrong.',
                      style: TextStyle(color: Colors.red)));
                }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(4, (_) => const SkeletonListTile()),
            ),
          );
        }

        final entries = (snapshot.data ?? [])
            .map((raw) =>
                BehavioralEntry.fromFirestore(raw['id'] as String? ?? '', raw))
            .toList();

        if (entries.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.psychology_outlined,
            title: 'No behaviors logged',
            subtitle: 'Tracking patterns helps identify triggers.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: entries.length,
          itemBuilder: (_, i) => _buildEntryCard(entries[i]),
        );
      },
    );
  }

  Widget _buildEntryCard(BehavioralEntry entry) {
    final dateStr = entry.createdAt != null
        ? DateFormat('MMM d, yyyy').format(entry.createdAt!.toDate())
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Severity color bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: entry.severityColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: type + severity
                    Row(
                      children: [
                        Expanded(
                          child: Text(entry.behaviorType,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: entry.severityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.severityLabel} ${entry.severity}/5',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: entry.severityColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Time + duration
                    Text(
                      '${entry.timeOfDay}${entry.durationLabel.isNotEmpty ? ' \u00B7 ~${entry.durationLabel}' : ''}',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                    // Trigger
                    if (entry.trigger != null && entry.trigger!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            const Text('\uD83C\uDFAF ',
                                style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Text(entry.trigger!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    // Technique
                    if (entry.deEscalationTechnique != null &&
                        entry.deEscalationTechnique!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Text('\uD83D\uDEE1\uFE0F ',
                                style: TextStyle(fontSize: 12)),
                            Expanded(
                              child: Text(entry.deEscalationTechnique!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    // Outcome
                    if (entry.outcome != null && entry.outcome!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Text(
                              entry.outcome!.contains('crisis') ||
                                      entry.outcome!.contains('not fully')
                                  ? '\u26A0\uFE0F '
                                  : '\u2713 ',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Expanded(
                              child: Text(entry.outcome!,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    // Notes
                    if (entry.notes != null && entry.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(entry.notes!,
                            style: TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    const SizedBox(height: 4),
                    Text('$dateStr \u00B7 by ${entry.loggedByName}',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textLight)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Log Form ──────────────────────────────────────────────────────

class _BehavioralLogForm extends StatefulWidget {
  const _BehavioralLogForm({required this.firestore});
  final FirestoreService firestore;

  @override
  State<_BehavioralLogForm> createState() => _BehavioralLogFormState();
}

class _BehavioralLogFormState extends State<_BehavioralLogForm> {
  String? _selectedType;
  int? _severity;
  int? _durationMinutes;
  String? _selectedTrigger;
  String? _selectedTechnique;
  String? _selectedOutcome;
  DateTime _episodeTime = DateTime.now();
  final _notesCtrl = TextEditingController();
  bool _isSaving = false;

  bool get _canSave => _selectedType != null && _severity != null;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final elderId =
          context.read<ActiveElderProvider>().activeElder?.id ?? '';
      if (elderId.isEmpty) return;

      final data = BehavioralEntry(
        elderId: elderId,
        behaviorType: _selectedType!,
        severity: _severity!,
        durationMinutes: _durationMinutes,
        trigger: _selectedTrigger,
        deEscalationTechnique: _selectedTechnique,
        outcome: _selectedOutcome,
        timeOfDay: DateFormat('HH:mm').format(_episodeTime),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        loggedBy: user.uid,
        loggedByName: user.displayName ?? user.email ?? 'Unknown',
      ).toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await widget.firestore.addBehavioralEntry(elderId, data);
      HapticUtils.success();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Behavioral observation saved.'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint('Behavioral log save error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to save. Please try again.'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FormSheetHeader(title: 'Log Behavioral Observation'),
          const SizedBox(height: 16),

          // ── Behavior Type ──────────────────────────────────
          _label('Behavior Type *'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BehavioralEntry.kBehaviorTypes
                .map((t) => _selectionChip(
                    t, _selectedType == t, () => setState(() => _selectedType = t),
                    AppTheme.tileOrangeDeep))
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── Severity ───────────────────────────────────────
          _label('Severity *'),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (i) {
              final s = i + 1;
              final isSelected = _severity == s;
              final color = BehavioralEntry(
                elderId: '', behaviorType: '', severity: s,
                timeOfDay: '', loggedBy: '', loggedByName: '',
              ).severityColor;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _severity = s),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 4 ? 6 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? color : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text('$s',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? color : Colors.grey.shade500,
                        )),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),

          // ── Time ───────────────────────────────────────────
          Row(
            children: [
              _label('Time of Episode'),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_episodeTime),
                  );
                  if (picked != null) {
                    setState(() {
                      _episodeTime = DateTime(
                        _episodeTime.year, _episodeTime.month,
                        _episodeTime.day, picked.hour, picked.minute,
                      );
                    });
                  }
                },
                child: Text(DateFormat('h:mm a').format(_episodeTime)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Duration ───────────────────────────────────────
          _label('Duration (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(5, (i) {
              final mins = BehavioralEntry.kDurationOptions[i];
              final label = BehavioralEntry.kDurationLabels[i];
              return _selectionChip(
                  label, _durationMinutes == mins,
                  () => setState(() => _durationMinutes = mins),
                  AppTheme.textSecondary);
            }),
          ),
          const SizedBox(height: 16),

          // ── Trigger ────────────────────────────────────────
          _label('Trigger (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BehavioralEntry.kCommonTriggers
                .map((t) => _selectionChip(
                    t, _selectedTrigger == t,
                    () => setState(() => _selectedTrigger = t),
                    AppTheme.tileBlueDark))
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── Technique ──────────────────────────────────────
          _label('De-escalation Technique (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BehavioralEntry.kTechniques
                .map((t) => _selectionChip(
                    t, _selectedTechnique == t,
                    () => setState(() => _selectedTechnique = t),
                    AppTheme.tileTeal))
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── Outcome ────────────────────────────────────────
          _label('Outcome (optional)'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: BehavioralEntry.kOutcomes
                .map((t) => _selectionChip(
                    t, _selectedOutcome == t,
                    () => setState(() => _selectedOutcome = t),
                    const Color(0xFF5D4037)))
                .toList(),
          ),
          const SizedBox(height: 16),

          // ── Notes ──────────────────────────────────────────
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              hintText: 'Describe what happened...',
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),

          // ── Save ───────────────────────────────────────────
          ElevatedButton(
            onPressed: _canSave && !_isSaving ? _handleSave : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tileOrangeDeep,
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary));

  Widget _selectionChip(String label, bool selected, VoidCallback onTap, Color color) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              color: selected ? color : null,
            )),
      ),
    );
  }
}
