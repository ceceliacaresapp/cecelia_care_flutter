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
import 'package:cecelia_care_flutter/models/mood_entry.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';

class MoodForm extends StatefulWidget {
  final MoodEntry? editingItem;
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const MoodForm({
    super.key,
    this.editingItem,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<MoodForm> createState() => _MoodFormState();
}

class _MoodFormState extends State<MoodForm> {
  final _formKey = GlobalKey<FormState>();

  int _moodLevel = 0;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  late AppLocalizations _l10n;
  late ThemeData _theme;

  static const Map<int, String> _moodEmojis = {
    5: '😄',
    4: '😊',
    3: '😐',
    2: '😟',
    1: '😠',
  };

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

  @override
  void didUpdateWidget(covariant MoodForm old) {
    super.didUpdateWidget(old);
    if (old.editingItem != widget.editingItem) _initializeFields();
  }

  void _initializeFields() {
    final editing = widget.editingItem;
    if (editing != null) {
      _moodLevel = editing.moodLevel ?? 0;
      _noteController.text = editing.note ?? '';
    } else {
      _moodLevel = 0;
      _noteController.clear();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveMood() async {
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
        'moodLevel': _moodLevel,
        'note': _noteController.text.trim(),
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
            'mood', payload, widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessMoodUpdated, Colors.green);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await journal.addJournalEntry('mood', payload, user.uid);
        _showSnackBar(_l10n.formSuccessMoodSaved, Colors.green);
      }
      HapticUtils.success();
      Navigator.of(context).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving/updating mood: $e');
      _showSnackBar(_l10n.formErrorGenericSaveUpdate, Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteMood() async {
    if (widget.editingItem == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.formConfirmDeleteTitle),
        content: Text(_l10n.formConfirmDeleteMoodMessage),
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
            'mood', widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessMoodDeleted, Colors.green);
        Navigator.of(context).pop();
        widget.onClose?.call();
      } catch (e) {
        debugPrint('Error deleting mood: $e');
        _showSnackBar(_l10n.formErrorFailedToDeleteMood, Colors.red);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String msg, Color col) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: col,
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
              ? _l10n.moodFormTitleEdit
              : _l10n.moodFormTitleNew,
          onDelete: widget.editingItem != null ? _handleDeleteMood : null,
          deleteTooltip: _l10n.formTooltipDeleteMood,
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
                    '${_l10n.moodFormLabelSelectMood}*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _moodEmojis.entries.map((e) {
                      final lvl = e.key;
                      final emoji = e.value;
                      final sel = _moodLevel == lvl;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _moodLevel = lvl;
                          _formKey.currentState?.validate();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.primaryColor.withOpacity(0.2)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: sel
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            emoji,
                            style:
                                TextStyle(fontSize: sel ? 40 : 32),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  Opacity(
                    opacity: 0,
                    child: SizedBox(
                      height: 0,
                      child: TextFormField(
                        key: ValueKey(_moodLevel),
                        initialValue:
                            _moodLevel > 0 ? _moodLevel.toString() : '',
                        validator: (v) =>
                            (v == null || v.isEmpty)
                                ? _l10n
                                    .moodFormValidationSelectOrSpecifyMood
                                : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _l10n.formLabelNotesOptional,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    decoration:
                        InputDecoration(hintText: _l10n.moodFormHintNotes),
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
                            _isSaving ? null : _handleSaveMood,
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
