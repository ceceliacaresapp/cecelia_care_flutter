// lib/screens/calendar_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/calendar_event.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/widgets/event_form_modal.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';

// Calendar accent color — teal, matching the nav tab.
const _kCalendarColor = Color(0xFF00897B);

class HealthReminderEvent {
  final String id;
  final String elderId;
  final String createdBy;
  final String title;
  final Timestamp scheduledDateTime;
  final int notificationId;

  HealthReminderEvent({
    required this.id,
    required this.elderId,
    required this.createdBy,
    required this.title,
    required this.scheduledDateTime,
    required this.notificationId,
  });

  factory HealthReminderEvent.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return HealthReminderEvent(
      id: doc.id,
      elderId: data['elderId'],
      createdBy: data['createdBy'],
      title: data['title'],
      scheduledDateTime: data['scheduledDateTime'],
      notificationId: data['notificationId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'elderId': elderId,
      'createdBy': createdBy,
      'title': title,
      'scheduledDateTime': scheduledDateTime,
      'notificationId': notificationId,
    };
  }
}

class _HealthReminder {
  final String title;
  final String frequency;
  _HealthReminder({required this.title, required this.frequency});
}

enum _DeleteChoice { thisOnly, allInSeries }

class CalendarScreen extends StatefulWidget {
  final ElderProfile activeElder;
  final String? currentUserId;

  const CalendarScreen({
    super.key,
    required this.activeElder,
    required this.currentUserId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late AppLocalizations _l10n;
  late ThemeData _theme;

  List<CalendarEvent> _calendarEvents = [];
  bool _isLoadingEvents = true;
  DateTime _selectedDate = DateTime.now();
  bool _showEventForm = false;
  CalendarEvent? _editingEvent;
  String _modalMode = 'create';
  StreamSubscription<QuerySnapshot>? _eventsSub;

  List<HealthReminderEvent> _healthReminders = [];
  StreamSubscription<QuerySnapshot>? _healthRemindersSub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
    if (_eventsSub == null) {
      _subscribeToCalendarEvents();
      _subscribeToHealthReminders();
    }
  }

  @override
  void didUpdateWidget(covariant CalendarScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeElder.id != widget.activeElder.id) {
      _eventsSub?.cancel();
      _healthRemindersSub?.cancel();
      setState(() {
        _calendarEvents = [];
        _healthReminders = [];
        _isLoadingEvents = true;
      });
      _subscribeToCalendarEvents();
      _subscribeToHealthReminders();
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    _healthRemindersSub?.cancel();
    super.dispose();
  }

  String _formatEventDateTime(Timestamp timestamp, {bool allDay = false}) {
    if (allDay) return _l10n.calendarAllDay;
    return DateFormat.jm(_l10n.localeName).format(timestamp.toDate());
  }

  void _subscribeToHealthReminders() {
    final elderId = widget.activeElder.id;
    if (elderId.isEmpty) {
      if (mounted) setState(() => _healthReminders = []);
      return;
    }
    _healthRemindersSub = FirebaseFirestore.instance
        .collection('healthReminders')
        .where('elderId', isEqualTo: elderId)
        .snapshots()
        .listen(
      (snapshot) {
        final reminders = snapshot.docs
            .map((doc) => HealthReminderEvent.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
        if (mounted) setState(() => _healthReminders = reminders);
      },
      onError: (error) =>
          debugPrint('Error fetching health reminders: $error'),
    );
  }

  void _subscribeToCalendarEvents() {
    final elderId = widget.activeElder.id;
    if (elderId.isEmpty) {
      if (mounted) setState(() {
        _calendarEvents = [];
        _isLoadingEvents = false;
      });
      return;
    }
    _eventsSub = FirebaseFirestore.instance
        .collection('calendarEvents')
        .where('elderId', isEqualTo: elderId)
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        final events = snapshot.docs
            .map((doc) => CalendarEvent.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>))
            .toList();
        if (mounted) setState(() {
          _calendarEvents = events;
          _isLoadingEvents = false;
        });
      },
      onError: (error) {
        debugPrint('Error fetching calendar events: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_l10n.calendarErrorLoadEvents)));
          setState(() {
            _calendarEvents = [];
            _isLoadingEvents = false;
          });
        }
      },
    );
  }

  Map<DateTime, List<CalendarEvent>> get _eventsMap {
    final Map<DateTime, List<CalendarEvent>> map = {};
    for (final ev in _calendarEvents) {
      final dt = ev.startDateTime.toDate();
      final dateOnly = DateTime.utc(dt.year, dt.month, dt.day);
      map.putIfAbsent(dateOnly, () => []).add(ev);
    }
    return map;
  }

  List<CalendarEvent> get _eventsForSelectedDate {
    final dateOnly = DateTime.utc(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _eventsMap[dateOnly] ?? [];
  }

  bool _canEditDeleteEvent(CalendarEvent event) {
    if (widget.currentUserId == null) return false;
    return widget.activeElder.primaryAdminUserId == widget.currentUserId ||
        event.createdBy == widget.currentUserId;
  }

  bool _canEditDeleteHealthReminder(HealthReminderEvent reminder) {
    if (widget.currentUserId == null) return false;
    return widget.activeElder.primaryAdminUserId == widget.currentUserId ||
        reminder.createdBy == widget.currentUserId;
  }

  void _onAddNewEvent() {
    if (widget.currentUserId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorUserNotLoggedIn)));
      return;
    }
    final now = DateTime.now();
    final baseDate = DateTime(_selectedDate.year, _selectedDate.month,
        _selectedDate.day, now.hour, (now.minute ~/ 15) * 15);
    setState(() {
      _editingEvent = CalendarEvent(
        elderId: widget.activeElder.id,
        createdBy: widget.currentUserId!,
        title: '',
        eventType: '',
        startDateTime: Timestamp.fromDate(baseDate),
        endDateTime: null,
        allDay: false,
        notes: '',
      );
      _modalMode = 'create';
      _showEventForm = true;
    });
  }

  void _onEditEvent(CalendarEvent event) {
    if (event.id == null || event.id!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorEditMissingId)));
      return;
    }
    if (!_canEditDeleteEvent(event)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorEditPermission)));
      return;
    }
    setState(() {
      _editingEvent = event;
      _modalMode = 'edit';
      _showEventForm = true;
    });
  }

  Future<void> _onSubmitEvent(
      CalendarEvent eventFromForm, String mode) async {
    final firestoreService = context.read<FirestoreService>();
    try {
      if (mode == 'create') {
        final docRef =
            await firestoreService.addCalendarEvent(eventFromForm);
        await _scheduleEventNotification(
            eventFromForm.copyWith(id: docRef.id));
      } else {
        final local = _editingEvent;
        if (local == null || local.id == null || local.id!.isEmpty) {
          throw Exception(_l10n.calendarErrorUpdateOriginalMissing);
        }
        if (!_canEditDeleteEvent(local)) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_l10n.calendarErrorUpdatePermission)));
          return;
        }
        await firestoreService.updateCalendarEvent(
            local.id!, eventFromForm.toFirestore());
        await _cancelEventNotification(local);
        await _scheduleEventNotification(
          eventFromForm.id == null || eventFromForm.id!.isEmpty
              ? eventFromForm.copyWith(id: local.id)
              : eventFromForm,
        );
      }
      if (mounted) {
        setState(() {
          _showEventForm = false;
          _editingEvent = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(mode == 'create'
                ? _l10n.calendarEventAddedSuccess
                : _l10n.calendarEventUpdatedSuccess)));
      }
    } catch (e) {
      debugPrint('Error saving calendar event: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorSaveEvent(e.toString()))));
    }
  }

  Future<void> _scheduleEventNotification(CalendarEvent event) async {
    if (event.id == null || event.id!.isEmpty) return;
    try {
      final eventTitle = event.title.isNotEmpty
          ? event.title
          : _l10n.calendarUntitledEvent;
      await NotificationService.instance.scheduleOneTimeNotification(
        id: event.id!.hashCode,
        title: eventTitle,
        body: _l10n.calendarEventStarting(eventTitle),
        payload:
            '{"eventId":"${event.id}", "type":"calendar_event_start"}',
        scheduledTime: event.startDateTime.toDate(),
        channelKey: 'calendar_events',
      );
    } catch (e) {
      debugPrint(
          'Error scheduling notification for event ${event.id}: $e');
    }
  }

  Future<void> _cancelEventNotification(CalendarEvent event) async {
    if (event.id == null || event.id!.isEmpty) return;
    await NotificationService.instance.cancel(event.id.hashCode);
  }

  Future<void> _onDeleteEvent(CalendarEvent event) async {
    if (event.id == null || event.id!.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorDeleteMissingId)));
      return;
    }
    if (!_canEditDeleteEvent(event)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorDeletePermission)));
      return;
    }

    final isRecurring =
        event.recurrenceRule != null || event.recurrenceParentId != null;
    final eventTitle = event.title.isNotEmpty
        ? event.title
        : _l10n.calendarUntitledEvent;

    if (isRecurring) {
      // Ask whether to delete just this instance or the whole series
      final choice = await showDialog<_DeleteChoice>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Recurring Event'),
          content: Text('Delete "$eventTitle"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(_l10n.cancelButton)),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, _DeleteChoice.thisOnly),
              child: const Text('This event only'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, _DeleteChoice.allInSeries),
              style: TextButton.styleFrom(
                  foregroundColor: AppTheme.dangerColor),
              child: const Text('All recurring events'),
            ),
          ],
        ),
      );
      if (choice == null) return;
      try {
        await _cancelEventNotification(event);
        if (choice == _DeleteChoice.allInSeries) {
          final parentId = event.recurrenceParentId ?? event.id!;
          await context
              .read<FirestoreService>()
              .deleteRecurringEvents(parentId);
        } else {
          await context
              .read<FirestoreService>()
              .deleteCalendarEvent(event.id!);
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.eventDeletedSuccess)));
      } catch (e) {
        debugPrint('Error deleting calendar event: $e');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.errorCouldNotDeleteEvent)));
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.calendarConfirmDeleteTitle),
        content:
            Text(_l10n.calendarConfirmDeleteContent(eventTitle)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerColor),
            child: Text(_l10n.deleteButton),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _cancelEventNotification(event);
        await context
            .read<FirestoreService>()
            .deleteCalendarEvent(event.id!);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.eventDeletedSuccess)));
      } catch (e) {
        debugPrint('Error deleting calendar event: $e');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.errorCouldNotDeleteEvent)));
      }
    }
  }

  Future<void> _showReminderDialog(BuildContext context,
      _HealthReminder reminder,
      {HealthReminderEvent? existingReminder}) async {
    final now = DateTime.now();
    final initialDt =
        existingReminder?.scheduledDateTime.toDate() ?? now;
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDt,
      firstDate: now.subtract(const Duration(minutes: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (selectedDate == null || !mounted) return;

    final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDt));
    if (selectedTime == null) return;

    final scheduledDt = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, selectedTime.hour, selectedTime.minute);
    final notificationId =
        (reminder.title.hashCode + widget.activeElder.id.hashCode)
            .toUnsigned(31);
    final reminderData = {
      'elderId': widget.activeElder.id,
      'createdBy': widget.currentUserId,
      'title': reminder.title,
      'scheduledDateTime': Timestamp.fromDate(scheduledDt),
      'notificationId': notificationId,
    };
    try {
      if (existingReminder != null) {
        await FirebaseFirestore.instance
            .collection('healthReminders')
            .doc(existingReminder.id)
            .update(reminderData);
      } else {
        await FirebaseFirestore.instance
            .collection('healthReminders')
            .add(reminderData);
      }
      await NotificationService.instance.cancel(notificationId);
      await NotificationService.instance.scheduleOneTimeNotification(
        id: notificationId,
        title: _l10n.calendarReminderNotificationTitle,
        body: reminder.title,
        payload: 'health_reminder|${reminder.title}',
        scheduledTime: scheduledDt,
        channelKey: 'health_reminders',
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_l10n.calendarReminderSet(
              reminder.title,
              DateFormat.yMd(_l10n.localeName)
                  .add_jm()
                  .format(scheduledDt)))));
    } catch (e) {
      debugPrint('Error saving health reminder: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_l10n.calendarErrorSavingReminder(e.toString()))));
    }
  }

  Future<void> _onCancelHealthReminder(
      HealthReminderEvent reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.calendarConfirmDeleteTitle),
        content:
            Text(_l10n.calendarConfirmCancelReminder(reminder.title)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(_l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerColor),
            child: Text(_l10n.confirmButton),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await NotificationService.instance
            .cancel(reminder.notificationId);
        await FirebaseFirestore.instance
            .collection('healthReminders')
            .doc(reminder.id)
            .delete();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text(_l10n.calendarReminderCancelled(reminder.title))));
      } catch (e) {
        debugPrint('Error cancelling reminder: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final elder = widget.activeElder;
    final List<_HealthReminder> reminders = [
      _HealthReminder(title: _l10n.vaccineCovid19, frequency: _l10n.vaccineCovid19Freq),
      _HealthReminder(title: _l10n.vaccineInfluenza, frequency: _l10n.vaccineInfluenzaFreq),
      _HealthReminder(title: _l10n.vaccineRSV, frequency: _l10n.vaccineRSVFreq),
      _HealthReminder(title: _l10n.vaccineTdap, frequency: _l10n.vaccineTdapFreq),
      _HealthReminder(title: _l10n.vaccineShingles, frequency: _l10n.vaccineShinglesFreq),
      _HealthReminder(title: _l10n.vaccinePneumococcal, frequency: _l10n.vaccinePneumococcalFreq),
      _HealthReminder(title: _l10n.vaccineHepatitisB, frequency: _l10n.vaccineHepatitisBFreq),
      _HealthReminder(title: _l10n.checkupPhysicalExam, frequency: _l10n.checkupPhysicalExamFreq),
      _HealthReminder(title: _l10n.checkupMammogram, frequency: _l10n.checkupMammogramFreq),
      _HealthReminder(title: _l10n.checkupPapTest, frequency: _l10n.checkupPapTestFreq),
      _HealthReminder(title: _l10n.checkupColonCancer, frequency: _l10n.checkupColonCancerFreq),
      _HealthReminder(title: _l10n.checkupLungCancer, frequency: _l10n.checkupLungCancerFreq),
      _HealthReminder(title: _l10n.checkupProstateCancer, frequency: _l10n.checkupProstateCancerFreq),
      _HealthReminder(title: _l10n.checkupSkinCancer, frequency: _l10n.checkupSkinCancerFreq),
      _HealthReminder(title: _l10n.checkupBloodPressure, frequency: _l10n.checkupBloodPressureFreq),
      _HealthReminder(title: _l10n.checkupCholesterol, frequency: _l10n.checkupCholesterolFreq),
      _HealthReminder(title: _l10n.checkupBloodGlucose, frequency: _l10n.checkupBloodGlucoseFreq),
      _HealthReminder(title: _l10n.checkupVision, frequency: _l10n.checkupVisionFreq),
      _HealthReminder(title: _l10n.checkupHearing, frequency: _l10n.checkupHearingFreq),
      _HealthReminder(title: _l10n.checkupBoneDensity, frequency: _l10n.checkupBoneDensityFreq),
      _HealthReminder(title: _l10n.checkupCognitive, frequency: _l10n.checkupCognitiveFreq),
      _HealthReminder(title: _l10n.checkupMentalHealth, frequency: _l10n.checkupMentalHealthFreq),
    ];

    return Stack(
      children: [
        SingleChildScrollView(
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Calendar section ──────────────────────────────────
              _SectionLabel(
                  label: _l10n.calendarScreenTitle(elder.profileName)),
              const SizedBox(height: 12),

              // Add event button — teal to match the calendar nav color
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(_l10n.calendarAddNewEventButton),
                  style: FilledButton.styleFrom(
                    backgroundColor: _kCalendarColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _onAddNewEvent,
                ),
              ),
              const SizedBox(height: 12),

              // Calendar widget — same styling, just cleaner container
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: TableCalendar<CalendarEvent>(
                    locale: _l10n.localeName,
                    firstDay:
                        DateTime.utc(DateTime.now().year - 2, 1, 1),
                    lastDay:
                        DateTime.utc(DateTime.now().year + 2, 12, 31),
                    focusedDay: _selectedDate,
                    selectedDayPredicate: (day) =>
                        isSameDay(day, _selectedDate),
                    eventLoader: (day) {
                      final dateOnly =
                          DateTime.utc(day.year, day.month, day.day);
                      return _eventsMap[dateOnly] ?? [];
                    },
                    calendarStyle: CalendarStyle(
                      markersMaxCount: 3,
                      markerDecoration: const BoxDecoration(
                          color: _kCalendarColor,
                          shape: BoxShape.circle),
                      todayDecoration: BoxDecoration(
                          color: _kCalendarColor.withOpacity(0.2),
                          shape: BoxShape.circle),
                      selectedDecoration: const BoxDecoration(
                          color: _kCalendarColor,
                          shape: BoxShape.circle),
                      todayTextStyle: const TextStyle(
                          color: AppTheme.textPrimary),
                      selectedTextStyle: const TextStyle(
                          color: Colors.white),
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: _theme.textTheme.titleLarge!
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    onDaySelected: (selected, focused) {
                      if (!isSameDay(_selectedDate, selected)) {
                        setState(() => _selectedDate = selected);
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Events for selected day
              _SectionLabel(
                label: _l10n.calendarEventsOnDate(
                    DateFormat.yMMMMd(_l10n.localeName)
                        .format(_selectedDate)),
              ),
              const SizedBox(height: 8),
              if (_isLoadingEvents)
                const Center(
                    child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircularProgressIndicator()))
              else if (_eventsForSelectedDate.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(_l10n.calendarNoEventsScheduled,
                        style: AppStyles.emptyStateText),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _eventsForSelectedDate.length,
                  itemBuilder: (context, i) =>
                      _buildEventCard(_eventsForSelectedDate[i]),
                ),

              const SizedBox(height: 24),

              // ── Health reminders section ──────────────────────────
              _SectionLabel(label: _l10n.calendarRemindersTitle),
              const SizedBox(height: 8),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reminders.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final tpl = reminders[index];
                  final saved = _healthReminders
                      .cast<HealthReminderEvent?>()
                      .firstWhere((r) => r?.title == tpl.title,
                          orElse: () => null);
                  return _ReminderRow(
                    reminder: tpl,
                    saved: saved,
                    canEdit: saved != null
                        ? _canEditDeleteHealthReminder(saved)
                        : true,
                    onTap: () => _showReminderDialog(context, tpl,
                        existingReminder: saved),
                    onCancel: saved != null
                        ? () => _onCancelHealthReminder(saved)
                        : null,
                    onEdit: saved != null
                        ? () => _showReminderDialog(context, tpl,
                            existingReminder: saved)
                        : null,
                    l10n: _l10n,
                    theme: _theme,
                  );
                },
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
        if (_showEventForm && _editingEvent != null)
          EventFormModal(
            initialEvent: _editingEvent!,
            mode: _modalMode,
            onCancel: () => setState(() {
              _showEventForm = false;
              _editingEvent = null;
            }),
            onSubmit: (event) => _onSubmitEvent(event, _modalMode),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Event card — left teal border strip, soft shadow
  // ---------------------------------------------------------------------------
  Widget _buildEventCard(CalendarEvent event) {
    final canEditDelete = _canEditDeleteEvent(event);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: _kCalendarColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCalendarColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _kCalendarColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                if (event.recurrenceRule != null ||
                                    event.recurrenceParentId != null) ...[
                                  const Icon(Icons.repeat,
                                      size: 14,
                                      color: _kCalendarColor),
                                  const SizedBox(width: 4),
                                ],
                                Expanded(
                                  child: Text(
                                    event.title.isNotEmpty
                                        ? event.title
                                        : _l10n.calendarUntitledEvent,
                                    style: AppStyles.cardTitle.copyWith(
                                        color: _kCalendarColor),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (canEditDelete &&
                              event.id != null &&
                              event.id!.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 18,
                                  color: AppTheme.textSecondary),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: _l10n.calendarTooltipEditEvent,
                              onPressed: () => _onEditEvent(event),
                            )
                          else
                            const SizedBox(width: 24),
                        ],
                      ),
                      if (event.eventType.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_l10n.calendarEventTypePrefix} ${event.eventType}',
                          style: _theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined,
                              size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            _formatEventDateTime(event.startDateTime,
                                allDay: event.allDay),
                            style: _theme.textTheme.bodyMedium
                                ?.copyWith(
                                    color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                      if (event.notes != null &&
                          event.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${_l10n.calendarEventNotesPrefix} ${event.notes!}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: _theme.textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                      if (canEditDelete &&
                          event.id != null &&
                          event.id!.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => _onDeleteEvent(event),
                            style: TextButton.styleFrom(
                                foregroundColor: AppTheme.dangerColor,
                                minimumSize: Size.zero,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap),
                            child: Text(_l10n.deleteButton,
                                style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                    ],
                  ),
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
// _ReminderRow — health reminder list item with soft styling
// ---------------------------------------------------------------------------

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.reminder,
    required this.saved,
    required this.canEdit,
    required this.onTap,
    required this.l10n,
    required this.theme,
    this.onCancel,
    this.onEdit,
  });

  final _HealthReminder reminder;
  final HealthReminderEvent? saved;
  final bool canEdit;
  final VoidCallback onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onEdit;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isSet = saved != null;
    return Container(
      decoration: BoxDecoration(
        color: isSet
            ? _kCalendarColor.withOpacity(0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSet
              ? _kCalendarColor.withOpacity(0.25)
              : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            title: Text(reminder.title,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w500)),
            subtitle: Text(reminder.frequency,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppTheme.textSecondary)),
            trailing: IconButton(
              icon: Icon(
                isSet
                    ? Icons.notifications_active
                    : Icons.notifications_active_outlined,
                color: isSet ? _kCalendarColor : AppTheme.textSecondary,
              ),
              onPressed: onTap,
              tooltip: l10n.setReminder,
            ),
          ),
          if (isSet)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  const Icon(Icons.alarm_outlined,
                      size: 14, color: _kCalendarColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      DateFormat.yMd(l10n.localeName)
                          .add_jm()
                          .format(
                              saved!.scheduledDateTime.toDate()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _kCalendarColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (canEdit) ...[
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: AppTheme.textSecondary),
                      onPressed: onEdit,
                      tooltip: l10n.editReminder,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined,
                          size: 16, color: AppTheme.dangerColor),
                      onPressed: onCancel,
                      tooltip: l10n.cancelReminder,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionLabel — matches the dashboard section label style
// ---------------------------------------------------------------------------

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
