// lib/screens/emergency_card_screen.dart
//
// Lock-screen-style emergency info card for the active care recipient.
// Displays: name, DOB, allergies, dietary restrictions, current medications,
// emergency contact, and rescue medication dosing references. "Share as PDF"
// generates a one-page PDF and opens the system share sheet.
//
// Reads from ElderProfile, MedicationDefinitionsProvider, and a static
// rescue-medication data set. Per-elder rescue-med toggles persist via
// SharedPreferences.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/rescue_med.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key});

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  Set<String> _activeRescueMeds = <String>{};
  String? _loadedForElderId;

  String _prefsKey(String elderId) => 'rescue_meds_$elderId';

  Future<void> _loadRescueMeds(String elderId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey(elderId));
    Set<String> ids = <String>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          ids = decoded.map((e) => e.toString()).toSet();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _activeRescueMeds = ids;
      _loadedForElderId = elderId;
    });
  }

  Future<void> _saveRescueMeds(String elderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefsKey(elderId), jsonEncode(_activeRescueMeds.toList()));
  }

  void _openRescueMedEditor(String elderId) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (sbCtx, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sbCtx).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.textLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Rescue Medications',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Toggle on the rescue meds prescribed for this care recipient. They will appear on this screen and on the shared PDF.',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: ListView.builder(
                    itemCount: kRescueMeds.length,
                    itemBuilder: (_, i) {
                      final med = kRescueMeds[i];
                      final isOn = _activeRescueMeds.contains(med.id);
                      return SwitchListTile(
                        value: isOn,
                        activeThumbColor: med.color,
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: med.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(med.icon, color: med.color),
                        ),
                        title: Text(
                          med.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          med.indication,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onChanged: (v) {
                          setSheetState(() {
                            if (v) {
                              _activeRescueMeds.add(med.id);
                            } else {
                              _activeRescueMeds.remove(med.id);
                            }
                          });
                          setState(() {});
                          _saveRescueMeds(elderId);
                          HapticUtils.warning();
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(sbCtx).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.dangerColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeElder = context.watch<ActiveElderProvider>().activeElder;
    final medDefs = context.watch<MedicationDefinitionsProvider>();

    if (activeElder == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency Card')),
        body: const Center(
          child: Text(
            'No care recipient selected.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    // Lazy-load (or reload when the active elder changes).
    if (_loadedForElderId != activeElder.id) {
      _loadRescueMeds(activeElder.id);
    }

    final displayName = activeElder.preferredName?.isNotEmpty == true
        ? activeElder.preferredName!
        : activeElder.profileName;
    final meds = medDefs.medDefinitions;

    final activeRescue = kRescueMeds
        .where((m) => _activeRescueMeds.contains(m.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Card'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          children: [
            // ── Emergency card ──────────────────────────────────────
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: AppTheme.dangerColor.withValues(alpha: 0.3),
                    width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.dangerColor.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Red header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(18)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.medical_information_outlined,
                            color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EMERGENCY INFORMATION',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Body
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (activeElder.dateOfBirth.isNotEmpty)
                          _InfoRow(
                            icon: Icons.cake_outlined,
                            label: 'Date of Birth',
                            value: activeElder.dateOfBirth,
                            color: AppTheme.tileIndigo,
                          ),
                        _InfoRow(
                          icon: Icons.warning_amber_outlined,
                          label: 'Allergies',
                          value: activeElder.allergies.isNotEmpty
                              ? activeElder.allergies.join(', ')
                              : 'None listed',
                          color: AppTheme.tileOrange,
                          isWarning: activeElder.allergies.isNotEmpty,
                        ),
                        if (activeElder.dietaryRestrictions.isNotEmpty)
                          _InfoRow(
                            icon: Icons.restaurant_outlined,
                            label: 'Dietary Restrictions',
                            value: activeElder.dietaryRestrictions,
                            color: AppTheme.statusGreen,
                          ),
                        _InfoRow(
                          icon: Icons.medication_outlined,
                          label: 'Current Medications',
                          value: meds.isNotEmpty
                              ? meds
                                  .map((m) => m.dose != null &&
                                          m.dose!.isNotEmpty
                                      ? '${m.name} (${m.dose})'
                                      : m.name)
                                  .join('\n')
                              : 'None listed',
                          color: AppTheme.tileBlue,
                        ),
                        const Divider(height: 32),
                        if (activeElder.emergencyContactName != null &&
                            activeElder
                                .emergencyContactName!.isNotEmpty) ...[
                          _InfoRow(
                            icon: Icons.contact_phone_outlined,
                            label: 'Emergency Contact',
                            value: [
                              activeElder.emergencyContactName!,
                              if (activeElder
                                      .emergencyContactRelationship !=
                                  null)
                                '(${activeElder.emergencyContactRelationship})',
                              if (activeElder.emergencyContactPhone !=
                                  null)
                                activeElder.emergencyContactPhone!,
                            ].join('\n'),
                            color: AppTheme.dangerColor,
                          ),
                        ] else
                          _InfoRow(
                            icon: Icons.contact_phone_outlined,
                            label: 'Emergency Contact',
                            value:
                                'Not set — add in Settings → Manage Care Recipients',
                            color: AppTheme.textLight,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Rescue Medications section ──────────────────────────
            _RescueMedsSection(
              activeMeds: activeRescue,
              onEdit: () => _openRescueMedEditor(activeElder.id),
            ),

            const SizedBox(height: 16),

            // Disclaimer
            Text(
              'Generated by Cecelia Care on ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textLight,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 20),

            // ── Share as PDF button ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => _generateAndSharePdf(
                  context,
                  activeElder,
                  meds.map((m) => m.dose != null && m.dose!.isNotEmpty
                      ? '${m.name} (${m.dose})'
                      : m.name).toList(),
                  activeRescue,
                ),
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text(
                  'Share as PDF',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.dangerColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Share with doctors, nurses, or family members',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF generation + share
  // ---------------------------------------------------------------------------
  Future<void> _generateAndSharePdf(
    BuildContext context,
    ElderProfile elder,
    List<String> medNames,
    List<RescueMed> activeRescue,
  ) async {
    try {
      final displayName = elder.preferredName?.isNotEmpty == true
          ? elder.preferredName!
          : elder.profileName;

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context ctx) {
            return [
              // Header
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#E53935'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'EMERGENCY INFORMATION',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      displayName,
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              if (elder.dateOfBirth.isNotEmpty)
                _pdfInfoRow('Date of Birth', elder.dateOfBirth),
              _pdfInfoRow(
                'Allergies',
                elder.allergies.isNotEmpty
                    ? elder.allergies.join(', ')
                    : 'None listed',
                isHighlight: elder.allergies.isNotEmpty,
              ),
              if (elder.dietaryRestrictions.isNotEmpty)
                _pdfInfoRow('Dietary Restrictions', elder.dietaryRestrictions),
              _pdfInfoRow(
                'Current Medications',
                medNames.isNotEmpty ? medNames.join('\n') : 'None listed',
              ),
              pw.SizedBox(height: 6),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 6),
              if (elder.emergencyContactName != null &&
                  elder.emergencyContactName!.isNotEmpty)
                _pdfInfoRow(
                  'Emergency Contact',
                  [
                    elder.emergencyContactName!,
                    if (elder.emergencyContactRelationship != null)
                      '(${elder.emergencyContactRelationship})',
                    if (elder.emergencyContactPhone != null)
                      elder.emergencyContactPhone!,
                  ].join('\n'),
                )
              else
                _pdfInfoRow('Emergency Contact', 'Not set'),

              // ── Rescue Medications PDF section ──────────────────
              if (activeRescue.isNotEmpty) ...[
                pw.SizedBox(height: 14),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E53935'),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'RESCUE MEDICATION INSTRUCTIONS',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                pw.SizedBox(height: 8),
                ...activeRescue.map(_pdfRescueMed),
              ],

              pw.SizedBox(height: 14),
              pw.Center(
                child: pw.Text(
                  'Generated by Cecelia Care on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey500,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
            ];
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();
      final Directory tempDir = await getTemporaryDirectory();
      final safeName = displayName.replaceAll(RegExp(r'[^\w\s]'), '');
      final file =
          File('${tempDir.path}/Emergency_Card_$safeName.pdf');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'Emergency Card — $displayName',
      );

      if (context.mounted) {
        HapticUtils.success();
      }
    } catch (e) {
      debugPrint('EmergencyCardScreen._generateAndSharePdf error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not generate PDF: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    }
  }

  static pw.Widget _pdfInfoRow(String label, String value,
      {bool isHighlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 14),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: isHighlight
                  ? PdfColor.fromHex('#FFF3E0')
                  : PdfColor.fromHex('#F5F5F5'),
              borderRadius: pw.BorderRadius.circular(6),
              border: isHighlight
                  ? pw.Border.all(
                      color: PdfColor.fromHex('#F57C00'), width: 0.5)
                  : null,
            ),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight:
                    isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isHighlight
                    ? PdfColor.fromHex('#E65100')
                    : PdfColors.grey800,
                lineSpacing: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfRescueMed(RescueMed med) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFFBFB'),
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColor.fromHex('#E53935'), width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            med.name,
            style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#B71C1C')),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Indication: ${med.indication}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.Text(
            'Route: ${med.route}',
            style: const pw.TextStyle(fontSize: 10),
          ),
          pw.SizedBox(height: 6),
          ...List.generate(
            med.steps.length,
            (i) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Text(
                '${i + 1}. ${med.steps[i]}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFEBEE'),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'WARNING: ${med.warning}',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#B71C1C'),
              ),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'CALL 911 IMMEDIATELY',
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#B71C1C')),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Rescue meds section (on-screen)
// ---------------------------------------------------------------------------

class _RescueMedsSection extends StatelessWidget {
  const _RescueMedsSection({
    required this.activeMeds,
    required this.onEdit,
  });

  final List<RescueMed> activeMeds;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.dangerColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              children: [
                Icon(Icons.medication_liquid_outlined,
                    color: AppTheme.dangerColor, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'RESCUE MEDICATIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text(activeMeds.isEmpty ? 'Add' : 'Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.dangerColor,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          if (activeMeds.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No rescue medications selected. Tap "Add" to choose which apply to this care recipient — instructions will appear here and on the shared PDF.',
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: activeMeds
                    .map((m) => _RescueMedCard(med: m))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _RescueMedCard extends StatelessWidget {
  const _RescueMedCard({required this.med});
  final RescueMed med;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: med.color.withValues(alpha: 0.04),
        border:
            Border(left: BorderSide(color: med.color, width: 4)),
      ),
      child: Theme(
        data: Theme.of(context)
            .copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: med.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(med.icon, color: med.color, size: 22),
          ),
          title: Text(
            med.name,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                med.indication,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: med.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  med.route,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: med.color,
                  ),
                ),
              ),
            ],
          ),
          children: [
            ...List.generate(med.steps.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: med.color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        med.steps[i],
                        style: const TextStyle(
                            fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppTheme.dangerColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.dangerColor, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      med.warning,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.dangerColor,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'CALL 911 IMMEDIATELY',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: AppTheme.dangerColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InfoRow — on-screen info row with icon, label, and value
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isWarning = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isWarning
                        ? const Color(0xFFFFF3E0)
                        : AppTheme.backgroundGray,
                    borderRadius: BorderRadius.circular(8),
                    border: isWarning
                        ? Border.all(
                            color: AppTheme.tileOrange
                                .withValues(alpha: 0.3))
                        : null,
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isWarning ? FontWeight.w600 : FontWeight.normal,
                      color: isWarning
                          ? AppTheme.tileOrangeDeep
                          : AppTheme.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
