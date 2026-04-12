// lib/screens/discharge_checklist_screen.dart
//
// Hospital-to-home discharge wizard. Four sections:
//   1. Discharge step checklist
//   2. Medication reconciliation (compares pre-hospital meds vs discharge)
//   3. Home safety re-assessment
//   4. Follow-up appointment scheduler (creates calendar events)
//
// Persists incrementally to elderProfiles/{elderId}/dischargeChecklists.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/models/calendar_event.dart';
import 'package:cecelia_care_flutter/models/discharge_checklist.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class DischargeChecklistScreen extends StatefulWidget {
  const DischargeChecklistScreen({super.key});

  @override
  State<DischargeChecklistScreen> createState() =>
      _DischargeChecklistScreenState();
}

class _DischargeChecklistScreenState extends State<DischargeChecklistScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestore = FirestoreService();
  late final TabController _tab;

  String? _checklistId;
  String _facilityName = '';
  String _dischargeDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final Map<String, bool> _steps = {};
  final Map<String, bool> _safety = {};
  final List<_MedRecon> _medRecon = [];
  final List<_FollowUp> _followUps = [];
  bool _initialized = false;
  bool _saving = false;

  static const Color _accent = AppTheme.tileBlueDark;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
    // Pre-populate common follow-up types.
    for (final f in DischargeChecklist.kFollowUpTypes) {
      _followUps.add(_FollowUp(
        type: f['type']!,
        label: f['label']!,
      ));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _initFromMeds());
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _initFromMeds() {
    if (_initialized) return;
    final meds = context.read<MedicationDefinitionsProvider>().medDefinitions;
    setState(() {
      for (final m in meds) {
        _medRecon.add(_MedRecon(
          name: m.name,
          oldDose: m.dose ?? '',
          newDose: m.dose ?? '',
          status: 'continued',
          existingId: m.id,
        ));
      }
      _initialized = true;
    });
  }

  double get _stepsProgress =>
      DischargeChecklist.kDischargeSteps.isEmpty
          ? 0
          : _steps.values.where((v) => v).length /
              DischargeChecklist.kDischargeSteps.length;

  double get _safetyProgress =>
      DischargeChecklist.kSafetyChecks.isEmpty
          ? 0
          : _safety.values.where((v) => v).length /
              DischargeChecklist.kSafetyChecks.length;

  double get _medProgress => _medRecon.isEmpty ? 0 : 1;

  double get _followProgress {
    if (_followUps.isEmpty) return 0;
    final scheduled =
        _followUps.where((f) => f.scheduledDate != null).length;
    return scheduled / _followUps.length;
  }

  double get _overallProgress =>
      (_stepsProgress + _safetyProgress + _medProgress + _followProgress) / 4;

  Future<void> _save({bool markComplete = false}) async {
    final elder = context.read<ActiveElderProvider>().activeElder;
    final user = FirebaseAuth.instance.currentUser;
    if (elder == null || user == null) return;

    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'createdBy': user.uid,
        'createdByName': user.displayName ?? user.email ?? 'Unknown',
        'dischargeDate': _dischargeDate,
        if (_facilityName.isNotEmpty) 'facilityName': _facilityName,
        'checklistSteps': _steps,
        'safetyChecks': _safety,
        'medChanges': _medRecon.map((m) => m.toMap()).toList(),
        'followUps': _followUps.map((f) => f.toMap()).toList(),
        'isComplete': markComplete,
      };
      if (_checklistId == null) {
        _checklistId =
            await _firestore.addDischargeChecklist(elder.id, data);
      } else {
        await _firestore.updateDischargeChecklist(
            elder.id, _checklistId!, data);
      }
      HapticUtils.success();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(markComplete ? 'Discharge plan complete' : 'Saved'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _applyMedChanges() async {
    final elder = context.read<ActiveElderProvider>().activeElder;
    if (elder == null) return;
    final medProv = context.read<MedicationDefinitionsProvider>();
    int added = 0, updated = 0;
    for (final m in _medRecon) {
      if (m.status == 'new' && m.existingId == null) {
        await medProv.addMedicationDefinition(
            name: m.name, dose: m.newDose, elderId: elder.id);
        added++;
      } else if (m.status == 'changed' &&
          m.existingId != null &&
          m.newDose != m.oldDose) {
        // Use addOrUpdate via provider — needs the original definition;
        // for simplicity, just write directly via firestore here.
        await FirebaseFirestore.instance
            .collection('medicationDefinitions')
            .doc(m.existingId)
            .update({'dose': m.newDose});
        updated++;
      }
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Applied: $added new, $updated dose changes'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _scheduleFollowUp(_FollowUp f) async {
    final elder = context.read<ActiveElderProvider>().activeElder;
    final user = FirebaseAuth.instance.currentUser;
    if (elder == null || user == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: f.scheduledDate ?? DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    final dt = DateTime(picked.year, picked.month, picked.day,
        time?.hour ?? 10, time?.minute ?? 0);
    try {
      final ref = await _firestore.addCalendarEvent(CalendarEvent(
        title: f.label,
        startDateTime: Timestamp.fromDate(dt),
        allDay: false,
        elderId: elder.id,
        eventType: 'appointment',
        createdBy: user.uid,
        createdByDisplayName:
            user.displayName ?? user.email ?? 'Unknown',
        notes: f.notes,
      ));
      setState(() {
        f.scheduledDate = dt;
        f.calendarEventId = ref.id;
      });
      HapticUtils.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not schedule: $e')),
        );
      }
    }
  }

  void _shareSummary() {
    final buf = StringBuffer();
    final elder = context.read<ActiveElderProvider>().activeElder;
    buf.writeln('🏥 Discharge Plan — ${elder?.profileName ?? "Care Recipient"}');
    buf.writeln('Discharge date: $_dischargeDate');
    if (_facilityName.isNotEmpty) buf.writeln('Facility: $_facilityName');
    buf.writeln('');
    buf.writeln(
        'Discharge steps: ${_steps.values.where((v) => v).length}/${DischargeChecklist.kDischargeSteps.length}');
    buf.writeln(
        'Home safety: ${_safety.values.where((v) => v).length}/${DischargeChecklist.kSafetyChecks.length}');
    buf.writeln('Medication reconciliation: ${_medRecon.length} meds reviewed');
    final scheduled =
        _followUps.where((f) => f.scheduledDate != null).length;
    buf.writeln('Follow-ups scheduled: $scheduled/${_followUps.length}');
    buf.writeln('');
    buf.writeln('Sent from Cecelia Care');
    Share.share(buf.toString(),
        subject: 'Discharge plan — ${elder?.profileName ?? ""}');
  }

  @override
  Widget build(BuildContext context) {
    final elder = context.watch<ActiveElderProvider>().activeElder;
    if (elder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Discharge Plan')),
        body: const Center(child: Text('No care recipient selected.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discharge Plan'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Share summary',
            onPressed: _shareSummary,
          ),
          IconButton(
            icon: const Icon(Icons.save_outlined),
            tooltip: 'Save',
            onPressed: _saving ? null : () => _save(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(82),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.task_alt,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 6),
                        Text(
                            'Overall ${(_overallProgress * 100).round()}% complete',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _overallProgress,
                        minHeight: 5,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              TabBar(
                controller: _tab,
                isScrollable: true,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'Steps (${(_stepsProgress * 100).round()}%)'),
                  Tab(text: 'Meds'),
                  Tab(text: 'Safety (${(_safetyProgress * 100).round()}%)'),
                  Tab(text: 'Follow-ups'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildStepsTab(),
          _buildMedsTab(),
          _buildSafetyTab(),
          _buildFollowUpsTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _save(),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save progress'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : () => _save(markComplete: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark complete'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Tab 1: Steps ────────────────────────────────────────────────
  Widget _buildStepsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _intakeCard(),
        const SizedBox(height: 8),
        ...DischargeChecklist.kDischargeSteps.map((s) {
          final id = s['id']!;
          final done = _steps[id] ?? false;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ExpansionTile(
              leading: Checkbox(
                value: done,
                activeColor: _accent,
                onChanged: (v) =>
                    setState(() => _steps[id] = v ?? false),
              ),
              title: Text(s['title']!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    decoration: done ? TextDecoration.lineThrough : null,
                    color: done ? AppTheme.textSecondary : null,
                  )),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(s['desc']!,
                      style: const TextStyle(fontSize: 12, height: 1.4)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _intakeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Discharge details',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Facility (optional)',
                hintText: 'e.g. Mass General Hospital',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => _facilityName = v,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.parse(_dischargeDate),
                      firstDate: DateTime.now()
                          .subtract(const Duration(days: 30)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 30)),
                    );
                    if (picked != null) {
                      setState(() => _dischargeDate =
                          DateFormat('yyyy-MM-dd').format(picked));
                    }
                  },
                  child: Text('Discharge date: $_dischargeDate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Tab 2: Meds ─────────────────────────────────────────────────
  Widget _buildMedsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'Compare the discharge medication list against pre-hospital meds. Mark each as continuing, dose changed, stopped, or new.',
            style: TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(height: 10),
        ..._medRecon.asMap().entries.map((e) {
          final i = e.key;
          final m = e.value;
          return _medReconCard(i, m);
        }),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _medRecon.add(_MedRecon(
                name: '',
                oldDose: '',
                newDose: '',
                status: 'new',
              ));
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add new medication from discharge'),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: _applyMedChanges,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
          ),
          icon: const Icon(Icons.sync),
          label: const Text('Apply changes to medication list'),
        ),
      ],
    );
  }

  Widget _medReconCard(int i, _MedRecon m) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: TextEditingController(text: m.name)
                ..selection = TextSelection.fromPosition(
                    TextPosition(offset: m.name.length)),
              decoration: const InputDecoration(
                labelText: 'Medication',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => m.name = v,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _statusChip(m, 'continued', 'Continuing',
                    AppTheme.statusGreen),
                _statusChip(m, 'changed', 'Dose changed',
                    AppTheme.tileOrange),
                _statusChip(
                    m, 'stopped', 'Stopped', AppTheme.statusRed),
                _statusChip(m, 'new', 'New', AppTheme.tileBlue),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: m.oldDose)
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: m.oldDose.length)),
                    decoration: const InputDecoration(
                      labelText: 'Pre-hospital dose',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => m.oldDose = v,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: m.newDose)
                      ..selection = TextSelection.fromPosition(
                          TextPosition(offset: m.newDose.length)),
                    decoration: const InputDecoration(
                      labelText: 'Discharge dose',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => m.newDose = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: TextEditingController(text: m.notes)
                ..selection = TextSelection.fromPosition(
                    TextPosition(offset: m.notes.length)),
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => m.notes = v,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _medRecon.removeAt(i)),
                icon: const Icon(Icons.delete_outline,
                    size: 16, color: AppTheme.dangerColor),
                label: const Text('Remove',
                    style: TextStyle(color: AppTheme.dangerColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(_MedRecon m, String value, String label, Color color) {
    final selected = m.status == value;
    return GestureDetector(
      onTap: () => setState(() => m.status = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              selected ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? color : Colors.grey.shade700,
            )),
      ),
    );
  }

  // ── Tab 3: Safety ───────────────────────────────────────────────
  Widget _buildSafetyTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: DischargeChecklist.kSafetyChecks.map((s) {
        final id = s['id']!;
        final done = _safety[id] ?? false;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: CheckboxListTile(
            value: done,
            activeColor: _accent,
            title: Text(s['title']!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: done ? TextDecoration.lineThrough : null,
                  color: done ? AppTheme.textSecondary : null,
                )),
            onChanged: (v) =>
                setState(() => _safety[id] = v ?? false),
          ),
        );
      }).toList(),
    );
  }

  // ── Tab 4: Follow-ups ───────────────────────────────────────────
  Widget _buildFollowUpsTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        ..._followUps.asMap().entries.map((e) {
          final i = e.key;
          final f = e.value;
          final scheduled = f.scheduledDate != null;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        scheduled
                            ? Icons.event_available
                            : Icons.event_outlined,
                        color: scheduled
                            ? AppTheme.statusGreen
                            : _accent,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(f.label,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: AppTheme.textLight),
                        onPressed: () =>
                            setState(() => _followUps.removeAt(i)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: TextEditingController(text: f.notes ?? '')
                      ..selection = TextSelection.fromPosition(TextPosition(
                          offset: (f.notes ?? '').length)),
                    decoration: const InputDecoration(
                      labelText: 'Notes (provider, location, prep)',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => f.notes = v,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (scheduled)
                        Expanded(
                          child: Text(
                            DateFormat('EEE MMM d • h:mm a')
                                .format(f.scheduledDate!),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.statusGreen),
                          ),
                        )
                      else
                        const Expanded(
                            child: Text('Not scheduled',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary))),
                      ElevatedButton.icon(
                        onPressed: () => _scheduleFollowUp(f),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: const Icon(Icons.calendar_today, size: 14),
                        label: Text(
                            scheduled ? 'Reschedule' : 'Add to calendar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _followUps.add(_FollowUp(
                  type: 'other', label: 'New follow-up'));
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add custom follow-up'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Local working models (mutable, used inside the wizard only)
// ─────────────────────────────────────────────────────────────

class _MedRecon {
  String name;
  String oldDose;
  String newDose;
  String status; // continued | changed | stopped | new
  String notes;
  String? existingId;

  _MedRecon({
    required this.name,
    required this.oldDose,
    required this.newDose,
    required this.status,
    this.notes = '',
    this.existingId,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'status': status,
        'oldDose': oldDose,
        'newDose': newDose,
        'notes': notes,
      };
}

class _FollowUp {
  String type;
  String label;
  String? notes;
  DateTime? scheduledDate;
  String? calendarEventId;

  _FollowUp({
    required this.type,
    required this.label,
    this.notes,
    this.scheduledDate,
    this.calendarEventId,
  });

  Map<String, dynamic> toMap() => {
        'type': type,
        'label': label,
        if (notes != null) 'notes': notes,
        if (scheduledDate != null)
          'scheduledDate': Timestamp.fromDate(scheduledDate!),
        if (calendarEventId != null) 'calendarEventId': calendarEventId,
      };
}
