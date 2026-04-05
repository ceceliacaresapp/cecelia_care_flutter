import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cecelia_care_flutter/providers/notification_prefs_provider.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- FIX ---
    // Enabled localization and got the theme for consistent styling.
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final prefsProvider = context.watch<NotificationPrefsProvider>();

    return Scaffold(
      appBar: AppBar(
        // Use a localization key for the title.
        title: Text(l10n.notificationPreferencesTitle),
      ),
      body: ListView(
        children: <Widget>[
          if (prefsProvider.isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          // --- FIX ---
          // Updated error handling to use the new `errorInfo` object.
          else if (prefsProvider.errorInfo != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                // Display a localized, user-friendly error message.
                l10n.genericError(prefsProvider.errorInfo!.details),
                style: TextStyle(color: theme.colorScheme.error),
              ),
            )
          else ...[
            // --- FIX ---
            // All titles now use localization keys.
            SwitchListTile(
              title: Text(l10n.medsNotificationsLabel),
              value: prefsProvider.prefs.meds,
              onChanged: (bool value) => prefsProvider.toggleMeds(value),
              secondary: const Icon(Icons.medication_outlined),
            ),
            SwitchListTile(
              title: Text(l10n.calendarNotificationsLabel),
              value: prefsProvider.prefs.calendar,
              onChanged: (bool value) => prefsProvider.toggleCalendar(value),
              secondary: const Icon(Icons.calendar_today_outlined),
            ),
            SwitchListTile(
              title: Text(l10n.selfCareNotificationsLabel),
              value: prefsProvider.prefs.selfCare,
              onChanged: (bool value) => prefsProvider.toggleSelfCare(value),
              secondary: const Icon(Icons.spa_outlined),
            ),
            SwitchListTile(
              title: Text(l10n.chatNotificationsLabel),
              value: prefsProvider.prefs.chatMessages,
              onChanged: (bool value) => prefsProvider.toggleChatMessages(value),
              secondary: const Icon(Icons.chat_bubble_outline),
            ),
            SwitchListTile(
              title: Text(l10n.healthRemindersNotificationsLabel),
              value: prefsProvider.prefs.healthReminders,
              onChanged: (bool value) => prefsProvider.toggleHealthReminders(value),
              secondary: const Icon(Icons.monitor_heart_outlined),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'ALZHEIMER\'S & DEMENTIA',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            SwitchListTile(
              title: Text(l10n.sundowningAlertLabel),
              subtitle: Text(
                l10n.sundowningAlertSubtitle,
                style: const TextStyle(fontSize: 12),
              ),
              value: prefsProvider.prefs.sundowningAlert,
              onChanged: (bool value) async {
                await prefsProvider.toggleSundowningAlert(value);
                if (value) {
                  await NotificationService.instance.scheduleSundowningAlert();
                } else {
                  await NotificationService.instance.cancelSundowningAlert();
                }
              },
              secondary: const Icon(Icons.wb_twilight_outlined),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'SKIN & MOBILITY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Repositioning Reminders'),
              subtitle: const Text(
                'Every 2 hours during daytime (6 AM \u2013 8 PM)',
                style: TextStyle(fontSize: 12),
              ),
              value: prefsProvider.prefs.repositioningReminder,
              onChanged: (bool value) async {
                await prefsProvider.toggleRepositioningReminder(value);
                if (value) {
                  await NotificationService.instance
                      .scheduleRepositioningReminders();
                } else {
                  await NotificationService.instance
                      .cancelRepositioningReminders();
                }
              },
              secondary: const Icon(Icons.rotate_left_outlined),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'NUTRITION & WEIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Weight Loss Alerts'),
              subtitle: const Text(
                'Alert when >5% weight loss in 30 days',
                style: TextStyle(fontSize: 12),
              ),
              value: prefsProvider.prefs.weightAlerts,
              onChanged: (bool value) =>
                  prefsProvider.toggleWeightAlerts(value),
              secondary: const Icon(Icons.monitor_weight_outlined),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'CAREGIVER WELLBEING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text('Burnout Check-in Nudges'),
              subtitle: const Text(
                'Gentle reminder when your wellbeing has been low',
                style: TextStyle(fontSize: 12),
              ),
              value: prefsProvider.prefs.burnoutNudges,
              onChanged: (bool value) =>
                  prefsProvider.toggleBurnoutNudges(value),
              secondary: const Icon(Icons.favorite_border),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            SwitchListTile(
              title: Text(l10n.generalNotificationsLabel),
              value: prefsProvider.prefs.generalDefault,
              onChanged: (bool value) => prefsProvider.toggleGeneralDefault(value),
              secondary: const Icon(Icons.notifications_active_outlined),
            ),
          ],
        ],
      ),
    );
  }
}