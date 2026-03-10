import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import '../providers/active_elder_provider.dart';
import '../providers/user_profile_provider.dart';
import 'timeline_screen.dart';
import 'care_screen.dart';
import 'calendar_screen.dart';
import 'expenses_screen.dart';
import 'settings_screen.dart';
import 'manage_care_recipient_profiles_screen.dart';
import 'self_care_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _greetingShown = false;

  // Declare late variables to hold the theme and localization data.
  late AppLocalizations _l10n;
  late ThemeData _theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Fetch the data only when dependencies change.
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);

    if (!_greetingShown) {
      _showWelcomeGreeting();
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showWelcomeGreeting() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _greetingShown) return;

      final userProfileProvider =
          Provider.of<UserProfileProvider>(context, listen: false);
      final activeElderProvider =
          Provider.of<ActiveElderProvider>(context, listen: false);

      final userProfile = userProfileProvider.userProfile;
      final activeElder = activeElderProvider.activeElder;

      if (userProfile != null && activeElder != null) {
        // Use the stored _l10n variable instead of looking it up again.
        final userName = userProfile.displayName.isNotEmpty
            ? userProfile.displayName
            : _l10n.timelineAnonymousUser;
        final elderName = (activeElder.preferredName?.isNotEmpty == true)
            ? activeElder.preferredName!
            : activeElder.profileName;

        final greeting = _l10n.homeScreenWelcomeGreeting(userName, elderName);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(greeting),
            duration: const Duration(seconds: 5),
          ),
        );
        _greetingShown = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = Provider.of<UserProfileProvider>(context).userProfile;
    final String preferredTerm =
        userProfile?.preferredTerm ?? _l10n.termElderDefault;

    final activeElderProvider = Provider.of<ActiveElderProvider>(context);
    final activeElder = activeElderProvider.activeElder;
    final bool isActiveElderLoading = activeElderProvider.isLoading;
    final currentUser = FirebaseAuth.instance.currentUser;

    // --- I18N UPDATE ---
    // Replaced hardcoded "Care" string with a key from AppLocalizations.
    final List<String> baseTitles = [
      _l10n.homeScreenBaseTitleTimeline,
      _l10n.careScreenTitle, // Changed from "Care"
      _l10n.homeScreenBaseTitleCalendar(preferredTerm),
      _l10n.homeScreenBaseTitleExpenses,
      _l10n.homeScreenBaseTitleSettings,
      _l10n.selfCareScreenTitle,
    ];

    String appBarTitle = baseTitles[_selectedIndex];
    if (activeElder != null && _selectedIndex < 4) {
      final String elderDisplayName = (activeElder.preferredName != null &&
              activeElder.preferredName!.isNotEmpty)
          ? activeElder.preferredName!
          : activeElder.profileName;
      appBarTitle = '$elderDisplayName - ${baseTitles[_selectedIndex]}';
    }

    final List<Widget> pages = [
      const TimelineScreen(),
      const CareScreen(),
      if (activeElder != null)
        CalendarScreen(
          activeElder: activeElder,
          currentUserId: currentUser?.uid,
        )
      else
        Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 60,
                  color: AppTheme.textLight,
                ),
                const SizedBox(height: 16),
                Text(
                  _l10n.selectTermToViewCalendar(preferredTerm),
                  style: AppStyles.emptyStateText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      const ExpensesScreen(),
      SettingsScreen(
        navigateToManageCareRecipientProfiles: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageCareRecipientProfilesScreen(),
            ),
          );
        },
      ),
      const SelfCareScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        centerTitle: true,
      ),
      body: SafeArea(
        child: (isActiveElderLoading && activeElder == null && _selectedIndex < 4)
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(index: _selectedIndex, children: pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: _theme.primaryColor,
        unselectedItemColor: AppTheme.textSecondary,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.timeline),
            label: _l10n.bottomNavTimeline,
          ),
          // --- I18N UPDATE ---
          // Replaced hardcoded "Care" string and removed 'const'
          BottomNavigationBarItem(
            icon: const Icon(Icons.favorite_border),
            label: _l10n.careScreenTitle, // Changed from "Care"
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today_outlined),
            activeIcon: const Icon(Icons.calendar_today),
            label: _l10n.bottomNavCalendar(preferredTerm),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_outlined),
            activeIcon: const Icon(Icons.receipt_long),
            label: _l10n.bottomNavExpenses,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: _l10n.bottomNavSettings,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.self_improvement_outlined),
            activeIcon: const Icon(Icons.self_improvement),
            label: _l10n.selfCareScreenTitle,
          ),
        ],
      ),
    );
  }
}