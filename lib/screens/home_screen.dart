import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
 
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/widgets/confetti_overlay.dart';
import 'package:cecelia_care_flutter/widgets/offline_banner.dart';
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
import 'self_care_screen.dart';
import 'manage_care_recipient_profiles_screen.dart';
import 'onboarding_screen.dart';
 
// ---------------------------------------------------------------------------
// Tab accent colors — 6 tabs. Settings lives in the AppBar gear icon.
// ---------------------------------------------------------------------------
const _kNavColors = [
  Color(0xFF1E88E5), // Home      — blue
  Color(0xFF5C6BC0), // Timeline  — indigo
  Color(0xFFE91E63), // Care      — pink/heart
  Color(0xFF00897B), // Calendar  — teal
  Color(0xFFF57C00), // Expenses  — amber-orange
  Color(0xFF8E24AA), // Self Care — purple
];
 
const _kTimelineIndex = 1;
const _kTabCount = 6;
 
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
 
class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _greetingShown = false;
  bool _onboardingChecked = false;
 
  // One navigator per tab — pushes stay scoped inside the tab so the
  // bottom nav remains visible on every sub-screen.
  final List<GlobalKey<NavigatorState>> _navigatorKeys = List.generate(
    _kTabCount,
    (_) => GlobalKey<NavigatorState>(),
  );
 
  late AppLocalizations _l10n;
 
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
 
    if (!_greetingShown) {
      _showWelcomeGreeting();
    }
  }

  /// Watches [UserProfileProvider.needsOnboarding] reactively.
  /// Called in [build] — when the provider stream delivers the new user's
  /// profile doc with onboardingCompleted == false, this fires the
  /// onboarding screen exactly once. No race condition because we wait
  /// for the provider (which auto-creates the doc) instead of doing a
  /// raw Firestore .get() that can fire before the doc exists.
  void _maybeShowOnboarding(UserProfileProvider provider) {
    if (_onboardingChecked) return;
    if (provider.isLoading) return; // still loading — wait
    if (!provider.needsOnboarding) return; // existing user or already done

    _onboardingChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnboardingScreen(
          onComplete: () {
            if (mounted) Navigator.of(context).pop();
          },
        ),
      ));
    });
  }
 
  void _onItemTapped(int index) {
    if (index == _selectedIndex) {
      // Same tab tapped again → pop to root (standard mobile pattern).
      _navigatorKeys[index]
          .currentState
          ?.popUntil((route) => route.isFirst);
    } else {
      // Switching to a different tab → pop the OLD tab back to its root
      // so when the user returns they see the top-level screen, not
      // whatever sub-screen they had navigated into (e.g. Settings).
      _navigatorKeys[_selectedIndex]
          .currentState
          ?.popUntil((route) => route.isFirst);
      setState(() => _selectedIndex = index);
    }
 
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
 
  // ---------------------------------------------------------------------------
  // Wraps a tab's root widget in a nested Navigator so every Navigator.push
  // inside the tab stays scoped — the bottom nav remains visible.
  // ---------------------------------------------------------------------------
  Widget _buildTab(int index, Widget child) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(
        builder: (_) => _TabScaffold(tabIndex: index, body: child),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context);
    final userProfile = userProfileProvider.userProfile;
    final String preferredTerm =
        userProfile?.preferredTerm ?? _l10n.termElderDefault;

    // Check onboarding reactively — fires once when the provider
    // delivers a new-user profile with onboardingCompleted == false.
    _maybeShowOnboarding(userProfileProvider);
 
    final activeElderProvider =
        Provider.of<ActiveElderProvider>(context);
    final activeElder = activeElderProvider.activeElder;
    final bool isActiveElderLoading = activeElderProvider.isLoading;
 
    // Watch MessageProvider so badge rebuilds on count change.
    final int unreadMessages =
        context.watch<MessageProvider>().unreadCount;
 
    // Role — used to show locked placeholders for viewer role.
    final role = context.watch<ActiveElderProvider>().currentUserRole;
    final bool isViewer = role == CaregiverRole.viewer;
 
    final List<Widget> pages = [
      _buildTab(0, const DashboardScreen()),
      _buildTab(1, const TimelineScreen()),
      _buildTab(
        2,
        !isViewer
            ? const CareScreen()
            : const _ViewerLockedTab(label: 'Care'),
      ),
      // Calendar uses a wrapper that watches ActiveElderProvider so it
      // rebuilds correctly inside the nested navigator.
      _buildTab(3, const _CalendarTabBody()),
      _buildTab(
        4,
        !isViewer
            ? const ExpensesScreen()
            : const _ViewerLockedTab(label: 'Expenses'),
      ),
      _buildTab(
        5,
        !isViewer
            ? const SelfCareScreen()
            : const _ViewerLockedTab(label: 'Self Care'),
      ),
    ];
 
    // PopScope handles the Android back button:
    //  1. If the current tab's navigator can pop → pop within the tab.
    //  2. Otherwise if we're not on Home → switch to Home.
    //  3. Otherwise → let the system handle it (exit app).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final nav = _navigatorKeys[_selectedIndex].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
        } else {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        // No AppBar here — each tab provides its own via _TabScaffold.
        body: ConfettiOverlay(
          child: Column(
            children: [
              // Offline indicator — auto-shows/hides based on connectivity
              const OfflineBanner(),
              // Tab content
              Expanded(
                child: (isActiveElderLoading &&
                        activeElder == null &&
                        _selectedIndex > 0 &&
                        _selectedIndex < 4)
                    ? const Center(child: CircularProgressIndicator())
                    : IndexedStack(index: _selectedIndex, children: pages),
              ),
            ],
          ),
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
                unreadCount: unreadMessages,
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
                icon: Icons.self_improvement_outlined,
                activeIcon: Icons.self_improvement,
                index: 5,
              ),
              label: _l10n.selfCareScreenTitle,
            ),
          ],
        ),
      ),
    );
  }
} // end _HomeScreenState
 
// ---------------------------------------------------------------------------
// _TabScaffold — wraps each tab's root page with a styled AppBar.
//
// Features:
//   • Gradient AppBar (darker → lighter indigo) for visual depth
//   • Title inside a translucent pill for distinction
//   • Settings gear icon in actions — available on every screen
//   • Reactive — title updates when activeElder or preferredTerm changes
//
// Sub-screens pushed via Navigator.push inside a tab get their own
// Scaffold+AppBar (with a back arrow). The bottom nav stays visible
// because the push is scoped to the tab's nested Navigator.
// ---------------------------------------------------------------------------
class _TabScaffold extends StatelessWidget {
  const _TabScaffold({
    required this.tabIndex,
    required this.body,
  });
 
  final int tabIndex;
  final Widget body;
 
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeElder = context.watch<ActiveElderProvider>().activeElder;
    final userProfile = context.watch<UserProfileProvider>().userProfile;
    final preferredTerm =
        userProfile?.preferredTerm ?? l10n.termElderDefault;
 
    final baseTitles = [
      'Home',
      l10n.homeScreenBaseTitleTimeline,
      l10n.careScreenTitle,
      l10n.homeScreenBaseTitleCalendar(preferredTerm),
      l10n.homeScreenBaseTitleExpenses,
      l10n.selfCareScreenTitle,
    ];
 
    String appBarTitle = baseTitles[tabIndex];
    if (activeElder != null && tabIndex > 0 && tabIndex < 5) {
      final elderDisplayName =
          (activeElder.preferredName?.isNotEmpty == true)
              ? activeElder.preferredName!
              : activeElder.profileName;
      appBarTitle = '$elderDisplayName - ${baseTitles[tabIndex]}';
    }
 
    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            appBarTitle,
            style: const TextStyle(fontSize: 17),
          ),
        ),
        centerTitle: true,
        // No back arrow on the tab's root page.
        automaticallyImplyLeading: false,
        // Gradient gives the AppBar visual depth.
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withOpacity(0.82),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        actions: [
          // Care recipient quick-switch avatar — tap to manage profiles.
          if (activeElder != null)
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) =>
                      const ManageCareRecipientProfilesScreen(),
                ));
              },
              child: Tooltip(
                message: 'Switch care recipient',
                child: Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: CircleAvatar(
                    radius: 15,
                    backgroundColor: Colors.white.withOpacity(0.25),
                    backgroundImage:
                        (activeElder.photoUrl?.isNotEmpty == true)
                            ? NetworkImage(activeElder.photoUrl!)
                            : null,
                    child: (activeElder.photoUrl == null ||
                            activeElder.photoUrl!.isEmpty)
                        ? Text(
                            activeElder.profileName[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.homeScreenBaseTitleSettings,
            onPressed: () {
              // Push Settings onto the current tab's nested navigator
              // so the bottom nav stays visible.
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(
                    title: Text(l10n.homeScreenBaseTitleSettings),
                    centerTitle: true,
                    flexibleSpace: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.82),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ),
                  body: SettingsScreen(),
                ),
              ));
            },
          ),
        ],
      ),
      body: body,
    );
  }
}
 
// ---------------------------------------------------------------------------
// _CalendarTabBody — watches ActiveElderProvider so the Calendar rebuilds
// correctly inside the nested navigator when the active elder changes.
//
// CalendarScreen takes activeElder as a constructor param. Inside a nested
// Navigator the widget is only built once via onGenerateRoute. This wrapper
// lives inside the route tree but watches the provider directly, so when
// activeElder changes it rebuilds and passes fresh props to CalendarScreen.
// ---------------------------------------------------------------------------
class _CalendarTabBody extends StatelessWidget {
  const _CalendarTabBody();
 
  @override
  Widget build(BuildContext context) {
    final activeElder = context.watch<ActiveElderProvider>().activeElder;
    final currentUser = FirebaseAuth.instance.currentUser;
 
    if (activeElder == null) {
      final l10n = AppLocalizations.of(context)!;
      final userProfile = context.watch<UserProfileProvider>().userProfile;
      final preferredTerm =
          userProfile?.preferredTerm ?? l10n.termElderDefault;
 
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 60, color: AppTheme.textLight),
              const SizedBox(height: 16),
              Text(
                l10n.selectTermToViewCalendar(preferredTerm),
                style: AppStyles.emptyStateText,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
 
    return CalendarScreen(
      activeElder: activeElder,
      currentUserId: currentUser?.uid,
    );
  }
}
 
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
            const Icon(Icons.lock_outline,
                size: 48, color: Color(0xFF8E24AA)),
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
