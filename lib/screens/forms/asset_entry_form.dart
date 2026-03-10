// lib/screens/forms/asset_entry_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/models/budget_entry.dart'; // For BudgetPerspective
import 'package:cecelia_care_flutter/models/financial_asset.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';

class AssetEntryForm extends StatefulWidget {
  final String careRecipientId;
  final FinancialAsset? editingItem;

  const AssetEntryForm({
    super.key,
    required this.careRecipientId,
    this.editingItem,
  });

  @override
  State<AssetEntryForm> createState() => _AssetEntryFormState();
}

class _AssetEntryFormState extends State<AssetEntryForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();

  // Form State
  BudgetPerspective _perspective = BudgetPerspective.caregiver;
  String? _selectedCategory;
  DateTime _dateOfValuation = DateTime.now();

  // Asset Categories
  final List<String> _assetCategories = [
    'Real Estate',
    'Bank Account - Checking',
    'Bank Account - Savings',
    'Investment - Stocks',
    'Investment - Bonds',
    'Retirement Account (401k, IRA)',
    'Vehicle',
    'Personal Property',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.editingItem != null) {
      final item = widget.editingItem!;
      _descriptionController.text = item.description;
      _valueController.text = item.value.toString();
      _notesController.text = item.notes ?? '';
      _perspective = item.perspective;
      _selectedCategory = item.category;
      _dateOfValuation = item.dateOfValuation;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _valueController.dispose();
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

      // This now matches the updated FinancialAsset model constructor
      final entryData = FinancialAsset(
        id: widget.editingItem?.id,
        userId: currentUser.uid,
        careRecipientId: widget.careRecipientId,
        perspective: _perspective,
        description: _descriptionController.text.trim(),
        value: double.tryParse(_valueController.text.trim()) ?? 0.0,
        category: _selectedCategory!,
        dateOfValuation: _dateOfValuation,
        notes: _notesController.text.trim(),
      );

      if (widget.editingItem != null) {
        await firestoreService.updateAsset(entryData.id!, entryData);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Asset updated successfully!')));
      } else {
        await firestoreService.addAsset(entryData);
        scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Asset added successfully!')));
      }
      
      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error saving asset: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfValuation,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Select Date of Valuation',
    );
    if (pickedDate != null && pickedDate != _dateOfValuation) {
      setState(() => _dateOfValuation = pickedDate);
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
              Text(widget.editingItem != null ? 'Edit Asset' : 'Add New Asset', style: AppStyles.modalTitle),
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
                decoration: const InputDecoration(labelText: 'Asset Description'),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Current Value', prefixText: '\$'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please enter a value';
                  if (double.tryParse(v) == null) return 'Please enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text('Select a Category'),
                onChanged: (v) => setState(() => _selectedCategory = v),
                items: _assetCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                validator: (v) => v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 16),
              
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Date of Value: ${DateFormat.yMd().format(_dateOfValuation)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Notes (e.g., account number)'),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Btn(title: 'Cancel', variant: BtnVariant.secondaryOutline, onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  Btn(title: widget.editingItem != null ? 'Update' : 'Save Asset', onPressed: _isSaving ? null : _handleSave),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}