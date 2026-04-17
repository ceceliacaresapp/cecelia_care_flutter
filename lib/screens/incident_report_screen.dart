// lib/screens/incident_report_screen.dart
//
// Regulatory Incident Reporter — structured form + history list +
// compliance PDF. Covers falls, elopements, medication errors,
// behavioral incidents, injuries, and more.
//
// Every compliance-critical field is surfaced in the form; required
// fields are gated before save. The PDF output is formatted for
// facility binders and liability documentation.

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

import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/models/incident_report.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/ai_suggestion_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const Color _kAccent = AppTheme.statusRed;
const Color _kAccentDeep = Color(0xFFB71C1C);

class IncidentReportScreen extends StatelessWidget {
  const IncidentReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final elderProv = context.watch<ActiveElderProvider>();
    final elder = elderProv.activeElder;
    final canLog = elderProv.currentUserRole.canLog;

    if (elder == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Incident Reports'),
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('No care recipient selected.',
              style: TextStyle(color: AppTheme.textSecondary)),
        ),
      );
    }

    final displayName = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName!
        : elder.profileName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Reports'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: canLog
          ? FloatingActionButton.extended(
              backgroundColor: _kAccentDeep,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('File report'),
              onPressed: () => _openForm(context, elder.id, displayName, null),
            )
          : null,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: context
            .read<FirestoreService>()
            .getIncidentReportsStream(elder.id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final raw = snap.data ?? const <Map<String, dynamic>>[];
          final reports = raw
              .map((m) =>
                  IncidentReport.fromFirestore(m['id'] as String, m))
              .toList();

          if (reports.isEmpty) {
            return _EmptyState(
              canLog: canLog,
              onStart: () =>
                  _openForm(context, elder.id, displayName, null),
            );
          }

          final open = reports
              .where((r) => r.status != IncidentStatus.closed)
              .toList();
          final closed = reports
              .where((r) => r.status == IncidentStatus.closed)
              .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              _SafetyBanner(),
              const SizedBox(height: 14),
              if (open.isNotEmpty) ...[
                _SectionLabel('Open reports (${open.length})'),
                const SizedBox(height: 6),
                for (final r in open)
                  _ReportCard(
                    report: r,
                    onTap: () =>
                        _openForm(context, elder.id, displayName, r),
                    onSharePdf: () =>
                        _sharePdf(context, r, displayName),
                  ),
              ],
              if (closed.isNotEmpty) ...[
                const SizedBox(height: 14),
                _SectionLabel('Closed (${closed.length})'),
                const SizedBox(height: 6),
                for (final r in closed)
                  Opacity(
                    opacity: 0.75,
                    child: _ReportCard(
                      report: r,
                      onTap: () =>
                          _openForm(context, elder.id, displayName, r),
                      onSharePdf: () =>
                          _sharePdf(context, r, displayName),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _openForm(BuildContext context, String elderId,
      String displayName, IncidentReport? existing) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _IncidentFormScreen(
        elderId: elderId,
        careRecipientName: displayName,
        existing: existing,
      ),
    ));
  }

  Future<void> _sharePdf(
      BuildContext context, IncidentReport report, String elderName) async {
    try {
      final bytes = await _buildPdf(report, elderName);
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/Incident_Report_${DateFormat('yyyyMMdd_HHmm').format(report.occurredAt)}.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject:
            'Incident report — ${report.type.label} — $elderName',
      );
      HapticUtils.success();
    } catch (e) {
      debugPrint('Incident PDF error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  Future<Uint8List> _buildPdf(IncidentReport r, String elderName) async {
    final pdf = pw.Document();
    final dateStamp = DateFormat('MMMM d, yyyy – h:mm a').format(DateTime.now());
    final occurStr =
        DateFormat('EEEE, MMMM d, yyyy – h:mm a').format(r.occurredAt);

    final isSevere = r.requiresSupervisorReview;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border:
                pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Text(
            'Page ${ctx.pageNumber} of ${ctx.pagesCount} · '
            'Report generated $dateStamp',
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.blueGrey400),
          ),
        ),
        build: (ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: isSevere
                  ? PdfColor.fromHex('#FFEBEE')
                  : PdfColor.fromHex('#FFF3E0'),
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(
                color: isSevere
                    ? PdfColor.fromHex('#E53935')
                    : PdfColor.fromHex('#F57C00'),
                width: 1.0,
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'INCIDENT REPORT',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#B71C1C'),
                        letterSpacing: 2.5,
                      ),
                    ),
                    if (isSevere)
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#E53935'),
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(4)),
                        ),
                        child: pw.Text(
                          'REQUIRES SUPERVISOR REVIEW',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),
                pw.SizedBox(height: 10),
                _meta('Care recipient', elderName),
                _meta('Incident type', r.type.label),
                _meta('Severity', r.severity.shortLabel),
                _meta('Date / time of incident', occurStr),
                _meta('Location', r.location),
                _meta('Status', r.status.label),
                _meta('Reported by', r.reportedByName),
              ],
            ),
          ),
          pw.SizedBox(height: 14),
          _section('DESCRIPTION OF INCIDENT'),
          pw.SizedBox(height: 4),
          _textBlock(r.description),
          pw.SizedBox(height: 12),
          _section('PERSONS INVOLVED'),
          pw.SizedBox(height: 4),
          _meta(
              'Witnesses', r.witnessNames.isEmpty ? 'None listed' : r.witnessNames.join(', ')),
          _meta('Staff involved',
              r.staffInvolved.isEmpty ? 'None listed' : r.staffInvolved.join(', ')),
          pw.SizedBox(height: 12),
          _section('IMMEDIATE ACTIONS TAKEN'),
          pw.SizedBox(height: 4),
          _textBlock(r.immediateActions),
          pw.SizedBox(height: 4),
          _meta('Injury occurred', r.injuryOccurred ? 'Yes' : 'No'),
          if (r.injuryOccurred &&
              r.injuryDescription != null &&
              r.injuryDescription!.isNotEmpty)
            _meta('Injury details', r.injuryDescription!),
          _meta('Emergency services contacted',
              r.emergencyServicesContacted ? 'Yes' : 'No'),
          _meta('Family notified', r.familyNotified ? 'Yes' : 'No'),
          if (r.familyNotified &&
              r.familyNotifiedDetails != null &&
              r.familyNotifiedDetails!.isNotEmpty)
            _meta('Notification details', r.familyNotifiedDetails!),
          pw.SizedBox(height: 12),
          _section('FOLLOW-UP PLAN'),
          pw.SizedBox(height: 4),
          _textBlock(r.followUpPlan),
          if (r.followUpDueDate != null)
            _meta('Follow-up due',
                DateFormat('MMM d, yyyy').format(r.followUpDueDate!)),
          if (r.preventiveMeasures != null &&
              r.preventiveMeasures!.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            _meta('Preventive measures', r.preventiveMeasures!),
          ],
          if (r.supervisorNotes != null &&
              r.supervisorNotes!.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            _section('SUPERVISOR / REVIEWER NOTES'),
            pw.SizedBox(height: 4),
            _textBlock(r.supervisorNotes!),
          ],
          pw.SizedBox(height: 24),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 180,
                      decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColors.grey400))),
                      height: 30,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Reporter signature',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey500)),
                  ],
                ),
              ),
              pw.SizedBox(width: 20),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 180,
                      decoration: const pw.BoxDecoration(
                          border: pw.Border(
                              bottom: pw.BorderSide(
                                  color: PdfColors.grey400))),
                      height: 30,
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text('Supervisor signature / date',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey500)),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Generated by Cecelia Care. This document is a caregiver-'
            'authored record. Retain the original for facility compliance '
            'and liability purposes.',
            style: pw.TextStyle(
              fontSize: 9,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.blueGrey600,
              lineSpacing: 3,
            ),
          ),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _section(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#E53935'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
            letterSpacing: 1.4,
          ),
        ),
      );

  pw.Widget _meta(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 160,
              child: pw.Text('$label:',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blueGrey700)),
            ),
            pw.Expanded(
              child:
                  pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
            ),
          ],
        ),
      );

  pw.Widget _textBlock(String text) => pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromHex('#FAFAFA'),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Text(
          text,
          style: const pw.TextStyle(fontSize: 11, lineSpacing: 3.5),
        ),
      );
}

// ---------------------------------------------------------------------------
// List widgets
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canLog, required this.onStart});
  final bool canLog;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 28, 28, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Icon(Icons.assignment_outlined,
              size: 48, color: _kAccent.withValues(alpha: 0.55)),
          const SizedBox(height: 14),
          Text(
            'No incidents on file.',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kAccentDeep),
          ),
          const SizedBox(height: 8),
          const Text(
            'Document falls, elopements, medication errors, and behavioral '
            'events with a structured form. Every report is timestamped, '
            'auditable, and generates a formatted PDF for compliance '
            'binders or liability records.',
            style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5),
          ),
          if (canLog) ...[
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.add),
                label: const Text('File first report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccentDeep,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusM)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SafetyBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: _kAccent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.shield_outlined, size: 18, color: _kAccentDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Each report is timestamped and can be exported as a '
              'compliance-ready PDF. These records protect you and the '
              'person in your care.',
              style: TextStyle(
                fontSize: 12,
                color: _kAccentDeep,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.onTap,
    required this.onSharePdf,
  });

  final IncidentReport report;
  final VoidCallback onTap;
  final VoidCallback onSharePdf;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: report.type.color.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusS),
                    ),
                    child: Icon(report.type.icon,
                        color: report.type.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.type.label,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${DateFormat('MMM d, yyyy – h:mm a').format(report.occurredAt)}'
                          ' · ${report.location}',
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(status: report.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                report.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 12.5,
                    color: AppTheme.textPrimary,
                    height: 1.45),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SeverityChip(severity: report.severity),
                  if (report.injuryOccurred) ...[
                    const SizedBox(width: 6),
                    _MiniPill(
                        color: AppTheme.dangerColor, label: 'INJURY'),
                  ],
                  if (report.emergencyServicesContacted) ...[
                    const SizedBox(width: 6),
                    _MiniPill(
                        color: AppTheme.dangerColor, label: '911'),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf_outlined,
                        size: 18),
                    tooltip: 'Share PDF',
                    color: _kAccentDeep,
                    visualDensity: VisualDensity.compact,
                    onPressed: onSharePdf,
                  ),
                ],
              ),
              Text(
                'Reported by ${report.reportedByName}',
                style: const TextStyle(
                    fontSize: 10.5, color: AppTheme.textLight),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: status.color,
        ),
      ),
    );
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.severity});
  final IncidentSeverity severity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: severity.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        severity.shortLabel.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: severity.color,
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen form
// ---------------------------------------------------------------------------

class _IncidentFormScreen extends StatefulWidget {
  const _IncidentFormScreen({
    required this.elderId,
    required this.careRecipientName,
    this.existing,
  });

  final String elderId;
  final String careRecipientName;
  final IncidentReport? existing;

  @override
  State<_IncidentFormScreen> createState() => _IncidentFormScreenState();
}

class _IncidentFormScreenState extends State<_IncidentFormScreen> {
  late IncidentType _type;
  late IncidentSeverity _severity;
  late IncidentStatus _status;
  late DateTime _occurredAt;
  late TextEditingController _locationCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _actionsCtrl;
  late TextEditingController _followUpCtrl;
  late TextEditingController _injuryCtrl;
  late TextEditingController _familyCtrl;
  late TextEditingController _preventiveCtrl;
  late TextEditingController _supervisorCtrl;
  late TextEditingController _witnessCtrl;
  late TextEditingController _staffCtrl;

  bool _injuryOccurred = false;
  bool _emergencyCalled = false;
  bool _familyNotified = false;
  DateTime? _followUpDue;
  bool _isSaving = false;
  bool _aiBusy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _type = e?.type ?? IncidentType.fall;
    _severity = e?.severity ?? IncidentSeverity.minor;
    _status = e?.status ?? IncidentStatus.open;
    _occurredAt = e?.occurredAt ?? DateTime.now();
    _locationCtrl = TextEditingController(text: e?.location ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');
    _actionsCtrl = TextEditingController(text: e?.immediateActions ?? '');
    _followUpCtrl = TextEditingController(text: e?.followUpPlan ?? '');
    _injuryCtrl =
        TextEditingController(text: e?.injuryDescription ?? '');
    _familyCtrl =
        TextEditingController(text: e?.familyNotifiedDetails ?? '');
    _preventiveCtrl =
        TextEditingController(text: e?.preventiveMeasures ?? '');
    _supervisorCtrl =
        TextEditingController(text: e?.supervisorNotes ?? '');
    _witnessCtrl =
        TextEditingController(text: e?.witnessNames.join(', ') ?? '');
    _staffCtrl =
        TextEditingController(text: e?.staffInvolved.join(', ') ?? '');
    _injuryOccurred = e?.injuryOccurred ?? false;
    _emergencyCalled = e?.emergencyServicesContacted ?? false;
    _familyNotified = e?.familyNotified ?? false;
    _followUpDue = e?.followUpDueDate;
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _descCtrl.dispose();
    _actionsCtrl.dispose();
    _followUpCtrl.dispose();
    _injuryCtrl.dispose();
    _familyCtrl.dispose();
    _preventiveCtrl.dispose();
    _supervisorCtrl.dispose();
    _witnessCtrl.dispose();
    _staffCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_descCtrl.text.trim().isEmpty ||
        _actionsCtrl.text.trim().isEmpty ||
        _followUpCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Description, immediate actions, and follow-up plan are required.'),
        backgroundColor: AppTheme.dangerColor,
      ));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);

    final firestore = context.read<FirestoreService>();
    final report = IncidentReport(
      id: widget.existing?.id,
      elderId: widget.elderId,
      type: _type,
      severity: _severity,
      occurredAt: _occurredAt,
      location: _locationCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      careRecipientName: widget.careRecipientName,
      witnessNames: _split(_witnessCtrl.text),
      staffInvolved: _split(_staffCtrl.text),
      immediateActions: _actionsCtrl.text.trim(),
      injuryOccurred: _injuryOccurred,
      injuryDescription: _injuryCtrl.text.trim().isEmpty
          ? null
          : _injuryCtrl.text.trim(),
      emergencyServicesContacted: _emergencyCalled,
      familyNotified: _familyNotified,
      familyNotifiedDetails: _familyCtrl.text.trim().isEmpty
          ? null
          : _familyCtrl.text.trim(),
      followUpPlan: _followUpCtrl.text.trim(),
      followUpDueDate: _followUpDue,
      preventiveMeasures: _preventiveCtrl.text.trim().isEmpty
          ? null
          : _preventiveCtrl.text.trim(),
      supervisorNotes: _supervisorCtrl.text.trim().isEmpty
          ? null
          : _supervisorCtrl.text.trim(),
      status: _status,
      reportedByUid: user.uid,
      reportedByName: user.displayName ?? 'Caregiver',
      createdAt: widget.existing?.createdAt,
    );

    try {
      if (widget.existing?.id == null) {
        await firestore.addIncidentReport(
            widget.elderId, report.toFirestore());
      } else {
        await firestore.updateIncidentReport(
            widget.elderId, widget.existing!.id!, report.toFirestore());
      }
      HapticUtils.success();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    }
  }

  List<String> _split(String s) => s
      .split(RegExp(r'[,;]'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _askAi() async {
    if (_aiBusy) return;
    setState(() => _aiBusy = true);
    final res = await AiSuggestionService.instance.suggestIncidentNarrative(
      elderId: widget.elderId,
      elderDisplayName: widget.careRecipientName,
      context: {
        'type': _type.firestoreValue,
        'severity': _severity.firestoreValue,
        'description': _descCtrl.text.trim(),
        'immediateActions': _actionsCtrl.text.trim(),
        'followUpPlan': _followUpCtrl.text.trim(),
        'injuryDescription': _injuryCtrl.text.trim(),
      },
    );
    if (!mounted) return;
    setState(() => _aiBusy = false);
    if (res.available && res.suggestion != null) {
      _descCtrl.text = res.suggestion!;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res.errorMessage ?? 'AI drafts are coming soon.'),
        backgroundColor: AppTheme.tileIndigoDark,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit report' : 'File incident report'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete',
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete this report?'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                            foregroundColor: AppTheme.dangerColor),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok != true || !context.mounted) return;
                final firestore = context.read<FirestoreService>();
                await firestore.deleteIncidentReport(
                    widget.elderId, widget.existing!.id!);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Type
          _FormSection(
            title: 'Incident type *',
            icon: Icons.report_outlined,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final t in IncidentType.values)
                  ChoiceChip(
                    avatar: Icon(t.icon, size: 14),
                    label: Text(t.label, style: const TextStyle(fontSize: 12)),
                    selected: _type == t,
                    selectedColor: t.color.withValues(alpha: 0.18),
                    onSelected: (_) => setState(() => _type = t),
                  ),
              ],
            ),
          ),
          // Severity
          _FormSection(
            title: 'Severity *',
            icon: Icons.flag_outlined,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final s in IncidentSeverity.values)
                  ChoiceChip(
                    label: Text(s.label,
                        style: const TextStyle(fontSize: 12)),
                    selected: _severity == s,
                    selectedColor: s.color.withValues(alpha: 0.18),
                    onSelected: (_) => setState(() => _severity = s),
                  ),
              ],
            ),
          ),
          // When + where
          _FormSection(
            title: 'When & where *',
            icon: Icons.schedule_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _occurredAt,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 1)),
                    );
                    if (date == null || !context.mounted) return;
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(_occurredAt),
                    );
                    if (time == null || !context.mounted) return;
                    setState(() {
                      _occurredAt = DateTime(
                        date.year, date.month, date.day,
                        time.hour, time.minute,
                      );
                    });
                  },
                  child: InputDecorator(
                    decoration: _dec(label: 'Date & time of incident'),
                    child: Text(
                      DateFormat('EEEE, MMM d, yyyy – h:mm a')
                          .format(_occurredAt),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const _FormLabel('Location'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final loc in IncidentReport.kLocations)
                      ChoiceChip(
                        label: Text(loc,
                            style: const TextStyle(fontSize: 12)),
                        selected: _locationCtrl.text == loc,
                        onSelected: (_) {
                          setState(() => _locationCtrl.text = loc);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _locationCtrl,
                  decoration: _dec(hint: 'Or type specific location'),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          // Description
          _FormSection(
            title: 'What happened * (narrative)',
            icon: Icons.description_outlined,
            trailing: _AiChip(onTap: _askAi, busy: _aiBusy),
            child: TextField(
              controller: _descCtrl,
              maxLines: 6,
              minLines: 4,
              decoration: _dec(
                hint: 'Describe the incident in detail — objective facts, '
                    'sequence of events, and any contributing factors.',
              ),
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ),
          // Persons involved
          _FormSection(
            title: 'Persons involved',
            icon: Icons.people_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FormLabel('Witnesses (comma-separated)'),
                TextField(
                  controller: _witnessCtrl,
                  decoration: _dec(hint: 'Jane Smith, John Doe'),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                const _FormLabel('Staff involved (comma-separated)'),
                TextField(
                  controller: _staffCtrl,
                  decoration: _dec(hint: 'Nurse Maria, Aide Tom'),
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          // Immediate actions
          _FormSection(
            title: 'Immediate actions taken *',
            icon: Icons.health_and_safety_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _actionsCtrl,
                  maxLines: 4,
                  minLines: 3,
                  decoration: _dec(
                    hint: 'What was done immediately? First aid? Assessment?',
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _injuryOccurred,
                  onChanged: (v) => setState(() => _injuryOccurred = v),
                  title: const Text('Injury occurred',
                      style: TextStyle(fontSize: 13)),
                ),
                if (_injuryOccurred)
                  TextField(
                    controller: _injuryCtrl,
                    maxLines: 2,
                    decoration: _dec(
                        hint: 'Describe the injury — type, location, severity'),
                    style: const TextStyle(fontSize: 13),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _emergencyCalled,
                  onChanged: (v) => setState(() => _emergencyCalled = v),
                  title: const Text('Emergency services contacted (911)',
                      style: TextStyle(fontSize: 13)),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _familyNotified,
                  onChanged: (v) => setState(() => _familyNotified = v),
                  title: const Text('Family notified',
                      style: TextStyle(fontSize: 13)),
                ),
                if (_familyNotified)
                  TextField(
                    controller: _familyCtrl,
                    decoration: _dec(hint: 'Who was contacted? When?'),
                    style: const TextStyle(fontSize: 13),
                  ),
              ],
            ),
          ),
          // Follow-up plan
          _FormSection(
            title: 'Follow-up plan *',
            icon: Icons.event_available_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _followUpCtrl,
                  maxLines: 4,
                  minLines: 3,
                  decoration: _dec(
                    hint: 'What happens next? Doctor visit? Policy change? '
                        'Equipment order?',
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate:
                          _followUpDue ?? DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) setState(() => _followUpDue = picked);
                  },
                  child: InputDecorator(
                    decoration: _dec(label: 'Follow-up due date'),
                    child: Text(
                      _followUpDue == null
                          ? 'Not set'
                          : DateFormat('MMM d, yyyy').format(_followUpDue!),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const _FormLabel('Preventive measures'),
                TextField(
                  controller: _preventiveCtrl,
                  maxLines: 3,
                  minLines: 2,
                  decoration: _dec(
                    hint: 'What will prevent recurrence? Grab bars? '
                        'New medication protocol? Increased supervision?',
                  ),
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
          // Supervisor notes + status
          _FormSection(
            title: 'Review & status',
            icon: Icons.verified_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FormLabel('Supervisor / reviewer notes'),
                TextField(
                  controller: _supervisorCtrl,
                  maxLines: 3,
                  minLines: 2,
                  decoration: _dec(hint: 'Review comments (optional)'),
                  style: const TextStyle(fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 10),
                const _FormLabel('Report status'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final s in IncidentStatus.values)
                      ChoiceChip(
                        label: Text(s.label,
                            style: const TextStyle(fontSize: 12)),
                        selected: _status == s,
                        selectedColor: s.color.withValues(alpha: 0.18),
                        onSelected: (_) => setState(() => _status = s),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSaving
                    ? 'Saving...'
                    : isEditing
                        ? 'Save changes'
                        : 'File report',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAccentDeep,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec({String? hint, String? label}) => InputDecoration(
        hintText: hint,
        labelText: label,
        isDense: true,
        hintStyle: const TextStyle(fontSize: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusS)),
      );
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              Icon(icon, size: 16, color: _kAccentDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: _kAccentDeep,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}

class _AiChip extends StatelessWidget {
  const _AiChip({required this.onTap, required this.busy});
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final available = AiSuggestionService.instance.isAvailable;
    return Tooltip(
      message: available
          ? 'Polish the narrative with AI'
          : 'AI narrative drafts coming soon',
      child: InkWell(
        onTap: busy ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
              if (busy)
                const SizedBox(
                    width: 11,
                    height: 11,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(
                  available
                      ? Icons.auto_awesome_outlined
                      : Icons.lock_clock_outlined,
                  size: 12,
                  color: available ? _kAccentDeep : AppTheme.textSecondary,
                ),
              const SizedBox(width: 4),
              Text(
                available ? 'Polish' : 'Soon',
                style: TextStyle(
                  fontSize: 10.5,
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
