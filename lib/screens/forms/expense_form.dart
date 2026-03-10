import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/models/expense_entry.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';

class ExpenseForm extends StatefulWidget {
  final ExpenseEntry? editingItem;
  final String currentDate;
  final ElderProfile activeElder;
  final VoidCallback? onClose;

  const ExpenseForm({
    super.key,
    this.editingItem,
    required this.currentDate,
    required this.activeElder,
    this.onClose,
  });

  @override
  State<ExpenseForm> createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<String> _expenseCategories = [];
  String _selectedCategory = '';
  String _otherCategoryOption = '';

  bool _isSaving = false;

  late AppLocalizations _l10n;
  late ThemeData _theme;

  @override
  void initState() {
    super.initState();
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
    _otherCategoryOption = _l10n.formOptionOther;
    _expenseCategories = [
      _l10n.expenseCategoryMedical,
      _l10n.expenseCategoryGroceries,
      _l10n.expenseCategorySupplies,
      _l10n.expenseCategoryHousehold,
      _l10n.expenseCategoryPersonalCare,
      _otherCategoryOption,
    ];
    if (_selectedCategory.isEmpty ||
        !_expenseCategories.contains(_selectedCategory)) {
      _selectedCategory = _expenseCategories.first;
    }
  }

  void _initializeFields() {
    final editing = widget.editingItem;
    if (editing != null) {
      _descriptionController.text = editing.description ?? '';
      _amountController.text = editing.amount?.toStringAsFixed(2) ?? '';
      _selectedCategory = _expenseCategories.contains(editing.category)
          ? editing.category!
          : _otherCategoryOption;
      _noteController.text = editing.note ?? '';
    } else {
      _descriptionController.clear();
      _amountController.clear();
      _selectedCategory = _expenseCategories.first;
      _noteController.clear();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final journal = context.read<JournalServiceProvider>();
      final user = AuthService.currentUser;
      if (user == null) {
        _showSnackBar(_l10n.formErrorNotAuthenticated, Colors.red);
        return;
      }

      final amountValue = double.tryParse(_amountController.text.trim());
      final payload = <String, dynamic>{
        'description': _descriptionController.text.trim(),
        'amount': amountValue,
        'category': _selectedCategory,
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
          'expense',
          payload,
          widget.editingItem!.firestoreId,
        );
        _showSnackBar(_l10n.formSuccessExpenseUpdated, Colors.green);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await journal.addJournalEntry('expense', payload, user.uid);
        _showSnackBar(_l10n.formSuccessExpenseSaved, Colors.green);
      }

      Navigator.of(context).pop();
      widget.onClose?.call();
    } catch (e) {
      debugPrint('Save/update error: $e');
      _showSnackBar(_l10n.formErrorGenericSaveUpdate, Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleDeleteExpense() async {
    if (widget.editingItem == null) {
      _showSnackBar(_l10n.formErrorNoItemToDelete, Colors.orange);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_l10n.formConfirmDeleteTitle),
        content: Text(_l10n.formConfirmDeleteExpenseMessage),
        actions: [
          TextButton(
            child: Text(_l10n.cancelButton),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.dangerColor,
            ),
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
          'expense',
          widget.editingItem!.firestoreId,
        );
        _showSnackBar(_l10n.formSuccessExpenseDeleted, Colors.green);
        Navigator.of(context).pop();
        widget.onClose?.call();
      } catch (e) {
        debugPrint('Delete error: $e');
        _showSnackBar(_l10n.formErrorFailedToDeleteExpense, Colors.red);
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
            ? _l10n.expenseFormTitleEdit
            : _l10n.expenseFormTitleNew),
        actions: [
          if (widget.editingItem != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.dangerColor),
              tooltip: _l10n.formTooltipDeleteExpense,
              onPressed: _isSaving ? null : _handleDeleteExpense,
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
                    '${_l10n.expenseFormLabelDescription}*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: _l10n.expenseFormHintDescription,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? _l10n.expenseFormValidationDescription
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_l10n.expenseFormLabelAmount} (\$)*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: _l10n.expenseFormHintAmount,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return _l10n.expenseFormValidationAmountEmpty;
                      }
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) {
                        return _l10n.expenseFormValidationAmountInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${_l10n.expenseFormLabelCategory}*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _expenseCategories.map((cat) {
                      final isSelected = cat == _selectedCategory;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedCategory = cat;
                        }),
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
                            cat,
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
                      hintText: _l10n.expenseFormHintNotes,
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
                        onPressed: _isSaving ? null : _handleSaveExpense,
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
