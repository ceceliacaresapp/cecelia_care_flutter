// lib/screens/succession_planner_screen.dart
//
// Care Network Succession Planner — "If I Can't Be Here".
//
// This screen lets a primary caregiver designate a backup and capture the
// tacit knowledge that never lives in the medical chart: daily routines,
// medication quirks, behavioral triggers, what calms the care recipient,
// doctor communication preferences, insurance details, legal/financial
// contacts, and document locations.
//
// It writes to elderProfiles/{elderId}/successionPlan/primary and produces
// a shareable PDF so a stand-in caregiver can pick up care without the
// primary needing to be reached.
//
// Scope notes:
//  • Admin + caregiver roles can edit; viewers see read-only.
//  • The AI "Suggest" button is wired to AiSuggestionService which
//    currently reports unavailable — the UI surfaces a coming-soon tooltip.
//  • PDF generation matches the visual language of emergency_card_screen's
//    PDF (red accents for emergency, indigo cover) for brand consistency.

import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/succession_plan.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/services/ai_suggestion_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';

const Color _kAccent = AppTheme.tileIndigo;
const Color _kAccentDeep = AppTheme.tileIndigoDeep;

class SuccessionPlannerScreen extends StatefulWidget {
  const SuccessionPlannerScreen({super.key});

  @override
  State<SuccessionPlannerScreen> createState() =>
      _SuccessionPlannerScreenState();
}

class _SuccessionPlannerScreenState extends State<SuccessionPlannerScreen> {
  SuccessionPlan? _plan;
  String? _loadedForElderId;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _hasChanges = false;

  // Controllers for free-text sections. Created once per load; disposed on
  // dispose() OR when the active elder changes mid-session.
  final _dailyRoutineCtrl = TextEditingController();
  final _medQuirksCtrl = TextEditingController();
  final _triggersCtrl = TextEditingController();
  final _calmingCtrl = TextEditingController();
  final _commTipsCtrl = TextEditingController();
  final _historyCtrl = TextEditingController();
  final _docsLocCtrl = TextEditingController();
  final _pharmacyCtrl = TextEditingController();
  final _privateKnowledgeCtrl = TextEditingController();

  // Backup caregiver controllers
  final _backupNameCtrl = TextEditingController();
  final _backupRelCtrl = TextEditingController();
  final _backupPhoneCtrl = TextEditingController();
  final _backupEmailCtrl = TextEditingController();
  final _backupNotesCtrl = TextEditingController();

  // Insurance controllers
  final _insProviderCtrl = TextEditingController();
  final _insPlanCtrl = TextEditingController();
  final _insMemberIdCtrl = TextEditingController();
  final _insGroupCtrl = TextEditingController();
  final _insPhoneCtrl = TextEditingController();
  final _insNotesCtrl = TextEditingController();

  /// Dynamic lists are edited in place; every modification bumps
  /// _hasChanges and rebuilds.
  List<DoctorContact> _doctors = [];
  List<LegalContact> _legalContacts = [];

  @override
  void initState() {
    super.initState();
    final controllers = _allTextControllers();
    for (final c in controllers) {
      c.addListener(_markChanged);
    }
  }

  @override
  void dispose() {
    for (final c in _allTextControllers()) {
      c.dispose();
    }
    super.dispose();
  }

  List<TextEditingController> _allTextControllers() => [
        _dailyRoutineCtrl,
        _medQuirksCtrl,
        _triggersCtrl,
        _calmingCtrl,
        _commTipsCtrl,
        _historyCtrl,
        _docsLocCtrl,
        _pharmacyCtrl,
        _privateKnowledgeCtrl,
        _backupNameCtrl,
        _backupRelCtrl,
        _backupPhoneCtrl,
        _backupEmailCtrl,
        _backupNotesCtrl,
        _insProviderCtrl,
        _insPlanCtrl,
        _insMemberIdCtrl,
        _insGroupCtrl,
        _insPhoneCtrl,
        _insNotesCtrl,
      ];

  void _markChanged() {
    if (!_hasChanges && mounted) setState(() => _hasChanges = true);
  }

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  Future<void> _loadPlanFor(String elderId) async {
    setState(() {
      _isLoading = true;
      _loadedForElderId = elderId;
    });
    try {
      final plan =
          await context.read<FirestoreService>().getSuccessionPlan(elderId);
      if (!mounted) return;
      _hydrateControllersFrom(plan);
      setState(() {
        _plan = plan;
        _isLoading = false;
        _hasChanges = false;
      });
    } catch (e) {
      debugPrint('SuccessionPlannerScreen load error: $e');
      if (!mounted) return;
      setState(() {
        _plan = SuccessionPlan.empty(elderId);
        _isLoading = false;
      });
    }
  }

  void _hydrateControllersFrom(SuccessionPlan plan) {
    _dailyRoutineCtrl.text = plan.dailyRoutine;
    _medQuirksCtrl.text = plan.medicationQuirks;
    _triggersCtrl.text = plan.behavioralTriggers;
    _calmingCtrl.text = plan.calmingTechniques;
    _commTipsCtrl.text = plan.communicationTips;
    _historyCtrl.text = plan.personalHistory;
    _docsLocCtrl.text = plan.documentLocations;
    _pharmacyCtrl.text = plan.pharmacyInfo;
    _privateKnowledgeCtrl.text = plan.privateKnowledge;

    _backupNameCtrl.text = plan.backup.name;
    _backupRelCtrl.text = plan.backup.relationship;
    _backupPhoneCtrl.text = plan.backup.phone;
    _backupEmailCtrl.text = plan.backup.email;
    _backupNotesCtrl.text = plan.backup.notes;

    _insProviderCtrl.text = plan.insurance.provider;
    _insPlanCtrl.text = plan.insurance.planName;
    _insMemberIdCtrl.text = plan.insurance.memberId;
    _insGroupCtrl.text = plan.insurance.groupNumber;
    _insPhoneCtrl.text = plan.insurance.phone;
    _insNotesCtrl.text = plan.insurance.notes;

    _doctors = List.of(plan.doctors);
    _legalContacts = List.of(plan.legalContacts);
  }

  /// Build the latest SuccessionPlan from current controller values.
  SuccessionPlan _currentPlanFromControllers(String elderId) {
    final base = _plan ?? SuccessionPlan.empty(elderId);
    final user = FirebaseAuth.instance.currentUser;
    return base.copyWith(
      elderId: elderId,
      backup: BackupCaregiver(
        name: _backupNameCtrl.text.trim(),
        relationship: _backupRelCtrl.text.trim(),
        phone: _backupPhoneCtrl.text.trim(),
        email: _backupEmailCtrl.text.trim(),
        notes: _backupNotesCtrl.text.trim(),
      ),
      dailyRoutine: _dailyRoutineCtrl.text.trim(),
      medicationQuirks: _medQuirksCtrl.text.trim(),
      behavioralTriggers: _triggersCtrl.text.trim(),
      calmingTechniques: _calmingCtrl.text.trim(),
      communicationTips: _commTipsCtrl.text.trim(),
      personalHistory: _historyCtrl.text.trim(),
      doctors: _doctors,
      insurance: SuccessionInsurancePolicy(
        provider: _insProviderCtrl.text.trim(),
        planName: _insPlanCtrl.text.trim(),
        memberId: _insMemberIdCtrl.text.trim(),
        groupNumber: _insGroupCtrl.text.trim(),
        phone: _insPhoneCtrl.text.trim(),
        notes: _insNotesCtrl.text.trim(),
      ),
      legalContacts: _legalContacts,
      documentLocations: _docsLocCtrl.text.trim(),
      pharmacyInfo: _pharmacyCtrl.text.trim(),
      privateKnowledge: _privateKnowledgeCtrl.text.trim(),
      updatedByUid: user?.uid,
      updatedByName: user?.displayName,
    );
  }

  // ---------------------------------------------------------------------------
  // Save
  // ---------------------------------------------------------------------------

  Future<void> _save({bool silent = false}) async {
    final elder = context.read<ActiveElderProvider>().activeElder;
    if (elder == null || _isSaving) return;
    setState(() => _isSaving = true);
    final updated = _currentPlanFromControllers(elder.id);
    try {
      await context.read<FirestoreService>().saveSuccessionPlan(updated);
      HapticUtils.success();
      if (!mounted) return;
      setState(() {
        _plan = updated;
        _hasChanges = false;
        _isSaving = false;
      });
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Succession plan saved.'),
          backgroundColor: AppTheme.statusGreen,
          duration: Duration(seconds: 2),
        ));
      }
    } catch (e) {
      debugPrint('SuccessionPlannerScreen save error: $e');
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not save: $e'),
        backgroundColor: AppTheme.dangerColor,
      ));
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final elderProv = context.watch<ActiveElderProvider>();
    final elder = elderProv.activeElder;
    final role = elderProv.currentUserRole;
    final canEdit = role.canLog; // admin + caregiver

    if (elder == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Succession Plan'),
          backgroundColor: _kAccent,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'No care recipient selected.',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    // Lazy-load whenever the active elder changes (also on first build).
    if (_loadedForElderId != elder.id) {
      // Post-frame so the setState call doesn't collide with build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_loadedForElderId != elder.id) _loadPlanFor(elder.id);
      });
    }

    final plan = _plan;
    final displayName = elder.preferredName?.isNotEmpty == true
        ? elder.preferredName!
        : elder.profileName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Succession Plan'),
        backgroundColor: _kAccent,
        foregroundColor: Colors.white,
        actions: [
          if (canEdit && _hasChanges)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: TextButton.icon(
                onPressed: _isSaving ? null : () => _save(),
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
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
      body: _isLoading || plan == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _IntroBanner(
                  displayName: displayName,
                  readOnly: !canEdit,
                ),
                const SizedBox(height: 14),
                _ReadinessCard(plan: _currentPlanFromControllers(elder.id)),
                const SizedBox(height: 18),

                // ── Backup caregiver ─────────────────────────────
                _Section(
                  title: 'Designated Backup Caregiver',
                  icon: Icons.supervisor_account_outlined,
                  subtitle:
                      'The person who steps in if you can\'t. They should know they\'re listed.',
                  child: _BackupCaregiverForm(
                    name: _backupNameCtrl,
                    relationship: _backupRelCtrl,
                    phone: _backupPhoneCtrl,
                    email: _backupEmailCtrl,
                    notes: _backupNotesCtrl,
                    readOnly: !canEdit,
                  ),
                ),

                // ── Daily routine ────────────────────────────────
                _SuggestableSection(
                  title: 'Daily Routine',
                  icon: Icons.schedule_outlined,
                  subtitle:
                      'The rhythm of a typical day — wake, meals, meds, quiet time, bedtime.',
                  controller: _dailyRoutineCtrl,
                  hint: 'e.g., Wakes 7 AM. Tea before meds. '
                      'Walk in garden after breakfast. Nap 1–3 PM…',
                  kind: AiSuggestionKind.dailyRoutine,
                  elder: elder,
                  readOnly: !canEdit,
                ),

                // ── Medication quirks ────────────────────────────
                _SuggestableSection(
                  title: 'Medication Quirks',
                  icon: Icons.medication_outlined,
                  subtitle:
                      'What you\'d never know from the label: crushing, timing, what it\'s taken with.',
                  controller: _medQuirksCtrl,
                  hint: 'e.g., Metoprolol must be crushed in applesauce. '
                      'Vitamin D only with fatty meal. Refuses pills unless…',
                  kind: AiSuggestionKind.medicationQuirks,
                  elder: elder,
                  readOnly: !canEdit,
                ),

                // ── Behavioral triggers ──────────────────────────
                _SuggestableSection(
                  title: 'Behavioral Triggers',
                  icon: Icons.warning_amber_outlined,
                  subtitle:
                      'What causes agitation, anxiety, or distress — and the early signs.',
                  controller: _triggersCtrl,
                  hint: 'e.g., Sundowning around 5 PM. '
                      'Gets anxious if bathroom door closes. Loud TV triggers pacing…',
                  kind: AiSuggestionKind.behavioralTriggers,
                  elder: elder,
                  readOnly: !canEdit,
                ),

                // ── What calms them ──────────────────────────────
                _SuggestableSection(
                  title: 'What Calms Them',
                  icon: Icons.spa_outlined,
                  subtitle:
                      'The things that bring comfort — songs, people, objects, routines.',
                  controller: _calmingCtrl,
                  hint: 'e.g., Mozart piano playlist. Holding the blue blanket. '
                      'Looking at the photo album on the coffee table…',
                  kind: AiSuggestionKind.calmingTechniques,
                  elder: elder,
                  readOnly: !canEdit,
                ),

                // ── Communication tips ───────────────────────────
                _SuggestableSection(
                  title: 'Communication Tips',
                  icon: Icons.record_voice_over_outlined,
                  subtitle:
                      'How to speak with them — what works, what doesn\'t.',
                  controller: _commTipsCtrl,
                  hint: 'e.g., Short sentences. Face them directly. '
                      'Give one choice at a time. Never argue about the year…',
                  kind: AiSuggestionKind.communicationTips,
                  elder: elder,
                  readOnly: !canEdit,
                ),

                // ── Personal history ─────────────────────────────
                _SuggestableSection(
                  title: 'Personal History & Preferences',
                  icon: Icons.history_edu_outlined,
                  subtitle:
                      'Stories, likes, dislikes — the person behind the patient.',
                  controller: _historyCtrl,
                  hint: 'e.g., Was a schoolteacher for 30 years. '
                      'Loves birds. Hates pity. Proud of grandkids. '
                      'Favorite dessert: lemon meringue pie…',
                  kind: AiSuggestionKind.personalHistory,
                  elder: elder,
                  readOnly: !canEdit,
                ),

                // ── Doctors ──────────────────────────────────────
                _Section(
                  title: 'Doctor Contacts & Preferences',
                  icon: Icons.local_hospital_outlined,
                  subtitle:
                      'Who to call, in what order, and how they prefer to be reached.',
                  trailing: canEdit
                      ? _AddButton(
                          onTap: () {
                            setState(() {
                              _doctors = [..._doctors, const DoctorContact()];
                              _hasChanges = true;
                            });
                          },
                          label: 'Add doctor',
                        )
                      : null,
                  child: _DoctorList(
                    doctors: _doctors,
                    readOnly: !canEdit,
                    onChanged: (i, doc) {
                      setState(() {
                        _doctors = [..._doctors];
                        _doctors[i] = doc;
                        _hasChanges = true;
                      });
                    },
                    onRemove: (i) {
                      setState(() {
                        _doctors = [..._doctors]..removeAt(i);
                        _hasChanges = true;
                      });
                    },
                  ),
                ),

                // ── Insurance ────────────────────────────────────
                _Section(
                  title: 'Insurance',
                  icon: Icons.shield_moon_outlined,
                  subtitle:
                      'Plan details. Only appears on the PDF — keep physical copies safe.',
                  child: _InsuranceForm(
                    provider: _insProviderCtrl,
                    plan: _insPlanCtrl,
                    memberId: _insMemberIdCtrl,
                    groupNumber: _insGroupCtrl,
                    phone: _insPhoneCtrl,
                    notes: _insNotesCtrl,
                    readOnly: !canEdit,
                  ),
                ),

                // ── Pharmacy ─────────────────────────────────────
                _Section(
                  title: 'Pharmacy',
                  icon: Icons.local_pharmacy_outlined,
                  child: TextField(
                    controller: _pharmacyCtrl,
                    readOnly: !canEdit,
                    maxLines: 3,
                    minLines: 2,
                    decoration: _fieldDecoration(
                      'e.g., CVS on Main St, 555-123-4567. '
                      'Auto-refill on the 5th. Pharmacist: Mei.',
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                // ── Legal / financial contacts ───────────────────
                _Section(
                  title: 'Legal & Financial Contacts',
                  icon: Icons.gavel_outlined,
                  subtitle:
                      'Power of attorney, attorney, accountant, banker.',
                  trailing: canEdit
                      ? _AddButton(
                          onTap: () {
                            setState(() {
                              _legalContacts = [
                                ..._legalContacts,
                                const LegalContact()
                              ];
                              _hasChanges = true;
                            });
                          },
                          label: 'Add contact',
                        )
                      : null,
                  child: _LegalContactList(
                    contacts: _legalContacts,
                    readOnly: !canEdit,
                    onChanged: (i, c) {
                      setState(() {
                        _legalContacts = [..._legalContacts];
                        _legalContacts[i] = c;
                        _hasChanges = true;
                      });
                    },
                    onRemove: (i) {
                      setState(() {
                        _legalContacts = [..._legalContacts]..removeAt(i);
                        _hasChanges = true;
                      });
                    },
                  ),
                ),

                // ── Document locations ───────────────────────────
                _Section(
                  title: 'Document Locations',
                  icon: Icons.folder_outlined,
                  subtitle:
                      'Where important papers live — not the papers themselves.',
                  child: TextField(
                    controller: _docsLocCtrl,
                    readOnly: !canEdit,
                    maxLines: 4,
                    minLines: 3,
                    decoration: _fieldDecoration(
                      'e.g., Will + POA in fireproof safe under bed, combo 14-22-7. '
                      'Birth cert in blue folder, top desk drawer. '
                      'Social Security card in wallet.',
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                // ── Private knowledge ────────────────────────────
                _Section(
                  title: 'Things Only I Know',
                  icon: Icons.favorite_outline,
                  subtitle:
                      'The hand-held details. The little things that make everything easier.',
                  child: TextField(
                    controller: _privateKnowledgeCtrl,
                    readOnly: !canEdit,
                    maxLines: 6,
                    minLines: 4,
                    decoration: _fieldDecoration(
                      'e.g., Always say "Dad" — not "Richard". '
                      'Side-sleeps on the right. '
                      'Lost pinky toenail, don\'t be alarmed. '
                      'The cat is his world — make sure she\'s visible.',
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),

                const SizedBox(height: 22),

                // ── Share CTA ────────────────────────────────────
                _ShareButton(
                  enabled: !_isSharing,
                  onTap: () => _generateAndSharePdf(elder, displayName),
                  isSharing: _isSharing,
                ),
                const SizedBox(height: 12),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'The PDF contains contact and insurance details — '
                      'share only with trusted backup caregivers.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF generation
  // ---------------------------------------------------------------------------

  Future<void> _generateAndSharePdf(
      ElderProfile elder, String displayName) async {
    if (_isSharing) return;

    // Auto-save any pending changes first so the PDF matches Firestore.
    if (_hasChanges) {
      await _save(silent: true);
      if (!mounted) return;
    }

    setState(() => _isSharing = true);
    try {
      final plan = _currentPlanFromControllers(elder.id);
      final medDefs =
          context.read<MedicationDefinitionsProvider>().medDefinitions;
      final medSummary = medDefs
          .map((m) =>
              m.dose != null && m.dose!.isNotEmpty ? '${m.name} (${m.dose})' : m.name)
          .toList();
      final preparedBy =
          FirebaseAuth.instance.currentUser?.displayName ?? 'Primary Caregiver';

      final bytes = await _buildPdf(
        elder: elder,
        displayName: displayName,
        plan: plan,
        medSummary: medSummary,
        preparedBy: preparedBy,
      );

      final tempDir = await getTemporaryDirectory();
      final safeName = displayName.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final file = File(
          '${tempDir.path}/If_I_Cant_Be_Here_${safeName.isEmpty ? 'plan' : safeName}.pdf');
      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: 'If I Can\'t Be Here — $displayName',
      );

      HapticUtils.success();
    } catch (e, s) {
      debugPrint('SuccessionPlannerScreen PDF error: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not generate PDF: $e'),
          backgroundColor: AppTheme.dangerColor,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<Uint8List> _buildPdf({
    required ElderProfile elder,
    required String displayName,
    required SuccessionPlan plan,
    required List<String> medSummary,
    required String preparedBy,
  }) async {
    final pdf = pw.Document();
    final dateStamp = DateFormat('MMMM d, yyyy').format(DateTime.now());

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
            'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
            style: const pw.TextStyle(
                fontSize: 9, color: PdfColors.blueGrey400),
          ),
        ),
        build: (ctx) => [
          _pdfCoverBlock(displayName, plan, preparedBy, dateStamp),
          pw.SizedBox(height: 18),

          // Top-of-page "read this first" panel
          _pdfReadFirstPanel(displayName, plan),
          pw.SizedBox(height: 14),

          // Backup caregiver
          _pdfSectionHeader('DESIGNATED BACKUP CAREGIVER',
              color: PdfColors.red700),
          pw.SizedBox(height: 8),
          _pdfBackupBlock(plan.backup),

          // Emergency contact from the elder profile
          if (elder.emergencyContactName != null &&
              elder.emergencyContactName!.isNotEmpty) ...[
            pw.SizedBox(height: 10),
            _pdfKeyValue('Additional emergency contact', [
              elder.emergencyContactName!,
              if (elder.emergencyContactRelationship != null)
                '(${elder.emergencyContactRelationship})',
              if (elder.emergencyContactPhone != null)
                elder.emergencyContactPhone!,
            ].join('  '))
          ],

          // Allergies + DOB from the elder profile for completeness
          pw.SizedBox(height: 14),
          _pdfSectionHeader('QUICK FACTS'),
          pw.SizedBox(height: 6),
          if (elder.dateOfBirth.isNotEmpty)
            _pdfKeyValue('Date of birth', elder.dateOfBirth),
          _pdfKeyValue(
            'Allergies',
            elder.allergies.isEmpty ? 'None listed' : elder.allergies.join(', '),
            highlight: elder.allergies.isNotEmpty,
          ),
          if (elder.dietaryRestrictions.isNotEmpty)
            _pdfKeyValue('Dietary restrictions', elder.dietaryRestrictions),
          _pdfKeyValue(
            'Current medications',
            medSummary.isEmpty ? 'None listed' : medSummary.join('\n'),
          ),

          // Narrative sections
          _pdfNarrative('Daily Routine', plan.dailyRoutine),
          _pdfNarrative('Medication Quirks', plan.medicationQuirks),
          _pdfNarrative('Behavioral Triggers', plan.behavioralTriggers,
              highlight: true),
          _pdfNarrative('What Calms Them', plan.calmingTechniques),
          _pdfNarrative('Communication Tips', plan.communicationTips),
          _pdfNarrative(
              'Personal History & Preferences', plan.personalHistory),

          // Doctors
          if (plan.doctors.any((d) => !d.isEmpty)) ...[
            pw.SizedBox(height: 14),
            _pdfSectionHeader('DOCTOR CONTACTS & PREFERENCES'),
            pw.SizedBox(height: 6),
            ...plan.doctors.where((d) => !d.isEmpty).map(_pdfDoctorBlock),
          ],

          // Insurance
          if (!plan.insurance.isEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSectionHeader('INSURANCE'),
            pw.SizedBox(height: 6),
            _pdfInsuranceBlock(plan.insurance),
          ],

          // Pharmacy
          if (plan.pharmacyInfo.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSectionHeader('PHARMACY'),
            pw.SizedBox(height: 6),
            pw.Text(plan.pharmacyInfo,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
          ],

          // Legal contacts
          if (plan.legalContacts.any((c) => !c.isEmpty)) ...[
            pw.SizedBox(height: 14),
            _pdfSectionHeader('LEGAL & FINANCIAL CONTACTS'),
            pw.SizedBox(height: 6),
            ...plan.legalContacts.where((c) => !c.isEmpty).map(_pdfLegalBlock),
          ],

          // Documents
          if (plan.documentLocations.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSectionHeader('DOCUMENT LOCATIONS'),
            pw.SizedBox(height: 6),
            pw.Text(plan.documentLocations,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
          ],

          // Private
          if (plan.privateKnowledge.trim().isNotEmpty) ...[
            pw.SizedBox(height: 14),
            _pdfSectionHeader('THINGS ONLY I KNOW'),
            pw.SizedBox(height: 6),
            pw.Text(plan.privateKnowledge,
                style: const pw.TextStyle(fontSize: 11, lineSpacing: 3)),
          ],

          pw.SizedBox(height: 22),
          pw.Center(
            child: pw.Text(
              'Prepared with care via Cecelia Care on $dateStamp',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.blueGrey500,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  // ---------------------------------------------------------------------------
  // PDF widgets
  // ---------------------------------------------------------------------------

  pw.Widget _pdfCoverBlock(String displayName, SuccessionPlan plan,
      String preparedBy, String dateStamp) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#EEF1FA'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColor.fromHex('#5C6BC0'), width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'IF I CAN\'T BE HERE',
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#3949AB'),
              letterSpacing: 2.5,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Care succession plan for $displayName',
            style: pw.TextStyle(
              fontSize: 22,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1A237E'),
            ),
          ),
          pw.SizedBox(height: 12),
          _pdfMetaRow('Prepared by', preparedBy),
          _pdfMetaRow('Last updated', dateStamp),
          _pdfMetaRow('Plan readiness',
              '${plan.completenessPercent}% complete '
                  '(${plan.filledSectionCount} of 12 sections)'),
        ],
      ),
    );
  }

  pw.Widget _pdfReadFirstPanel(String displayName, SuccessionPlan plan) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFF8E1'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#F57C00'), width: 0.6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'READ THIS FIRST',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#E65100'),
              letterSpacing: 1.5,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'You\'re reading this because the primary caregiver couldn\'t be '
            'here. $displayName is in your care now — here\'s what you need '
            'to know. In an emergency, dial 911 first. For poison '
            'exposures: 1-800-222-1222. The backup caregiver listed below '
            'is authorized to make routine decisions; medical decisions '
            'follow the POA on file.',
            style: const pw.TextStyle(fontSize: 10, lineSpacing: 3),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfBackupBlock(BackupCaregiver b) {
    if (b.isEmpty) {
      return pw.Text(
        'No backup caregiver designated yet.',
        style: pw.TextStyle(
          fontSize: 11,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
      );
    }
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFEBEE'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#E53935'), width: 0.5),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            b.name.isEmpty ? '(Name not provided)' : b.name,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#B71C1C'),
            ),
          ),
          if (b.relationship.isNotEmpty)
            pw.Text(b.relationship,
                style: const pw.TextStyle(fontSize: 11)),
          pw.SizedBox(height: 4),
          if (b.phone.isNotEmpty)
            _pdfKeyValue('Phone', b.phone, inline: true),
          if (b.email.isNotEmpty)
            _pdfKeyValue('Email', b.email, inline: true),
          if (b.notes.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            _pdfKeyValue('Access & notes', b.notes),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfDoctorBlock(DoctorContact d) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            d.name.isEmpty ? '(Doctor)' : d.name,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (d.specialty.isNotEmpty)
            pw.Text(d.specialty,
                style: pw.TextStyle(
                    fontSize: 10, color: PdfColors.blueGrey600)),
          if (d.phone.isNotEmpty)
            _pdfKeyValue('Phone', d.phone, inline: true),
          if (d.preferences.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            _pdfKeyValue('Preferences', d.preferences),
          ],
        ],
      ),
    );
  }

  pw.Widget _pdfLegalBlock(LegalContact c) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (c.role.isNotEmpty)
            pw.Text(c.role.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 1.2,
                  color: PdfColors.blueGrey600,
                )),
          pw.Text(
            c.name.isEmpty ? '(Name)' : c.name,
            style: pw.TextStyle(
                fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          if (c.phone.isNotEmpty)
            _pdfKeyValue('Phone', c.phone, inline: true),
          if (c.notes.isNotEmpty) _pdfKeyValue('Notes', c.notes),
        ],
      ),
    );
  }

  pw.Widget _pdfInsuranceBlock(SuccessionInsurancePolicy ins) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#F5F5F5'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (ins.provider.isNotEmpty)
            pw.Text(ins.provider,
                style: pw.TextStyle(
                    fontSize: 12, fontWeight: pw.FontWeight.bold)),
          if (ins.planName.isNotEmpty)
            pw.Text(ins.planName,
                style: pw.TextStyle(
                    fontSize: 10, color: PdfColors.blueGrey600)),
          pw.SizedBox(height: 4),
          if (ins.memberId.isNotEmpty)
            _pdfKeyValue('Member ID', ins.memberId, inline: true),
          if (ins.groupNumber.isNotEmpty)
            _pdfKeyValue('Group #', ins.groupNumber, inline: true),
          if (ins.phone.isNotEmpty)
            _pdfKeyValue('Phone', ins.phone, inline: true),
          if (ins.notes.isNotEmpty) _pdfKeyValue('Notes', ins.notes),
        ],
      ),
    );
  }

  pw.Widget _pdfSectionHeader(String text,
      {PdfColor color = PdfColors.indigo700}) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: pw.BoxDecoration(
        color: color,
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
  }

  pw.Widget _pdfNarrative(String title, String body,
      {bool highlight = false}) {
    if (body.trim().isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: highlight
                  ? PdfColor.fromHex('#E65100')
                  : PdfColors.blueGrey700,
              letterSpacing: 1.2,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: highlight
                  ? PdfColor.fromHex('#FFF3E0')
                  : PdfColor.fromHex('#FAFAFA'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              border: highlight
                  ? pw.Border.all(
                      color: PdfColor.fromHex('#F57C00'), width: 0.5)
                  : null,
            ),
            child: pw.Text(
              body,
              style: const pw.TextStyle(fontSize: 11, lineSpacing: 3),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMetaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 92,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfKeyValue(String label, String value,
      {bool inline = false, bool highlight = false}) {
    if (inline) {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('$label: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey600,
              )),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      );
    }
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blueGrey600,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(6),
            decoration: pw.BoxDecoration(
              color: highlight
                  ? PdfColor.fromHex('#FFF3E0')
                  : PdfColor.fromHex('#FAFAFA'),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight:
                    highlight ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: highlight
                    ? PdfColor.fromHex('#E65100')
                    : PdfColors.blueGrey900,
                lineSpacing: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers (screen-level)
// ---------------------------------------------------------------------------

InputDecoration _fieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 12, color: AppTheme.textLight),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.radiusS),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    isDense: true,
  );
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.displayName, required this.readOnly});
  final String displayName;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: _kAccent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake_outlined, color: _kAccentDeep, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Estate planning — for caregiving.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kAccentDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            readOnly
                ? 'You\'re viewing $displayName\'s succession plan. Editing '
                    'is limited to caregivers and admins.'
                : 'Document the details you\'d hate to have to remember in '
                    'a crisis. If you ever can\'t be here — a backup '
                    'caregiver can keep caring for $displayName without '
                    'missing a beat.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppTheme.textSecondary,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.plan});
  final SuccessionPlan plan;

  @override
  Widget build(BuildContext context) {
    final pct = plan.completenessPercent;
    final ratio = (pct / 100).clamp(0.0, 1.0);
    final Color color = pct >= 80
        ? AppTheme.statusGreen
        : pct >= 40
            ? AppTheme.statusAmber
            : AppTheme.dangerColor;
    final label = pct >= 80
        ? 'Plan is ready to share'
        : pct >= 40
            ? 'Filling in nicely'
            : 'Getting started';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'Plan readiness',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text('$pct%',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppTheme.backgroundGray,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$label — ${plan.filledSectionCount} of 12 sections complete',
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: _kAccent.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusM)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: _kAccentDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: _kAccentDeep,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppTheme.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _SuggestableSection extends StatefulWidget {
  const _SuggestableSection({
    required this.title,
    required this.icon,
    required this.subtitle,
    required this.controller,
    required this.hint,
    required this.kind,
    required this.elder,
    required this.readOnly,
  });

  final String title;
  final IconData icon;
  final String subtitle;
  final TextEditingController controller;
  final String hint;
  final AiSuggestionKind kind;
  final ElderProfile elder;
  final bool readOnly;

  @override
  State<_SuggestableSection> createState() => _SuggestableSectionState();
}

class _SuggestableSectionState extends State<_SuggestableSection> {
  bool _loading = false;

  Future<void> _requestSuggestion() async {
    if (_loading) return;
    setState(() => _loading = true);
    final displayName = widget.elder.preferredName?.isNotEmpty == true
        ? widget.elder.preferredName!
        : widget.elder.profileName;
    final result = await AiSuggestionService.instance.suggest(
      AiSuggestionRequest(
        kind: widget.kind,
        elderId: widget.elder.id,
        elderDisplayName: displayName,
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (!result.available || result.suggestion == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          result.errorMessage ??
              'AI suggestions are coming soon. Type from experience — you know them best.',
        ),
        backgroundColor: AppTheme.tileIndigoDark,
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    // Future: when the provider is wired up, diff into the controller.
    widget.controller.text = result.suggestion!;
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: widget.title,
      icon: widget.icon,
      subtitle: widget.subtitle,
      trailing: widget.readOnly
          ? null
          : _SuggestChip(onTap: _requestSuggestion, loading: _loading),
      child: TextField(
        controller: widget.controller,
        readOnly: widget.readOnly,
        maxLines: 6,
        minLines: 3,
        decoration: _fieldDecoration(widget.hint),
        style: const TextStyle(fontSize: 13, height: 1.4),
      ),
    );
  }
}

class _SuggestChip extends StatelessWidget {
  const _SuggestChip({required this.onTap, required this.loading});
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final available = AiSuggestionService.instance.isAvailable;
    return Tooltip(
      message: available
          ? 'Generate a starter draft using this elder\'s logged history'
          : 'AI suggestions are coming soon',
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusXL),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: available
                ? _kAccentDeep.withValues(alpha: 0.1)
                : AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
            border: Border.all(
              color: available
                  ? _kAccentDeep.withValues(alpha: 0.3)
                  : AppTheme.textLight.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
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

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap, required this.label});
  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: _kAccentDeep,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _BackupCaregiverForm extends StatelessWidget {
  const _BackupCaregiverForm({
    required this.name,
    required this.relationship,
    required this.phone,
    required this.email,
    required this.notes,
    required this.readOnly,
  });

  final TextEditingController name;
  final TextEditingController relationship;
  final TextEditingController phone;
  final TextEditingController email;
  final TextEditingController notes;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabeledField(
          label: 'Name *',
          controller: name,
          hint: 'Full name',
          readOnly: readOnly,
        ),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Relationship *',
                controller: relationship,
                hint: 'e.g., Sister, Neighbor',
                readOnly: readOnly,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LabeledField(
                label: 'Phone *',
                controller: phone,
                hint: '(555) 123-4567',
                keyboardType: TextInputType.phone,
                readOnly: readOnly,
                onTapSuffix: phone.text.trim().isEmpty
                    ? null
                    : () => launchUrl(Uri.parse('tel:${phone.text.trim()}')),
                suffixIcon: Icons.call_outlined,
              ),
            ),
          ],
        ),
        _LabeledField(
          label: 'Email',
          controller: email,
          hint: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          readOnly: readOnly,
        ),
        _LabeledField(
          label: 'Access notes',
          controller: notes,
          hint: 'House key, gate code, pet instructions…',
          maxLines: 3,
          readOnly: readOnly,
        ),
      ],
    );
  }
}

class _InsuranceForm extends StatelessWidget {
  const _InsuranceForm({
    required this.provider,
    required this.plan,
    required this.memberId,
    required this.groupNumber,
    required this.phone,
    required this.notes,
    required this.readOnly,
  });

  final TextEditingController provider;
  final TextEditingController plan;
  final TextEditingController memberId;
  final TextEditingController groupNumber;
  final TextEditingController phone;
  final TextEditingController notes;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Provider',
                controller: provider,
                hint: 'e.g., Blue Cross',
                readOnly: readOnly,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LabeledField(
                label: 'Plan name',
                controller: plan,
                hint: 'e.g., PPO Gold',
                readOnly: readOnly,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _LabeledField(
                label: 'Member ID',
                controller: memberId,
                hint: 'ABC123456789',
                readOnly: readOnly,
                inputFormatters: const [],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LabeledField(
                label: 'Group #',
                controller: groupNumber,
                hint: '00123',
                readOnly: readOnly,
              ),
            ),
          ],
        ),
        _LabeledField(
          label: 'Member services phone',
          controller: phone,
          hint: '1-800-555-0100',
          keyboardType: TextInputType.phone,
          readOnly: readOnly,
        ),
        _LabeledField(
          label: 'Notes',
          controller: notes,
          hint: 'Copays, prior auth contact, pharmacy benefit…',
          maxLines: 3,
          readOnly: readOnly,
        ),
      ],
    );
  }
}

class _DoctorList extends StatelessWidget {
  const _DoctorList({
    required this.doctors,
    required this.readOnly,
    required this.onChanged,
    required this.onRemove,
  });

  final List<DoctorContact> doctors;
  final bool readOnly;
  final void Function(int index, DoctorContact doc) onChanged;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (doctors.isEmpty) {
      return Text(
        readOnly
            ? 'No doctor contacts listed.'
            : 'Tap "Add doctor" to start. Include whoever you call first.',
        style: const TextStyle(
            fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < doctors.length; i++)
          _InlineDoctorCard(
            key: ValueKey('doctor_$i'),
            doctor: doctors[i],
            readOnly: readOnly,
            index: i,
            onChanged: (d) => onChanged(i, d),
            onRemove: () => onRemove(i),
          ),
      ],
    );
  }
}

class _InlineDoctorCard extends StatefulWidget {
  const _InlineDoctorCard({
    super.key,
    required this.doctor,
    required this.readOnly,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final DoctorContact doctor;
  final bool readOnly;
  final int index;
  final ValueChanged<DoctorContact> onChanged;
  final VoidCallback onRemove;

  @override
  State<_InlineDoctorCard> createState() => _InlineDoctorCardState();
}

class _InlineDoctorCardState extends State<_InlineDoctorCard> {
  late final TextEditingController _name;
  late final TextEditingController _specialty;
  late final TextEditingController _phone;
  late final TextEditingController _prefs;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.doctor.name);
    _specialty = TextEditingController(text: widget.doctor.specialty);
    _phone = TextEditingController(text: widget.doctor.phone);
    _prefs = TextEditingController(text: widget.doctor.preferences);
  }

  @override
  void dispose() {
    _name.dispose();
    _specialty.dispose();
    _phone.dispose();
    _prefs.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(DoctorContact(
      name: _name.text.trim(),
      specialty: _specialty.text.trim(),
      phone: _phone.text.trim(),
      preferences: _prefs.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Doctor ${widget.index + 1}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.8),
              ),
              const Spacer(),
              if (!widget.readOnly)
                IconButton(
                  tooltip: 'Remove',
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.dangerColor),
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Name',
                  controller: _name,
                  hint: 'Dr. Chen',
                  readOnly: widget.readOnly,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Specialty',
                  controller: _specialty,
                  hint: 'Cardiologist',
                  readOnly: widget.readOnly,
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
          _LabeledField(
            label: 'Phone',
            controller: _phone,
            hint: '(555) 123-4567',
            keyboardType: TextInputType.phone,
            readOnly: widget.readOnly,
            onChanged: (_) => _emit(),
          ),
          _LabeledField(
            label: 'Preferences & notes',
            controller: _prefs,
            hint: 'MyChart preferred. Nurse Sara handles refills.',
            maxLines: 2,
            readOnly: widget.readOnly,
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}

class _LegalContactList extends StatelessWidget {
  const _LegalContactList({
    required this.contacts,
    required this.readOnly,
    required this.onChanged,
    required this.onRemove,
  });

  final List<LegalContact> contacts;
  final bool readOnly;
  final void Function(int index, LegalContact c) onChanged;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Text(
        readOnly
            ? 'No legal or financial contacts listed.'
            : 'Add POA holders, attorney, accountant — anyone with legal or financial standing.',
        style: const TextStyle(
            fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < contacts.length; i++)
          _InlineLegalCard(
            key: ValueKey('legal_$i'),
            contact: contacts[i],
            readOnly: readOnly,
            index: i,
            onChanged: (c) => onChanged(i, c),
            onRemove: () => onRemove(i),
          ),
      ],
    );
  }
}

class _InlineLegalCard extends StatefulWidget {
  const _InlineLegalCard({
    super.key,
    required this.contact,
    required this.readOnly,
    required this.index,
    required this.onChanged,
    required this.onRemove,
  });

  final LegalContact contact;
  final bool readOnly;
  final int index;
  final ValueChanged<LegalContact> onChanged;
  final VoidCallback onRemove;

  @override
  State<_InlineLegalCard> createState() => _InlineLegalCardState();
}

class _InlineLegalCardState extends State<_InlineLegalCard> {
  late final TextEditingController _role;
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _notes;

  static const List<String> _rolePresets = [
    'Power of Attorney',
    'Healthcare Proxy',
    'Attorney',
    'Accountant',
    'Financial Advisor',
    'Banker',
    'Executor',
  ];

  @override
  void initState() {
    super.initState();
    _role = TextEditingController(text: widget.contact.role);
    _name = TextEditingController(text: widget.contact.name);
    _phone = TextEditingController(text: widget.contact.phone);
    _notes = TextEditingController(text: widget.contact.notes);
  }

  @override
  void dispose() {
    _role.dispose();
    _name.dispose();
    _phone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(LegalContact(
      role: _role.text.trim(),
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      notes: _notes.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.backgroundGray,
        borderRadius: BorderRadius.circular(AppTheme.radiusS),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Contact ${widget.index + 1}',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.8),
              ),
              const Spacer(),
              if (!widget.readOnly)
                IconButton(
                  tooltip: 'Remove',
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: AppTheme.dangerColor),
                  visualDensity: VisualDensity.compact,
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          _LabeledField(
            label: 'Role',
            controller: _role,
            hint: 'e.g., Power of Attorney',
            readOnly: widget.readOnly,
            onChanged: (_) => _emit(),
          ),
          if (!widget.readOnly)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _rolePresets.map((preset) {
                  return GestureDetector(
                    onTap: () {
                      _role.text = preset;
                      _emit();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusXL),
                      ),
                      child: Text(preset,
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: _LabeledField(
                  label: 'Name',
                  controller: _name,
                  hint: 'Full name',
                  readOnly: widget.readOnly,
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LabeledField(
                  label: 'Phone',
                  controller: _phone,
                  hint: '(555) 123-4567',
                  keyboardType: TextInputType.phone,
                  readOnly: widget.readOnly,
                  onChanged: (_) => _emit(),
                ),
              ),
            ],
          ),
          _LabeledField(
            label: 'Notes',
            controller: _notes,
            hint: 'Firm name, account ref, scope of authority…',
            maxLines: 2,
            readOnly: widget.readOnly,
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.readOnly = false,
    this.onChanged,
    this.onTapSuffix,
    this.suffixIcon,
    this.inputFormatters,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool readOnly;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTapSuffix;
  final IconData? suffixIcon;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: maxLines > 1 ? 1 : null,
            readOnly: readOnly,
            onChanged: onChanged,
            inputFormatters: inputFormatters,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(fontSize: 12, color: AppTheme.textLight),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 8),
              isDense: true,
              suffixIcon: suffixIcon != null && onTapSuffix != null
                  ? IconButton(
                      icon: Icon(suffixIcon, size: 18),
                      onPressed: onTapSuffix,
                      visualDensity: VisualDensity.compact,
                      color: _kAccentDeep,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton({
    required this.enabled,
    required this.onTap,
    required this.isSharing,
  });

  final bool enabled;
  final VoidCallback onTap;
  final bool isSharing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: enabled ? onTap : null,
        icon: isSharing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.picture_as_pdf_outlined),
        label: Text(
          isSharing ? 'Preparing…' : 'Share "If I Can\'t Be Here" PDF',
          style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _kAccentDeep,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
          ),
          elevation: 2,
        ),
      ),
    );
  }
}
