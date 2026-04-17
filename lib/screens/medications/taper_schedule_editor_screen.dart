// lib/screens/medications/taper_schedule_editor_screen.dart
//
// Create / view / edit a single TaperSchedule. Three main regions:
//
//   1. Metadata — medication, prescriber, reason, doctor-approval toggle.
//   2. Step ladder — visual, reorderable list of dose ranges with
//      inline edit. Presets populate a blank schedule in one tap.
//   3. Calendar — month view where each day is colored by the current
//      step's dose, highlighting today and step boundaries.
//
// Reminders are scheduled through NotificationService.scheduleTaperReminders
// on save when `reminderEnabled` is true; they're cancelled automatically
// before every reschedule to avoid orphans.

import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/models/medication_definition.dart';
import 'package:cecelia_care_flutter/models/taper_schedule.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/services/ai_suggestion_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const Color _kAccent = AppTheme.tileOrange;
const Color _kAccentDeep = AppTheme.tileOrangeDeep;

class TaperScheduleEditorScreen extends StatefulWidget {
  const TaperScheduleEditorScreen({super.key, this.existingTaperId});

  /// When null, we're creating a new taper. When non-null, we hydrate
  /// from Firestore and allow edits.
  final String? existingTaperId;

  @override
  State<TaperScheduleEditorScreen> createState() =>
      _TaperScheduleEditorScreenState();
}

class _TaperScheduleEditorScreenState
    extends State<TaperScheduleEditorScreen> {
  // Current working copy — in-memory until the user taps Save.
  late TaperSchedule _plan;
  bool _hydrated = false;
  bool _isSaving = false;
  bool _hasChanges = false;

  // Controllers for text fields
  final _medNameCtrl = TextEditingController();
  final _prescriberCtrl = TextEditingController();
  final _reasonNoteCtrl = TextEditingController();

  MedicationDefinition? _linkedDef;

  @override
  void initState() {
    super.initState();
    _medNameCtrl.addListener(() {
      _plan = _plan.copyWith(medName: _medNameCtrl.text);
      _markChanged();
    });
    _prescriberCtrl.addListener(() {
      _plan = _plan.copyWith(prescriberName: _prescriberCtrl.text);
      _markChanged();
    });
    _reasonNoteCtrl.addListener(() {
      _plan = _plan.copyWith(reasonNote: _reasonNoteCtrl.text);
      _markChanged();
    });
  }

  @override
  void dispose() {
    _medNameCtrl.dispose();
    _prescriberCtrl.dispose();
    _reasonNoteCtrl.dispose();
    super.dispose();
  }

  void _markChanged() {
    if (!_hasChanges && mounted) setState(() => _hasChanges = true);
  }

  Future<void> _hydrate(String elderId) async {
    if (_hydrated) return;
    final existing = widget.existingTaperId;
    if (existing == null) {
      _plan = TaperSchedule.empty(elderId);
    } else {
      final loaded = await context
          .read<FirestoreService>()
          .getTaperSchedule(elderId: elderId, taperId: existing);
      _plan = loaded ?? TaperSchedule.empty(elderId);
      _medNameCtrl.text = _plan.medName;
      _prescriberCtrl.text = _plan.prescriberName;
      _reasonNoteCtrl.text = _plan.reasonNote ?? '';
    }
    _hydrated = true;
    if (mounted) setState(() {});
  }

  // ---------------------------------------------------------------------------
  // Save + delete
  // ---------------------------------------------------------------------------

  Future<void> _save() async {
    if (_isSaving) return;
    final issues = _plan.validate();
    if (issues.isNotEmpty) {
      _showValidationDialog(issues);
      return;
    }
    final elderProv = context.read<ActiveElderProvider>();
    final elder = elderProv.activeElder;
    if (elder == null) return;

    setState(() => _isSaving = true);

    final service = context.read<FirestoreService>();
    final user = FirebaseAuth.instance.currentUser;

    // Auto-activate when we have valid content + today is in window.
    final status = _plan.status == TaperStatus.draft && _plan.isTodayInWindow
        ? TaperStatus.active
        : _plan.status;

    final toSave = _plan.copyWith(
      status: status,
      createdByUid: _plan.createdByUid ?? user?.uid,
      createdByName: _plan.createdByName ?? user?.displayName,
      medDefId: _linkedDef?.id ?? _plan.medDefId,
    );

    try {
      String savedId;
      if (widget.existingTaperId == null && toSave.id.isEmpty) {
        savedId = await service.createTaperSchedule(toSave);
      } else {
        savedId = toSave.id.isEmpty
            ? await service.createTaperSchedule(toSave)
            : toSave.id;
        await service.updateTaperSchedule(toSave.copyWith(id: savedId));
      }

      final saved = toSave.copyWith(id: savedId);

      // (Re)schedule notifications if enabled, otherwise cancel.
      await _applyNotificationState(saved, elder.profileName);

      HapticUtils.success();
      if (!mounted) return;
      setState(() {
        _plan = saved;
        _hasChanges = false;
        _isSaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Taper schedule saved.'),
        backgroundColor: AppTheme.statusGreen,
      ));
    } catch (e) {
      debugPrint('TaperScheduleEditor save error: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save: $e'),
        backgroundColor: AppTheme.dangerColor,
      ));
    }
  }

  Future<void> _applyNotificationState(
      TaperSchedule saved, String elderName) async {
    if (!saved.reminderEnabled ||
        saved.startDate == null ||
        saved.endDate == null) {
      await NotificationService.instance.cancelTaperReminders(
        elderId: saved.elderId,
        taperId: saved.id,
      );
      return;
    }
    // Parse the reminder time.
    final parts = saved.reminderTime.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    await NotificationService.instance.scheduleTaperReminders(
      elderId: saved.elderId,
      taperId: saved.id,
      medName: saved.medName,
      elderName: elderName,
      startDate: saved.startDate!,
      endDate: saved.endDate!,
      reminderTime: TimeOfDay(hour: hour, minute: minute),
      bodyForDay: (day) {
        final step = saved.stepForDay(day);
        if (step == null) return '';
        return '${step.doseDisplay} — ${step.frequency}';
      },
    );
  }

  void _showValidationDialog(List<String> issues) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('A few details are missing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final i in issues)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: AppTheme.dangerColor),
                    const SizedBox(width: 8),
                    Expanded(child: Text(i)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (widget.existingTaperId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this taper?'),
        content: const Text(
          'The schedule and all its reminders will be removed. This '
          'cannot be undone.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final elder = context.read<ActiveElderProvider>().activeElder;
    final firestore = context.read<FirestoreService>();
    if (elder == null) return;
    try {
      await NotificationService.instance.cancelTaperReminders(
        elderId: elder.id,
        taperId: _plan.id,
      );
      await firestore.deleteTaperSchedule(
        elderId: elder.id,
        taperId: _plan.id,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      debugPrint('TaperScheduleEditor delete error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not delete: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Step editing
  // ---------------------------------------------------------------------------

  Future<void> _addStepDialog() async {
    final nextStart = _plan.steps.isEmpty
        ? DateTime.now()
        : _plan.steps.last.toDate.add(const Duration(days: 1));
    final template = TaperStep(
      fromDate: nextStart,
      toDate: nextStart.add(const Duration(days: 2)),
      dose: _plan.steps.isNotEmpty ? _plan.steps.last.dose : 5,
      doseUnit: _plan.steps.isNotEmpty ? _plan.steps.last.doseUnit : 'mg',
      frequency: _plan.steps.isNotEmpty
          ? _plan.steps.last.frequency
          : 'once daily',
    );
    final result = await _showStepDialog(template);
    if (result == null) return;
    setState(() {
      _plan = _plan.copyWith(steps: [..._plan.steps, result]);
      _hasChanges = true;
    });
  }

  Future<void> _editStep(int index) async {
    final step = _plan.steps[index];
    final result = await _showStepDialog(step);
    if (result == null) return;
    setState(() {
      final updated = [..._plan.steps];
      updated[index] = result;
      _plan = _plan.copyWith(steps: updated);
      _hasChanges = true;
    });
  }

  void _removeStep(int index) {
    setState(() {
      final updated = [..._plan.steps]..removeAt(index);
      _plan = _plan.copyWith(steps: updated);
      _hasChanges = true;
    });
  }

  Future<TaperStep?> _showStepDialog(TaperStep template) async {
    return showDialog<TaperStep>(
      context: context,
      builder: (ctx) => _StepEditorDialog(initial: template),
    );
  }

  void _applyPreset(TaperPreset preset) {
    final start = _plan.startDate ?? DateTime.now();
    setState(() {
      _plan = _plan.copyWith(
        steps: preset.materialize(start: start),
      );
      _hasChanges = true;
    });
    HapticUtils.selection();
  }

  // ---------------------------------------------------------------------------
  // AI suggestion (stub)
  // ---------------------------------------------------------------------------

  Future<void> _requestAiSuggestion() async {
    final elder = context.read<ActiveElderProvider>().activeElder;
    if (elder == null) return;
    final result = await AiSuggestionService.instance.suggestTaperSchedule(
      elderId: elder.id,
      elderDisplayName: elder.profileName,
      context: {
        'medName': _plan.medName,
        'startingDose': _plan.steps.isEmpty ? null : _plan.steps.first.dose,
        'doseUnit': _plan.steps.isEmpty ? null : _plan.steps.first.doseUnit,
        'reason': _plan.reason.firestoreValue,
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        result.errorMessage ??
            (result.suggestion ?? 'No suggestion returned.'),
      ),
      backgroundColor: result.available
          ? AppTheme.statusGreen
          : AppTheme.tileIndigoDark,
    ));
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final elderProv = context.watch<ActiveElderProvider>();
    final elder = elderProv.activeElder;
    final canEdit = elderProv.currentUserRole.canLog;

    if (elder == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Taper Schedule'),
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No care recipient selected.')),
      );
    }

    // Lazy hydrate on first build.
    if (!_hydrated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hydrated) _hydrate(elder.id);
      });
      return Scaffold(
        appBar: AppBar(
          title: const Text('Taper Schedule'),
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTaperId == null
            ? 'New Taper'
            : 'Edit Taper'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Share as PDF',
            onPressed: _plan.steps.isEmpty ? null : () => _sharePdf(elder),
          ),
          if (canEdit && widget.existingTaperId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete taper',
              onPressed: _confirmDelete,
            ),
          if (canEdit && _hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined,
                        color: Colors.white, size: 18),
                label: Text(
                  _isSaving ? 'Saving…' : 'Save',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _TodayCallout(plan: _plan),
          const SizedBox(height: 14),
          _MetaSection(
            plan: _plan,
            medNameCtrl: _medNameCtrl,
            prescriberCtrl: _prescriberCtrl,
            reasonNoteCtrl: _reasonNoteCtrl,
            readOnly: !canEdit,
            onReasonChanged: (r) {
              setState(() {
                _plan = _plan.copyWith(reason: r);
                _hasChanges = true;
              });
            },
            onMedicationPicked: (def) {
              setState(() {
                _linkedDef = def;
                _medNameCtrl.text = def.name;
                _plan = _plan.copyWith(
                  medName: def.name,
                  medDefId: def.id,
                );
                _hasChanges = true;
              });
            },
            onDoctorApprovedChanged: (v) {
              setState(() {
                _plan = _plan.copyWith(isDoctorApproved: v);
                _hasChanges = true;
              });
            },
          ),
          const SizedBox(height: 14),
          _StepLadderSection(
            plan: _plan,
            readOnly: !canEdit,
            onAdd: _addStepDialog,
            onEdit: _editStep,
            onRemove: _removeStep,
            onPreset: _applyPreset,
            onSuggest: _requestAiSuggestion,
          ),
          const SizedBox(height: 14),
          if (_plan.steps.isNotEmpty) ...[
            _CalendarSection(plan: _plan),
            const SizedBox(height: 14),
          ],
          _ReminderSection(
            plan: _plan,
            readOnly: !canEdit,
            onToggleReminder: (v) {
              setState(() {
                _plan = _plan.copyWith(reminderEnabled: v);
                _hasChanges = true;
              });
            },
            onPickTime: () async {
              final parts = _plan.reminderTime.split(':');
              final initial = parts.length == 2
                  ? TimeOfDay(
                      hour: int.tryParse(parts[0]) ?? 9,
                      minute: int.tryParse(parts[1]) ?? 0)
                  : const TimeOfDay(hour: 9, minute: 0);
              final picked = await showTimePicker(
                context: context,
                initialTime: initial,
              );
              if (picked == null || !mounted) return;
              setState(() {
                _plan = _plan.copyWith(
                  reminderTime:
                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
                );
                _hasChanges = true;
              });
            },
          ),
          const SizedBox(height: 14),
          if (_plan.id.isNotEmpty && canEdit)
            _StatusSection(
              current: _plan.status,
              onChange: (s) {
                setState(() {
                  _plan = _plan.copyWith(status: s);
                  _hasChanges = true;
                });
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF export
  // ---------------------------------------------------------------------------

  Future<void> _sharePdf(dynamic elder) async {
    try {
      final bytes = await _buildPdf(elder);
      final dir = await getTemporaryDirectory();
      final safeName =
          _plan.medName.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final file = File(
          '${dir.path}/Taper_${safeName.isEmpty ? 'schedule' : safeName}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Taper schedule — ${_plan.medName}',
      );
      HapticUtils.success();
    } catch (e) {
      debugPrint('Taper PDF error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  Future<Uint8List> _buildPdf(dynamic elder) async {
    final pdf = pw.Document();
    final elderName = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName
        : elder.profileName;
    final dateStamp = DateFormat('MMMM d, yyyy').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFF3E0'),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                  color: PdfColor.fromHex('#F57C00'), width: 0.8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'TAPERING SCHEDULE',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#E65100'),
                    letterSpacing: 2.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  _plan.medName,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('#BF360C'),
                  ),
                ),
                pw.SizedBox(height: 10),
                _pdfMeta('Patient', elderName as String),
                _pdfMeta('Prescribed by', _plan.prescriberName),
                _pdfMeta('Reason', _plan.reason.label),
                if (_plan.reasonNote != null &&
                    _plan.reasonNote!.isNotEmpty)
                  _pdfMeta('Notes', _plan.reasonNote!),
                _pdfMeta('Schedule', _plan.summary),
                _pdfMeta('Generated', dateStamp),
              ],
            ),
          ),
          pw.SizedBox(height: 18),
          pw.Text('DOSING STEPS',
              style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.4)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
                color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(0.6),
              1: pw.FlexColumnWidth(2.2),
              2: pw.FlexColumnWidth(1.4),
              3: pw.FlexColumnWidth(1.4),
              4: pw.FlexColumnWidth(1.2),
            },
            children: [
              pw.TableRow(
                decoration:
                    const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: ['#', 'Dates', 'Dose', 'Frequency', 'Days']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(h,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold)),
                        ))
                    .toList(),
              ),
              for (int i = 0; i < _plan.steps.length; i++)
                pw.TableRow(
                  children: [
                    pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('${i + 1}',
                            style: const pw.TextStyle(fontSize: 9))),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(
                        '${DateFormat('MMM d').format(_plan.steps[i].fromDate)} – '
                        '${DateFormat('MMM d').format(_plan.steps[i].toDate)}',
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_plan.steps[i].doseDisplay,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(_plan.steps[i].frequency,
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text('${_plan.steps[i].durationDays}',
                          style: const pw.TextStyle(fontSize: 9)),
                    ),
                  ],
                ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Reminder: Do not alter this schedule without speaking to the '
            'prescribing doctor. Abrupt changes to certain medications can '
            'cause serious withdrawal or symptom return.',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.blueGrey600,
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _pdfMeta(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 90,
            child: pw.Text('$label:',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey700,
                )),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sections
// ---------------------------------------------------------------------------

class _TodayCallout extends StatelessWidget {
  const _TodayCallout({required this.plan});
  final TaperSchedule plan;

  @override
  Widget build(BuildContext context) {
    final today = plan.todaysStep;
    final inWindow = plan.isTodayInWindow;

    if (!inWindow) {
      if (plan.startDate == null) {
        return const SizedBox.shrink();
      }
      final before = DateTime.now().isBefore(plan.startDate!);
      final msg = before
          ? 'Taper starts ${DateFormat('MMM d').format(plan.startDate!)}'
          : 'Taper ended ${DateFormat('MMM d').format(plan.endDate!)}';
      return _calloutBase(
        color: AppTheme.textSecondary,
        icon: Icons.event_outlined,
        title: msg,
        body: 'No dose scheduled for today.',
      );
    }

    if (today == null) {
      return _calloutBase(
        color: AppTheme.statusAmber,
        icon: Icons.warning_amber_rounded,
        title: 'No step covers today',
        body: 'Check the schedule — there may be a gap between steps.',
      );
    }

    return _calloutBase(
      color: AppTheme.statusGreen,
      icon: Icons.medication_liquid_outlined,
      title: 'Today: ${today.doseDisplay}',
      body: '${today.frequency}. Day '
          '${(plan.completedDays + 1).clamp(1, plan.totalDays)} '
          'of ${plan.totalDays}.',
    );
  }

  Widget _calloutBase({
    required Color color,
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaSection extends StatelessWidget {
  const _MetaSection({
    required this.plan,
    required this.medNameCtrl,
    required this.prescriberCtrl,
    required this.reasonNoteCtrl,
    required this.readOnly,
    required this.onReasonChanged,
    required this.onMedicationPicked,
    required this.onDoctorApprovedChanged,
  });

  final TaperSchedule plan;
  final TextEditingController medNameCtrl;
  final TextEditingController prescriberCtrl;
  final TextEditingController reasonNoteCtrl;
  final bool readOnly;
  final ValueChanged<TaperReason> onReasonChanged;
  final ValueChanged<MedicationDefinition> onMedicationPicked;
  final ValueChanged<bool> onDoctorApprovedChanged;

  @override
  Widget build(BuildContext context) {
    final defs =
        context.watch<MedicationDefinitionsProvider>().medDefinitions;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Medication & prescriber',
              icon: Icons.medical_services_outlined),
          if (defs.isNotEmpty && !readOnly) ...[
            const SizedBox(height: 8),
            Text(
              'Pick from your saved medications:',
              style: const TextStyle(
                  fontSize: 11.5, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in defs.take(12))
                  ChoiceChip(
                    label: Text(d.name,
                        style: const TextStyle(fontSize: 12)),
                    selected: medNameCtrl.text == d.name,
                    onSelected: (_) => onMedicationPicked(d),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          TextField(
            controller: medNameCtrl,
            readOnly: readOnly,
            decoration: const InputDecoration(
              labelText: 'Medication name *',
              hintText: 'e.g., Prednisone',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: prescriberCtrl,
            readOnly: readOnly,
            decoration: const InputDecoration(
              labelText: 'Prescribing doctor *',
              hintText: 'e.g., Dr. Chen',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          _sectionTitle(context, 'Reason for tapering',
              icon: Icons.info_outline),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final r in TaperReason.values)
                ChoiceChip(
                  label: Text(r.label,
                      style: const TextStyle(fontSize: 12)),
                  selected: plan.reason == r,
                  onSelected: readOnly ? null : (_) => onReasonChanged(r),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: reasonNoteCtrl,
            readOnly: readOnly,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'e.g., Weaning after 8-week flare-up',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            style: const TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 14),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: plan.isDoctorApproved,
            onChanged: readOnly
                ? null
                : (v) => onDoctorApprovedChanged(v ?? false),
            title: const Text(
              'I am transcribing a plan my prescriber gave me',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Required. Tapering is never guesswork — the doctor sets the plan.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLadderSection extends StatelessWidget {
  const _StepLadderSection({
    required this.plan,
    required this.readOnly,
    required this.onAdd,
    required this.onEdit,
    required this.onRemove,
    required this.onPreset,
    required this.onSuggest,
  });

  final TaperSchedule plan;
  final bool readOnly;
  final VoidCallback onAdd;
  final void Function(int) onEdit;
  final void Function(int) onRemove;
  final void Function(TaperPreset) onPreset;
  final VoidCallback onSuggest;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionTitle(context, 'Step ladder',
                    icon: Icons.stairs_outlined),
              ),
              if (!readOnly) ...[
                _AiStubChip(onTap: onSuggest),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add step',
                      style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    foregroundColor: _kAccentDeep,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
          if (plan.steps.isEmpty && !readOnly) ...[
            const SizedBox(height: 6),
            const Text(
              'Start from a common preset or build manually:',
              style: TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in kTaperPresets)
                  InkWell(
                    onTap: () => onPreset(p),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _kAccent.withValues(alpha: 0.08),
                        border: Border.all(
                            color: _kAccent.withValues(alpha: 0.3)),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _kAccentDeep)),
                          Text(p.description,
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ] else if (plan.steps.isEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'No steps yet.',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  fontStyle: FontStyle.italic),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _StepLadder(
                steps: plan.steps,
                readOnly: readOnly,
                onEdit: onEdit,
                onRemove: onRemove,
              ),
            ),
        ],
      ),
    );
  }
}

class _StepLadder extends StatelessWidget {
  const _StepLadder({
    required this.steps,
    required this.readOnly,
    required this.onEdit,
    required this.onRemove,
  });

  final List<TaperStep> steps;
  final bool readOnly;
  final void Function(int) onEdit;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    // Compute a max dose for bar-width scaling.
    final maxDose =
        steps.map((s) => s.dose).fold<double>(0, (a, b) => b > a ? b : a);
    return Column(
      children: [
        for (int i = 0; i < steps.length; i++)
          _StepRow(
            index: i,
            step: steps[i],
            maxDose: maxDose,
            readOnly: readOnly,
            onEdit: () => onEdit(i),
            onRemove: () => onRemove(i),
          ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.index,
    required this.step,
    required this.maxDose,
    required this.readOnly,
    required this.onEdit,
    required this.onRemove,
  });

  final int index;
  final TaperStep step;
  final double maxDose;
  final bool readOnly;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ratio = maxDose == 0 ? 0.0 : (step.dose / maxDose).clamp(0.05, 1.0);
    final isToday = step.containsDay(DateTime.now());
    return InkWell(
      onTap: readOnly ? null : onEdit,
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isToday
              ? _kAccent.withValues(alpha: 0.09)
              : AppTheme.backgroundGray,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: isToday
              ? Border.all(color: _kAccent.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kAccentDeep,
                    shape: BoxShape.circle,
                  ),
                  child: Text('${index + 1}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${DateFormat('MMM d').format(step.fromDate)} – '
                        '${DateFormat('MMM d').format(step.toDate)}  '
                        '• ${step.durationDays}d',
                        style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${step.doseDisplay} — ${step.frequency}',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _kAccent,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusXL),
                    ),
                    child: const Text('TODAY',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white)),
                  ),
                if (!readOnly)
                  IconButton(
                    tooltip: 'Remove',
                    icon: Icon(Icons.delete_outline,
                        size: 18, color: AppTheme.dangerColor),
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Dose bar
            LayoutBuilder(builder: (ctx, c) {
              return Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: c.maxWidth * ratio,
                    decoration: BoxDecoration(
                      color: _kAccent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              );
            }),
            if (step.notes != null && step.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(step.notes!,
                  style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CalendarSection extends StatefulWidget {
  const _CalendarSection({required this.plan});
  final TaperSchedule plan;

  @override
  State<_CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<_CalendarSection> {
  late DateTime _focused;

  @override
  void initState() {
    super.initState();
    _focused = widget.plan.startDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final first = plan.startDate ?? DateTime.now();
    final last = plan.endDate ?? DateTime.now();

    // Compute an intensity (0..1) per dose bucket for cell coloring.
    final maxDose =
        plan.steps.map((s) => s.dose).fold<double>(0, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 2, 6, 8),
            child: _sectionTitle(context, 'Calendar',
                icon: Icons.calendar_month_outlined),
          ),
          TableCalendar<TaperStep>(
            firstDay: first.subtract(const Duration(days: 14)),
            lastDay: last.add(const Duration(days: 14)),
            focusedDay: _focused,
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              leftChevronIcon: Icon(Icons.chevron_left, size: 20),
              rightChevronIcon: Icon(Icons.chevron_right, size: 20),
              titleTextStyle:
                  TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle:
                  TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              weekendStyle:
                  TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
              cellMargin: EdgeInsets.all(2),
            ),
            onPageChanged: (d) => setState(() => _focused = d),
            calendarBuilders: CalendarBuilders<TaperStep>(
              defaultBuilder: (ctx, day, _) =>
                  _buildDayCell(day, plan, maxDose),
              todayBuilder: (ctx, day, _) =>
                  _buildDayCell(day, plan, maxDose, isToday: true),
              selectedBuilder: (ctx, day, _) =>
                  _buildDayCell(day, plan, maxDose, isToday: true),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 4),
            child: Row(
              children: [
                _LegendSwatch(
                    color: _kAccent.withValues(alpha: 0.2),
                    label: 'Low dose'),
                const SizedBox(width: 10),
                _LegendSwatch(
                    color: _kAccent.withValues(alpha: 0.6),
                    label: 'Mid dose'),
                const SizedBox(width: 10),
                _LegendSwatch(color: _kAccent, label: 'High dose'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime day, TaperSchedule plan, double maxDose,
      {bool isToday = false}) {
    final step = plan.stepForDay(day);
    final isInWindow = step != null;

    Color bg = Colors.transparent;
    Color txt = AppTheme.textPrimary;
    if (isInWindow) {
      final ratio =
          maxDose == 0 ? 0.0 : (step.dose / maxDose).clamp(0.0, 1.0);
      // Very-low (including zero) doses still get a light tint so the
      // caregiver can tell the day is part of the plan.
      bg = _kAccent.withValues(alpha: 0.15 + 0.65 * ratio);
      txt = ratio > 0.5 ? Colors.white : _kAccentDeep;
    }
    if (isToday) {
      return Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
          border: Border.all(color: AppTheme.primaryColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${day.day}',
                style: TextStyle(
                  fontSize: 12,
                  color: txt,
                  fontWeight: FontWeight.w700,
                )),
            if (step != null)
              Text(step.doseDisplay,
                  style: TextStyle(fontSize: 8, color: txt)),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${day.day}',
              style: TextStyle(
                  fontSize: 12,
                  color: txt,
                  fontWeight:
                      isInWindow ? FontWeight.w700 : FontWeight.normal)),
          if (step != null)
            Text(step.doseDisplay,
                style: TextStyle(fontSize: 8, color: txt)),
        ],
      ),
    );
  }
}

class _LegendSwatch extends StatelessWidget {
  const _LegendSwatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppTheme.textSecondary)),
      ],
    );
  }
}

class _ReminderSection extends StatelessWidget {
  const _ReminderSection({
    required this.plan,
    required this.readOnly,
    required this.onToggleReminder,
    required this.onPickTime,
  });

  final TaperSchedule plan;
  final bool readOnly;
  final ValueChanged<bool> onToggleReminder;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Daily reminder',
              icon: Icons.alarm_outlined),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: plan.reminderEnabled,
            onChanged: readOnly ? null : onToggleReminder,
            title: const Text(
              'Notify caregivers each day',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            subtitle: const Text(
              'Posts today\'s dose to the med-reminders channel.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
          if (plan.reminderEnabled) ...[
            const SizedBox(height: 6),
            InkWell(
              onTap: readOnly ? null : onPickTime,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 18, color: _kAccentDeep),
                    const SizedBox(width: 8),
                    Text('Fires at ${plan.reminderTime}',
                        style: TextStyle(
                          fontSize: 14,
                          color: _kAccentDeep,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(width: 6),
                    if (!readOnly)
                      const Icon(Icons.edit_outlined,
                          size: 14, color: AppTheme.textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Reminders are scheduled up to 60 days ahead. Longer tapers '
              're-schedule automatically when you re-open the app.',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.current, required this.onChange});
  final TaperStatus current;
  final ValueChanged<TaperStatus> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(context, 'Status', icon: Icons.flag_outlined),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in TaperStatus.values)
                ChoiceChip(
                  label:
                      Text(s.label, style: const TextStyle(fontSize: 12)),
                  selected: current == s,
                  onSelected: (_) => onChange(s),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step editor dialog
// ---------------------------------------------------------------------------

class _StepEditorDialog extends StatefulWidget {
  const _StepEditorDialog({required this.initial});
  final TaperStep initial;

  @override
  State<_StepEditorDialog> createState() => _StepEditorDialogState();
}

class _StepEditorDialogState extends State<_StepEditorDialog> {
  late DateTime _from;
  late DateTime _to;
  late TextEditingController _doseCtrl;
  late TextEditingController _notesCtrl;
  late String _doseUnit;
  late String _frequency;

  static const _doseUnits = ['mg', 'mcg', 'pill', 'ml', 'patch'];
  static const _frequencies = [
    'once daily',
    'twice daily',
    'three times daily',
    'every other day',
    'every morning',
    'at bedtime',
  ];

  @override
  void initState() {
    super.initState();
    _from = widget.initial.fromDate;
    _to = widget.initial.toDate;
    _doseCtrl = TextEditingController(
        text: widget.initial.dose == widget.initial.dose.roundToDouble()
            ? widget.initial.dose.toInt().toString()
            : widget.initial.dose.toString());
    _notesCtrl = TextEditingController(text: widget.initial.notes ?? '');
    _doseUnit = widget.initial.doseUnit;
    _frequency = widget.initial.frequency;
  }

  @override
  void dispose() {
    _doseCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      });
    }
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to.isBefore(_from) ? _from : _to,
      firstDate: _from,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _to = picked);
  }

  void _submit() {
    final dose = double.tryParse(_doseCtrl.text.trim());
    if (dose == null || dose < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Enter a valid dose (0 or greater).'),
        backgroundColor: AppTheme.dangerColor,
      ));
      return;
    }
    Navigator.of(context).pop(
      TaperStep(
        fromDate: _from,
        toDate: _to,
        dose: dose,
        doseUnit: _doseUnit,
        frequency: _frequency,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _to.difference(_from).inDays + 1;
    return AlertDialog(
      title: const Text('Dose step'),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickFrom,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Text(DateFormat('MMM d, yyyy').format(_from)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: _pickTo,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Text(DateFormat('MMM d, yyyy').format(_to)),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('$days day${days == 1 ? '' : 's'}',
                  style: const TextStyle(
                      fontSize: 11, color: AppTheme.textSecondary)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _doseCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Dose',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _doseUnit,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: _doseUnits
                        .map((u) =>
                            DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _doseUnit = v ?? _doseUnit),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequencies.contains(_frequency)
                  ? _frequency
                  : _frequencies.first,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _frequencies
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (v) => setState(() => _frequency = v ?? _frequency),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g., Crush and mix in applesauce',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kAccentDeep,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save step'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

Widget _sectionTitle(BuildContext context, String text,
    {required IconData icon}) {
  return Row(
    children: [
      Icon(icon, size: 17, color: _kAccentDeep),
      const SizedBox(width: 8),
      Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          color: _kAccentDeep,
        ),
      ),
    ],
  );
}

class _AiStubChip extends StatelessWidget {
  const _AiStubChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final available = AiSuggestionService.instance.isAvailable;
    return Tooltip(
      message: available
          ? 'Draft a schedule with AI (starting point only)'
          : 'AI taper suggestions are coming soon',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: available
                ? _kAccentDeep.withValues(alpha: 0.1)
                : AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(
                color: available
                    ? _kAccentDeep.withValues(alpha: 0.3)
                    : AppTheme.textLight.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                available
                    ? Icons.auto_awesome_outlined
                    : Icons.lock_clock_outlined,
                size: 13,
                color: available ? _kAccentDeep : AppTheme.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                available ? 'Suggest' : 'Soon',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: available ? _kAccentDeep : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
