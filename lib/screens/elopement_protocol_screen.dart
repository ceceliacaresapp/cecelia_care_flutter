// lib/screens/elopement_protocol_screen.dart
//
// Emergency response screen for when a care recipient goes missing.
// Step-by-step timed checklist: search house, check spots, call 911,
// alert neighbors, share emergency card PDF.
//
// Pattern mirrors SOS screen (card-based step-through) but with a
// completely different urgency level — this is "your person is gone
// right now", not "you need a mental health break."
//
// Pure UI — no Firestore reads during the protocol. Elder info comes
// from ActiveElderProvider. Optional "save to journal" at the end.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Emergency color palette ──────────────────────────────────────────────
const _kEmergencyRed = Color(0xFFD32F2F);
const _kEmergencyDark = Color(0xFFB71C1C);
const _kEmergencyBg = Color(0xFFFFF5F5);
const _kStepDone = Color(0xFF43A047);

// ─── Protocol steps definition ────────────────────────────────────────────
class _ProtocolStep {
  final String title;
  final String description;
  final String? emphasis;
  final IconData icon;
  final _StepAction? action;

  const _ProtocolStep({
    required this.title,
    required this.description,
    this.emphasis,
    required this.icon,
    this.action,
  });
}

enum _StepActionType { call, share, navigate }

class _StepAction {
  final String label;
  final _StepActionType type;
  final String? phoneNumber;

  const _StepAction({
    required this.label,
    required this.type,
    this.phoneNumber,
  });
}

const List<_ProtocolStep> _kProtocolSteps = [
  _ProtocolStep(
    title: 'Search the house immediately',
    description:
        'Check ALL rooms, closets, behind furniture, under beds, garage, '
        'basement, attic, and locked rooms. Check vehicles.',
    emphasis: 'Many "wandering" episodes end inside the home.',
    icon: Icons.home_outlined,
  ),
  _ProtocolStep(
    title: 'Check known favorite spots',
    description:
        'Check places the person frequently visited: former home, church, '
        'park, neighbor\'s house, favorite store, or workplace.',
    icon: Icons.place_outlined,
  ),
  _ProtocolStep(
    title: 'Call 911',
    description:
        'Tell the dispatcher: "I have a missing person with dementia / '
        'Alzheimer\'s who may be disoriented." Provide name, physical '
        'description, and what they were last wearing.',
    icon: Icons.emergency_outlined,
    action: _StepAction(
      label: 'Call 911',
      type: _StepActionType.call,
      phoneNumber: '911',
    ),
  ),
  _ProtocolStep(
    title: 'Alert neighbors and nearby contacts',
    description:
        'Call or text neighbors immediately. Ask them to check their yards, '
        'garages, sheds, and vehicles. Share a photo and description.',
    icon: Icons.people_outlined,
    action: _StepAction(
      label: 'Share photo & info',
      type: _StepActionType.share,
    ),
  ),
  _ProtocolStep(
    title: 'Share Emergency Card with searchers',
    description:
        'Generate and share the emergency card PDF with police, neighbors, '
        'and anyone helping. It includes name, DOB, medical info, allergies, '
        'and current medications.',
    icon: Icons.description_outlined,
    action: _StepAction(
      label: 'Generate & share PDF',
      type: _StepActionType.share,
    ),
  ),
  _ProtocolStep(
    title: 'Notify all caregivers',
    description:
        'Alert every caregiver on the care team that the person is missing. '
        'Coordinate search areas so you cover more ground.',
    icon: Icons.group_outlined,
  ),
  _ProtocolStep(
    title: 'Expand search area',
    description:
        'If not found within 15 minutes, search a wider radius. People with '
        'dementia can walk surprisingly fast and far. Check bodies of water, '
        'wooded areas, construction sites, and busy roads.',
    emphasis: 'Call the Alzheimer\'s Association 24/7 Helpline for guidance.',
    icon: Icons.search_outlined,
    action: _StepAction(
      label: 'Call 1-800-272-3900',
      type: _StepActionType.call,
      phoneNumber: '18002723900',
    ),
  ),
  _ProtocolStep(
    title: 'Document for the report',
    description:
        'Note: last known clothing, direction of travel, time last seen, '
        'and who has been contacted. This helps police and searchers.',
    icon: Icons.edit_note_outlined,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
// ElopementProtocolScreen
// ═══════════════════════════════════════════════════════════════════════════

class ElopementProtocolScreen extends StatefulWidget {
  const ElopementProtocolScreen({super.key});

  @override
  State<ElopementProtocolScreen> createState() =>
      _ElopementProtocolScreenState();
}

class _ElopementProtocolScreenState extends State<ElopementProtocolScreen> {
  // Elapsed timer
  late final DateTime _protocolStartTime;
  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  // Step completion state — index → completion timestamp
  final Map<int, DateTime> _completedSteps = {};

  // Notes field for step 8 (Document)
  final _notesCtrl = TextEditingController();

  // Protocol ended flag
  bool _protocolEnded = false;
  bool _isSavingToJournal = false;

  @override
  void initState() {
    super.initState();
    _protocolStartTime = DateTime.now();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _protocolEnded) return;
      setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  String _formatElapsed(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _toggleStep(int index) {
    HapticUtils.success();
    setState(() {
      if (_completedSteps.containsKey(index)) {
        _completedSteps.remove(index);
      } else {
        _completedSteps[index] = DateTime.now();
      }
    });
  }

  Future<void> _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('ElopementProtocol: could not launch phone: $e');
    }
  }

  Future<void> _shareElderInfo(ElderProfile elder) async {
    final description = StringBuffer();
    description.writeln('MISSING PERSON — NEEDS IMMEDIATE HELP');
    description.writeln('');
    description.writeln('Name: ${elder.profileName}');
    description.writeln('Date of Birth: ${elder.dateOfBirth}');
    if (elder.allergies.isNotEmpty) {
      description.writeln('Allergies: ${elder.allergies.join(', ')}');
    }
    description.writeln('');
    description.writeln(
        'This person has dementia and may be confused or disoriented. '
        'They may not respond to their name. If found, please stay with '
        'them and call the caregiver or 911 immediately.');
    description.writeln('');
    description.writeln(
        'Last seen: approximately ${DateFormat('h:mm a').format(_protocolStartTime)}');

    await Share.share(description.toString(),
        subject: 'Missing Person: ${elder.profileName}');
  }

  Future<void> _generateAndSharePdf(
    ElderProfile elder,
    List<String> medNames,
  ) async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.letter,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(12),
                  color: PdfColors.red,
                  child: pw.Text(
                    'MISSING PERSON — EMERGENCY',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
                pw.SizedBox(height: 16),
                _pdfRow('Name', elder.profileName),
                _pdfRow('Date of Birth', elder.dateOfBirth),
                _pdfRow(
                  'Allergies',
                  elder.allergies.isNotEmpty
                      ? elder.allergies.join(', ')
                      : 'None known',
                ),
                _pdfRow('Dietary Restrictions',
                    elder.dietaryRestrictions.isNotEmpty
                        ? elder.dietaryRestrictions
                        : 'None'),
                pw.SizedBox(height: 8),
                if (medNames.isNotEmpty) ...[
                  pw.Text('Current Medications:',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.SizedBox(height: 4),
                  ...medNames
                      .map((m) => pw.Padding(
                            padding:
                                const pw.EdgeInsets.only(left: 12, bottom: 2),
                            child:
                                pw.Text('• $m', style: const pw.TextStyle(fontSize: 11)),
                          ))
                      ,
                ],
                pw.SizedBox(height: 16),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.red),
                  ),
                  child: pw.Text(
                    'This person has dementia and may be confused or '
                    'disoriented. They may not respond to their name or '
                    'recognize danger. If found, please stay with them and '
                    'call 911 immediately.',
                    style: const pw.TextStyle(fontSize: 11),
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  'Protocol activated: ${DateFormat('MMM d, yyyy h:mm a').format(_protocolStartTime)}',
                  style: pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final safeName =
          elder.profileName.replaceAll(RegExp(r'[^\w]'), '_');
      final file = File(
          '${tempDir.path}/Missing_Person_$safeName.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Missing Person: ${elder.profileName}',
      );
    } catch (e) {
      debugPrint('ElopementProtocol._generateAndSharePdf error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate PDF: $e'),
            backgroundColor: _kEmergencyRed,
          ),
        );
      }
    }
  }

  static pw.Widget _pdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(label,
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold, fontSize: 12)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _endProtocol() {
    _elapsedTimer?.cancel();
    HapticUtils.celebration();
    setState(() => _protocolEnded = true);
  }

  Future<void> _saveToJournal() async {
    setState(() => _isSavingToJournal = true);
    try {
      final journal = context.read<JournalServiceProvider>();
      final user = AuthService.currentUser;
      final elder =
          context.read<ActiveElderProvider>().activeElder;
      if (user == null || elder == null) return;

      final completedList = <String>[];
      final pendingList = <String>[];
      for (var i = 0; i < _kProtocolSteps.length; i++) {
        final step = _kProtocolSteps[i];
        if (_completedSteps.containsKey(i)) {
          final ts = DateFormat('h:mm a').format(_completedSteps[i]!);
          completedList.add('${step.title} (at $ts)');
        } else {
          pendingList.add(step.title);
        }
      }

      final payload = <String, dynamic>{
        'shift': 'Elopement Response',
        'completed': completedList.join('\n'),
        'pending': pendingList.join('\n'),
        'concerns': _notesCtrl.text.trim(),
        'stamp': Timestamp.now(),
        'time': DateFormat('HH:mm').format(_protocolStartTime),
        'date': DateFormat('yyyy-MM-dd').format(_protocolStartTime),
        'elderId': elder.id,
        'loggedByUserId': user.uid,
        'loggedBy': user.displayName ?? user.email ?? 'Unknown',
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
      };

      await journal.addJournalEntry('handoff', payload, user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Protocol saved to timeline.'),
            backgroundColor: _kStepDone,
          ),
        );
      }
    } catch (e) {
      debugPrint('ElopementProtocol._saveToJournal error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: _kEmergencyRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingToJournal = false);
    }
  }

  Future<bool> _confirmExit() async {
    if (_protocolEnded) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Protocol?'),
        content: const Text(
          'The emergency protocol is still active. '
          'Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                TextButton.styleFrom(foregroundColor: _kEmergencyRed),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ─────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final elder =
        context.watch<ActiveElderProvider>().activeElder;
    final medDefs =
        context.watch<MedicationDefinitionsProvider>().medDefinitions;
    final medNames = medDefs.map((m) {
      final dose = m.dose != null && m.dose!.isNotEmpty ? ' (${m.dose})' : '';
      return '${m.name}$dose';
    }).toList();

    return PopScope(
      canPop: _protocolEnded,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmExit();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: _kEmergencyBg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 20),
              SizedBox(width: 8),
              Text('MISSING PERSON PROTOCOL'),
            ],
          ),
          centerTitle: true,
          backgroundColor: _kEmergencyDark,
          foregroundColor: Colors.white,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kEmergencyDark, _kEmergencyRed],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final shouldPop = await _confirmExit();
                if (shouldPop && mounted) Navigator.of(context).pop();
              },
              child: const Text('Exit',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Elapsed timer banner ────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              color: _protocolEnded
                  ? _kStepDone
                  : _kEmergencyRed,
              child: Center(
                child: Text(
                  _protocolEnded
                      ? 'PROTOCOL ENDED — ${_formatElapsed(_elapsedSeconds)}'
                      : 'ELAPSED: ${_formatElapsed(_elapsedSeconds)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 2,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),

            // ── Scrollable content ──────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Elder info card
                    if (elder != null) _buildElderCard(elder),

                    const SizedBox(height: 16),

                    // Progress indicator
                    _buildProgress(),

                    const SizedBox(height: 16),

                    // Protocol steps
                    if (!_protocolEnded)
                      ...List.generate(_kProtocolSteps.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildStepCard(
                            i,
                            _kProtocolSteps[i],
                            elder,
                            medNames,
                          ),
                        );
                      }),

                    // Completion view
                    if (_protocolEnded) _buildCompletionSummary(),

                    // Person Found button
                    if (!_protocolEnded) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _endProtocol,
                          icon: const Icon(Icons.check_circle_outline,
                              size: 22),
                          label: const Text('Person Found — End Protocol',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kStepDone,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Elder info card ──────────────────────────────────────────────
  Widget _buildElderCard(ElderProfile elder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kEmergencyRed.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: _kEmergencyRed.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 28,
            backgroundColor: _kEmergencyRed.withOpacity(0.1),
            child: Text(
              elder.profileName.isNotEmpty
                  ? elder.profileName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _kEmergencyRed),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  elder.profileName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _kEmergencyDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'DOB: ${elder.dateOfBirth}',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                ),
                if (elder.allergies.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Allergies: ${elder.allergies.join(', ')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kEmergencyRed,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Progress bar ─────────────────────────────────────────────────
  Widget _buildProgress() {
    final total = _kProtocolSteps.length;
    final done = _completedSteps.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '$done of $total steps completed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done == total ? _kStepDone : AppTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              'Started ${DateFormat('h:mm a').format(_protocolStartTime)}',
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: total > 0 ? done / total : 0,
            backgroundColor: _kEmergencyRed.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(
                done == total ? _kStepDone : _kEmergencyRed),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ─── Individual step card ─────────────────────────────────────────
  Widget _buildStepCard(
    int index,
    _ProtocolStep step,
    ElderProfile? elder,
    List<String> medNames,
  ) {
    final isDone = _completedSteps.containsKey(index);
    final doneTime = _completedSteps[index];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? _kStepDone.withOpacity(0.4)
              : _kEmergencyRed.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDone ? _kStepDone : _kEmergencyRed).withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main tappable area
          InkWell(
            onTap: () => _toggleStep(index),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14), bottom: Radius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step number / check
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? _kStepDone
                          : _kEmergencyRed.withOpacity(0.1),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _kEmergencyRed.withOpacity(0.7),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDone
                                ? _kStepDone
                                : AppTheme.textPrimary,
                            decoration: isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDone
                                ? AppTheme.textLight
                                : AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        if (step.emphasis != null && !isDone) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _kEmergencyRed.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              step.emphasis!,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _kEmergencyRed,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                        if (isDone && doneTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '✅ Completed at ${DateFormat('h:mm a').format(doneTime)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _kStepDone,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action button row (if step has an action)
          if (step.action != null && !isDone) ...[
            const Divider(height: 1, indent: 62),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: _buildActionButton(
                    step.action!, index, elder, medNames),
              ),
            ),
          ],

          // Notes field for step 8 (Document)
          if (index == 7 && !isDone) ...[
            const Divider(height: 1, indent: 62),
            Padding(
              padding: const EdgeInsets.fromLTRB(62, 8, 14, 12),
              child: TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Clothing, direction of travel, contacts made...',
                  hintStyle: TextStyle(
                      fontSize: 12, color: AppTheme.textLight),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppTheme.textLight.withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                        color: AppTheme.textLight.withOpacity(0.3)),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Action button for a step ─────────────────────────────────────
  Widget _buildActionButton(
    _StepAction action,
    int stepIndex,
    ElderProfile? elder,
    List<String> medNames,
  ) {
    final isCall = action.type == _StepActionType.call;
    final color = isCall ? _kEmergencyRed : const Color(0xFF1565C0);

    return TextButton.icon(
      onPressed: () {
        if (isCall && action.phoneNumber != null) {
          _launchPhone(action.phoneNumber!);
        } else if (stepIndex == 3 && elder != null) {
          // Step 4: share elder info as text
          _shareElderInfo(elder);
        } else if (stepIndex == 4 && elder != null) {
          // Step 5: generate and share PDF
          _generateAndSharePdf(elder, medNames);
        }
      },
      icon: Icon(
        isCall ? Icons.call : Icons.share_outlined,
        size: 16,
        color: color,
      ),
      label: Text(action.label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
      ),
    );
  }

  // ─── Completion summary ───────────────────────────────────────────
  Widget _buildCompletionSummary() {
    final total = _kProtocolSteps.length;
    final done = _completedSteps.length;
    final minutes = _elapsedSeconds ~/ 60;

    return Column(
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _kStepDone.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: _kStepDone, size: 48),
              const SizedBox(height: 12),
              const Text(
                'Person Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _kStepDone,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Protocol active for $minutes minute${minutes == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
              Text(
                '$done of $total steps completed',
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 16),
              // Step timestamps
              ...List.generate(_kProtocolSteps.length, (i) {
                final step = _kProtocolSteps[i];
                final isDone = _completedSteps.containsKey(i);
                final ts = _completedSteps[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        isDone
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isDone ? _kStepDone : AppTheme.textLight,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDone
                                ? AppTheme.textPrimary
                                : AppTheme.textLight,
                          ),
                        ),
                      ),
                      if (isDone && ts != null)
                        Text(
                          DateFormat('h:mm a').format(ts),
                          style: const TextStyle(
                              fontSize: 11, color: _kStepDone),
                        ),
                    ],
                  ),
                );
              }),

              if (_notesCtrl.text.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Notes: ${_notesCtrl.text.trim()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Save to journal button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: _isSavingToJournal ? null : _saveToJournal,
            icon: _isSavingToJournal
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.save_outlined, size: 20),
            label: Text(
              _isSavingToJournal
                  ? 'Saving...'
                  : 'Save to Timeline',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kStepDone,
              side: BorderSide(color: _kStepDone.withOpacity(0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Return to Care tab
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Return to Care',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
