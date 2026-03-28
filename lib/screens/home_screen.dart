import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import '../providers/active_elder_provider.dart';
import '../providers/user_profile_provider.dart';
import 'dashboard_screen.dart';
import 'timeline_screen.dart';
import 'care_screen.dart';
import 'calendar_screen.dart';
import 'expenses_screen.dart';
import 'settings_screen.dart';
import 'manage_care_recipient_profiles_screen.dart';
import 'self_care_screen.dart';

// ---------------------------------------------------------------------------
// Tab accent colors — one distinct color per nav item.
// ---------------------------------------------------------------------------
const _kNavColors = [
  Color(0xFF1E88E5), // Home      — blue
  Color(0xFF5C6BC0), // Timeline  — indigo
  Color(0xFFE91E63), // Care      — pink/heart
  Color(0xFF00897B), // Calendar  — teal
  Color(0xFFF57C00), // Expenses  — amber-orange
  Color(0xFF546E7A), // Settings  — blue-grey
  Color(0xFF8E24AA), // Self Care — purple
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _greetingShown = false;

  late AppLocalizations _l10n;
  late ThemeData _theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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

  // ---------------------------------------------------------------------------
  // Builds a nav icon that uses the tab-specific accent color when selected
  // and a muted version of the same color when unselected.
  // ---------------------------------------------------------------------------
  Widget _navIcon({
    required IconData icon,
    required IconData activeIcon,
    required int index,
  }) {
    final bool selected = _selectedIndex == index;
    final Color color = _kNavColors[index];
    return Icon(
      selected ? activeIcon : icon,
      color: selected ? color : color.withOpacity(0.45),
    );
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

    final List<String> baseTitles = [
      'Home',
      _l10n.homeScreenBaseTitleTimeline,
      _l10n.careScreenTitle,
      _l10n.homeScreenBaseTitleCalendar(preferredTerm),
      _l10n.homeScreenBaseTitleExpenses,
      _l10n.homeScreenBaseTitleSettings,
      _l10n.selfCareScreenTitle,
    ];

    String appBarTitle = baseTitles[_selectedIndex];
    if (activeElder != null && _selectedIndex > 0 && _selectedIndex < 5) {
      final String elderDisplayName = (activeElder.preferredName != null &&
              activeElder.preferredName!.isNotEmpty)
          ? activeElder.preferredName!
          : activeElder.profileName;
      appBarTitle = '$elderDisplayName - ${baseTitles[_selectedIndex]}';
    }

    final List<Widget> pages = [
      const DashboardScreen(),
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
        child: (isActiveElderLoading &&
                activeElder == null &&
                _selectedIndex > 0 &&
                _selectedIndex < 5)
            ? const Center(child: CircularProgressIndicator())
            : IndexedStack(index: _selectedIndex, children: pages),
      ),
      // -----------------------------------------------------------------------
      // FIX: Each nav item now uses its own accent color instead of a single
      // selectedItemColor. We build custom icon widgets per-tab and set
      // selectedItemColor/unselectedItemColor to transparent so Flutter's
      // default tinting doesn't override the custom colors.
      // -----------------------------------------------------------------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        // Transparent so the custom _navIcon colors show through unmodified.
        selectedItemColor: _kNavColors[_selectedIndex],
        unselectedItemColor: AppTheme.textSecondary,
        selectedLabelStyle: TextStyle(
          color: _kNavColors[_selectedIndex],
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          BottomNavigationBarItem(
            icon: _navIcon(
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              index: 0,
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: _navIcon(
              icon: Icons.timeline_outlined,
              activeIcon: Icons.timeline,
              index: 1,
            ),
            label: _l10n.bottomNavTimeline,
          ),
          BottomNavigationBarItem(
            icon: _navIcon(
              icon: Icons.favorite_border,
              activeIcon: Icons.favorite,
              index: 2,
            ),
            label: _l10n.careScreenTitle,
          ),
          BottomNavigationBarItem(
            icon: _navIcon(
              icon: Icons.calendar_today_outlined,
              activeIcon: Icons.calendar_today,
              index: 3,
            ),
            label: _l10n.bottomNavCalendar(preferredTerm),
          ),
          BottomNavigationBarItem(
            icon: _navIcon(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              index: 4,
            ),
            label: _l10n.bottomNavExpenses,
          ),
          BottomNavigationBarItem(
            icon: _navIcon(
              icon: Icons.settings_outlined,
              activeIcon: Icons.settings,
              index: 5,
            ),
            label: _l10n.bottomNavSettings,
          ),
          BottomNavigationBarItem(
            icon: _navIcon(
              icon: Icons.self_improvement_outlined,
              activeIcon: Icons.self_improvement,
              index: 6,
            ),
            label: _l10n.selfCareScreenTitle,
          ),
        ],
      ),
    );
  }
}
