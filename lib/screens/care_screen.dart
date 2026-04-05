// lib/screens/care_screen.dart
//
// Care tab — the caregiver's toolkit. Redesigned with larger featured tiles
// for Medications and Image Scanner, plus standard tiles for Resources
// and Budget.

import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/screens/budget_screen.dart';
import 'package:cecelia_care_flutter/screens/settings/image_upload_screen.dart';
import 'package:cecelia_care_flutter/screens/training_library_screen.dart';
import 'package:cecelia_care_flutter/screens/emergency_card_screen.dart';
import 'package:cecelia_care_flutter/screens/doctor_summary_screen.dart';
import 'package:cecelia_care_flutter/screens/appointment_prep_screen.dart';
import 'package:cecelia_care_flutter/screens/care_plan_templates_screen.dart';
import 'package:cecelia_care_flutter/screens/shift_schedule_screen.dart';
import 'package:cecelia_care_flutter/screens/document_vault_screen.dart';
import 'package:cecelia_care_flutter/screens/respite_care_finder_screen.dart';
import 'package:cecelia_care_flutter/screens/adl_assessment_screen.dart';
import 'package:cecelia_care_flutter/screens/communication_cards_screen.dart';
import 'package:cecelia_care_flutter/screens/wound_tracking_screen.dart';
import 'package:cecelia_care_flutter/screens/behavioral_log_screen.dart';
import 'package:cecelia_care_flutter/screens/wandering_risk_screen.dart';
import 'package:cecelia_care_flutter/screens/elopement_protocol_screen.dart';
import 'package:cecelia_care_flutter/screens/fall_risk_screen.dart';
import 'package:cecelia_care_flutter/screens/skin_integrity_screen.dart';
import 'package:cecelia_care_flutter/screens/weight_trend_screen.dart';
import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/screens/medications/medication_manager_screen.dart';
import 'package:cecelia_care_flutter/providers/medication_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/services/rxnav_service.dart';
import 'package:cecelia_care_flutter/locator.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:provider/provider.dart';

class CareScreen extends StatelessWidget {
  const CareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final elderProv = context.watch<ActiveElderProvider>();
    final role = elderProv.currentUserRole;
    final activeElder = elderProv.activeElder;
    final medDefs = context.watch<MedicationDefinitionsProvider>();

    // In multi-view, care tools need a specific elder — show a picker prompt.
    if (elderProv.isMultiView) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Icon(Icons.touch_app_outlined,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Select a care recipient to access care tools',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('Care tools operate on a specific person\'s data.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: elderProv.allElders.map((elder) {
                final name = elder.preferredName?.isNotEmpty == true
                    ? elder.preferredName!
                    : elder.profileName;
                return ActionChip(
                  avatar: CircleAvatar(
                    radius: 12,
                    backgroundImage: elder.photoUrl != null &&
                            elder.photoUrl!.isNotEmpty
                        ? NetworkImage(elder.photoUrl!)
                        : null,
                    child: elder.photoUrl == null || elder.photoUrl!.isEmpty
                        ? Text(name.isNotEmpty ? name[0] : '?',
                            style: const TextStyle(fontSize: 10))
                        : null,
                  ),
                  label: Text(name),
                  onPressed: () => elderProv.setActive(elder),
                );
              }).toList(),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Featured tile: Manage Medications ──────────────────────
        _FeaturedTile(
          icon: Icons.medication_liquid_outlined,
          title: l10n.manageMedications,
          color: AppTheme.tileBlue,
          subtitle: medDefs.medDefinitions.isNotEmpty
              ? '${medDefs.medDefinitions.length} active medication${medDefs.medDefinitions.length == 1 ? '' : 's'}'
              : 'Add and track medications',
          previewChips: medDefs.medDefinitions.take(3).map((m) {
            return m.name.length > 20
                ? '${m.name.substring(0, 18)}…'
                : m.name;
          }).toList(),
          actionLabel: 'Manage',
          onTap: () {
            if (activeElder != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MultiProvider(
                    providers: [
                      ChangeNotifierProvider<MedicationDefinitionsProvider>(
                        create: (_) => MedicationDefinitionsProvider()
                          ..updateForElder(activeElder),
                      ),
                      ChangeNotifierProvider<MedicationProvider>(
                        create: (ctx) => MedicationProvider(
                          elderId: activeElder.id,
                          firestoreService: ctx.read<FirestoreService>(),
                          rxNavService: locator<RxNavService>(),
                          medDefsProvider:
                              ctx.read<MedicationDefinitionsProvider>(),
                          elderName: activeElder.profileName,
                        ),
                      ),
                    ],
                    child: const MedicationManagerScreen(),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.settingsNoActiveElderSelected)),
              );
            }
          },
        ),

        const SizedBox(height: 14),

        // ── Featured tile: Image Scanner / Documents ──────────────
        _FeaturedTile(
          icon: Icons.document_scanner_outlined,
          title: l10n.imageUploadScreenTitle,
          color: AppTheme.tileIndigo,
          subtitle: 'Upload photos, receipts, and documents',
          actionLabel: 'Open',
          trailingWidget: activeElder != null
              ? StreamBuilder<List<Map<String, dynamic>>>(
                  stream: context
                      .read<FirestoreService>()
                      .getImageFoldersStream(activeElder.id),
                  builder: (ctx, snap) {
                    final count = snap.data?.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.tileIndigo.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count folder${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF5C6BC0),
                        ),
                      ),
                    );
                  },
                )
              : null,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ImageUploadScreen()),
          ),
        ),

        const SizedBox(height: 14),

        // ── Row 1: Resources + Budget ─────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.menu_book_outlined,
                title: l10n.helpfulResourcesTitle,
                subtitle: 'Training & resources',
                color: AppTheme.tileTeal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrainingLibraryScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            if (role.canAccessBudget)
              Expanded(
                child: _StandardTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.budgetTrackerTitle,
                  subtitle: 'Budgets & income',
                  color: AppTheme.tileOrange,
                  onTap: () {
                    if (activeElder != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              BudgetScreen(careRecipientId: activeElder.id),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text(l10n.settingsNoActiveElderSelected)),
                      );
                    }
                  },
                ),
              )
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),

        const SizedBox(height: 14),

        // ── Row 2: Emergency Card + Doctor Summary ────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.medical_information_outlined,
                title: 'Emergency Card',
                subtitle: 'Share with doctors',
                color: AppTheme.dangerColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EmergencyCardScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StandardTile(
                icon: Icons.summarize_outlined,
                title: 'Doctor Summary',
                subtitle: 'Last 7 days PDF',
                color: AppTheme.tileIndigo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DoctorSummaryScreen()),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Row 3: Appointment Prep + Care Plans ──────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.checklist_outlined,
                title: 'Appointment Prep',
                subtitle: '30-day summary',
                color: AppTheme.tileIndigoDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AppointmentPrepScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StandardTile(
                icon: Icons.auto_fix_high_outlined,
                title: 'Care Plans',
                subtitle: 'Auto-fill calendar',
                color: AppTheme.tileTeal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CarePlanTemplatesScreen()),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Row 4: Shift Schedule + Document Vault ────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.schedule_outlined,
                title: 'Shift Schedule',
                subtitle: 'Assign caregivers',
                color: AppTheme.tileBlueDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ShiftScheduleScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StandardTile(
                icon: Icons.folder_special_outlined,
                title: 'Document Vault',
                subtitle: 'Legal & financial',
                color: AppTheme.tileIndigo,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const DocumentVaultScreen()),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Row 5: Respite Finder + ADL Score ─────────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.location_on_outlined,
                title: 'Respite Finder',
                subtitle: 'Find local services',
                color: AppTheme.tileTeal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RespiteCareFinderScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StandardTile(
                icon: Icons.accessibility_new_outlined,
                title: 'ADL Score',
                subtitle: 'Weekly assessment',
                color: AppTheme.tileBlueDark,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AdlAssessmentScreen()),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Row 6: Comm Cards + Wound Tracker ─────────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.sign_language_outlined,
                title: 'Comm Cards',
                subtitle: 'Picture + ASL signs',
                color: AppTheme.tilePurple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CommunicationCardsScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StandardTile(
                icon: Icons.healing_outlined,
                title: 'Wound Tracker',
                subtitle: 'Photo documentation',
                color: AppTheme.statusRed,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WoundTrackingScreen()),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Row 7: Behavioral Log + Wandering Risk ────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.psychology_outlined,
                title: 'Behavioral Log',
                subtitle: 'Track behaviors',
                color: AppTheme.tileOrangeDeep,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BehavioralLogScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StandardTile(
                icon: Icons.directions_walk_outlined,
                title: 'Wandering Risk',
                subtitle: 'Safety assessment',
                color: AppTheme.tileRedDeep,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WanderingRiskScreen()),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Row 8: Elopement Protocol ─────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.emergency_outlined,
                title: 'Elopement Protocol',
                subtitle: 'Missing person response',
                color: AppTheme.statusRedDeep,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ElopementProtocolScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StandardTile(
                icon: Icons.elderly_outlined,
                title: 'Fall Risk',
                subtitle: 'STEADI assessment',
                color: AppTheme.tilePink,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const FallRiskScreen()),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Row 9: Skin Integrity ─────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.airline_seat_flat_outlined,
                title: 'Skin Integrity',
                subtitle: 'Pressure & turning',
                color: const Color(0xFF00838F),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SkinIntegrityScreen()),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _StandardTile(
                icon: Icons.monitor_weight_outlined,
                title: 'Weight Trends',
                subtitle: 'Track & alert',
                color: const Color(0xFF00695C),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const WeightTrendScreen()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Featured tile — large, with subtitle, optional preview chips and trailing
// ---------------------------------------------------------------------------

class _FeaturedTile extends StatelessWidget {
  const _FeaturedTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
    this.previewChips = const [],
    this.actionLabel = 'Open',
    this.trailingWidget,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;
  final List<String> previewChips;
  final String actionLabel;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: color),
                ),
                const SizedBox(width: 14),
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
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingWidget != null) trailingWidget!,
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: color.withOpacity(0.4)),
              ],
            ),
            if (previewChips.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: previewChips.map((label) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.15)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color.withOpacity(0.8),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Standard tile — compact square for secondary actions
// ---------------------------------------------------------------------------

class _StandardTile extends StatelessWidget {
  const _StandardTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
