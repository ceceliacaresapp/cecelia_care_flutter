import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../../locator.dart';
import '../../providers/active_elder_provider.dart';
import '../../models/caregiver_role.dart';
import '../../providers/medication_definitions_provider.dart';
import '../../providers/medication_provider.dart';
import '../../services/notification_service.dart';
import '../../services/rxnav_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_styles.dart';
import '../../models/medication_entry.dart';
import '../../models/medication_definition.dart';
import 'package:cecelia_care_flutter/widgets/cecelia_bot_sheet.dart';

class MedicationManagerScreen extends StatefulWidget {
  static const String route = '/medications';
  const MedicationManagerScreen({super.key});

  @override
  State<MedicationManagerScreen> createState() =>
      _MedicationManagerScreenState();
}

class _MedicationManagerScreenState extends State<MedicationManagerScreen>
    with SingleTickerProviderStateMixin {
  late AppLocalizations _l10n;
  late ThemeData _theme;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeElder =
        Provider.of<ActiveElderProvider>(context, listen: false).activeElder;

    if (activeElder == null) {
      return Scaffold(
        appBar: AppBar(title: Text(_l10n.manageMedications)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _l10n.settingsSelectElderToViewMedDefs,
              style: AppStyles.emptyStateText,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_l10n.manageMedications),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.textOnPrimary,
          unselectedLabelColor: AppTheme.textOnPrimary.withOpacity(0.7),
          indicatorColor: AppTheme.textOnPrimary,
          tabs: const [
            Tab(text: 'Medications'),
            Tab(text: 'Reminders'),
          ],
        ),
      ),
      floatingActionButton: _buildFab(context, activeElder),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MedicationLogTab(l10n: _l10n, theme: _theme),
          _RemindersTab(activeElder: activeElder),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context, dynamic activeElder) {
    final role = Provider.of<ActiveElderProvider>(context, listen: false)
        .currentUserRole;

    // Viewer: no FABs at all
    if (!role.canMarkMedications) return const SizedBox.shrink();

    // Caregiver: only the Cecelia chat FAB, no add-medication FAB
    if (!role.canManageMedicationDefinitions) {
      return FloatingActionButton(
        heroTag: 'chatWithCeceliaFab',
        backgroundColor: AppTheme.primaryColor,
        onPressed: () async {
          final medList =
              await context.read<MedicationProvider>().medsStream().first;
          final medsJsonList = medList
              .map((med) => {
                    'name': med.name,
                    'rxCui': med.rxCui,
                    'dose': med.dose,
                    'schedule': med.schedule,
                  })
              .toList();
          final contextForAI = {
            'elderId': activeElder.id,
            'currentMedications': medsJsonList,
          };
          if (!context.mounted) return;
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => CeceliaBotSheet(contextForAI: contextForAI),
          );
        },
        tooltip: _l10n.medicationsTooltipAskCecelia,
        child: const Icon(Icons.chat_bubble_outline,
            color: AppTheme.textOnPrimary),
      );
    }

    // Admin: both FABs
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: 'addMedicationFab',
          backgroundColor: AppTheme.accentColor,
          onPressed: () {
            final medicationProvider = context.read<MedicationProvider>();
            final medDefsProvider =
                context.read<MedicationDefinitionsProvider>();
            showDialog(
              context: context,
              builder: (_) => MultiProvider(
                providers: [
                  ChangeNotifierProvider<MedicationProvider>.value(
                      value: medicationProvider),
                  ChangeNotifierProvider<MedicationDefinitionsProvider>.value(
                      value: medDefsProvider),
                ],
                child: const _AddMedicationDialog(),
              ),
            );
          },
          tooltip: _l10n.medicationsAddDialogTitle,
          child: const Icon(Icons.add, color: AppTheme.textOnPrimary),
        ),
        const SizedBox(height: 16),
        FloatingActionButton(
          heroTag: 'chatWithCeceliaFab',
          backgroundColor: AppTheme.primaryColor,
          onPressed: () async {
            final medList =
                await context.read<MedicationProvider>().medsStream().first;
            final medsJsonList = medList
                .map((med) => {
                      'name': med.name,
                      'rxCui': med.rxCui,
                      'dose': med.dose,
                      'schedule': med.schedule,
                    })
                .toList();
            final contextForAI = {
              'elderId': activeElder.id,
              'currentMedications': medsJsonList,
            };
            if (!context.mounted) return;
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => CeceliaBotSheet(contextForAI: contextForAI),
            );
          },
          tooltip: _l10n.medicationsTooltipAskCecelia,
          child: const Icon(Icons.chat_bubble_outline,
              color: AppTheme.textOnPrimary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 1 — Medication log with adherence strip
//
// Groups all MedicationEntry records by name. Each unique medication name
// gets one card showing:
//   - Name + dose/schedule summary
//   - An adherence history strip (last 14 entries, newest on the right)
//   - Taken / Skip buttons to log today's dose
//   - Delete button to remove the most-recent entry for that med name
//
// The strip mirrors the MoodHistoryStrip pattern from lib/widgets/:
//   horizontal ListView, one colored dot per entry, label below.
// ---------------------------------------------------------------------------

class _MedicationLogTab extends StatelessWidget {
  const _MedicationLogTab({required this.l10n, required this.theme});
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MedicationEntry>>(
      stream: context.watch<MedicationProvider>().medsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('Error loading medications: ${snapshot.error}');
          return Center(child: Text(l10n.formErrorGenericSaveUpdate));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
              child: Text(l10n.medicationsListEmpty,
                  style: AppStyles.emptyStateText));
        }

        // Group entries by medication name. Within each group, sort oldest→newest
        // so the strip renders left=old, right=recent.
        final allEntries = snapshot.data!;
        final Map<String, List<MedicationEntry>> grouped = {};
        for (final m in allEntries) {
          grouped.putIfAbsent(m.name, () => []).add(m);
        }
        for (final entries in grouped.values) {
          entries.sort((a, b) =>
              a.createdAt.compareTo(b.createdAt));
        }
        final medNames = grouped.keys.toList();

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: medNames.length,
          itemBuilder: (_, i) {
            final name = medNames[i];
            final entries = grouped[name]!;
            final latest = entries.last;
            return _MedicationAdherenceCard(
              name: name,
              latest: latest,
              entries: entries,
              l10n: l10n,
              theme: theme,
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Single medication card with adherence strip
// ---------------------------------------------------------------------------

class _MedicationAdherenceCard extends StatelessWidget {
  const _MedicationAdherenceCard({
    required this.name,
    required this.latest,
    required this.entries,
    required this.l10n,
    required this.theme,
  });

  final String name;
  final MedicationEntry latest;
  final List<MedicationEntry> entries;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    // Show at most the last 14 entries in the strip.
    final stripEntries = entries.length > 14
        ? entries.sublist(entries.length - 14)
        : entries;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: AppStyles.listTileTitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      Text(
                        '${latest.dose.isNotEmpty ? latest.dose : l10n.medicationsDoseNotSet}'
                        ' – '
                        '${latest.schedule.isNotEmpty ? latest.schedule : l10n.medicationsScheduleNotSet}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                if (context
                    .read<ActiveElderProvider>()
                    .currentUserRole
                    .canManageMedicationDefinitions)
                  IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppTheme.dangerColor),
                  tooltip: l10n.medicationsTooltipDelete,
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(
                            l10n.medicationsConfirmDeleteTitle(name)),
                        content:
                            Text(l10n.medicationsConfirmDeleteContent),
                        actions: [
                          TextButton(
                              onPressed: () =>
                                  Navigator.of(ctx).pop(false),
                              child: Text(l10n.cancelButton)),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(ctx).pop(true),
                            style: TextButton.styleFrom(
                                foregroundColor: AppTheme.dangerColor),
                            child: Text(l10n.deleteButton),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      try {
                        // Delete the most recent entry for this med name.
                        await context
                            .read<MedicationProvider>()
                            .removeMedication(latest.firestoreId);
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    l10n.medicationsDeletedSuccess(
                                        name))));
                      } catch (e, stack) {
                        debugPrint(
                            '_MedicationAdherenceCard.delete error: $e\n$stack');
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    l10n.formErrorGenericSaveUpdate)));
                      }
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Adherence history strip ──────────────────────────────
            // Mirrors MoodHistoryStrip: horizontal ListView, one item per
            // entry. Dot color: green=taken, red=skipped, grey=pending.
            if (stripEntries.isNotEmpty) ...[
              Text(
                'Adherence (last ${stripEntries.length})',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: stripEntries.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 6),
                  itemBuilder: (_, idx) {
                    final e = stripEntries[idx];
                    final Color dotColor;
                    if (e.takenAt != null && e.taken) {
                      dotColor = const Color(0xFF43A047); // green
                    } else if (e.takenAt != null && !e.taken) {
                      dotColor = AppTheme.dangerColor; // red
                    } else {
                      dotColor = AppTheme.textLight; // grey/pending
                    }
                    final label = DateFormat('M/d')
                        .format(e.createdAt.toDate());
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondary),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            // ── Taken / Skip action buttons ──────────────────────────
            // Only show if the latest entry hasn't been actioned today.
            _AdherenceActions(
              entry: latest,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Taken / Skip buttons
// ---------------------------------------------------------------------------

class _AdherenceActions extends StatefulWidget {
  const _AdherenceActions({required this.entry, required this.l10n});
  final MedicationEntry entry;
  final AppLocalizations l10n;

  @override
  State<_AdherenceActions> createState() => _AdherenceActionsState();
}

class _AdherenceActionsState extends State<_AdherenceActions> {
  bool _busy = false;

  bool get _actionedToday {
    if (widget.entry.takenAt == null) return false;
    final t = widget.entry.takenAt!.toDate();
    final now = DateTime.now();
    return t.year == now.year &&
        t.month == now.month &&
        t.day == now.day;
  }

  Future<void> _mark(bool taken) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context
          .read<MedicationProvider>()
          .markTaken(entry: widget.entry, taken: taken);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(taken
              ? '${widget.entry.name} marked as taken ✓'
              : '${widget.entry.name} marked as skipped'),
          backgroundColor:
              taken ? const Color(0xFF43A047) : AppTheme.dangerColor,
        ));
      }
    } catch (e) {
      debugPrint('_AdherenceActions._mark error: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_actionedToday) {
      // Already logged today — show status badge instead of buttons.
      final takenToday = widget.entry.taken;
      return Row(
        children: [
          Icon(
            takenToday ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: takenToday
                ? const Color(0xFF43A047)
                : AppTheme.dangerColor,
          ),
          const SizedBox(width: 6),
          Text(
            takenToday ? 'Taken today' : 'Skipped today',
            style: TextStyle(
              fontSize: 12,
              color: takenToday
                  ? const Color(0xFF43A047)
                  : AppTheme.dangerColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : OutlinedButton.icon(
                onPressed: () => _mark(true),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Taken'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF43A047),
                  side: const BorderSide(color: Color(0xFF43A047)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
        const SizedBox(width: 8),
        if (!_busy)
          OutlinedButton.icon(
            onPressed: () => _mark(false),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Skip'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.dangerColor,
              side: const BorderSide(color: AppTheme.dangerColor),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Tab 2 — Reminder scheduling (unchanged from previous version)
// ---------------------------------------------------------------------------

class _RemindersTab extends StatelessWidget {
  const _RemindersTab({required this.activeElder});
  final dynamic activeElder;

  @override
  Widget build(BuildContext context) {
    final defsProvider = context.watch<MedicationDefinitionsProvider>();

    if (defsProvider.isLoadingMedDefs) {
      return const Center(child: CircularProgressIndicator());
    }

    if (defsProvider.medDefinitions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No medications added yet.\nAdd medications on the Medications tab first.',
            style: AppStyles.emptyStateText,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: defsProvider.medDefinitions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final def = defsProvider.medDefinitions[i];
        return _ReminderCard(def: def, activeElder: activeElder);
      },
    );
  }
}

class _ReminderCard extends StatefulWidget {
  const _ReminderCard({required this.def, required this.activeElder});
  final MedicationDefinition def;
  final dynamic activeElder;

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  bool _isBusy = false;

  TimeOfDay _timeFromString(String? timeStr) {
    if (timeStr != null && RegExp(r'^\d{2}:\d{2}$').hasMatch(timeStr)) {
      final parts = timeStr.split(':');
      return TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    return const TimeOfDay(hour: 8, minute: 0);
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _onToggle(bool enable) async {
    if (_isBusy || widget.def.id == null) return;
    final l10n = AppLocalizations.of(context)!;
    final defsProvider = context.read<MedicationDefinitionsProvider>();

    if (enable) {
      final initialTime = _timeFromString(widget.def.defaultTime);
      final picked = await showTimePicker(
        context: context,
        initialTime: initialTime,
        helpText: 'Set daily reminder time for ${widget.def.name}',
      );
      if (picked == null) return;
      if (!mounted) return;

      setState(() => _isBusy = true);
      try {
        final timeStr = _formatTime(picked);
        await NotificationService.instance.scheduleMedReminder(l10n, {
          'elderId': widget.activeElder.id,
          'elderName': widget.activeElder.profileName,
          'medName': widget.def.name,
          'dosage': widget.def.dose ?? '',
          'time': timeStr,
        });
        await defsProvider.updateReminderEnabled(
            medDefId: widget.def.id!, enabled: true);
        if (widget.def.defaultTime != timeStr) {
          await defsProvider
              .addOrUpdate(widget.def.copyWith(defaultTime: timeStr));
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Daily reminder set for ${widget.def.name} at $timeStr'),
            backgroundColor: Colors.green,
          ));
        }
      } catch (e, stack) {
        debugPrint('_ReminderCard._onToggle(enable) error: $e\n$stack');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Failed to set reminder. Please try again.'),
            backgroundColor: AppTheme.dangerColor,
          ));
        }
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
    } else {
      setState(() => _isBusy = true);
      try {
        await NotificationService.instance.cancelMedReminder(
          elderId: widget.activeElder.id,
          medName: widget.def.name,
          timeStr: widget.def.defaultTime ?? '08:00',
        );
        await defsProvider.updateReminderEnabled(
            medDefId: widget.def.id!, enabled: false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Reminder cancelled for ${widget.def.name}'),
          ));
        }
      } catch (e, stack) {
        debugPrint('_ReminderCard._onToggle(disable) error: $e\n$stack');
      } finally {
        if (mounted) setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _editTime() async {
    if (!widget.def.reminderEnabled || widget.def.id == null) return;
    final l10n = AppLocalizations.of(context)!;
    final defsProvider = context.read<MedicationDefinitionsProvider>();
    final picked = await showTimePicker(
      context: context,
      initialTime: _timeFromString(widget.def.defaultTime),
      helpText: 'Change reminder time for ${widget.def.name}',
    );
    if (picked == null || !mounted) return;

    setState(() => _isBusy = true);
    try {
      final timeStr = _formatTime(picked);
      await NotificationService.instance.cancelMedReminder(
        elderId: widget.activeElder.id,
        medName: widget.def.name,
        timeStr: widget.def.defaultTime ?? '08:00',
      );
      await NotificationService.instance.scheduleMedReminder(l10n, {
        'elderId': widget.activeElder.id,
        'elderName': widget.activeElder.profileName,
        'medName': widget.def.name,
        'dosage': widget.def.dose ?? '',
        'time': timeStr,
      });
      await defsProvider
          .addOrUpdate(widget.def.copyWith(defaultTime: timeStr));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Reminder updated to $timeStr for ${widget.def.name}'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e, stack) {
      debugPrint('_ReminderCard._editTime error: $e\n$stack');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final def = widget.def;
    final timeStr = def.defaultTime ?? '08:00';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: def.reminderEnabled
              ? AppTheme.primaryColor.withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(def.name,
                          style: AppStyles.listTileTitle,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1),
                      if (def.dose != null && def.dose!.isNotEmpty)
                        Text(def.dose!,
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                _isBusy
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch(
                        value: def.reminderEnabled,
                        onChanged: _onToggle,
                        activeColor: AppTheme.primaryColor,
                      ),
              ],
            ),
            if (def.reminderEnabled) ...[
              const SizedBox(height: 8),
              const Divider(height: 1),
              const SizedBox(height: 8),
              InkWell(
                onTap: _editTime,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_outlined,
                          size: 18, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text('Daily at $timeStr',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(width: 6),
                      const Icon(Icons.edit_outlined,
                          size: 14, color: AppTheme.textSecondary),
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text('No reminder set',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textLight,
                      fontStyle: FontStyle.italic)),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AddMedicationDialog (unchanged)
// ---------------------------------------------------------------------------

class _AddMedicationDialog extends StatefulWidget {
  const _AddMedicationDialog();
  @override
  State<_AddMedicationDialog> createState() => _AddMedicationDialogState();
}

class _AddMedicationDialogState extends State<_AddMedicationDialog> {
  late AppLocalizations _l10n;
  late final RxNavService _rxNavService;

  final _nameController = TextEditingController();
  final _doseController = TextEditingController();
  final _scheduleController = TextEditingController();

  List<DrugSuggestion> _suggestions = [];
  DrugSuggestion? _chosenSuggestion;
  bool _isLoadingSuggestions = false;
  String? _searchError;
  Timer? _debounce;
  bool _isLoadingInteractions = false;

  @override
  void initState() {
    super.initState();
    _rxNavService = locator<RxNavService>();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    _scheduleController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _searchDrug(String query) async {
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _searchError = null;
        _isLoadingSuggestions = false;
      });
      return;
    }
    setState(() {
      _isLoadingSuggestions = true;
      _searchError = null;
    });
    try {
      final res = await _rxNavService.searchByName(query);
      if (!mounted) return;
      setState(() {
        _suggestions = res.take(10).toList();
        _isLoadingSuggestions = false;
      });
    } on RxNavApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = e.message;
        _isLoadingSuggestions = false;
        _suggestions = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _searchError = _l10n.rxNavGenericSearchError;
        _isLoadingSuggestions = false;
        _suggestions = [];
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _searchDrug(query));
  }

  Future<List<String>> _performInteractionCheckAndGetConfirmation(
    MedicationDefinition newlyAddedMedDefinition,
    List<MedicationDefinition> otherMedsForElder,
  ) async {
    final medicationProvider = context.read<MedicationProvider>();
    if (newlyAddedMedDefinition.rxCui == null ||
        newlyAddedMedDefinition.rxCui!.isEmpty) {
      return [];
    }
    List<DrugInteraction> currentInteractions;
    try {
      currentInteractions = await medicationProvider
          .warnIfInteractions(newlyAddedMedDefinition.rxCui!);
    } catch (e) {
      debugPrint('Interaction check failed: $e');
      return [];
    }
    if (!mounted) return [];
    if (currentInteractions.isNotEmpty) {
      final continueWithSave = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(_l10n.medicationsInteractionsFoundTitle),
          content: _buildInteractionsDialogContent(currentInteractions),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(_l10n.cancelButton)),
            ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(_l10n.medicationsInteractionsSaveAnyway)),
          ],
        ),
      );
      if (continueWithSave != true) return [];
      return currentInteractions.map((interaction) {
        String otherDrugName = 'Unknown Drug';
        if (interaction.drug1Name?.toLowerCase() ==
            newlyAddedMedDefinition.name.toLowerCase()) {
          otherDrugName = interaction.drug2Name ?? 'Unknown Drug';
        } else if (interaction.drug2Name?.toLowerCase() ==
            newlyAddedMedDefinition.name.toLowerCase()) {
          otherDrugName = interaction.drug1Name ?? 'Unknown Drug';
        }
        return _l10n.medicationsInteractionDetails(
            interaction.severity, otherDrugName, interaction.description);
      }).toList();
    }
    return [];
  }

  Future<void> _handleAddMedication() async {
    if (_chosenSuggestion == null || _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_l10n.medicationsValidationNameRequired)));
      return;
    }
    if (_doseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_l10n.medicationsValidationDoseRequired)));
      return;
    }
    setState(() => _isLoadingInteractions = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final activeElder =
          Provider.of<ActiveElderProvider>(context, listen: false).activeElder;
      final medicationDefinitionsProvider =
          context.read<MedicationDefinitionsProvider>();
      final medicationProvider = context.read<MedicationProvider>();

      if (currentUser == null || activeElder == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_l10n.formErrorUserOrElderNotFound)));
        return;
      }

      final now = Timestamp.now();
      await medicationProvider.addMedication(
        MedicationEntry(
          firestoreId: '',
          name: _chosenSuggestion!.name,
          rxCui: _chosenSuggestion!.rxCui,
          dose: _doseController.text.trim(),
          schedule: _scheduleController.text.trim(),
          time: null,
          taken: false,
          loggedByUserId: currentUser.uid,
          loggedByDisplayName: currentUser.displayName ??
              currentUser.email ??
              _l10n.formUnknownUser,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final String? savedDefinitionId =
          await medicationDefinitionsProvider.addMedicationDefinition(
        name: _chosenSuggestion!.name,
        elderId: activeElder.id,
        rxCui: _chosenSuggestion!.rxCui,
        dose: _doseController.text.trim().isNotEmpty
            ? _doseController.text.trim()
            : null,
        defaultTime: _scheduleController.text.trim().isNotEmpty
            ? _scheduleController.text.trim()
            : null,
        checkInteractionsFunction: _performInteractionCheckAndGetConfirmation,
      );

      if (savedDefinitionId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(_l10n.medicationDefinitionSaveFailed)));
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                _l10n.medicationsAddedSuccess(_chosenSuggestion!.name))));
        Navigator.of(context).pop();
      }
    } on RxNavApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, stack) {
      debugPrint('_handleAddMedication error: $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_l10n.formErrorGenericSaveUpdate)));
    } finally {
      if (mounted) setState(() => _isLoadingInteractions = false);
    }
  }

  Widget _buildInteractionsDialogContent(
      List<DrugInteraction> interactions) {
    if (interactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_l10n.medicationsNoInteractionsFound,
              textAlign: TextAlign.center),
        ),
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
        minWidth: MediaQuery.of(context).size.width * 0.8,
      ),
      child: ListView(
        shrinkWrap: true,
        children: interactions
            .map((i) => ListTile(
                  title: Text(i.severity,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: i.severity.toLowerCase() == 'high'
                              ? AppTheme.dangerColor
                              : (i.severity.toLowerCase() == 'n/a'
                                  ? AppTheme.textLight
                                  : AppTheme.accentColor)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1),
                  subtitle: Text(i.description,
                      overflow: TextOverflow.ellipsis, maxLines: 3),
                  isThreeLine: i.description.length > 50,
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_l10n.medicationsAddDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: _l10n.medicationsSearchHint,
                hintText: _l10n.medicationsSearchHint,
                suffixIcon: _isLoadingSuggestions
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
              ),
              onChanged: _onSearchChanged,
              textInputAction: TextInputAction.search,
            ),
            if (_searchError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(_searchError!,
                    style:
                        const TextStyle(color: AppTheme.dangerColor)),
              ),
            if (_suggestions.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _suggestions.map((s) {
                      return ListTile(
                        title: Text(s.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1),
                        onTap: () => setState(() {
                          _chosenSuggestion = s;
                          _nameController.text = s.name;
                          _suggestions.clear();
                          _searchError = null;
                        }),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _doseController,
              decoration:
                  InputDecoration(labelText: _l10n.medicationsDoseHint),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _scheduleController,
              decoration: InputDecoration(
                  labelText: _l10n.medicationsScheduleHint),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(_l10n.cancelButton)),
        ElevatedButton(
          onPressed: (_chosenSuggestion == null || _isLoadingInteractions)
              ? null
              : _handleAddMedication,
          child: _isLoadingInteractions
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.textOnPrimary))
              : Text(_l10n.saveButton),
        ),
      ],
    );
  }
}
