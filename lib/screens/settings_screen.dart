import 'package:cecelia_care_flutter/utils/page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:provider/provider.dart';
import 'package:cecelia_care_flutter/screens/settings/my_account_screen.dart';
import 'package:cecelia_care_flutter/screens/notification_settings_screen.dart';
import 'package:cecelia_care_flutter/screens/settings/inclusive_language_guide_screen.dart';
import 'package:cecelia_care_flutter/screens/export_screen.dart';
import 'package:cecelia_care_flutter/models/caregiver_role.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/compact_grid_tile.dart';
import 'package:cecelia_care_flutter/providers/theme_provider.dart';
import 'package:cecelia_care_flutter/screens/manage_care_recipient_profiles_screen.dart';
import 'package:cecelia_care_flutter/screens/invite/create_invite_screen.dart';
import 'package:cecelia_care_flutter/screens/invite/redeem_invite_screen.dart';
import 'package:cecelia_care_flutter/screens/settings/dashboard_settings_screen.dart';
import 'package:cecelia_care_flutter/screens/settings/custom_entry_types_screen.dart';
import 'package:cecelia_care_flutter/screens/accessibility_settings_screen.dart';
import 'package:cecelia_care_flutter/services/biometric_lock_service.dart';
import 'package:cecelia_care_flutter/widgets/staggered_fade_in.dart';
import 'package:cecelia_care_flutter/widgets/cached_avatar.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? navigateToManageCareRecipientProfiles;
  const SettingsScreen({super.key, this.navigateToManageCareRecipientProfiles});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void dispose() { super.dispose(); }

  Widget? _avatarChild(UserProfile profile, Color primaryColor) {
    if (profile.avatarUrl?.isNotEmpty == true) return null;
    if (profile.displayName.isNotEmpty) {
      return Text(profile.displayName[0].toUpperCase(),
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor));
    }
    return Icon(Icons.person, size: 48, color: primaryColor);
  }

  Future<void> _handleClearData() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final activeElder = Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
    final currentUser = Provider.of<UserProfileProvider>(context, listen: false).userProfile;
    if (activeElder == null || currentUser == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settingsClearDataErrorElderOrUserMissing)));
      return;
    }
    if (activeElder.primaryAdminUserId != currentUser.uid) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settingsClearDataErrorNotAdmin)));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsClearDataDialogTitle(activeElder.profileName)),
        content: Text(l10n.settingsClearDataDialogContent),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: Text(l10n.cancelButton)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsClearDataDialogConfirmButton)),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await Provider.of<FirestoreService>(context, listen: false).clearElderData(activeElder.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsClearDataSuccess(activeElder.profileName))));
      }
    } catch (e) {
      debugPrint('SettingsScreen._handleClearData error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsClearDataErrorGeneric(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeElderProvider = Provider.of<ActiveElderProvider>(context);
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final ElderProfile? activeElder = activeElderProvider.activeElder;
    final UserProfile? userProfile = userProfileProvider.userProfile;
    final bool isLoadingUserProfile = userProfileProvider.isLoading;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final bool isPrimaryAdmin = activeElder != null && userProfile != null &&
        activeElder.primaryAdminUserId == userProfile.uid;

    final role = activeElderProvider.currentUserRole;
    final canExport = role.canExport;

    final canAccessProfilesScreen = role.canAccessProfilesScreen;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      children: [
        // ── Profile header card ───────────────────────────────────
        _ProfileHeaderCard(
          userProfile: userProfile,
          isLoading: isLoadingUserProfile,
          errorText: l10n.settingsErrorLoadingProfile,
          theme: theme,
          avatarChild: userProfile != null
              ? _avatarChild(userProfile, Colors.white)
              : null,
        ),

        const SizedBox(height: 12),

        // ── Role indicator ────────────────────────────────────────
        if (!isPrimaryAdmin && activeElder != null)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: AppTheme.backgroundGray,
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              border:
                  Border.all(color: AppTheme.textLight.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                Icon(
                  role == CaregiverRole.viewer
                      ? Icons.visibility_outlined
                      : Icons.favorite_border,
                  size: 16,
                  color: role == CaregiverRole.viewer
                      ? AppTheme.tilePurple
                      : AppTheme.tileTeal,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    role == CaregiverRole.viewer
                        ? 'View-only access to ${activeElder.profileName}\'s care log'
                        : 'Caregiver for ${activeElder.profileName}',
                    style: textTheme.bodySmall
                        ?.copyWith(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),

        // ── People row ────────────────────────────────────────────
        _SectionHeader(label: 'People'),
        const SizedBox(height: 6),
        StaggeredFadeIn(
          index: 0,
          child: Row(
            children: [
              if (canAccessProfilesScreen)
                Expanded(
                  child: _SettingsGridTile(
                    icon: Icons.group_outlined,
                    title: l10n.settingsItemManageProfiles,
                    subtitle: activeElder?.profileName ?? 'Set up profiles',
                    color: AppTheme.tileBlue,
                    onTap: widget.navigateToManageCareRecipientProfiles ??
                        () => Navigator.push(
                              context,
                              FadeSlideRoute(page:
                                      const ManageCareRecipientProfilesScreen()),
                            ),
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: 14),
              Expanded(
                child: _SettingsGridTile(
                  icon: Icons.account_circle_outlined,
                  title: l10n.settingsTitleMyAccount,
                  subtitle: 'Profile & preferences',
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.push(context,
                      FadeSlideRoute(page: const MyAccountScreen())),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Invites row ───────────────────────────────────────────
        // Create Invite is admin-only; Redeem Invite is available to
        // every signed-in user so they can join another family's team.
        _SectionHeader(label: 'Family invites'),
        const SizedBox(height: 6),
        StaggeredFadeIn(
          index: 1,
          child: Row(
            children: [
              if (isPrimaryAdmin)
                Expanded(
                  child: _SettingsGridTile(
                    icon: Icons.group_add_outlined,
                    title: 'Invite family',
                    subtitle: 'Generate a code',
                    color: AppTheme.tileBlue,
                    onTap: () => Navigator.push(
                        context,
                        FadeSlideRoute(
                            page: const CreateInviteScreen())),
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: 14),
              Expanded(
                child: _SettingsGridTile(
                  icon: Icons.vpn_key_outlined,
                  title: 'Redeem invite',
                  subtitle: 'Enter a code',
                  color: AppTheme.tileIndigo,
                  onTap: () => Navigator.push(
                      context,
                      FadeSlideRoute(page: const RedeemInviteScreen())),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Customize row ─────────────────────────────────────────
        _SectionHeader(label: 'Customize'),
        const SizedBox(height: 6),
        StaggeredFadeIn(
          index: 1,
          child: Row(
            children: [
              Expanded(
                child: _SettingsGridTile(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Dashboard',
                  subtitle: 'Reorder sections',
                  color: AppTheme.tileTeal,
                  onTap: () => Navigator.push(context,
                      FadeSlideRoute(page:
                              const DashboardSettingsScreen())),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SettingsGridTile(
                  icon: Icons.extension_outlined,
                  title: 'Entry Types',
                  subtitle: 'Custom log fields',
                  color: AppTheme.tileIndigo,
                  onTap: () => Navigator.push(context,
                      FadeSlideRoute(page:
                              const CustomEntryTypesScreen())),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // ── Preferences row ───────────────────────────────────────
        _SectionHeader(label: 'Preferences'),
        const SizedBox(height: 6),
        StaggeredFadeIn(
          index: 2,
          child: Row(
            children: [
              Expanded(
                child: _SettingsGridTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Notifications',
                  subtitle: 'Alerts & reminders',
                  color: AppTheme.tileTeal,
                  onTap: () => Navigator.push(context,
                      FadeSlideRoute(page:
                              const NotificationSettingsScreen())),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SettingsGridTile(
                  icon: Icons.accessibility_new_outlined,
                  title: 'Accessibility',
                  subtitle: 'Visual & sensory',
                  color: AppTheme.tileBlueDark,
                  onTap: () => Navigator.push(context,
                      FadeSlideRoute(page:
                              const AccessibilitySettingsScreen())),
                ),
              ),
            ],
          ),
        ),

        // ── Biometric lock ─────────────────────────────────────────
        if (BiometricLockService.instance.isDeviceSupported)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: _BiometricLockToggle(),
          ),

        const SizedBox(height: 14),

        // ── More row ──────────────────────────────────────────────
        _SectionHeader(label: 'More'),
        const SizedBox(height: 6),
        StaggeredFadeIn(
          index: 3,
          child: Row(
            children: [
              if (canExport)
                Expanded(
                  child: _SettingsGridTile(
                    icon: Icons.download_outlined,
                    title: 'Export Logs',
                    subtitle: 'CSV & PDF reports',
                    color: AppTheme.tileIndigo,
                    onTap: () {
                      if (activeElder == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Please select a care recipient first.')));
                        return;
                      }
                      Navigator.push(
                          context,
                          FadeSlideRoute(page:
                                  ExportScreen(activeElder: activeElder)));
                    },
                  ),
                )
              else
                const Expanded(child: SizedBox.shrink()),
              const SizedBox(width: 14),
              Expanded(
                child: _SettingsGridTile(
                  icon: Icons.diversity_3_outlined,
                  title: 'Language Guide',
                  subtitle: 'Inclusive care terms',
                  color: AppTheme.tilePurple,
                  onTap: () => Navigator.push(
                      context,
                      FadeSlideRoute(page:
                              const InclusiveLanguageGuideScreen())),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),
        StaggeredFadeIn(
          index: 4,
          child: Row(
            children: [
              Expanded(
                child: _SettingsGridTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How we handle data',
                  color: AppTheme.tileBlueDark,
                  onTap: () => launchUrl(
                    Uri.parse('https://ceceliacareapp.web.app/privacy-policy.html'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _SettingsGridTile(
                  icon: Icons.language_outlined,
                  title: 'Website',
                  subtitle: 'ceceliacareapp.web.app',
                  color: AppTheme.primaryColor,
                  onTap: () => launchUrl(
                    Uri.parse('https://ceceliacareapp.web.app'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // ── Appearance ────────────────────────────────────────────
        _SectionHeader(label: 'Appearance'),
        const SizedBox(height: 6),
        const _DarkModeSelector(),

        const SizedBox(height: 24),

        // ── Sign out ──────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isLoadingUserProfile
                ? null
                : () => userProfileProvider.signOut(),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusM)),
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.settingsButtonSignOut),
          ),
        ),

        // ── Admin danger zone ─────────────────────────────────────
        if (isPrimaryAdmin) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              border: Border.all(
                  color: AppTheme.dangerColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADMIN: ${activeElder.profileName}'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppTheme.dangerColor,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _handleClearData,
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.dangerColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: const Icon(Icons.delete_forever_outlined,
                            color: AppTheme.dangerColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(l10n.settingsItemClearData,
                            style: TextStyle(
                                color: AppTheme.dangerColor,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),
      ],
    );
  }
}

// Profile header gradient card
class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.userProfile,
    required this.isLoading,
    required this.errorText,
    required this.theme,
    this.avatarChild,
  });

  final UserProfile? userProfile;
  final bool isLoading;
  final String errorText;
  final ThemeData theme;
  final Widget? avatarChild;

  @override
  Widget build(BuildContext context) {
    if (isLoading && userProfile == null) {
      return const Padding(padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()));
    }
    if (userProfile == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Text(errorText,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
          textAlign: TextAlign.center));
    }
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusL),
        boxShadow: [BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.25),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        CachedAvatar(
          imageUrl: userProfile!.avatarUrl,
          radius: 44,
          backgroundColor: Colors.white.withValues(alpha: 0.25),
          fallbackChild: avatarChild ?? const Icon(Icons.person, size: 48, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(userProfile!.displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          textAlign: TextAlign.center),
        if (userProfile!.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(userProfile!.email,
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
            textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}

// Section header
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppTheme.textSecondary,
          letterSpacing: 0.8, fontWeight: FontWeight.w600)));
  }
}

// Settings grid tile — matches the Care screen's colorful tile pattern
class _SettingsGridTile extends StatelessWidget {
  const _SettingsGridTile({
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
    return CompactGridTile(
      icon: icon,
      title: title,
      color: color,
      onTap: onTap,
    );
  }
}

// ---------------------------------------------------------------------------
// Dark mode selector — three-option segmented control (Light / System / Dark)
// ---------------------------------------------------------------------------

class _DarkModeSelector extends StatelessWidget {
  const _DarkModeSelector();

  static const _kColor = AppTheme.tileIndigo; // indigo — matches export tile

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final current = themeProvider.themeMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _kColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
          border: Border.all(color: _kColor.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kColor.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                  ),
                  child: Icon(
                    themeProvider.isDark(context)
                        ? Icons.dark_mode_outlined
                        : Icons.light_mode_outlined,
                    color: _kColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Theme',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ThemeChip(
                  label: 'Light',
                  icon: Icons.light_mode_outlined,
                  selected: current == ThemeMode.light,
                  onTap: () => themeProvider.setLight(),
                ),
                const SizedBox(width: 8),
                _ThemeChip(
                  label: 'System',
                  icon: Icons.settings_brightness_outlined,
                  selected: current == ThemeMode.system,
                  onTap: () => themeProvider.setSystem(),
                ),
                const SizedBox(width: 8),
                _ThemeChip(
                  label: 'Dark',
                  icon: Icons.dark_mode_outlined,
                  selected: current == ThemeMode.dark,
                  onTap: () => themeProvider.setDark(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  static const _kColor = AppTheme.tileIndigo;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? _kColor.withValues(alpha: 0.12)
                : AppTheme.backgroundGray,
            borderRadius: BorderRadius.circular(AppTheme.radiusS),
            border: Border.all(
              color: selected ? _kColor : Colors.transparent,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? _kColor : AppTheme.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                  color: selected ? _kColor : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Biometric lock toggle
// ---------------------------------------------------------------------------

class _BiometricLockToggle extends StatefulWidget {
  @override
  State<_BiometricLockToggle> createState() => _BiometricLockToggleState();
}

class _BiometricLockToggleState extends State<_BiometricLockToggle> {
  late bool _enabled;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _enabled = BiometricLockService.instance.isEnabled;
  }

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    final success = await BiometricLockService.instance.setEnabled(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (success) _enabled = value;
    });
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          value
              ? 'Biometric lock enabled. The app will lock when you leave.'
              : 'Biometric lock disabled.',
        ),
        backgroundColor: value ? AppTheme.statusGreen : AppTheme.textSecondary,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
            ),
            child: const Icon(Icons.fingerprint,
                color: AppTheme.primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'App lock',
                  style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                Text(
                  _enabled
                      ? 'Biometric or PIN required to open'
                      : 'Off — anyone with your phone can open the app',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          _busy
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Switch(
                  value: _enabled,
                  onChanged: _toggle,
                  activeThumbColor: AppTheme.primaryColor,
                ),
        ],
      ),
    );
  }
}
