import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:cecelia_care_flutter/providers/self_care_provider.dart';
import 'package:cecelia_care_flutter/models/self_care_reminder.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/widgets/badge_tile.dart';
import 'package:cecelia_care_flutter/models/badge.dart' as app_badge;
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

class SelfCareScreen extends StatefulWidget {
  const SelfCareScreen({super.key});

  @override
  State<SelfCareScreen> createState() => _SelfCareScreenState();
}

class _SelfCareScreenState extends State<SelfCareScreen> {
  final _noteCtrl = TextEditingController();
  String? _lastKnownTodayNote;
  bool _isInit = false;

  final Map<String, int> _stableReminderIds = {
    'hydrate': 1001,
    'stretch': 1002,
    'walk': 1003,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final scProv = context.read<SelfCareProvider>();
      
      // FIX: Added proper error handling to prevent the crash
      Future.wait([
        scProv.load(),
        scProv.loadHistory(),
      ]).catchError((error) {
        debugPrint('Error during initial data load in SelfCareScreen: $error');
        // Return an empty list so Future.wait finishes successfully even if there's an error
        return <void>[]; 
      });
      
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scProv = context.watch<SelfCareProvider>();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (scProv.todayNote != _lastKnownTodayNote) {
      _noteCtrl.text = scProv.todayNote ?? '';
      _lastKnownTodayNote = scProv.todayNote;
    }

    final badgeProvider = Provider.of<BadgeProvider>(context);
    final unlockedBadges =
        badgeProvider.badges.values.where((badge) => badge.unlocked).toList();
    unlockedBadges.sort((a, b) => a.label.compareTo(b.label));

    Widget bodyContent;
    if (scProv.isLoading &&
        scProv.todayMood == null &&
        scProv.reminders.isEmpty) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (scProv.errorInfo != null) {
      // FIX: Ensure error details are passed safely
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            // Fallback string in case genericError is missing or null
            "Error: ${scProv.errorInfo!.details}", 
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      bodyContent = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            // Caregiver Journal Section
            _buildCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.caregiverJournalTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 12.0),
                  Btn(
                    title: l10n.caregiverJournalButton,
                    onPressed: () => context.pushNamed('caregiver-journal'),
                    variant: BtnVariant.primary,
                  ),
                ],
              ),
            ),

            // My Achievements Section
            if (unlockedBadges.isNotEmpty)
              _buildCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.selfCareScreenAchievementsTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 12.0),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: unlockedBadges.length,
                        itemBuilder: (context, index) {
                          final app_badge.Badge badge = unlockedBadges[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: SizedBox(
                              width: 120,
                              child: BadgeTile(badge: badge),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

            // Daily Mood Section
            _buildCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.dailyMood, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ['🙂', '😐', '😔', '😡', '😍'].map((emoji) {
                      return InkWell(
                        onTap: () => scProv.saveMood(emoji, _noteCtrl.text),
                        customBorder: const CircleBorder(),
                        child: Text(emoji, style: const TextStyle(fontSize: 32)),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(labelText: l10n.optionalNote),
                    onSubmitted: (text) =>
                        scProv.saveMood(scProv.todayMood ?? '🙂', text),
                  ),
                ],
              ),
            ),

            // Streak History Section
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: scProv.history.length > 7 ? 7 : scProv.history.length,
                itemBuilder: (ctx, i) {
                  final reversedHistory = scProv.history.reversed.toList();
                  if (i >= reversedHistory.length) return const SizedBox.shrink();

                  final entry = reversedHistory[i];
                  final isStreakDay = i < scProv.currentStreak;
                  final formattedDate = DateFormat('MMM d', Localizations.localeOf(context).languageCode).format(entry.date);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isStreakDay ? theme.primaryColor : Colors.grey.shade300,
                        child: Text(entry.emoji, style: const TextStyle(fontSize: 20)),
                      ),
                      const SizedBox(height: 6),
                      Text(formattedDate, style: theme.textTheme.bodySmall),
                    ],
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Break Reminders Section
            _buildCard(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.breakReminders, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  _buildReminderSwitchListTile(context: context, provider: scProv, id: 'hydrate', label: l10n.hydrate),
                  _buildReminderSwitchListTile(context: context, provider: scProv, id: 'stretch', label: l10n.stretch),
                  _buildReminderSwitchListTile(context: context, provider: scProv, id: 'walk', label: l10n.walk),
                ],
              ),
            ),
            const SizedBox(height: AppStyles.spacingL),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selfCareScreenTitle),
      ),
      body: bodyContent,
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }

  Widget _buildReminderSwitchListTile({
    required BuildContext context,
    required SelfCareProvider provider,
    required String id,
    required String label,
  }) {
    final rem = provider.reminders[id];
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: theme.textTheme.bodyMedium),
      subtitle: Text(rem?.timeOfDay ?? l10n.off, style: theme.textTheme.bodySmall),
      value: rem?.timeOfDay != null,
      activeThumbColor: theme.primaryColor,
      onChanged: (on) async {
        if (!on) {
          await provider.saveReminder(SelfCareReminder(id: id, timeOfDay: null));
          await NotificationService.instance.cancel(_stableReminderIds[id] ?? id.hashCode);
        } else {
          final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
          if (pickedTime != null && mounted) {
            await provider.saveReminder(SelfCareReminder(id: id, timeOfDay: pickedTime.format(context)));
            await NotificationService.instance.scheduleDailyRepeatingNotification(
              notificationId: _stableReminderIds[id] ?? id.hashCode,
              time: pickedTime,
              channelId: 'self_care',
              title: l10n.selfCareReminderTitle,
              // FIX: Used string interpolation instead of potentially missing l10n method
              body: '$label time!', 
              payload: '{"type":"$id", "reminderType":"self_care"}',
            );
          }
        }
      },
    );
  }
}