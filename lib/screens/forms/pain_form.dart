import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/models/pain_entry.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/widgets/form_sheet_header.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PainForm extends StatefulWidget {
  final PainEntry? editingItem;
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const PainForm({
    super.key,
    this.editingItem,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<PainForm> createState() => _PainFormState();
}

class _PainFormState extends State<PainForm> {
  final _formKey = GlobalKey<FormState>();

  List<String> _painDescriptionOptions = [];
  String _otherPainDescriptionOption = '';

  late TextEditingController _locationController;
  late TextEditingController _intensityController;
  late TextEditingController _descriptionController;
  late TextEditingController _noteController;
  String _selectedDescriptionChip = '';

  bool _isSaving = false;

  late AppLocalizations _l10n;
  late ThemeData _theme;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController();
    _intensityController = TextEditingController();
    _descriptionController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
    _initializeLocalizedOptions();
    _initializeFields();
  }

  void _initializeLocalizedOptions() {
    _otherPainDescriptionOption = _l10n.formOptionOther;
    _painDescriptionOptions = [
      _l10n.painTypeAching,
      _l10n.painTypeBurning,
      _l10n.painTypeDull,
      _l10n.painTypeSharp,
      _l10n.painTypeShooting,
      _l10n.painTypeStabbing,
      _l10n.painTypeThrobbing,
      _l10n.painTypeTender,
      _otherPainDescriptionOption,
    ];
  }

  @override
  void didUpdateWidget(covariant PainForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editingItem != widget.editingItem ||
        oldWidget.currentDate != widget.currentDate) {
      _initializeLocalizedOptions();
      _initializeFields();
    }
  }

  void _initializeFields() {
    final editing = widget.editingItem;
    if (editing != null) {
      _locationController.text = editing.location ?? '';
      _intensityController.text = editing.intensity?.toString() ?? '';
      _noteController.text = editing.note ?? '';
      final storedDescription = editing.description ?? '';
      if (_painDescriptionOptions.contains(storedDescription) &&
          storedDescription != _otherPainDescriptionOption) {
        _selectedDescriptionChip = storedDescription;
        _descriptionController.text = storedDescription;
      } else if (storedDescription.isNotEmpty) {
        _selectedDescriptionChip = _otherPainDescriptionOption;
        _descriptionController.text = storedDescription;
      } else {
        _selectedDescriptionChip = '';
        _descriptionController.clear();
      }
    } else {
      _locationController.clear();
      _intensityController.clear();
      _descriptionController.clear();
      _noteController.clear();
      _selectedDescriptionChip = '';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _locationController.dispose();
    _intensityController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSavePain() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final journal = context.read<JournalServiceProvider>();
      final user = AuthService.currentUser;
      if (user == null) {
        _showSnackBar(_l10n.formErrorNotAuthenticated, Colors.red);
        return;
      }
      final descriptionToSave =
          _selectedDescriptionChip == _otherPainDescriptionOption
              ? _descriptionController.text.trim()
              : (_selectedDescriptionChip.isNotEmpty
                  ? _selectedDescriptionChip
                  : _descriptionController.text.trim());
      final payload = <String, dynamic>{
        'location': _locationController.text.trim(),
        'intensity': int.tryParse(_intensityController.text.trim()),
        'description': descriptionToSave,
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
      if (widget.editingItem != null &&
          widget.editingItem!.firestoreId.isNotEmpty) {
        await journal.updateJournalEntry(
            'pain', payload, widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessPainUpdated, Colors.green);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await journal.addJournalEntry('pain', payload, user.uid);
        _showSnackBar(_l10n.formSuccessPainSaved, Colors.green);
      }
      HapticUtils.success();
      Navigator.of(context).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving/updating pain: $e');
      _showSnackBar(_l10n.formErrorGenericSaveUpdate, Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeletePain() async {
    if (widget.editingItem == null ||
        widget.editingItem!.firestoreId.isEmpty) {
      _showSnackBar(_l10n.formErrorNoItemToDelete, Colors.orange);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.formConfirmDeleteTitle),
        content: Text(_l10n.formConfirmDeletePainMessage),
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
            'pain', widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessPainDeleted, Colors.green);
        Navigator.of(context).pop();
        widget.onClose?.call();
      } catch (e) {
        debugPrint('Error deleting pain: $e');
        _showSnackBar(
            _l10n.formErrorFailedToDeletePain, Colors.red);
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
              ? _l10n.painFormTitleEdit
              : _l10n.painFormTitleNew,
          onDelete:
              widget.editingItem != null ? _handleDeletePain : null,
          deleteTooltip: _l10n.formTooltipDeletePain,
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
                    '${_l10n.painFormLabelLocation}*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                        hintText: _l10n.painFormHintLocation),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _l10n.painFormValidationLocation;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_l10n.painFormLabelIntensity}*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _intensityController,
                    decoration: InputDecoration(
                        hintText: _l10n.painFormHintIntensity),
                    keyboardType: TextInputType.number,
                    maxLength: 2,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _l10n
                            .painFormValidationIntensityEmpty;
                      }
                      final p = int.tryParse(value.trim());
                      if (p == null || p < 0 || p > 10) {
                        return _l10n
                            .painFormValidationIntensityRange;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_l10n.painFormLabelDescription}*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _painDescriptionOptions.map((opt) {
                      final selected =
                          opt == _selectedDescriptionChip;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedDescriptionChip = opt;
                            if (opt != _otherPainDescriptionOption) {
                              _descriptionController.text = opt;
                            } else {
                              _descriptionController.clear();
                            }
                            _formKey.currentState?.validate();
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? AppTheme.primaryColor
                                : AppTheme.backgroundGray,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected
                                  ? AppTheme.primaryColor
                                  : _theme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: selected
                                  ? AppTheme.textOnPrimary
                                  : AppTheme.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
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
                        key: ValueKey(
                            'desc_validator_$_selectedDescriptionChip'),
                        initialValue: (_selectedDescriptionChip
                                    .isEmpty &&
                                _descriptionController.text
                                    .trim()
                                    .isEmpty)
                            ? null
                            : 'valid',
                        validator: (value) {
                          if (_selectedDescriptionChip.isEmpty &&
                              _descriptionController.text
                                  .trim()
                                  .isEmpty) {
                            return _l10n
                                .painFormValidationSelectOrSpecifyDescription;
                          }
                          if (_selectedDescriptionChip ==
                                  _otherPainDescriptionOption &&
                              _descriptionController.text
                                  .trim()
                                  .isEmpty) {
                            return _l10n
                                .painFormValidationSpecifyOtherDescription;
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  if (_selectedDescriptionChip ==
                      _otherPainDescriptionOption) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                          hintText: _l10n
                              .painFormHintSpecifyOtherDescription),
                      onChanged: (_) => setState(
                          () => _formKey.currentState?.validate()),
                      validator: (value) {
                        if (_selectedDescriptionChip ==
                                _otherPainDescriptionOption &&
                            (value == null || value.trim().isEmpty)) {
                          return _l10n
                              .painFormValidationSpecifyOtherDescription;
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    _l10n.formLabelNotesOptional,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _noteController,
                    decoration: InputDecoration(
                        hintText: _l10n.painFormHintNotes),
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
                        onPressed:
                            _isSaving ? null : _handleSavePain,
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
