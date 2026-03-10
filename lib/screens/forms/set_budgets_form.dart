import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';
import 'package:cecelia_care_flutter/widgets/btn.dart';

class SetBudgetsForm extends StatefulWidget {
  final String careRecipientId;
  final DateTime month;

  const SetBudgetsForm({
    super.key,
    required this.careRecipientId,
    required this.month,
  });

  @override
  _SetBudgetsFormState createState() => _SetBudgetsFormState();
}

class _SetBudgetsFormState extends State<SetBudgetsForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _expenseCategories = [
    'Medical & Health', 'Housing', 'Professional Care', 'Daily Living',
    'Transportation', 'Legal & Financial', 'Caregiver Support'
  ];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var category in _expenseCategories) {
      _controllers[category] = TextEditingController();
    }
    _loadExistingBudgets();
  }

  Future<void> _loadExistingBudgets() async {
    setState(() => _isLoading = true);
    try {
      final firestoreService = context.read<FirestoreService>();
      
      final existingBudgets = await firestoreService.getCategoryBudgets(
        elderId: widget.careRecipientId,
        month: widget.month,
      );

      if (mounted) {
        _controllers.forEach((category, controller) {
          if (existingBudgets.containsKey(category)) {
            controller.text = existingBudgets[category]!.toStringAsFixed(0);
          }
        });
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budgets: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    
    try {
      final firestoreService = context.read<FirestoreService>();

      final Map<String, double> budgetsToSave = {};
      _controllers.forEach((category, controller) {
        final amount = double.tryParse(controller.text.trim());
        if (amount != null && amount > 0) {
          budgetsToSave[category] = amount;
        }
      });
      
      await firestoreService.setCategoryBudgets(
        elderId: widget.careRecipientId, 
        budgets: budgetsToSave,
        month: widget.month,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budgets saved successfully!')),
        );
        Navigator.of(context).pop();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving budgets: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Set Budgets for ${DateFormat('MMMM yyyy').format(widget.month)}",
              style: AppStyles.modalTitle,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: _expenseCategories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextFormField(
                          // THIS LINE IS FIXED
                          controller: _controllers[category],
                          decoration: InputDecoration(
                            labelText: category,
                            prefixText: '\$',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Btn(
                  title: 'Cancel',
                  variant: BtnVariant.secondaryOutline,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const SizedBox(width: 12),
                Btn(
                  title: 'Save Budgets',
                  onPressed: _isSaving ? null : _handleSave,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}