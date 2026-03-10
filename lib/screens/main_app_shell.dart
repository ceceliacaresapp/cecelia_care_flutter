import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/screens/timeline_screen.dart';
import 'package:cecelia_care_flutter/screens/care_screen.dart';
import 'package:cecelia_care_flutter/screens/calendar_screen.dart';
import 'package:cecelia_care_flutter/screens/expenses_screen.dart';
import 'package:cecelia_care_flutter/screens/settings_screen.dart';
import 'package:cecelia_care_flutter/screens/manage_care_recipient_profiles_screen.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

class MainAppShell extends StatefulWidget {
  final String? currentUserId;

  const MainAppShell({super.key, required this.currentUserId});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeElder = Provider.of<ActiveElderProvider>(context).activeElder;
    final l10n = AppLocalizations.of(context)!;
    final userProfile = Provider.of<UserProfileProvider>(context).userProfile;
    final String preferredTerm =
        userProfile?.preferredTerm ?? l10n.termElderDefault;

    final List<Widget> pages = <Widget>[
      const TimelineScreen(),
      const CareScreen(),
      activeElder != null
          ? CalendarScreen(
              activeElder: activeElder,
              currentUserId: widget.currentUserId,
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 60,
                      // --- STYLE UPDATE ---
                      // Replaced hardcoded color with a theme-based color.
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.selectTermToViewCalendar(preferredTerm),
                      style: AppStyles.emptyStateText,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _currentIndex = 4;
                      }),
                      child: Text(l10n.goToSettingsButton),
                    ),
                  ],
                ),
              ),
            ),
      const ExpensesScreen(),
      // --- FIX ---
      // Changed from navigateToManageElderProfiles to the correct parameter name
      // and imported the corresponding screen.
      SettingsScreen(
        navigateToManageCareRecipientProfiles: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageCareRecipientProfilesScreen(),
            ),
          ).then((_) {
            if (mounted) {
              setState(() {});
            }
          });
        },
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(color: Colors.black),
        unselectedLabelStyle: const TextStyle(color: Colors.black),
        type: BottomNavigationBarType.fixed,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.timeline),
            label: l10n.bottomNavTimeline,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            // --- I18N UPDATE ---
            // Replaced hardcoded "Care" with a localization key.
            label: l10n.careScreenTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: const Icon(Icons.calendar_today),
            label: l10n.bottomNavCalendar(preferredTerm),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.attach_money),
            label: l10n.bottomNavExpenses,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l10n.bottomNavSettings,
          ),
        ],
      ),
    );
  }
}