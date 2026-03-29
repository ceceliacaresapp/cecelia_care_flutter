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
import 'package:provider/provider.dart';

class _CareAction {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _CareAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}

class CareScreen extends StatelessWidget {
  const CareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final role = context.watch<ActiveElderProvider>().currentUserRole;
    final List<_CareAction> careActions = [
      _CareAction(
        title: l10n.manageMedications,
        icon: Icons.medication_liquid_outlined,
        color: const Color(0xFF1E88E5), // blue
        onTap: () {
          final activeElder =
              Provider.of<ActiveElderProvider>(context, listen: false)
                  .activeElder;
          if (activeElder != null) {
            // Use Navigator.push (not GoRouter) so the bottom nav stays visible.
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
      _CareAction(
        title: l10n.imageUploadScreenTitle,
        icon: Icons.document_scanner_outlined,
        color: const Color(0xFF5C6BC0), // indigo
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ImageUploadScreen()),
        ),
      ),
      _CareAction(
        title: l10n.helpfulResourcesTitle,
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF00897B), // teal
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ResourcesScreen()),
        ),
      ),
      if (role.canAccessBudget)
        _CareAction(
          title: l10n.budgetTrackerTitle,
          icon: Icons.account_balance_wallet_outlined,
          color: const Color(0xFFF57C00),
          onTap: () {
            final activeElder =
                Provider.of<ActiveElderProvider>(context, listen: false)
                    .activeElder;
            if (activeElder != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      BudgetScreen(careRecipientId: activeElder.id),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.settingsNoActiveElderSelected)),
              );
            }
          },
        ),
    ];

    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14.0,
          mainAxisSpacing: 14.0,
          childAspectRatio: 1.0,
        ),
        itemCount: careActions.length,
        itemBuilder: (context, index) {
          final action = careActions[index];
          return _CareActionTile(action: action);
        },
      ),
    );
  }
}

class _CareActionTile extends StatelessWidget {
  const _CareActionTile({required this.action});
  final _CareAction action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: action.color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: action.color.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(action.icon, size: 32, color: action.color),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                action.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: action.color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
