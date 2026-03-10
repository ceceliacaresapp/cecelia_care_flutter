import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/models/activity_entry.dart';
import 'package:provider/provider.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';

class ActivityForm extends StatefulWidget {
  final ActivityEntry? editingItem;
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const ActivityForm({
    super.key,
    this.editingItem,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<ActivityForm> createState() => _ActivityFormState();
}

class _ActivityFormState extends State<ActivityForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _activityTypeController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedActivityTypeChip = '';
  List<String> _activityTypeOptions = [];
  String _otherOption = '';

  bool _isSaving = false;

  late AppLocalizations _l10n;
  late ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _activityTypeController.addListener(_onActivityTypeChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
    _initializeLocalizedOptions();
    _initializeFields();
  }

  void _onActivityTypeChanged() {
    final value = _activityTypeController.text;
    if (mounted) {
      setState(() {
        if (_activityTypeOptions.contains(value) && value != _otherOption) {
          _selectedActivityTypeChip = value;
        } else if (value.isNotEmpty) {
          _selectedActivityTypeChip = _otherOption;
        } else {
          _selectedActivityTypeChip = '';
        }
      });
    }
  }

  void _initializeLocalizedOptions() {
    _otherOption = _l10n.formOptionOther;
    _activityTypeOptions = [
      _l10n.activityTypeWalk,
      _l10n.activityTypeExercise,
      _l10n.activityTypePhysicalTherapy,
      _l10n.activityTypeOccupationalTherapy,
      _l10n.activityTypeOuting,
      _l10n.activityTypeSocialVisit,
      _l10n.activityTypeReading,
      _l10n.activityTypeTV,
      _l10n.activityTypeGardening,
      _otherOption,
    ];
  }

  void _initializeFields() {
    final editing = widget.editingItem;
    if (editing != null) {
      _activityTypeController.text = editing.activityType ?? '';
      _durationController.text = editing.duration ?? '';
      _noteController.text = editing.note ?? '';
    } else {
      _activityTypeController.clear();
      _durationController.clear();
      _noteController.clear();
    }
    _onActivityTypeChanged();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _activityTypeController.removeListener(_onActivityTypeChanged);
    _activityTypeController.dispose();
    _durationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final journalService = context.read<JournalServiceProvider>();
      final currentUser = AuthService.currentUser;
      if (currentUser == null) {
        _showSnackBar(_l10n.formErrorNotAuthenticated, Colors.red);
        return;
      }

      final payload = <String, dynamic>{
        'activityType': _activityTypeController.text.trim(),
        'duration': _durationController.text.trim(),
        'note': _noteController.text.trim(),
        'stamp': Timestamp.now(),
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'date': widget.currentDate,
        'elderId': widget.activeElder.id,
        'loggedByUserId': currentUser.uid,
        'loggedBy':
            currentUser.displayName ?? currentUser.email ?? _l10n.formUnknownUser,
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
      };

      if (widget.editingItem != null &&
          widget.editingItem!.firestoreId.isNotEmpty) {
        await journalService.updateJournalEntry(
            'activity', payload, widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessActivityUpdated, Colors.green);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await journalService.addJournalEntry(
            'activity', payload, currentUser.uid);
        _showSnackBar(_l10n.formSuccessActivitySaved, Colors.green);
      }

      Navigator.of(context).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving/updating activity: $e');
      _showSnackBar(_l10n.formErrorGenericSaveUpdate, Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteActivity() async {
    if (widget.editingItem == null ||
        widget.editingItem!.firestoreId.isEmpty) {
      _showSnackBar(_l10n.formErrorNoItemToDelete, Colors.orange);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.formConfirmDeleteTitle),
        content: Text(_l10n.formConfirmDeleteActivityMessage),
        actions: [
          TextButton(
            child: Text(_l10n.cancelButton),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style:
                TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        final journalService = context.read<JournalServiceProvider>();
        await journalService.deleteJournalEntry(
            'activity', widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessActivityDeleted, Colors.green);
        Navigator.of(context).pop();
        widget.onClose?.call();
      } catch (e) {
        debugPrint('Error deleting activity: $e');
        _showSnackBar(_l10n.formErrorFailedToDeleteActivity, Colors.red);
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editingItem != null
            ? _l10n.activityFormTitleEdit
            : _l10n.activityFormTitleNew),
        actions: [
          if (widget.editingItem != null)
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
              tooltip: _l10n.formTooltipDeleteActivity,
              onPressed: _isSaving ? null : _handleDeleteActivity,
            ),
        ],
      ),
      body: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    _l10n.activityFormLabelActivityTypeRequired,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activityTypeOptions.map((opt) {
                      final isSelected = opt == _selectedActivityTypeChip;
                      return GestureDetector(
                        onTap: () {
                          if (mounted) {
                            setState(() {
                              _selectedActivityTypeChip = opt;
                              _activityTypeController.text =
                                  (opt != _otherOption) ? opt : '';
                              _formKey.currentState?.validate();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.backgroundGray,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : _theme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: isSelected
                                  ? AppTheme.textOnPrimary
                                  : AppTheme.textPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _activityTypeController,
                    decoration: InputDecoration(
                      hintText: _l10n.activityFormHintActivityType,
                    ),
                    onChanged: (_) => _formKey.currentState?.validate(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _l10n.activityFormValidationActivityType;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _l10n.activityFormLabelDuration,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _durationController,
                    decoration: InputDecoration(
                      hintText: _l10n.activityFormHintDuration,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _l10n.formLabelNotesOptional,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: _l10n.activityFormHintNotes,
                    ),
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
                            : () {
                                Navigator.of(context).pop();
                                widget.onClose?.call();
                              },
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      const SizedBox(width: 12),
                      Btn(
                        title: widget.editingItem != null
                            ? _l10n.updateButton
                            : _l10n.saveButton,
                        onPressed: _isSaving ? null : _handleSaveActivity,
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
      ),
    );
  }
}