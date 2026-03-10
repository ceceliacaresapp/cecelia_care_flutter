import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart'; // Import provider
import 'package:cecelia_care_flutter/screens/budget_screen.dart'; // Import the new BudgetScreen
import 'package:cecelia_care_flutter/screens/settings/image_upload_screen.dart';
import 'package:cecelia_care_flutter/screens/resources_screen.dart';
import 'package:go_router/go_router.dart'; // Import GoRouter
import 'package:provider/provider.dart'; // Import Provider

// A new data class to hold the information for each tile.
class _CareAction {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _CareAction({required this.title, required this.icon, required this.onTap});
}

class CareScreen extends StatelessWidget {
  const CareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Define the list of actions to display in the grid.
    final List<_CareAction> careActions = [
      _CareAction(
        title: l10n.manageMedications,
        icon: Icons.medication_liquid_outlined,
        onTap: () {
          // Get the active care recipient from the provider.
          final activeElder =
              Provider.of<ActiveElderProvider>(context, listen: false)
                  .activeElder;

          if (activeElder != null) {
            // Use GoRouter to navigate, passing the elderId as an 'extra' parameter.
            // This ensures the Provider is created correctly by the router.
            context.push('/medications', extra: activeElder.id);
          } else {
            // Show a message if no care recipient is selected.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.settingsNoActiveElderSelected)),
            );
          }
        },
      ),
      _CareAction(
        title: l10n.imageUploadScreenTitle,
        icon: Icons.document_scanner_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ImageUploadScreen(),
          ),
        ),
      ),
      _CareAction(
        title: l10n.helpfulResourcesTitle,
        icon: Icons.menu_book_outlined,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResourcesScreen(),
          ),
        ),
      ),
      // --- I18N UPDATE ---
      // Replaced the hardcoded "Budget Tracker" string.
      _CareAction(
        title: l10n.budgetTrackerTitle, // Changed from "Budget Tracker"
        icon: Icons.account_balance_wallet_outlined,
        onTap: () {
          final activeElder =
              Provider.of<ActiveElderProvider>(context, listen: false)
                  .activeElder;
          if (activeElder != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BudgetScreen(
                  careRecipientId:
                      activeElder.id, // Pass the active recipient's ID
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
    ];

    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 1.0,
        ),
        itemCount: careActions.length,
        itemBuilder: (context, index) {
          final action = careActions[index];
          return _buildCareActionTile(
            context: context,
            icon: action.icon,
            title: action.title,
            onTap: action.onTap,
          );
        },
      ),
    );
  }

  /// A reusable widget to create a consistent look for each action tile.
  Widget _buildCareActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48.0,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 12.0),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}