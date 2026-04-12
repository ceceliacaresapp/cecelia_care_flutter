// lib/screens/care_screen.dart
//
// Care tab — the caregiver's toolkit. Featured tiles (Medications, Image
// Scanner) at the top, then a compact 3-column grid of all other tools.
// The grid order is user-customizable via an edit-mode reorder list, saved
// to SharedPreferences.

import 'package:cecelia_care_flutter/utils/page_transitions.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cecelia_care_flutter/widgets/compact_grid_tile.dart';
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
import 'package:cecelia_care_flutter/screens/cognitive_assessment_screen.dart';
import 'package:cecelia_care_flutter/screens/discharge_checklist_screen.dart';
import 'package:cecelia_care_flutter/screens/pain_history_map_screen.dart';
import 'package:cecelia_care_flutter/screens/task_delegation_screen.dart';
import 'package:cecelia_care_flutter/screens/weight_trend_screen.dart';
import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/screens/medications/medication_manager_screen.dart';
import 'package:cecelia_care_flutter/providers/medication_provider.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/services/rxnav_service.dart';
import 'package:cecelia_care_flutter/locator.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/staggered_fade_in.dart';
import 'package:provider/provider.dart';

class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  static const String _orderPrefsKey = 'care_screen_tile_order';

  /// Persisted custom ordering of tile IDs. Empty until loaded.
  List<String> _customOrder = [];
  bool _orderLoaded = false;
  bool _editMode = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_orderPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).cast<String>();
        if (mounted) {
          setState(() {
            _customOrder = list;
            _orderLoaded = true;
          });
          return;
        }
      } catch (_) {}
    }
    if (mounted) setState(() => _orderLoaded = true);
  }

  Future<void> _saveOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_orderPrefsKey, jsonEncode(_customOrder));
  }

  /// Apply the persisted custom order to the canonical tile list. Tiles
  /// not in the saved order (newly added in code) are appended to the end.
  List<_TileSpec> _orderedTiles(List<_TileSpec> canonical) {
    if (_customOrder.isEmpty) return canonical;
    final byId = {for (final t in canonical) t.id: t};
    final ordered = <_TileSpec>[];
    for (final id in _customOrder) {
      final t = byId.remove(id);
      if (t != null) ordered.add(t);
    }
    ordered.addAll(byId.values); // anything new in code, appended
    return ordered;
  }

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

    final canonicalTiles = _buildTileSpecs(context, l10n, role, activeElder);
    final tiles = _orderedTiles(canonicalTiles);

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
                    if (snap.hasError) {
                      debugPrint(
                          'Care screen image folders stream error: ${snap.error}');
                      return const SizedBox.shrink();
                    }
                    final count = snap.data?.length ?? 0;
                    if (count == 0) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.tileIndigo.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count folder${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.tileIndigo,
                        ),
                      ),
                    );
                  },
                )
              : null,
          onTap: () => Navigator.push(
            context,
            FadeSlideRoute(page: const ImageUploadScreen()),
          ),
        ),

        const SizedBox(height: 18),

        // ── Tools header with edit toggle ──────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              const Text('Tools',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w800)),
              const Spacer(),
              if (_editMode)
                TextButton.icon(
                  onPressed: () {
                    HapticUtils.selection();
                    setState(() => _editMode = false);
                  },
                  icon: const Icon(Icons.check, size: 14),
                  label: const Text('Done', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.primaryColor,
                  ),
                )
              else
                TextButton.icon(
                  onPressed: () {
                    HapticUtils.selection();
                    setState(() => _editMode = true);
                  },
                  icon: const Icon(Icons.tune, size: 14),
                  label:
                      const Text('Reorder', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // ── Tool grid OR reorder list ──────────────────────────────
        if (_editMode)
          _buildReorderList(tiles)
        else
          _buildCompactGrid(tiles),
      ],
    );
  }

  // ── Tile spec catalog (single source of truth) ─────────────────
  List<_TileSpec> _buildTileSpecs(
    BuildContext context,
    AppLocalizations l10n,
    CaregiverRole role,
    dynamic activeElder,
  ) {
    return [
      _TileSpec(
        id: 'resources',
        icon: Icons.menu_book_outlined,
        title: l10n.helpfulResourcesTitle,
        color: AppTheme.tileTeal,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const TrainingLibraryScreen())),
      ),
      if (role.canAccessBudget)
        _TileSpec(
          id: 'budget',
          icon: Icons.account_balance_wallet_outlined,
          title: l10n.budgetTrackerTitle,
          color: AppTheme.tileOrange,
          onTap: () {
            if (activeElder != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        BudgetScreen(careRecipientId: activeElder.id)),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.settingsNoActiveElderSelected)));
            }
          },
        ),
      _TileSpec(
        id: 'emergencyCard',
        icon: Icons.medical_information_outlined,
        title: 'Emergency Card',
        color: AppTheme.dangerColor,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const EmergencyCardScreen())),
      ),
      _TileSpec(
        id: 'doctorSummary',
        icon: Icons.summarize_outlined,
        title: 'Doctor Summary',
        color: AppTheme.tileIndigo,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const DoctorSummaryScreen())),
      ),
      _TileSpec(
        id: 'appointmentPrep',
        icon: Icons.checklist_outlined,
        title: 'Appointment Prep',
        color: AppTheme.tileIndigoDark,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const AppointmentPrepScreen())),
      ),
      _TileSpec(
        id: 'carePlans',
        icon: Icons.auto_fix_high_outlined,
        title: 'Care Plans',
        color: AppTheme.tileTeal,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const CarePlanTemplatesScreen())),
      ),
      _TileSpec(
        id: 'shiftSchedule',
        icon: Icons.schedule_outlined,
        title: 'Shift Schedule',
        color: AppTheme.tileBlueDark,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const ShiftScheduleScreen())),
      ),
      _TileSpec(
        id: 'documentVault',
        icon: Icons.folder_special_outlined,
        title: 'Document Vault',
        color: AppTheme.tileIndigo,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const DocumentVaultScreen())),
      ),
      _TileSpec(
        id: 'respiteFinder',
        icon: Icons.location_on_outlined,
        title: 'Respite Finder',
        color: AppTheme.tileTeal,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const RespiteCareFinderScreen())),
      ),
      _TileSpec(
        id: 'adlScore',
        icon: Icons.accessibility_new_outlined,
        title: 'ADL Score',
        color: AppTheme.tileBlueDark,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const AdlAssessmentScreen())),
      ),
      _TileSpec(
        id: 'commCards',
        icon: Icons.sign_language_outlined,
        title: 'Comm Cards',
        color: AppTheme.tilePurple,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CommunicationCardsScreen())),
      ),
      _TileSpec(
        id: 'woundTracker',
        icon: Icons.healing_outlined,
        title: 'Wound Tracker',
        color: AppTheme.statusRed,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const WoundTrackingScreen())),
      ),
      _TileSpec(
        id: 'behavioralLog',
        icon: Icons.psychology_outlined,
        title: 'Behavioral Log',
        color: AppTheme.tileOrangeDeep,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const BehavioralLogScreen())),
      ),
      _TileSpec(
        id: 'wanderingRisk',
        icon: Icons.directions_walk_outlined,
        title: 'Wandering Risk',
        color: AppTheme.tileRedDeep,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const WanderingRiskScreen())),
      ),
      _TileSpec(
        id: 'elopement',
        icon: Icons.emergency_outlined,
        title: 'Elopement Protocol',
        color: AppTheme.statusRedDeep,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const ElopementProtocolScreen())),
      ),
      _TileSpec(
        id: 'fallRisk',
        icon: Icons.elderly_outlined,
        title: 'Fall Risk',
        color: AppTheme.tilePink,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const FallRiskScreen())),
      ),
      _TileSpec(
        id: 'skinIntegrity',
        icon: Icons.airline_seat_flat_outlined,
        title: 'Skin Integrity',
        color: AppTheme.entryVitalAccent,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const SkinIntegrityScreen())),
      ),
      _TileSpec(
        id: 'weightTrends',
        icon: Icons.monitor_weight_outlined,
        title: 'Weight Trends',
        color: AppTheme.entryActivityAccent,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const WeightTrendScreen())),
      ),
      _TileSpec(
        id: 'taskBoard',
        icon: Icons.task_alt_outlined,
        title: 'Task Board',
        color: AppTheme.tileBlueDark,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const TaskDelegationScreen())),
      ),
      _TileSpec(
        id: 'dischargePlan',
        icon: Icons.assignment_turned_in_outlined,
        title: 'Discharge Plan',
        color: AppTheme.tileBlueDark,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const DischargeChecklistScreen())),
      ),
      _TileSpec(
        id: 'cognitiveScreen',
        icon: Icons.psychology_alt_outlined,
        title: 'Cognitive Screen',
        color: AppTheme.entryMoodAccent,
        onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CognitiveAssessmentScreen())),
      ),
      _TileSpec(
        id: 'painMap',
        icon: Icons.accessibility_outlined,
        title: 'Pain Map',
        color: AppTheme.statusRed,
        onTap: () => Navigator.push(context,
            FadeSlideRoute(page: const PainHistoryMapScreen())),
      ),
    ];
  }

  Widget _buildCompactGrid(List<_TileSpec> tiles) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.95,
      ),
      itemCount: tiles.length,
      itemBuilder: (_, i) {
        final t = tiles[i];
        return StaggeredFadeIn(
          index: i,
          child: CompactGridTile(
            icon: t.icon,
            title: t.title,
            color: t.color,
            onTap: t.onTap,
          ),
        );
      },
    );
  }

  Widget _buildReorderList(List<_TileSpec> tiles) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: true,
      itemCount: tiles.length,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (newIndex > oldIndex) newIndex--;
          final reordered = [...tiles];
          final moved = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, moved);
          _customOrder = reordered.map((t) => t.id).toList();
        });
        _saveOrder();
      },
      itemBuilder: (_, i) {
        final t = tiles[i];
        return Padding(
          key: ValueKey(t.id),
          padding: const EdgeInsets.only(bottom: 6),
          child: CompactListTile(
            icon: t.icon,
            title: t.title,
            color: t.color,
            onTap: () {},
            showChevron: false,
            trailing: Icon(Icons.drag_handle,
                color: AppTheme.textLight, size: 18),
          ),
        );
      },
    );
  }
}

/// Spec for a single Care-screen tile. Stable `id` lets the user's
/// custom ordering survive code changes (new tiles get appended).
class _TileSpec {
  final String id;
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _TileSpec({
    required this.id,
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
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
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
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
                    color: color.withValues(alpha: 0.12),
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
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailingWidget != null) trailingWidget!,
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: color.withValues(alpha: 0.4)),
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
                      color: color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withValues(alpha: 0.15)),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color.withValues(alpha: 0.8),
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

