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
import 'package:cecelia_care_flutter/screens/resources_screen.dart';
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
    final role = context.watch<ActiveElderProvider>().currentUserRole;
    final activeElder =
        context.watch<ActiveElderProvider>().activeElder;
    final medDefs = context.watch<MedicationDefinitionsProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Featured tile: Manage Medications ──────────────────────
        _FeaturedTile(
          icon: Icons.medication_liquid_outlined,
          title: l10n.manageMedications,
          color: const Color(0xFF1E88E5),
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
          color: const Color(0xFF5C6BC0),
          subtitle: 'Upload photos, receipts, and documents',
          actionLabel: 'Open',
          // Show folder count if available
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
                        color: const Color(0xFF5C6BC0).withOpacity(0.1),
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

        // ── Standard tiles row ────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _StandardTile(
                icon: Icons.menu_book_outlined,
                title: l10n.helpfulResourcesTitle,
                subtitle: '25+ guides & links',
                color: const Color(0xFF00897B),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ResourcesScreen()),
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
                  color: const Color(0xFFF57C00),
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
            // Header row
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

            // Preview chips — show up to 3 medication names
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
