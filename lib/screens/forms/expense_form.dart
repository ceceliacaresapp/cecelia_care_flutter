import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/elder_profile.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/models/expense_entry.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:cecelia_care_flutter/widgets/form_sheet_header.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/models/journal_entry.dart';
import 'package:cecelia_care_flutter/models/entry_types.dart';
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

  final TextEditingController _descriptionController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<String> _expenseCategories = [];
  String _selectedCategory = '';
  String _otherCategoryOption = '';

  bool _isSaving = false;

  // Attached image — optional link to an uploaded image entry
  String? _attachedImageEntryId;
  String? _attachedImageUrl;
  String? _attachedImageTitle;

  late AppLocalizations _l10n;
  late ThemeData _theme;

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
      _amountController.text =
          editing.amount?.toStringAsFixed(2) ?? '';
      _selectedCategory =
          _expenseCategories.contains(editing.category)
              ? editing.category!
              : _otherCategoryOption;
      _noteController.text = editing.note ?? '';
      // Pre-fill attached image if editing an entry that had one
      // (stored in the Firestore document alongside the expense fields)
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
      final amountValue =
          double.tryParse(_amountController.text.trim());
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
        if (_attachedImageEntryId != null)
          'attachedImageEntryId': _attachedImageEntryId,
        if (_attachedImageUrl != null)
          'attachedImageUrl': _attachedImageUrl,
        if (_attachedImageTitle != null)
          'attachedImageTitle': _attachedImageTitle,
      };
      if (widget.editingItem != null) {
        await journal.updateJournalEntry(
            'expense', payload, widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessExpenseUpdated, Colors.green);
      } else {
        payload['createdAt'] = FieldValue.serverTimestamp();
        await journal.addJournalEntry('expense', payload, user.uid);
        _showSnackBar(_l10n.formSuccessExpenseSaved, Colors.green);
      }
      Navigator.of(context, rootNavigator: true).pop();
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
            'expense', widget.editingItem!.firestoreId);
        _showSnackBar(_l10n.formSuccessExpenseDeleted, Colors.green);
        Navigator.of(context, rootNavigator: true).pop();
        widget.onClose?.call();
      } catch (e) {
        debugPrint('Delete error: $e');
        _showSnackBar(
            _l10n.formErrorFailedToDeleteExpense, Colors.red);
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
              ? _l10n.expenseFormTitleEdit
              : _l10n.expenseFormTitleNew,
          onDelete:
              widget.editingItem != null ? _handleDeleteExpense : null,
          deleteTooltip: _l10n.formTooltipDeleteExpense,
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
                    '${_l10n.expenseFormLabelDescription}*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                        hintText: _l10n.expenseFormHintDescription),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty)
                            ? _l10n.expenseFormValidationDescription
                            : null,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${_l10n.expenseFormLabelAmount} (\$)*',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: InputDecoration(
                        hintText: _l10n.expenseFormHintAmount),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return _l10n.expenseFormValidationAmountEmpty;
                      }
                      final n = double.tryParse(v);
                      if (n == null || n <= 0) {
                        return _l10n
                            .expenseFormValidationAmountInvalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
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
                        onTap: () =>
                            setState(() => _selectedCategory = cat),
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
                  const SizedBox(height: 20),
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
                        hintText: _l10n.expenseFormHintNotes),
                  ),
                  const SizedBox(height: 20),
                  // Attach image section
                  Text(
                    'Attach Image (optional)',
                    style: _theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _ImageAttachPicker(
                    elderId: widget.activeElder.id,
                    selectedImageEntryId: _attachedImageEntryId,
                    selectedImageUrl: _attachedImageUrl,
                    selectedImageTitle: _attachedImageTitle,
                    onSelected: (id, url, title) => setState(() {
                      _attachedImageEntryId = id;
                      _attachedImageUrl = url;
                      _attachedImageTitle = title;
                    }),
                    onCleared: () => setState(() {
                      _attachedImageEntryId = null;
                      _attachedImageUrl = null;
                      _attachedImageTitle = null;
                    }),
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
                                Navigator.of(context, rootNavigator: true).pop();
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
                            _isSaving ? null : _handleSaveExpense,
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

// ---------------------------------------------------------------------------
// _ImageAttachPicker — lets the user select an uploaded image to attach
// to an expense entry.
// ---------------------------------------------------------------------------

class _ImageAttachPicker extends StatelessWidget {
  const _ImageAttachPicker({
    required this.elderId,
    required this.selectedImageEntryId,
    required this.selectedImageUrl,
    required this.selectedImageTitle,
    required this.onSelected,
    required this.onCleared,
  });

  final String elderId;
  final String? selectedImageEntryId;
  final String? selectedImageUrl;
  final String? selectedImageTitle;
  final void Function(String id, String url, String title) onSelected;
  final VoidCallback onCleared;

  static const _kColor = Color(0xFF5C6BC0); // indigo

  @override
  Widget build(BuildContext context) {
    // If an image is already attached, show it with a clear button
    if (selectedImageUrl != null && selectedImageUrl!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kColor.withOpacity(0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.network(
              selectedImageUrl!,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 80,
                color: const Color(0xFFE8EAF6),
                child: const Center(
                    child: Icon(Icons.broken_image, color: _kColor)),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onCleared,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, size: 16, color: _kColor),
                ),
              ),
            ),
            if (selectedImageTitle != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  color: Colors.black45,
                  child: Text(
                    selectedImageTitle!,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Show a picker button that opens a bottom sheet of uploaded images
    return GestureDetector(
      onTap: () => _showImagePicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: _kColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: _kColor.withOpacity(0.25), style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(Icons.attach_file_outlined, color: _kColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Choose from uploaded images',
              style: TextStyle(
                  fontSize: 13,
                  color: _kColor,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.7),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Select an image',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: StreamBuilder<List<JournalEntry>>(
                stream: Provider.of<JournalServiceProvider>(
                        sheetCtx, listen: false)
                    .getJournalEntriesStream(
                  elderId: elderId,
                  currentUserId: AuthService.currentUserId ?? '',
                  entryTypeFilter: 'image',
                ),
                builder: (_, snapshot) {
                  final entries = snapshot.data
                          ?.where((e) => e.type == EntryType.image)
                          .toList() ??
                      [];
                  if (entries.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('No images uploaded yet.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xFF757575))),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final url = e.data?['url'] as String? ?? '';
                      final title =
                          e.data?['title'] as String? ?? 'Image';
                      if (url.isEmpty) return const SizedBox.shrink();
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(sheetCtx).pop();
                          onSelected(e.id ?? '', url, title);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(url, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFE8EAF6),
                                    child: const Icon(Icons.broken_image,
                                        color: _kColor),
                                  )),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
