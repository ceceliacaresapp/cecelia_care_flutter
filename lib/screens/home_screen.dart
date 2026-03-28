import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import '../providers/active_elder_provider.dart';
import '../providers/message_provider.dart';
import '../models/caregiver_role.dart';
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

const _kTimelineIndex = 1;

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
    setState(() => _selectedIndex = index);

    // Mark messages read when the user taps the Timeline tab.
    if (index == _kTimelineIndex) {
      context.read<MessageProvider>().markRead();
    }
  }

  void _showWelcomeGreeting() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _greetingShown) return;

      final userProfile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;
      final activeElder =
          Provider.of<ActiveElderProvider>(context, listen: false).activeElder;

      if (userProfile != null && activeElder != null) {
        final userName = userProfile.displayName.isNotEmpty
            ? userProfile.displayName
            : _l10n.timelineAnonymousUser;
        final elderName = (activeElder.preferredName?.isNotEmpty == true)
            ? activeElder.preferredName!
            : activeElder.profileName;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(_l10n.homeScreenWelcomeGreeting(userName, elderName)),
            duration: const Duration(seconds: 5),
          ),
        );
        _greetingShown = true;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Nav icon with optional unread badge.
  // For the Timeline tab, wraps the icon in a Stack with a red count bubble
  // when unreadCount > 0. All other tabs pass unreadCount = 0.
  // ---------------------------------------------------------------------------
  Widget _navIcon({
    required IconData icon,
    required IconData activeIcon,
    required int index,
    int unreadCount = 0,
  }) {
    final bool selected = _selectedIndex == index;
    final Color color = _kNavColors[index];
    final Widget iconWidget = Icon(
      selected ? activeIcon : icon,
      color: selected ? color : color.withOpacity(0.45),
    );

    if (unreadCount <= 0) return iconWidget;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: -6,
          top: -4,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            constraints:
                const BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              unreadCount > 99 ? '99+' : '$unreadCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile =
        Provider.of<UserProfileProvider>(context).userProfile;
    final String preferredTerm =
        userProfile?.preferredTerm ?? _l10n.termElderDefault;

    final activeElderProvider =
        Provider.of<ActiveElderProvider>(context);
    final activeElder = activeElderProvider.activeElder;
    final bool isActiveElderLoading = activeElderProvider.isLoading;
    final currentUser = FirebaseAuth.instance.currentUser;

    // Watch MessageProvider so badge rebuilds on count change.
    final int unreadMessages =
        context.watch<MessageProvider>().unreadCount;

    // Role — used to hide tabs and nav items for viewer/caregiver.
    final role = context.watch<ActiveElderProvider>().currentUserRole;
    final bool isViewer = role == CaregiverRole.viewer;

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
      final String elderDisplayName =
          (activeElder.preferredName != null &&
                  activeElder.preferredName!.isNotEmpty)
              ? activeElder.preferredName!
              : activeElder.profileName;
      appBarTitle = '$elderDisplayName - ${baseTitles[_selectedIndex]}';
    }

    final List<Widget> pages = [
      const DashboardScreen(),
      const TimelineScreen(),
      // Care tab — hidden for viewer (they see a locked placeholder)
      if (!isViewer) const CareScreen() else _ViewerLockedTab(label: 'Care'),
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
                const Icon(Icons.calendar_today_outlined,
                    size: 60, color: AppTheme.textLight),
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
      if (!isViewer) const ExpensesScreen() else _ViewerLockedTab(label: 'Expenses'),
      SettingsScreen(
        navigateToManageCareRecipientProfiles: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const ManageCareRecipientProfilesScreen(),
            ),
          );
        },
      ),
      if (!isViewer) const SelfCareScreen() else _ViewerLockedTab(label: 'Self Care'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
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
              index: _kTimelineIndex,
              unreadCount: unreadMessages, // ← badge here
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

} // end _HomeScreenState

// ---------------------------------------------------------------------------
// Locked placeholder shown on tabs that viewers cannot access
// ---------------------------------------------------------------------------
class _ViewerLockedTab extends StatelessWidget {
  const _ViewerLockedTab({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Color(0xFF8E24AA)),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8E24AA),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You have view-only access.\nThis section is not available for your role.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF546E7A), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
