import 'package:flutter/material.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/locale_provider.dart';
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
import 'package:cecelia_care_flutter/utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? navigateToManageCareRecipientProfiles;
  const SettingsScreen({super.key, this.navigateToManageCareRecipientProfiles});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Locale? _selectedLocale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _selectedLocale = Provider.of<LocaleProvider>(context, listen: false).selectedLocale;
    });
  }

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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsClearDataSuccess(activeElder.profileName))));
    } catch (e) {
      debugPrint("SettingsScreen._handleClearData error: $e");
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsClearDataErrorGeneric(e.toString()))));
    }
  }

  String _getLanguageDisplayName(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case "en": return l10n.languageNameEn;
      case "es": return l10n.languageNameEs;
      case "ko": return l10n.languageNameKo;
      case "ja": return l10n.languageNameJa;
      case "zh": return l10n.languageNameZh;
      default: return locale.toLanguageTag();
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

    if (_selectedLocale == null || !AppLocalizations.supportedLocales.contains(_selectedLocale)) {
      _selectedLocale = AppLocalizations.supportedLocales.firstWhere(
        (sl) => _selectedLocale != null && sl.languageCode == _selectedLocale!.languageCode,
        orElse: () => AppLocalizations.supportedLocales.first,
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Profile header card
        _ProfileHeaderCard(
          userProfile: userProfile,
          isLoading: isLoadingUserProfile,
          errorText: l10n.settingsErrorLoadingProfile,
          theme: theme,
          avatarChild: userProfile != null ? _avatarChild(userProfile, Colors.white) : null,
        ),

        const SizedBox(height: 24),

        // Account
        _SectionHeader(label: l10n.settingsTitleMyAccount),
        _SettingsTile(
          icon: Icons.account_circle_outlined,
          iconColor: AppTheme.primaryColor,
          title: l10n.settingsTitleMyAccount,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const MyAccountScreen())),
        ),
        const Divider(indent: 56, height: 1),
        _SettingsTile(
          icon: Icons.diversity_3_outlined,
          iconColor: const Color(0xFF8E24AA),
          title: l10n.inclusiveLanguageGuideTitle,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const InclusiveLanguageGuideScreen())),
        ),

        const SizedBox(height: 20),

        // Language
        _SectionHeader(label: l10n.settingsTitleLanguage),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: DropdownButtonFormField<Locale>(
            decoration: InputDecoration(
              labelText: l10n.settingsLabelSelectLanguage,
              labelStyle: textTheme.bodyMedium,
              prefixIcon: const Icon(Icons.language_outlined, color: AppTheme.textSecondary),
              filled: true,
              fillColor: AppTheme.primaryColor.withOpacity(0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
            ),
            value: _selectedLocale,
            items: AppLocalizations.supportedLocales.map((Locale locale) =>
              DropdownMenuItem<Locale>(
                value: locale,
                child: Text(_getLanguageDisplayName(locale, l10n), style: textTheme.bodyMedium),
              )).toList(),
            onChanged: (Locale? newValue) {
              if (newValue != null) {
                setState(() => _selectedLocale = newValue);
                Provider.of<LocaleProvider>(context, listen: false).setLocale(newValue);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.settingsLanguageChangedConfirmation(newValue.toLanguageTag()))));
              }
            },
          ),
        ),

        const SizedBox(height: 20),

        // Notifications
        _SectionHeader(label: l10n.settingsItemNotificationPreferences),
        _SettingsTile(
          icon: Icons.notifications_active_outlined,
          iconColor: const Color(0xFF00897B),
          title: l10n.settingsItemNotificationPreferences,
          onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
        ),

        const SizedBox(height: 20),

        // Export & Reports
        const _SectionHeader(label: "Export & Reports"),
        _SettingsTile(
          icon: Icons.download_outlined,
          iconColor: const Color(0xFF5C6BC0),
          title: "Export care logs",
          onTap: () {
            if (activeElder == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Please select a care recipient first.")));
              return;
            }
            Navigator.push(context,
              MaterialPageRoute(builder: (_) => ExportScreen(activeElder: activeElder)));
          },
        ),

        const SizedBox(height: 20),

        // Care recipient
        _SectionHeader(label: l10n.settingsTitleCareRecipientManagement),
        if (activeElder != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(l10n.settingsActiveCareRecipient(activeElder.profileName),
              style: textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Text(l10n.settingsNoActiveCareRecipient,
              style: textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
          ),
        _SettingsTile(
          icon: Icons.group_outlined,
          iconColor: const Color(0xFF1E88E5),
          title: l10n.settingsItemManageProfiles,
          onTap: widget.navigateToManageCareRecipientProfiles ?? () {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.settingsErrorCouldNotNavigateToProfiles)));
          },
        ),

        const SizedBox(height: 24),

        // Sign out
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoadingUserProfile ? null : () => userProfileProvider.signOut(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.settingsButtonSignOut),
            ),
          ),
        ),

        // Admin actions
        if (isPrimaryAdmin) ...[
          const SizedBox(height: 24),
          _SectionHeader(
            label: l10n.settingsTitleAdminActions(activeElder.profileName),
            danger: true,
          ),
          _SettingsTile(
            icon: Icons.delete_forever_outlined,
            title: l10n.settingsItemClearData,
            titleColor: AppTheme.dangerColor,
            iconColor: AppTheme.dangerColor,
            onTap: _handleClearData,
            showChevron: false,
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
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.78)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: AppTheme.primaryColor.withOpacity(0.25),
          blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(children: [
        CircleAvatar(
          radius: 44,
          backgroundColor: Colors.white.withOpacity(0.25),
          backgroundImage: (userProfile!.avatarUrl?.isNotEmpty == true)
            ? NetworkImage(userProfile!.avatarUrl!) : null,
          child: (userProfile!.avatarUrl == null || userProfile!.avatarUrl!.isEmpty)
            ? avatarChild ?? const Icon(Icons.person, size: 48, color: Colors.white)
            : null,
        ),
        const SizedBox(height: 12),
        Text(userProfile!.displayName,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          textAlign: TextAlign.center),
        if (userProfile!.email.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(userProfile!.email,
            style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
            textAlign: TextAlign.center),
        ],
      ]),
    );
  }
}

// Section header
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.danger = false});
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Text(label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: danger ? AppTheme.dangerColor : AppTheme.textSecondary,
          letterSpacing: 0.8, fontWeight: FontWeight.w600)));
  }
}

// Settings tile with colored icon badge
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.iconColor,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? iconColor;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? AppTheme.textSecondary;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title,
        style: theme.textTheme.bodyLarge?.copyWith(color: titleColor)),
      trailing: showChevron
        ? const Icon(Icons.chevron_right, color: AppTheme.textLight, size: 20) : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
