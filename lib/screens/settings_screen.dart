import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/locale_provider.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/user_profile.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/providers/user_profile_provider.dart';
import 'package:provider/provider.dart';
import 'package:cecelia_care_flutter/screens/settings/my_account_screen.dart';
import 'package:cecelia_care_flutter/screens/notification_settings_screen.dart';
import 'package:cecelia_care_flutter/screens/settings/inclusive_language_guide_screen.dart';

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
      _selectedLocale =
          Provider.of<LocaleProvider>(context, listen: false).selectedLocale;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _handleClearData() async {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    final activeElderProvider =
        Provider.of<ActiveElderProvider>(context, listen: false);
    final ElderProfile? activeElder = activeElderProvider.activeElder;
    final userProfileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final UserProfile? currentUser = userProfileProvider.userProfile;

    if (activeElder == null || currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsClearDataErrorElderOrUserMissing),
          ),
        );
      }
      return;
    }

    final bool isPrimaryAdminUser =
        activeElder.primaryAdminUserId == currentUser.uid;

    if (!isPrimaryAdminUser) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsClearDataErrorNotAdmin)),
        );
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsClearDataDialogTitle(activeElder.profileName)),
        content: Text(l10n.settingsClearDataDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.black),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.settingsClearDataDialogConfirmButton),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final List<String> journalTypes = [
        'medication', 'sleep', 'meal', 'mood', 'pain', 'activity', 'vital', 'expense',
      ];
      final daysSnapshot = await FirebaseFirestore.instance
          .collection('elders')
          .doc(activeElder.id)
          .collection('days')
          .get();

      WriteBatch batch1 = FirebaseFirestore.instance.batch();
      for (var dayDoc in daysSnapshot.docs) {
        for (String type in journalTypes) {
          final typeSnapshot = await dayDoc.reference.collection(type).get();
          for (var entryDoc in typeSnapshot.docs) {
            batch1.delete(entryDoc.reference);
          }
        }
      }
      if (daysSnapshot.docs.isNotEmpty) {
        await batch1.commit();
        debugPrint("Cleared journal entries from 'days' subcollections.");
      }

      final medicationsSnapshot = await FirebaseFirestore.instance
          .collection('elderProfiles')
          .doc(activeElder.id)
          .collection('medications')
          .get();
      if (medicationsSnapshot.docs.isNotEmpty) {
        WriteBatch medBatch = FirebaseFirestore.instance.batch();
        for (var doc in medicationsSnapshot.docs) {
          medBatch.delete(doc.reference);
        }
        await medBatch.commit();
        debugPrint(
            'Deleted ${medicationsSnapshot.docs.length} medication entries from subcollection.');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(l10n.settingsClearDataSuccess(activeElder.profileName)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error clearing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsClearDataErrorGeneric(e.toString())),
          ),
        );
      }
    }
  }

  String _getLanguageDisplayName(Locale locale, AppLocalizations l10n) {
    switch (locale.languageCode) {
      case 'en':
        return l10n.languageNameEn;
      case 'es':
        return l10n.languageNameEs;
      case 'ko':
        return l10n.languageNameKo;
      case 'ja':
        return l10n.languageNameJa;
      case 'zh':
        return l10n.languageNameZh;
      default:
        return locale.toLanguageTag();
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

    final bool isPrimaryAdmin = (activeElder != null &&
        userProfile != null &&
        activeElder.primaryAdminUserId == userProfile.uid);

    if (_selectedLocale == null ||
        !AppLocalizations.supportedLocales.contains(_selectedLocale)) {
      _selectedLocale = AppLocalizations.supportedLocales.firstWhere(
        (sl) =>
            _selectedLocale != null &&
            sl.languageCode == _selectedLocale!.languageCode,
        orElse: () => AppLocalizations.supportedLocales.first,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isLoadingUserProfile && userProfile == null) ...[
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 12),
          ] else if (userProfile != null) ...[
            Center(
              child: CircleAvatar(
                radius: 48,
                backgroundColor: theme.primaryColor.withOpacity(0.2),
                backgroundImage: userProfile.avatarUrl != null &&
                        userProfile.avatarUrl!.isNotEmpty
                    ? NetworkImage(userProfile.avatarUrl!)
                    : null,
                child: (userProfile.avatarUrl == null ||
                            userProfile.avatarUrl!.isEmpty) &&
                        userProfile.displayName.isNotEmpty
                    ? Text(
                        userProfile.displayName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ).copyWith(color: theme.primaryColor),
                      )
                    : (userProfile.avatarUrl == null ||
                                userProfile.avatarUrl!.isEmpty) &&
                            userProfile.displayName.isEmpty
                        ? Icon(
                            Icons.person,
                            size: 48,
                            color: Theme.of(context).primaryColor,
                          )
                        : null,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                userProfile.displayName,
                style: textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            if (userProfile.email.isNotEmpty)
              Center(
                child: Text(
                  userProfile.email,
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListTile(
                  leading: Icon(Icons.account_circle,
                      size: 24, color: theme.primaryColor),
                  title: Text(l10n.settingsTitleMyAccount,
                      style: textTheme.titleMedium),
                  trailing:
                      Icon(Icons.chevron_right, color: theme.primaryColor),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyAccountScreen()),
                    );
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoadingUserProfile
                    ? null
                    : () => userProfileProvider.signOut(),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.black,
                ),
                child: Text(l10n.settingsButtonSignOut),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ] else ...[
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  l10n.settingsErrorLoadingProfile,
                  style:
                      textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: Icon(Icons.diversity_3,
                    size: 24, color: theme.primaryColor),
                title: Text(l10n.inclusiveLanguageGuideTitle,
                    style: textTheme.titleMedium),
                trailing: Icon(Icons.chevron_right, color: theme.primaryColor),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              const InclusiveLanguageGuideScreen()));
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 16),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settingsTitleLanguage,
                      style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Locale>(
                    decoration: InputDecoration(
                      labelText: l10n.settingsLabelSelectLanguage,
                      labelStyle: textTheme.bodyMedium,
                    ),
                    initialValue: _selectedLocale,
                    items:
                        AppLocalizations.supportedLocales.map((Locale locale) {
                      return DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(_getLanguageDisplayName(locale, l10n),
                            style: textTheme.bodyMedium),
                      );
                    }).toList(),
                    onChanged: (Locale? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedLocale = newValue;
                        });
                        Provider.of<LocaleProvider>(context, listen: false)
                            .setLocale(newValue);
                        debugPrint(
                            'Language selected: ${newValue.toLanguageTag()}');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.settingsLanguageChangedConfirmation(
                                newValue.toLanguageTag(),
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: Icon(Icons.notifications_active_outlined,
                    size: 24, color: theme.primaryColor),
                title: Text(l10n.settingsItemNotificationPreferences,
                    style: textTheme.titleMedium),
                trailing: Icon(Icons.chevron_right, color: theme.primaryColor),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationSettingsScreen()),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),

          Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- I18N UPDATE ---
                  Text(l10n.settingsTitleCareRecipientManagement,
                      style: textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (activeElder != null) ...[
                    // --- I18N UPDATE ---
                    Text(
                      l10n.settingsActiveCareRecipient(activeElder.profileName),
                      style: textTheme.bodyMedium
                          ?.copyWith(fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    // --- I18N UPDATE ---
                    Text(
                      l10n.settingsNoActiveCareRecipient,
                      style:
                          textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    ),
                  ],
                  ListTile(
                    leading: Icon(Icons.group_outlined,
                        size: 24, color: theme.primaryColor),
                    // --- I18N UPDATE ---
                    title: Text(l10n.settingsItemManageProfiles,
                        style: textTheme.titleMedium),
                    trailing:
                        Icon(Icons.chevron_right, color: theme.primaryColor),
                    onTap: widget.navigateToManageCareRecipientProfiles ??
                        () {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              // --- I18N UPDATE ---
                              SnackBar(
                                content: Text(
                                  l10n.settingsErrorCouldNotNavigateToProfiles,
                                ),
                              ),
                            );
                          }
                        },
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),

          if (isPrimaryAdmin) ...[
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsTitleAdminActions(activeElder.profileName),
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: Icon(Icons.delete_forever_outlined,
                          color: theme.primaryColor),
                      // --- I18N UPDATE ---
                      title: Text(
                        l10n.settingsItemClearData,
                        style: textTheme.titleMedium,
                      ),
                      onTap: _handleClearData,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}