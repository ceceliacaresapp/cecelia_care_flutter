// lib/screens/forms/income_entry_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/budget_entry.dart'; // For BudgetPerspective
import 'package:cecelia_care_flutter/models/income_entry.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';

class IncomeEntryForm extends StatefulWidget {
  final String careRecipientId;
  final IncomeEntry? editingItem;

  const IncomeEntryForm({
    super.key,
    required this.careRecipientId,
    this.editingItem,
  });

  @override
  State<IncomeEntryForm> createState() => _IncomeEntryFormState();
}

class _IncomeEntryFormState extends State<IncomeEntryForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // Form State
  BudgetPerspective _perspective = BudgetPerspective.caregiver;
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isRecurring = false;

  // Income Categories
  final List<String> _incomeCategories = [
    'Salary / Wages',
    'Pension',
    'Social Security',
    'Investment Income',
    'Rental Income',
    'Gift',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingItem != null) {
      final item = widget.editingItem!;
      _descriptionController.text = item.description;
      _amountController.text = item.amount.toString();
      _notesController.text = item.notes ?? '';
      _perspective = item.perspective;
      _selectedCategory = item.category;
      _selectedDate = item.date;
      _isRecurring = item.isRecurring;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final firestoreService = context.read<FirestoreService>();
      final currentUser = AuthService.currentUser;

      if (currentUser == null) throw Exception('User not authenticated.');

      // This now matches the updated IncomeEntry model constructor
      final entryData = IncomeEntry(
        id: widget.editingItem?.id,
        userId: currentUser.uid,
        careRecipientId: widget.careRecipientId,
        perspective: _perspective,
        description: _descriptionController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        category: _selectedCategory!,
        date: _selectedDate,
        isRecurring: _isRecurring,
        notes: _notesController.text.trim(),
      );

      if (widget.editingItem != null) {
        await firestoreService.updateIncomeEntry(entryData.id!, entryData);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Income updated successfully!')));
      } else {
        await firestoreService.addIncomeEntry(entryData);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Income added successfully!')));
      }
      
      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving income: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    // No changes needed in the build method, it was already correct.
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.editingItem != null ? 'Edit Income' : 'Add New Income', style: AppStyles.modalTitle),
              const SizedBox(height: 24),

              SegmentedButton<BudgetPerspective>(
                segments: const [
                  ButtonSegment(value: BudgetPerspective.caregiver, label: Text('My Money')),
                  ButtonSegment(value: BudgetPerspective.careRecipient, label: Text('Their Money')),
                ],
                selected: {_perspective},
                onSelectionChanged: (newSelection) => setState(() => _perspective = newSelection.first),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(v) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text('Select a Category'),
                onChanged: (v) => setState(() => _selectedCategory = v),
                items: _incomeCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date: ${DateFormat.yMd().format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
              ),
              const SizedBox(height: 16),
              
              SwitchListTile(
                title: const Text('Is this a recurring monthly income?'),
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Btn(title: 'Cancel', variant: BtnVariant.secondaryOutline, onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Btn(title: widget.editingItem != null ? 'Update' : 'Save Income', onPressed: _isSaving ? null : _handleSave),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}