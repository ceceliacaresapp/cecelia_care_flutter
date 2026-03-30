import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/widgets/form_sheet_header.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/models/sleep_entry.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';

class SleepForm extends StatefulWidget {
  final SleepEntry? editingItem;
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const SleepForm({
    super.key,
    this.editingItem,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<SleepForm> createState() => _SleepFormState();
}

class _SleepFormState extends State<SleepForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _totalDurationController =
      TextEditingController();
  final TextEditingController _qualityController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSaving = false;

  late AppLocalizations _l10n;
  late ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
  }

  void _initializeFields() {
    final editing = widget.editingItem;
    if (editing != null) {
      _totalDurationController.text = editing.totalDuration ?? '';
      _qualityController.text = editing.quality?.toString() ?? '';
      _notesController.text = editing.note ?? '';
    } else {
      _totalDurationController.clear();
      _qualityController.clear();
      _notesController.clear();
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant SleepForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editingItem != widget.editingItem) _initializeFields();
  }

  @override
  void dispose() {
    _totalDurationController.dispose();
    _qualityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveSleep() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final journal = context.read<JournalServiceProvider>();
      final user = AuthService.currentUser;
      if (user == null) {
        _showSnackBar(_l10n.formErrorNotAuthenticated, Colors.red);
        return;
      }
      final payload = <String, dynamic>{
        'totalDuration': _totalDurationController.text.trim(),
        'quality': _qualityController.text.trim(),
        'note': _notesController.text.trim(),
        'stamp': Timestamp.now(),
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'date': widget.currentDate,
        'elderId': widget.activeElder.id,
        'loggedByUserId': user.uid,
        'loggedBy':
            user.displayName ?? user.email ?? _l10n.formUnknownUser,
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
      };
      if (widget.editingItem != null) {
        await journal.updateJournalEntry(
            'sleep', payload, widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessSleepUpdated, Colors.green);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await journal.addJournalEntry('sleep', payload, user.uid);
        _showSnackBar(_l10n.formSuccessSleepSaved, Colors.green);
      }
      HapticUtils.success();
      Navigator.of(context).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving/updating sleep: $e');
      _showSnackBar(_l10n.formErrorGenericSaveUpdate, Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteSleep() async {
    if (widget.editingItem == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.formConfirmDeleteTitle),
        content: Text(_l10n.formConfirmDeleteSleepMessage),
        actions: [
          TextButton(
            child: Text(_l10n.cancelButton),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: AppTheme.dangerColor),
            child: Text(_l10n.deleteButton),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        final journal = context.read<JournalServiceProvider>();
        await journal.deleteJournalEntry(
            'sleep', widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessSleepDeleted, Colors.green);
        Navigator.of(context).pop();
        widget.onClose?.call();
      } catch (e) {
        debugPrint('Error deleting sleep: $e');
        _showSnackBar(_l10n.formErrorFailedToDeleteSleep, Colors.red);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSheetHeader(
          title: widget.editingItem != null
              ? _l10n.sleepFormTitleEdit
              : _l10n.sleepFormTitleNew,
          onDelete:
              widget.editingItem != null ? _handleDeleteSleep : null,
          deleteTooltip: _l10n.formTooltipDeleteSleep,
          isSaving: _isSaving,
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l10n.sleepFormLabelTotalDuration,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _totalDurationController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        hintText: _l10n.sleepFormHintTotalDuration),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _l10n.sleepFormLabelQuality,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _qualityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        hintText: _l10n.sleepFormHintQuality),
                    validator: (value) {
                      if (value != null && value.trim().isNotEmpty) {
                        final v = int.tryParse(value.trim());
                        if (v == null || v < 1 || v > 5) {
                          return _l10n.sleepFormValidationQualityRange;
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _l10n.formLabelNotesOptional,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                        hintText: _l10n.sleepFormHintGeneralNotes),
                    maxLines: 3,
                    minLines: 1,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Btn(
                        title: _l10n.cancelButton,
                        variant: BtnVariant.secondaryOutline,
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      const SizedBox(width: 12),
                      Btn(
                        title: widget.editingItem != null
                            ? _l10n.updateButton
                            : _l10n.saveButton,
                        onPressed:
                            _isSaving ? null : _handleSaveSleep,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
