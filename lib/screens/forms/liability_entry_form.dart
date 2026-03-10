// lib/screens/forms/liability_entry_form.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/budget_entry.dart'; // For BudgetPerspective
import 'package:cecelia_care_flutter/models/financial_liability.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';

class LiabilityEntryForm extends StatefulWidget {
  final String careRecipientId;
  final FinancialLiability? editingItem;

  const LiabilityEntryForm({
    super.key,
    required this.careRecipientId,
    this.editingItem,
  });

  @override
  State<LiabilityEntryForm> createState() => _LiabilityEntryFormState();
}

class _LiabilityEntryFormState extends State<LiabilityEntryForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _interestRateController = TextEditingController();
  final _notesController = TextEditingController();

  // Form State
  BudgetPerspective _perspective = BudgetPerspective.caregiver;
  String? _selectedCategory;

  // Liability Categories
  final List<String> _liabilityCategories = [
    'Mortgage',
    'Credit Card Debt',
    'Auto Loan',
    'Student Loan',
    'Medical Debt',
    'Personal Loan',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingItem != null) {
      final item = widget.editingItem!;
      _descriptionController.text = item.description;
      _amountController.text = item.amount.toString();
      _interestRateController.text = item.interestRate?.toString() ?? '';
      _notesController.text = item.notes ?? '';
      _perspective = item.perspective;
      _selectedCategory = item.category;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _interestRateController.dispose();
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

      // This now matches the updated FinancialLiability model constructor
      final entryData = FinancialLiability(
        id: widget.editingItem?.id,
        userId: currentUser.uid,
        careRecipientId: widget.careRecipientId,
        perspective: _perspective,
        description: _descriptionController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        category: _selectedCategory!,
        interestRate: double.tryParse(_interestRateController.text.trim()),
        notes: _notesController.text.trim(),
      );

      if (widget.editingItem != null) {
        await firestoreService.updateLiability(entryData.id!, entryData);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Liability updated successfully!')));
      } else {
        await firestoreService.addLiability(entryData);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Liability added successfully!')));
      }
      
      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving liability: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 20),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.editingItem != null ? 'Edit Liability' : 'Add New Liability', style: AppStyles.modalTitle),
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
                decoration: const InputDecoration(labelText: 'Liability Description'),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount Owed', prefixText: '\$'),
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
                items: _liabilityCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _interestRateController,
                decoration: const InputDecoration(labelText: 'Interest Rate (Optional)', suffixText: '%'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (Optional)'),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Btn(title: 'Cancel', variant: BtnVariant.secondaryOutline, onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Btn(title: widget.editingItem != null ? 'Update' : 'Save Liability', onPressed: _isSaving ? null : _handleSave),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}