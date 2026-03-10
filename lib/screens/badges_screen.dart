import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/widgets/badge_tile.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final badgeProvider = Provider.of<BadgeProvider>(context);
    final allBadges = badgeProvider.badges.values.toList();

    // Sort badges: unlocked first, then by label
    allBadges.sort((a, b) {
      if (a.unlocked && !b.unlocked) return -1;
      if (!a.unlocked && b.unlocked) return 1;
      return a.label.compareTo(b.label);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selfCareScreenTitle), // Assuming "Badges" or "Achievements" would be a good title
                                            // Using selfCareScreenTitle as a placeholder if you don't have a specific one for badges yet.
                                            // You might want to add a "badgesScreenTitle" to your l10n files.
      ),
      body: badgeProvider.errorMessage != null
          ? Center(child: Text('Error: ${badgeProvider.errorMessage}'))
          : allBadges.isEmpty
              ? Center(
                  child: Text(
                    'No badges available yet. Keep using the app to earn them!', // TODO: Localize
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Adjust number of columns
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.8, // Adjust aspect ratio for tile size
                  ),
                  itemCount: allBadges.length,
                  itemBuilder: (context, index) {
                    return BadgeTile(badge: allBadges[index]);
                  },
                ),
    );
  }
}

