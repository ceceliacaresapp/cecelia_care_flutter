import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/widgets/form_sheet_header.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/models/vital_entry.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';

class VitalForm extends StatefulWidget {
  final VitalEntry? editingItem;
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const VitalForm({
    super.key,
    this.editingItem,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<VitalForm> createState() => _VitalFormState();
}

class _VitalFormState extends State<VitalForm> {
  final _formKey = GlobalKey<FormState>();

  List<Map<String, String>> _vitalTypes = [];
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedTypeKey = 'BP';

  bool _isSaving = false;

  late AppLocalizations _l10n;
  late ThemeData _theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);
    _initializeLocalizedVitalTypes();
    _initializeFields();
  }

  void _initializeLocalizedVitalTypes() {
    _vitalTypes = [
      {
        'key': 'BP',
        'label': _l10n.vitalTypeBPLabel,
        'unit': _l10n.vitalTypeBPUnit,
        'placeholder': _l10n.vitalTypeBPPlaceholder
      },
      {
        'key': 'HR',
        'label': _l10n.vitalTypeHRLabel,
        'unit': _l10n.vitalTypeHRUnit,
        'placeholder': _l10n.vitalTypeHRPlaceholder
      },
      {
        'key': 'WT',
        'label': _l10n.vitalTypeWTLabel,
        'unit': _l10n.vitalTypeWTUnit,
        'placeholder': _l10n.vitalTypeWTPlaceholder
      },
      {
        'key': 'BG',
        'label': _l10n.vitalTypeBGLabel,
        'unit': _l10n.vitalTypeBGUnit,
        'placeholder': _l10n.vitalTypeBGPlaceholder
      },
      {
        'key': 'Temp',
        'label': _l10n.vitalTypeTempLabel,
        'unit': _l10n.vitalTypeTempUnit,
        'placeholder': _l10n.vitalTypeTempPlaceholder
      },
      {
        'key': 'O2',
        'label': _l10n.vitalTypeO2Label,
        'unit': _l10n.vitalTypeO2Unit,
        'placeholder': _l10n.vitalTypeO2Placeholder
      },
    ];
    if (!_vitalTypes.any((vt) => vt['key'] == _selectedTypeKey)) {
      _selectedTypeKey = _vitalTypes.first['key']!;
    }
  }

  Map<String, String> get _currentVitalInfo =>
      _vitalTypes.firstWhere(
        (vt) => vt['key'] == _selectedTypeKey,
        orElse: () => _vitalTypes.first,
      );

  @override
  void didUpdateWidget(covariant VitalForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editingItem != widget.editingItem) _initializeFields();
  }

  void _initializeFields() {
    final editing = widget.editingItem;
    if (editing != null) {
      _selectedTypeKey = editing.vitalType;
      _valueController.text = editing.value ?? '';
      _noteController.text = editing.note ?? '';
    } else {
      _selectedTypeKey = _vitalTypes.isNotEmpty
          ? _vitalTypes.first['key']!
          : 'BP';
      _valueController.clear();
      _noteController.clear();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveVital() async {
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
        'vitalType': _selectedTypeKey,
        'value': _valueController.text.trim(),
        'unit': _currentVitalInfo['unit']!,
        'note': _noteController.text.trim(),
        'stamp': Timestamp.now(),
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'date': widget.currentDate,
        'elderId': widget.activeElder.id,
        'loggedByUserId': currentUser.uid,
        'loggedBy': currentUser.displayName ??
            currentUser.email ??
            _l10n.formUnknownUser,
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
      };
      if (widget.editingItem != null) {
        await journalService.updateJournalEntry(
            'vital', payload, widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessVitalUpdated, Colors.green);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await journalService.addJournalEntry(
            'vital', payload, currentUser.uid);
        _showSnackBar(_l10n.formSuccessVitalSaved, Colors.green);
      }
      HapticUtils.success();
      Navigator.of(context, rootNavigator: true).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving/updating vital: $e');
      _showSnackBar(_l10n.formErrorGenericSaveUpdate, Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteVital() async {
    if (widget.editingItem == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.formConfirmDeleteTitle),
        content: Text(_l10n.formConfirmDeleteVitalMessage),
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
        final journalService = context.read<JournalServiceProvider>();
        await journalService.deleteJournalEntry(
            'vital', widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessVitalDeleted, Colors.green);
        Navigator.of(context, rootNavigator: true).pop();
        widget.onClose?.call();
      } catch (e) {
        debugPrint('Error deleting vital: $e');
        _showSnackBar(
            _l10n.formErrorFailedToDeleteVital, Colors.red);
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
    final currentVitalDisplayInfo = _currentVitalInfo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSheetHeader(
          title: widget.editingItem != null
              ? _l10n.vitalFormTitleEdit
              : _l10n.vitalFormTitleNew,
          onDelete:
              widget.editingItem != null ? _handleDeleteVital : null,
          deleteTooltip: _l10n.formTooltipDeleteVital,
          isSaving: _isSaving,
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _l10n.vitalFormLabelTypeRequired,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _vitalTypes.map((vt) {
                      final isSelected =
                          vt['key'] == _selectedTypeKey;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedTypeKey = vt['key']!;
                          _formKey.currentState?.validate();
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.backgroundGray,
                            borderRadius: BorderRadius.circular(AppTheme.radiusXL),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : _theme.dividerColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            vt['label']!,
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
                  const SizedBox(height: 20),
                  Text(
                    _l10n.vitalFormLabelValueRequired(
                        currentVitalDisplayInfo['unit']!),
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _valueController,
                    decoration: InputDecoration(
                        hintText:
                            currentVitalDisplayInfo['placeholder']),
                    keyboardType: _selectedTypeKey == 'BP'
                        ? TextInputType.text
                        : const TextInputType.numberWithOptions(
                            decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return _l10n.vitalFormValidationValueEmpty;
                      }
                      if (_selectedTypeKey == 'BP') {
                        if (!RegExp(r'^\d{2,3}/\d{2,3}$')
                            .hasMatch(value.trim())) {
                          return _l10n.vitalFormValidationBPFormat;
                        }
                      } else {
                        if (double.tryParse(value.trim()) == null) {
                          return _l10n
                              .vitalFormValidationValueNumeric;
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
                    controller: _noteController,
                    decoration: InputDecoration(
                        hintText: _l10n.vitalFormHintNotes),
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
                            : () => Navigator.of(context, rootNavigator: true).pop(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      const SizedBox(width: 12),
                      Btn(
                        title: widget.editingItem != null
                            ? _l10n.updateButton
                            : _l10n.saveButton,
                        onPressed:
                            _isSaving ? null : _handleSaveVital,
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
