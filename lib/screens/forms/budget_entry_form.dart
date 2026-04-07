// lib/screens/forms/budget_entry_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/models/budget_entry.dart';
import 'package:cecelia_care_flutter/models/insurance_plan.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';
import 'package:provider/provider.dart';

class BudgetEntryForm extends StatefulWidget {
  final String careRecipientId;
  // NEW: Add an optional editingItem parameter
  final BudgetEntry? editingItem;

  const BudgetEntryForm({
    super.key, 
    required this.careRecipientId,
    this.editingItem, // Make it optional
  });

  @override
  State<BudgetEntryForm> createState() => _BudgetEntryFormState();
}

class _BudgetEntryFormState extends State<BudgetEntryForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  // Form State
  BudgetPerspective _perspective = BudgetPerspective.caregiver;
  String? _selectedCategory;
  String? _selectedSubCategory;
  DateTime _selectedDate = DateTime.now();
  bool _isTaxDeductible = false;
  bool _isRecurring = false;
  final _mileageController = TextEditingController();

  // Expense Taxonomy
  final Map<String, List<String>> _expenseTaxonomy = {
    'Medical & Health': [
      'Prescriptions', 'Medical Services', 'Durable Medical Equipment (DME)', 
      'Medical Supplies', 'Health Insurance Premiums'
    ],
    'Housing': ['Rent / Mortgage Contribution', 'Assisted Living / Nursing Home', 'Home Modifications', 'Utilities'],
    'Professional Care': ['In-Home Aide / Agency Care', 'Adult Day Care / Respite Care', 'Geriatric Care Management'],
    'Daily Living': ['Groceries & Food', 'Household Supplies', 'Entertainment & Outings'],
    'Transportation': ['Medical Travel (Mileage)', 'Medical Travel (Other)', 'Vehicle Modifications'],
    'Legal & Financial': ['Legal Fees', 'Financial Planning'],
    'Caregiver Support': ['Education & Training', 'Lost Wages (Tracking)'],
  };

  @override
  void initState() {
    super.initState();
    // NEW: Populate fields if we are editing an existing item
    if (widget.editingItem != null) {
      final item = widget.editingItem!;
      _descriptionController.text = item.description;
      _amountController.text = item.amount.toString();
      _notesController.text = item.notes ?? '';
      _perspective = item.perspective;
      _selectedCategory = item.category;
      _selectedSubCategory = item.subCategory;
      _selectedDate = item.date;
      _isTaxDeductible = item.isTaxDeductible;
      _isRecurring = item.isRecurring;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  void _calculateMileage() {
    final miles = double.tryParse(_mileageController.text.trim());
    if (miles == null || miles <= 0) return;
    final amount = miles * kMedicalMileageRate;
    setState(() {
      _amountController.text = amount.toStringAsFixed(2);
      if (_descriptionController.text.trim().isEmpty) {
        _descriptionController.text =
            '${miles.toStringAsFixed(0)} mi medical travel';
      }
      _isTaxDeductible = true;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      final firestoreService = context.read<FirestoreService>();
      final currentUser = AuthService.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated.');
      }

      final entryData = BudgetEntry(
        id: widget.editingItem?.id, // Use existing ID if editing
        userId: currentUser.uid,
        careRecipientId: widget.careRecipientId,
        perspective: _perspective,
        description: _descriptionController.text.trim(),
        amount: double.tryParse(_amountController.text.trim()) ?? 0.0,
        category: _selectedCategory!,
        subCategory: _selectedSubCategory,
        date: _selectedDate,
        notes: _notesController.text.trim(),
        isTaxDeductible: _isTaxDeductible,
        isRecurring: _isRecurring,
      );
      
      // NEW: Logic to handle both update and add
      if (widget.editingItem != null) {
        // We are editing, so call update
        await firestoreService.updateBudgetEntry(entryData.id!, entryData);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Expense updated successfully!')), // TODO: Localize
           );
        }
      } else {
        // We are adding a new entry
        await firestoreService.addBudgetEntry(entryData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Expense added successfully!')), // TODO: Localize
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: ${e.toString()}')), // TODO: Localize
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // NEW: Date Picker
  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, right: 16, top: 20
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // NEW: Changed title to be dynamic
              Text(
                widget.editingItem != null ? 'Edit Expense' : 'Add New Expense', 
                style: AppStyles.modalTitle
              ),
              const SizedBox(height: 24),

              SegmentedButton<BudgetPerspective>(
                segments: const [
                  ButtonSegment(value: BudgetPerspective.caregiver, label: Text('My Money')),
                  ButtonSegment(value: BudgetPerspective.careRecipient, label: Text('Their Money')),
                ],
                selected: {_perspective},
                onSelectionChanged: (newSelection) {
                  setState(() => _perspective = newSelection.first);
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => (value == null || value.isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text('Select a Category'),
                onChanged: (newValue) => setState(() {
                  _selectedCategory = newValue;
                  _selectedSubCategory = null;
                }),
                items: _expenseTaxonomy.keys.map((category) {
                  return DropdownMenuItem(value: category, child: Text(category));
                }).toList(),
                validator: (value) => value == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),

              // Subcategory (depends on category)
              if (_selectedCategory != null &&
                  (_expenseTaxonomy[_selectedCategory] ?? const [])
                      .isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  initialValue: _selectedSubCategory,
                  hint: const Text('Subcategory (optional)'),
                  onChanged: (v) =>
                      setState(() => _selectedSubCategory = v),
                  items: _expenseTaxonomy[_selectedCategory]!
                      .map((s) =>
                          DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Medical mileage helper — only shown for the relevant subcategory.
              if (_selectedSubCategory == 'Medical Travel (Mileage)') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color:
                            const Color(0xFF00897B).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Medical Mileage Calculator',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        'IRS rate: \$${kMedicalMileageRate.toStringAsFixed(2)}/mile (current year)',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _mileageController,
                              decoration: const InputDecoration(
                                labelText: 'Miles driven',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _calculateMileage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00897B),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.calculate, size: 16),
                            label: const Text('Calculate'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // NEW: Date Field
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
                title: const Text('Potentially Tax-Deductible?'),
                value: _isTaxDeductible,
                onChanged: (newValue) => setState(() => _isTaxDeductible = newValue),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Recurring monthly'),
                subtitle: const Text(
                    'Marks expenses that repeat each month (insurance, facility, pharmacy)',
                    style: TextStyle(fontSize: 11)),
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
                  Btn(
                    // NEW: Changed text to be dynamic
                    title: widget.editingItem != null ? 'Update' : 'Save Expense', 
                    onPressed: _isSaving ? null : _handleSave,
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}