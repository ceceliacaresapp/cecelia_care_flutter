import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cecelia_care_flutter/models/medication_entry.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/haptic_utils.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/widgets/form_sheet_header.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/providers/medication_definitions_provider.dart';
import 'package:cecelia_care_flutter/models/medication_definition.dart';
import 'package:cecelia_care_flutter/providers/day_entries_provider.dart';
import 'package:cecelia_care_flutter/services/med_interaction_api.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';

class MedForm extends StatefulWidget {
  final MedicationEntry? editingItem;
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const MedForm({
    super.key,
    this.editingItem,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<MedForm> createState() => _MedFormState();
}

class _MedFormState extends State<MedForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();

  String _time = '';
  bool _isTaken = false;
  TimeOfDay _medTime = const TimeOfDay(hour: 8, minute: 0);
  List<String> _interactions = [];
  bool _isLoadingInteractions = false;
  String? _currentSelectedRxcui;

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

  @override
  void didUpdateWidget(covariant MedForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editingItem != widget.editingItem) _initializeFields();
  }

  void _initializeFields() {
    const defaultTimeOfDay = TimeOfDay(hour: 8, minute: 0);
    final editing = widget.editingItem;
    if (editing != null) {
      _nameController.text = editing.name;
      _doseController.text = editing.dose ?? '';
      _isTaken = editing.taken;
      _currentSelectedRxcui = editing.rxCui;
      _fetchAndSetInteractions(_currentSelectedRxcui);
      final existing = editing.time;
      if (existing != null &&
          RegExp(r'^\d{2}:\d{2}$').hasMatch(existing)) {
        try {
          final parts = existing.split(':');
          _medTime = TimeOfDay(
              hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        } catch (_) {
          _medTime = defaultTimeOfDay;
        }
      } else {
        _medTime = defaultTimeOfDay;
      }
    } else {
      _nameController.clear();
      _doseController.clear();
      _isTaken = false;
      _currentSelectedRxcui = null;
      _medTime = defaultTimeOfDay;
      _interactions = [];
    }
    _time = _formatTimeOfDay(_medTime);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doseController.dispose();
    super.dispose();
  }

  void _applyMedDefinition(MedicationDefinition def) {
    _nameController.text = def.name;
    _doseController.text = def.dose ?? '';
    _currentSelectedRxcui = def.rxCui;
    if (def.defaultTime != null &&
        RegExp(r'^\d{2}:\d{2}$').hasMatch(def.defaultTime!)) {
      try {
        final parts = def.defaultTime!.split(':');
        _medTime = TimeOfDay(
            hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {
        _medTime = const TimeOfDay(hour: 8, minute: 0);
      }
    } else {
      _medTime = const TimeOfDay(hour: 8, minute: 0);
    }
    _time = _formatTimeOfDay(_medTime);
    _fetchAndSetInteractions(_currentSelectedRxcui);
    _formKey.currentState?.validate();
  }

  String _formatTimeOfDay(TimeOfDay tod) =>
      '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked =
        await showTimePicker(context: context, initialTime: _medTime);
    if (picked != null && mounted) {
      setState(() {
        _medTime = picked;
        _time = _formatTimeOfDay(picked);
      });
    }
  }

  Future<void> _fetchAndSetInteractions(String? newRxcui) async {
    if (!mounted) return;
    setState(() {
      _isLoadingInteractions = true;
      _interactions = [];
    });
    final all =
        await context.read<DayEntriesProvider>().getRxcuisForInteractionCheck(
              rxcuiToAdd: newRxcui,
              editingItemId: widget.editingItem?.firestoreId,
            );
    if (all.length < 2) {
      if (mounted) setState(() => _isLoadingInteractions = false);
      return;
    }
    final results = await MedInteractionApi.fetchInteractions(all);
    if (mounted) {
      setState(() {
        _interactions = results;
        _isLoadingInteractions = false;
      });
    }
  }

  Future<void> _handleSaveMed() async {
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
        'name': _nameController.text.trim(),
        'dose': _doseController.text.trim(),
        'time': _time,
        'taken': _isTaken,
        'date': widget.currentDate,
        'elderId': widget.activeElder.id,
        'stamp': Timestamp.now(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isPublic': true,
        'visibleToUserIds': <String>[],
        'rxCui': _currentSelectedRxcui ?? '',
        'loggedByUserId': user.uid,
        'loggedBy':
            user.displayName ?? user.email ?? _l10n.formUnknownUser,
      };
      if (widget.editingItem != null) {
        await journal.updateJournalEntry(
            'medication', payload, widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessMedUpdated, Colors.green);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await journal.addJournalEntry(
            'medication', payload, user.uid);
        _showSnackBar(_l10n.formSuccessMedSaved, Colors.green);
      }
      HapticUtils.success();
      Navigator.of(context, rootNavigator: true).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving/updating medication: $e');
      _showSnackBar(_l10n.formErrorGenericSaveUpdate, Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteMed() async {
    if (widget.editingItem == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.formConfirmDeleteTitle),
        content: Text(_l10n.formConfirmDeleteMedMessage),
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
            'medication', widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessMedDeleted, Colors.green);
        Navigator.of(context, rootNavigator: true).pop();
        widget.onClose?.call();
      } catch (e) {
        debugPrint('Error deleting medication: $e');
        _showSnackBar(
            _l10n.formErrorFailedToDeleteMed, Colors.red);
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
    final medDefsProvider = context.watch<MedicationDefinitionsProvider>();
    final medDefs = medDefsProvider.medDefinitions;
    final isLoadingDefs = medDefsProvider.isLoadingMedDefs;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSheetHeader(
          title: widget.editingItem != null
              ? _l10n.medFormTitleEdit
              : _l10n.medFormTitleNew,
          onDelete:
              widget.editingItem != null ? _handleDeleteMed : null,
          deleteTooltip: _l10n.formTooltipDeleteMed,
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
                    _l10n.medFormLabelNameRequired,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (isLoadingDefs)
                    const Center(child: CircularProgressIndicator())
                  else if (medDefs.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: medDefs.map((def) {
                        final isSel = _nameController.text
                                .trim()
                                .toLowerCase() ==
                            def.name.toLowerCase();
                        return GestureDetector(
                          onTap: () => mounted
                              ? setState(
                                  () => _applyMedDefinition(def))
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? AppTheme.primaryColor
                                  : AppTheme.backgroundGray,
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                color: isSel
                                    ? AppTheme.primaryColor
                                    : _theme.dividerColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              def.name,
                              style: TextStyle(
                                color: isSel
                                    ? AppTheme.textOnPrimary
                                    : AppTheme.textPrimary,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  if (!isLoadingDefs && medDefs.isNotEmpty)
                    const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                        hintText: medDefs.isNotEmpty
                            ? _l10n.medFormHintNameCustom
                            : _l10n.medFormHintName),
                    onChanged: (_) => setState(() {}),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _l10n.medFormValidationName
                        : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _l10n.medFormLabelDose,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _doseController,
                    decoration: InputDecoration(
                        hintText: _l10n.medFormHintDose),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _l10n.medFormLabelTime,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                AppTheme.textLight.withValues(alpha: 0.5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _time,
                        style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _isTaken,
                        onChanged: (v) =>
                            setState(() => _isTaken = v ?? false),
                        activeColor: AppTheme.primaryColor,
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isTaken = !_isTaken),
                        child: Text(_l10n.medFormLabelMarkAsTaken,
                            style: _theme.textTheme.bodyLarge),
                      ),
                    ],
                  ),
                  if (_isLoadingInteractions)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: LinearProgressIndicator(),
                    ),
                  if (!_isLoadingInteractions &&
                      _interactions.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            AppTheme.warningColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.warningColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _l10n.medicationsInteractionsSectionTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ..._interactions.map(
                            (txt) => Text('• $txt',
                                style: TextStyle(
                                    color: _theme.colorScheme.onSurface
                                        .withValues(alpha: 0.8))),
                          ),
                        ],
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
                            : () => Navigator.of(context, rootNavigator: true).pop(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                      const SizedBox(width: 12),
                      Btn(
                        title: widget.editingItem != null
                            ? _l10n.updateButton
                            : _l10n.saveButton,
                        onPressed: _isSaving ? null : _handleSaveMed,
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
