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
import 'package:cecelia_care_flutter/widgets/section.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';

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

  factory HealthReminderEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
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
    // Defer context-dependent initializations to didChangeDependencies
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);

    if(_eventsSub == null) { 
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
    if (allDay) {
      return _l10n.calendarAllDay;
    }
    final dateTime = timestamp.toDate();
    return DateFormat.jm(_l10n.localeName).format(dateTime);
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
      .listen((snapshot) {
        final reminders = snapshot.docs.map((doc) =>
          HealthReminderEvent.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>)
        ).toList();
        if (mounted) {
          setState(() {
            _healthReminders = reminders;
          });
        }
      }, onError: (error) {
        debugPrint('Error fetching health reminders: $error');
      });
  }


  void _subscribeToCalendarEvents() {
    final elderId = widget.activeElder.id;
    if (elderId.isEmpty) {
      if (mounted) {
        setState(() {
        _calendarEvents = [];
        _isLoadingEvents = false;
      });
      }
      return;
    }

    _eventsSub = FirebaseFirestore.instance
        .collection('calendarEvents')
        .where('elderId', isEqualTo: elderId)
        .orderBy('startDateTime', descending: false)
        .snapshots()
        .listen(
          (snapshot) {
            final events = snapshot.docs.map((doc) {
              return CalendarEvent.fromFirestore(
                doc as DocumentSnapshot<Map<String, dynamic>>,
              );
            }).toList();

            if (mounted) {
              setState(() {
                _calendarEvents = events;
                _isLoadingEvents = false;
              });
            }
          },
          onError: (error) {
            debugPrint('Error fetching calendar events: $error');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_l10n.calendarErrorLoadEvents)),
              );
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
    final dateOnly = DateTime.utc(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    return _eventsMap[dateOnly] ?? [];
  }

  bool _canEditDeleteEvent(CalendarEvent event) {
    if (widget.currentUserId == null) return false;
    final bool isPrimaryAdmin = widget.activeElder.primaryAdminUserId == widget.currentUserId;
    final bool isCreator = event.createdBy == widget.currentUserId;
    return isPrimaryAdmin || isCreator;
  }

  bool _canEditDeleteHealthReminder(HealthReminderEvent reminder) {
    if (widget.currentUserId == null) return false;
    return widget.activeElder.primaryAdminUserId == widget.currentUserId || reminder.createdBy == widget.currentUserId;
  }


  void _onAddNewEvent() {
    if (widget.currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorUserNotLoggedIn)),
        );
      }
      return;
    }

    final now = DateTime.now();
    final baseDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, now.hour, (now.minute ~/ 15) * 15);

    final newEvent = CalendarEvent(
      elderId: widget.activeElder.id,
      createdBy: widget.currentUserId!,
      title: '',
      eventType: '',
      startDateTime: Timestamp.fromDate(baseDate),
      endDateTime: null,
      allDay: false,
      notes: '',
    );

    setState(() {
      _editingEvent = newEvent;
      _modalMode = 'create';
      _showEventForm = true;
    });
  }

  void _onEditEvent(CalendarEvent event) {
    if (event.id == null || event.id!.isEmpty) {
      debugPrint('Error: Attempting to edit an event with no ID.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorEditMissingId)),
        );
      }
      return;
    }
    if (!_canEditDeleteEvent(event)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorEditPermission)),
        );
      }
      return;
    }
    setState(() {
      _editingEvent = event;
      _modalMode = 'edit';
      _showEventForm = true;
    });
  }

  Future<void> _onSubmitEvent(CalendarEvent eventFromForm, String mode) async {
    final firestoreService = context.read<FirestoreService>();
    try {
      if (mode == 'create') {
        DocumentReference<CalendarEvent> docRef = await firestoreService.addCalendarEvent(eventFromForm);
        String eventId = docRef.id;
        await _scheduleEventNotification(eventFromForm.copyWith(id: eventId));
      } else {
        final CalendarEvent? localEditingEvent = _editingEvent;
        if (localEditingEvent == null || localEditingEvent.id == null || localEditingEvent.id!.isEmpty) {
          throw Exception(_l10n.calendarErrorUpdateOriginalMissing);
        }
        if (!_canEditDeleteEvent(localEditingEvent)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_l10n.calendarErrorUpdatePermission)),
            );
          }
          return;
        }
        await firestoreService.updateCalendarEvent(localEditingEvent.id!, eventFromForm.toFirestore());
        await _cancelEventNotification(localEditingEvent);
        await _scheduleEventNotification(
          eventFromForm.id == null || eventFromForm.id!.isEmpty
              ? eventFromForm.copyWith(id: localEditingEvent.id)
              : eventFromForm,
        );
      }
      if (mounted) {
        setState(() {
          _showEventForm = false;
          _editingEvent = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mode == 'create' ? _l10n.calendarEventAddedSuccess : _l10n.calendarEventUpdatedSuccess)),
        );
      }
    } catch (e) {
      debugPrint('Error saving calendar event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_l10n.calendarErrorSaveEvent(e.toString()))),
        );
      }
    }
  }

  Future<void> _scheduleEventNotification(CalendarEvent event) async {
    if (event.id == null || event.id!.isEmpty) {
      debugPrint('NotificationService: Cannot schedule notification for event without ID.');
      return;
    }
    try {
      final DateTime eventStartDateTime = event.startDateTime.toDate();
      final String eventTitle = event.title.isNotEmpty ? event.title : _l10n.calendarUntitledEvent;
      final String eventId = event.id!;

      await NotificationService.instance.scheduleOneTimeNotification(
        id: eventId.hashCode,
        title: eventTitle,
        body: _l10n.calendarEventStarting(eventTitle),
        payload: '{"eventId":"$eventId", "type":"calendar_event_start"}',
        scheduledTime: eventStartDateTime,
        channelKey: 'calendar_events'
      );
      debugPrint('Notification scheduled for event: $eventId at $eventStartDateTime');
    } catch (e) {
      debugPrint('Error scheduling notification for event ${event.id}: $e');
    }
  }

  Future<void> _cancelEventNotification(CalendarEvent event) async {
    if (event.id == null || event.id!.isEmpty) return;
    final int notificationId = event.id.hashCode;
    await NotificationService.instance.cancel(notificationId);
    debugPrint('Attempted to cancel notification for event ${event.id} with notificationId $notificationId');
  }

  Future<void> _onDeleteEvent(CalendarEvent event) async {
    if (event.id == null || event.id!.isEmpty) {
      debugPrint('Error: Attempting to delete an event with no ID.');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_l10n.calendarErrorDeleteMissingId)));
      }
      return;
    }
    if (!_canEditDeleteEvent(event)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_l10n.calendarErrorDeletePermission)));
      }
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.calendarConfirmDeleteTitle),
        content: Text(_l10n.calendarConfirmDeleteContent(event.title.isNotEmpty ? event.title : _l10n.calendarUntitledEvent)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: Text(_l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final firestoreService = context.read<FirestoreService>();
      try {
        await _cancelEventNotification(event);
        await firestoreService.deleteCalendarEvent(event.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_l10n.eventDeletedSuccess)));
        }
      } catch (e) {
        debugPrint('Error deleting calendar event: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_l10n.errorCouldNotDeleteEvent)));
        }
      }
    }
  }

  Future<void> _showReminderDialog(BuildContext context, _HealthReminder reminder, {HealthReminderEvent? existingReminder}) async {
    final now = DateTime.now();
    final initialDateTime = existingReminder?.scheduledDateTime.toDate() ?? now;
    DateTime? selectedDate = await showDatePicker(
      context: context, initialDate: initialDateTime,
      firstDate: now.subtract(const Duration(minutes: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );

    if (selectedDate != null && mounted) {
      TimeOfDay? selectedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initialDateTime));

      if (selectedTime != null) {
        final scheduledDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
        final firestore = FirebaseFirestore.instance;
        final notificationId = (reminder.title.hashCode + widget.activeElder.id.hashCode).toUnsigned(31);

        final reminderData = {
          'elderId': widget.activeElder.id,
          'createdBy': widget.currentUserId,
          'title': reminder.title,
          'scheduledDateTime': Timestamp.fromDate(scheduledDateTime),
          'notificationId': notificationId,
        };

        try {
          if (existingReminder != null) {
            await firestore.collection('healthReminders').doc(existingReminder.id).update(reminderData);
          } else {
            await firestore.collection('healthReminders').add(reminderData);
          }

          await NotificationService.instance.cancel(notificationId);
          await NotificationService.instance.scheduleOneTimeNotification(
            id: notificationId,
            title: _l10n.calendarReminderNotificationTitle,
            body: reminder.title,
            payload: 'health_reminder|${reminder.title}',
            scheduledTime: scheduledDateTime,
            channelKey: 'health_reminders'
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_l10n.calendarReminderSet(reminder.title, DateFormat.yMd(_l10n.localeName).add_jm().format(scheduledDateTime)))),
            );
          }
        } catch (e) {
          debugPrint('Error saving health reminder: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_l10n.calendarErrorSavingReminder(e.toString()))),
            );
          }
        }
      }
    }
  }

  Future<void> _onCancelHealthReminder(HealthReminderEvent reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.calendarConfirmDeleteTitle),
        content: Text(_l10n.calendarConfirmCancelReminder(reminder.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(_l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            child: Text(_l10n.confirmButton),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await NotificationService.instance.cancel(reminder.notificationId);
        await FirebaseFirestore.instance.collection('healthReminders').doc(reminder.id).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.calendarReminderCancelled(reminder.title))),
          );
        }
      } catch (e) {
        debugPrint('Error cancelling reminder: $e');
      }
    }
  }

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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Section(
                title: _l10n.calendarScreenTitle(elder.profileName),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: Text(_l10n.calendarAddNewEventButton),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
                        onPressed: _onAddNewEvent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TableCalendar<CalendarEvent>(
                      locale: _l10n.localeName,
                      firstDay: DateTime.utc(DateTime.now().year - 2, 1, 1),
                      lastDay: DateTime.utc(DateTime.now().year + 2, 12, 31),
                      focusedDay: _selectedDate,
                      selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
                      eventLoader: (day) {
                        final dateOnly = DateTime.utc(day.year, day.month, day.day);
                        return _eventsMap[dateOnly] ?? [];
                      },
                      calendarStyle: CalendarStyle(
                        markersMaxCount: 3,
                        markerDecoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.3), shape: BoxShape.circle),
                        selectedDecoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
                        todayTextStyle: const TextStyle(color: AppTheme.textPrimary),
                        selectedTextStyle: const TextStyle(color: AppTheme.textOnPrimary),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: _theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(_selectedDate, selectedDay)) {
                          setState(() {
                            _selectedDate = selectedDay;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _l10n.calendarEventsOnDate(DateFormat.yMMMMd(_l10n.localeName).format(_selectedDate)),
                      style: AppStyles.sectionTitle,
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingEvents)
                      const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()))
                    else if (_eventsForSelectedDate.isEmpty)
                      Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text(_l10n.calendarNoEventsScheduled, style: AppStyles.emptyStateText)))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _eventsForSelectedDate.length,
                        itemBuilder: (context, index) => _buildEventCard(_eventsForSelectedDate[index]),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Section(
                title: _l10n.calendarRemindersTitle,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reminders.length,
                  itemBuilder: (context, index) {
                    final reminderTpl = reminders[index];
                    final HealthReminderEvent? savedReminder = _healthReminders.cast<HealthReminderEvent?>().firstWhere((r) => r?.title == reminderTpl.title, orElse: () => null);
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(reminderTpl.title, style: _theme.textTheme.titleMedium),
                            subtitle: Text(reminderTpl.frequency, style: _theme.textTheme.bodyMedium),
                            trailing: IconButton(
                              icon: Icon(savedReminder != null ? Icons.notifications_active : Icons.notifications_active_outlined),
                              onPressed: () => _showReminderDialog(context, reminderTpl, existingReminder: savedReminder),
                              tooltip: _l10n.setReminder,
                              color: AppTheme.accentColor,
                            ),
                          ),
                          if (savedReminder != null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
                              child: Container(
                                decoration: BoxDecoration(color: AppTheme.accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(_l10n.calendarReminderSetFor, style: _theme.textTheme.bodyLarge),
                                          const SizedBox(height: 4),
                                          Text(
                                            DateFormat.yMd(_l10n.localeName).add_jm().format(savedReminder.scheduledDateTime.toDate()),
                                            style: _theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if(_canEditDeleteHealthReminder(savedReminder)) ...[
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                                        onPressed: () => _showReminderDialog(context, reminderTpl, existingReminder: savedReminder),
                                        tooltip: _l10n.editReminder,
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel_outlined, size: 20, color: AppTheme.dangerColor),
                                        onPressed: () => _onCancelHealthReminder(savedReminder),
                                        tooltip: _l10n.cancelReminder,
                                      ),
                                    ]
                                  ],
                                ),
                              ),
                            )
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 70),
            ],
          ),
        ),
        if (_showEventForm && _editingEvent != null)
          EventFormModal(
            initialEvent: _editingEvent!,
            mode: _modalMode,
            onCancel: () {
              setState(() {
                _showEventForm = false;
                _editingEvent = null;
              });
            },
            onSubmit: (event) => _onSubmitEvent(event, _modalMode),
          ),
      ],
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final canEditDelete = _canEditDeleteEvent(event);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(side: const BorderSide(color: AppTheme.backgroundGray), borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    event.title.isNotEmpty ? event.title : _l10n.calendarUntitledEvent,
                    style: AppStyles.cardTitle.copyWith(color: AppTheme.primaryColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (canEditDelete && event.id != null && event.id!.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: _l10n.calendarTooltipEditEvent,
                    onPressed: () => _onEditEvent(event),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 6),
            if (event.eventType.isNotEmpty)
              Text(
                '${_l10n.calendarEventTypePrefix} ${event.eventType}',
                style: _theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 4),
            Text(
              '${_l10n.calendarEventTimePrefix} ${_formatEventDateTime(event.startDateTime, allDay: event.allDay)}',
              style: _theme.textTheme.bodyLarge,
            ),
            if (event.notes != null && event.notes!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${_l10n.calendarEventNotesPrefix} ${event.notes!}',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: _theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            if (canEditDelete && event.id != null && event.id!.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _onDeleteEvent(event),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
                  child: Text(_l10n.deleteButton),
                ),
              ),
          ],
        ),
      ),
    );
  }
}