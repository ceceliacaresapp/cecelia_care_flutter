// lib/widgets/event_form_modal.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/calendar_event.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';

/// A full-screen (or bottom-sheet) form to create/edit a CalendarEvent.
/// When “Save” is tapped, it returns the modified event via `onSubmit`.
class EventFormModal extends StatefulWidget {
  final CalendarEvent initialEvent;
  final String mode; // "create" or "edit"
  final VoidCallback onCancel;
  final Function(CalendarEvent) onSubmit;

  const EventFormModal({
    super.key,
    required this.initialEvent,
    required this.mode,
    required this.onCancel,
    required this.onSubmit,
  });

  @override
  State<EventFormModal> createState() => _EventFormModalState();
}

class _EventFormModalState extends State<EventFormModal> {
  late TextEditingController _titleCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _notesCtrl;
  final TextEditingController _startDateCtrl = TextEditingController();
  final TextEditingController _startTimeCtrl = TextEditingController();
  final TextEditingController _endDateCtrl = TextEditingController();
  final TextEditingController _endTimeCtrl = TextEditingController();
  final TextEditingController _recurrenceEndDateCtrl = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _allDay = false;
  String? _recurrenceRule; // null = no recurrence
  DateTime? _recurrenceEndDate;

  late AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    final init = widget.initialEvent;
    
    _titleCtrl = TextEditingController(text: init.title);
    _typeCtrl = TextEditingController(text: init.eventType);
    _notesCtrl = TextEditingController(text: init.notes ?? '');

    final sd = init.startDateTime.toDate();
    _startDate = DateTime(sd.year, sd.month, sd.day);
    _startTime = TimeOfDay(hour: sd.hour, minute: sd.minute);

    if (init.endDateTime != null) {
      final ed = init.endDateTime!.toDate();
      _endDate = DateTime(ed.year, ed.month, ed.day);
      _endTime = TimeOfDay(hour: ed.hour, minute: ed.minute);
    } else {
      _endDate = null;
      _endTime = null;
    }
    _allDay = init.allDay;
    _recurrenceRule = init.recurrenceRule;
    if (init.recurrenceEndDate != null) {
      final red = init.recurrenceEndDate!.toDate();
      _recurrenceEndDate = DateTime(red.year, red.month, red.day);
    }
    // Initial format without locale — will be re-synced in didChangeDependencies
    _syncDisplayControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _syncDisplayControllers();
  }

  /// Updates the read-only date/time text controllers to match the current state.
  void _syncDisplayControllers() {
    _startDateCtrl.text = _startDate != null
        ? DateFormat.yMd().format(_startDate!)
        : '';
    _startTimeCtrl.text = _startTime != null
        ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
        : '';
    _endDateCtrl.text = _endDate != null
        ? DateFormat.yMd().format(_endDate!)
        : '';
    _endTimeCtrl.text = _endTime != null
        ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
        : '';
    _recurrenceEndDateCtrl.text = _recurrenceEndDate != null
        ? DateFormat.yMd().format(_recurrenceEndDate!)
        : '';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _typeCtrl.dispose();
    _notesCtrl.dispose();
    _startDateCtrl.dispose();
    _startTimeCtrl.dispose();
    _endDateCtrl.dispose();
    _endTimeCtrl.dispose();
    _recurrenceEndDateCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initialDate = (isStart ? _startDate : _endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _syncDisplayControllers();
      });
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final initialTime = (isStart ? _startTime : _endTime) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
        _syncDisplayControllers();
      });
    }
  }

  void _onSave() {
    if (_titleCtrl.text.trim().isEmpty) {
      _showSnackBar(_l10n.eventFormValidationTitle);
      return;
    }
    if (!_allDay && (_startDate == null || _startTime == null)) {
      _showSnackBar(_l10n.eventFormValidationStartDateTime);
      return;
    }

    final startDateTime = DateTime(
      _startDate!.year, _startDate!.month, _startDate!.day,
      _allDay ? 0 : _startTime!.hour,
      _allDay ? 0 : _startTime!.minute,
    );
    final startTimestamp = Timestamp.fromDate(startDateTime);

    Timestamp? endTimestamp;
    if (_endDate != null) {
      final endDateTime = DateTime(
        _endDate!.year, _endDate!.month, _endDate!.day,
        _allDay ? 23 : (_endTime?.hour ?? 23),
        _allDay ? 59 : (_endTime?.minute ?? 59),
      );
      endTimestamp = Timestamp.fromDate(endDateTime);
    }

    if (_recurrenceRule != null && _recurrenceEndDate == null) {
      _showSnackBar('Please select a "Repeat Until" date.');
      return;
    }

    final Timestamp? recurrenceEndTimestamp = _recurrenceEndDate != null
        ? Timestamp.fromDate(DateTime(
            _recurrenceEndDate!.year,
            _recurrenceEndDate!.month,
            _recurrenceEndDate!.day,
            23, 59))
        : null;

    final updatedEvent = CalendarEvent(
      id: widget.initialEvent.id,
      elderId: widget.initialEvent.elderId,
      createdBy: widget.initialEvent.createdBy,
      title: _titleCtrl.text.trim(),
      eventType: _typeCtrl.text.trim(),
      startDateTime: startTimestamp,
      endDateTime: endTimestamp,
      allDay: _allDay,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      recurrenceRule: _recurrenceRule,
      recurrenceParentId: widget.initialEvent.recurrenceParentId,
      recurrenceEndDate: recurrenceEndTimestamp,
    );

    widget.onSubmit(updatedEvent);
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.mode == 'create'
                        ? _l10n.eventFormTitleCreate
                        : _l10n.eventFormTitleEdit,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onCancel,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: _l10n.eventFormLabelTitle,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _typeCtrl,
                decoration: InputDecoration(
                  labelText: _l10n.eventFormLabelType,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: _allDay,
                    onChanged: (val) => setState(() {
                      _allDay = val ?? false;
                      if (_allDay) {
                        _startTime = null;
                        _endTime = null;
                      }
                      _syncDisplayControllers();
                    }),
                  ),
                  Text(_l10n.eventFormLabelAllDay),
                ],
              ),
              const SizedBox(height: 8),
              _buildDateTimePicker(isStart: true),
              const SizedBox(height: 12),
              _buildDateTimePicker(isStart: false),
              const SizedBox(height: 12),
              _buildRecurrencePicker(),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _l10n.formLabelNotesOptional,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Btn(
                    title: _l10n.cancelButton,
                    onPressed: widget.onCancel,
                    variant: BtnVariant.secondaryOutline,
                  ),
                  const SizedBox(width: 16),
                  Btn(
                    title: _l10n.saveButton,
                    onPressed: _onSave,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({required bool isStart}) {
    final dateCtrl = isStart ? _startDateCtrl : _endDateCtrl;
    final timeCtrl = isStart ? _startTimeCtrl : _endTimeCtrl;

    String dateLabel = isStart
        ? _l10n.eventFormLabelStartDate
        : _l10n.eventFormLabelEndDate;
    if (_allDay && isStart) dateLabel = _l10n.eventFormLabelDate;
    if (_allDay && !isStart) return const SizedBox.shrink();

    String timeLabel = isStart
        ? _l10n.eventFormLabelStartTime
        : _l10n.eventFormLabelEndTime;

    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickDate(isStart),
          child: AbsorbPointer(
            child: TextField(
              controller: dateCtrl,
              readOnly: true,
              decoration: InputDecoration(
                labelText: dateLabel,
                hintText: _l10n.eventFormHintSelectDate,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
          ),
        ),
        if (!_allDay) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickTime(isStart),
            child: AbsorbPointer(
              child: TextField(
                controller: timeCtrl,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: timeLabel,
                  hintText: _l10n.eventFormHintSelectTime,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.access_time),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRecurrencePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _recurrenceRule,
          decoration: const InputDecoration(
            labelText: 'Repeat',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.repeat),
          ),
          items: const [
            DropdownMenuItem(value: null, child: Text('None')),
            DropdownMenuItem(value: 'daily', child: Text('Daily')),
            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
          ],
          onChanged: (val) => setState(() {
            _recurrenceRule = val;
            if (val == null) {
              _recurrenceEndDate = null;
              _recurrenceEndDateCtrl.clear();
            }
          }),
        ),
        if (_recurrenceRule != null) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _pickRecurrenceEndDate,
            child: AbsorbPointer(
              child: TextField(
                controller: _recurrenceEndDateCtrl,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Repeat Until',
                  hintText: 'Select end date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickRecurrenceEndDate() async {
    final initialDate = _recurrenceEndDate ??
        (_startDate ?? DateTime.now()).add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        _recurrenceEndDate = picked;
        _syncDisplayControllers();
      });
    }
  }
}
