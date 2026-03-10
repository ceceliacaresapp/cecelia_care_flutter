import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/models/meal_entry.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';

class MealForm extends StatefulWidget {
  final MealEntry? editingItem;
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const MealForm({
    super.key,
    this.editingItem,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<MealForm> createState() => _MealFormState();
}

class _MealFormState extends State<MealForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

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
  void didUpdateWidget(covariant MealForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.editingItem != widget.editingItem) {
      _initializeFields();
    }
  }

  void _initializeFields() {
    final editing = widget.editingItem;
    if (editing != null) {
      _descriptionController.text = editing.description ?? '';
      _caloriesController.text = editing.calories?.toString() ?? '';
      _noteController.text = editing.note ?? '';
    } else {
      _descriptionController.clear();
      _caloriesController.clear();
      _noteController.clear();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _caloriesController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveMeal() async {
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
        'description': _descriptionController.text.trim(),
        'calories': int.tryParse(_caloriesController.text.trim()),
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
          'meal',
          payload,
          widget.editingItem!.firestoreId,
        );
        _showSnackBar(_l10n.formSuccessMealUpdated, Colors.green);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await journal.addJournalEntry('meal', payload, user.uid);
        _showSnackBar(_l10n.formSuccessMealSaved, Colors.green);
      }

      Navigator.of(context).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Error saving/updating meal: $e');
      _showSnackBar(_l10n.formErrorGenericSaveUpdate, Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteMeal() async {
    if (widget.editingItem == null) {
      _showSnackBar(_l10n.formErrorNoItemToDelete, Colors.orange);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.formConfirmDeleteTitle),
        content: Text(_l10n.formConfirmDeleteMealMessage),
        actions: [
          TextButton(
            child: Text(_l10n.cancelButton),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.dangerColor),
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
        await journal.deleteJournalEntry('meal', widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessMealDeleted, Colors.green);
        Navigator.of(context).pop();
        widget.onClose?.call();
      } catch (e) {
        debugPrint('Error deleting meal: $e');
        _showSnackBar(_l10n.formErrorFailedToDeleteMeal, Colors.red);
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
            ? _l10n.mealFormTitleEdit
            : _l10n.mealFormTitleNew),
        actions: [
          if (widget.editingItem != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.dangerColor),
              tooltip: _l10n.formTooltipDeleteMeal,
              onPressed: _isSaving ? null : _handleDeleteMeal,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    '${_l10n.mealFormLabelDescription}*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _l10n.mealFormHintFoodDescription,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _l10n.mealFormValidationFoodDescription
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _l10n.mealFormLabelCalories,
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: _l10n.mealFormHintCalories,
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
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: _l10n.mealFormHintFoodNotes,
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
                        onPressed: _isSaving ? null : _handleSaveMeal,
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
