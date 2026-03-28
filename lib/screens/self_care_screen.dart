import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/providers/self_care_provider.dart';
import 'package:cecelia_care_flutter/models/self_care_reminder.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/models/badge.dart' as app_badge;
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';

// Self-care accent — purple, matching the nav tab.
const _kSelfCareColor = Color(0xFF8E24AA);

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
    "hydrate": 1001,
    "stretch": 1002,
    "walk": 1003,
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final scProv = context.read<SelfCareProvider>();
      Future.wait([scProv.load(), scProv.loadHistory()]).catchError((error) {
        debugPrint("Error during initial data load in SelfCareScreen: $error");
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
      _noteCtrl.text = scProv.todayNote ?? "";
      _lastKnownTodayNote = scProv.todayNote;
    }

    final badgeProvider = Provider.of<BadgeProvider>(context);
    final unlockedBadges = badgeProvider.badges.values
        .where((badge) => badge.unlocked)
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    Widget bodyContent;
    if (scProv.isLoading &&
        scProv.todayMood == null &&
        scProv.reminders.isEmpty) {
      bodyContent = const Center(child: CircularProgressIndicator());
    } else if (scProv.errorInfo != null) {
      bodyContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            "Error: ${scProv.errorInfo!.details}",
            style: TextStyle(color: theme.colorScheme.error),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      bodyContent = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Caregiver Journal
            _SelfCareCard(
              color: _kSelfCareColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _kSelfCareColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.menu_book_outlined,
                          color: _kSelfCareColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Text(l10n.caregiverJournalTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => context.pushNamed("caregiver-journal"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kSelfCareColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(l10n.caregiverJournalButton),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Achievements
            if (unlockedBadges.isNotEmpty) ...[
              _SectionLabel(label: l10n.selfCareScreenAchievementsTitle),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: unlockedBadges.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, i) =>
                      _BadgeChip(badge: unlockedBadges[i]),
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Daily Mood
            _SectionLabel(label: l10n.dailyMood),
            const SizedBox(height: 8),
            _SelfCareCard(
              color: const Color(0xFFE91E63),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: ["🙂", "😐", "😔", "😡", "😍"].map((emoji) {
                      final isSelected = scProv.todayMood == emoji;
                      return GestureDetector(
                        onTap: () => scProv.saveMood(emoji, _noteCtrl.text),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFE91E63).withOpacity(0.15)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(emoji,
                              style: TextStyle(
                                  fontSize: isSelected ? 36 : 30)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _noteCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.optionalNote,
                      filled: true,
                      fillColor: const Color(0xFFE91E63).withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: const Color(0xFFE91E63)
                                .withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: const Color(0xFFE91E63)
                                .withOpacity(0.3)),
                      ),
                    ),
                    onSubmitted: (text) =>
                        scProv.saveMood(scProv.todayMood ?? "🙂", text),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Mood history strip
            if (scProv.history.isNotEmpty) ...[
              _SectionLabel(label: "Mood history"),
              const SizedBox(height: 8),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount:
                      scProv.history.length > 7 ? 7 : scProv.history.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final reversed = scProv.history.reversed.toList();
                    if (i >= reversed.length) return const SizedBox.shrink();
                    final entry = reversed[i];
                    final isStreakDay = i < scProv.currentStreak;
                    final dateLabel = DateFormat("MMM d",
                            Localizations.localeOf(context).languageCode)
                        .format(entry.date);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: isStreakDay
                              ? _kSelfCareColor.withOpacity(0.15)
                              : AppTheme.backgroundGray,
                          child: Text(entry.emoji,
                              style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(height: 4),
                        Text(dateLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary)),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Break reminders
            _SectionLabel(label: l10n.breakReminders),
            const SizedBox(height: 8),
            _SelfCareCard(
              color: const Color(0xFF00897B),
              child: Column(
                children: [
                  _ReminderRow(
                    context: context,
                    provider: scProv,
                    id: "hydrate",
                    label: l10n.hydrate,
                    icon: Icons.water_drop_outlined,
                    stableIds: _stableReminderIds,
                    l10n: l10n,
                  ),
                  const Divider(height: 1),
                  _ReminderRow(
                    context: context,
                    provider: scProv,
                    id: "stretch",
                    label: l10n.stretch,
                    icon: Icons.self_improvement_outlined,
                    stableIds: _stableReminderIds,
                    l10n: l10n,
                  ),
                  const Divider(height: 1),
                  _ReminderRow(
                    context: context,
                    provider: scProv,
                    id: "walk",
                    label: l10n.walk,
                    icon: Icons.directions_walk_outlined,
                    stableIds: _stableReminderIds,
                    l10n: l10n,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppStyles.spacingL),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.selfCareScreenTitle)),
      body: bodyContent,
    );
  }
}

// Badge chip — gold trophy icon, no image asset dependency
class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badge});
  final app_badge.Badge badge;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      child: Container(
        width: 88,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFC107)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events,
                size: 30, color: Color(0xFFFFC107)),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                badge.label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8D6E00),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reminder row — replaces SwitchListTile with colored icon
class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.context,
    required this.provider,
    required this.id,
    required this.label,
    required this.icon,
    required this.stableIds,
    required this.l10n,
  });

  final BuildContext context;
  final SelfCareProvider provider;
  final String id;
  final String label;
  final IconData icon;
  final Map<String, int> stableIds;
  final AppLocalizations l10n;

  static const _color = Color(0xFF00897B);

  @override
  Widget build(BuildContext ctx) {
    final rem = provider.reminders[id];
    final isOn = rem?.timeOfDay != null;
    final theme = Theme.of(ctx);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: _color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                if (isOn)
                  Text(rem!.timeOfDay!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: _color))
                else
                  Text(l10n.off,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: isOn,
            activeColor: _color,
            onChanged: (on) async {
              if (!on) {
                await provider.saveReminder(
                    SelfCareReminder(id: id, timeOfDay: null));
                await NotificationService.instance
                    .cancel(stableIds[id] ?? id.hashCode);
              } else {
                final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now());
                if (pickedTime != null) {
                  await provider.saveReminder(SelfCareReminder(
                      id: id,
                      timeOfDay: pickedTime.format(context)));
                  await NotificationService.instance
                      .scheduleDailyRepeatingNotification(
                    notificationId: stableIds[id] ?? id.hashCode,
                    time: pickedTime,
                    channelId: "self_care",
                    title: l10n.selfCareReminderTitle,
                    body: "$label time!",
                    payload: '{"type":"$id","reminderType":"self_care"}',
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

// Soft card container with left accent strip
class _SelfCareCard extends StatelessWidget {
  const _SelfCareCard({required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Section label — matches dashboard style
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
