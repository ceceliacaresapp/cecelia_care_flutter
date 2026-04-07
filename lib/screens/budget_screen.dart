// lib/screens/budget_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/services/auth_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';
import 'package:cecelia_care_flutter/models/budget_entry.dart';
import 'package:cecelia_care_flutter/models/income_entry.dart';
import 'package:cecelia_care_flutter/models/financial_asset.dart';
import 'package:cecelia_care_flutter/models/financial_liability.dart';
import 'package:cecelia_care_flutter/models/insurance_plan.dart';
import 'package:cecelia_care_flutter/screens/forms/budget_entry_form.dart';
import 'package:cecelia_care_flutter/screens/forms/set_budgets_form.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/widgets/expense_breakdown_chart.dart';
import 'package:cecelia_care_flutter/widgets/insurance_tracker_card.dart';

import 'package:cecelia_care_flutter/screens/forms/income_entry_form.dart';
import 'package:cecelia_care_flutter/screens/forms/asset_entry_form.dart';
import 'package:cecelia_care_flutter/screens/forms/liability_entry_form.dart';

enum BudgetFilter { all, activeRecipient }

// A helper class to hold combined data for the list
class Transaction {
  final String id;
  final String description;
  final String category;
  final double amount;
  final DateTime date;
  final bool isIncome;
  final dynamic originalEntry; // To hold the original BudgetEntry or IncomeEntry

  Transaction({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.date,
    required this.isIncome,
    required this.originalEntry,
  });
}

// Accent color for the budget screen — amber-orange matching the Care tab tile.
const _kBudgetColor = Color(0xFFF57C00);

class BudgetScreen extends StatefulWidget {
  final String careRecipientId;
  const BudgetScreen({super.key, required this.careRecipientId});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  DateTime _selectedMonth = DateTime.now();
  BudgetFilter _selectedFilter = BudgetFilter.activeRecipient;
  InsurancePlan? _insurancePlan;
  bool _planLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadInsurancePlan();
  }

  Future<void> _loadInsurancePlan() async {
    final plan = await InsurancePlan.load(DateTime.now().year);
    if (mounted) {
      setState(() {
        _insurancePlan = plan;
        _planLoaded = true;
      });
    }
  }

  void _changeMonth(int increment) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + increment, 1);
    });
  }

  void _showAddEntryMenu(String? careRecipientIdForForm) {
    final targetCareRecipientId = careRecipientIdForForm ?? widget.careRecipientId;
    
    showModalBottomSheet(
      context: context,
      builder: (_) => Wrap(
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: const Text('Add Expense'),
            onTap: () {
              Navigator.pop(context);
              _showBudgetEntryForm(null, targetCareRecipientId);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add Income'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => IncomeEntryForm(careRecipientId: targetCareRecipientId));
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_outlined),
            title: const Text('Add Asset'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => AssetEntryForm(careRecipientId: targetCareRecipientId));
            },
          ),
            ListTile(
            leading: const Icon(Icons.credit_card_outlined),
            title: const Text('Add Liability'),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => LiabilityEntryForm(careRecipientId: targetCareRecipientId));
            },
          ),
        ],
      ),
    );
  }

  void _showBudgetEntryForm(BudgetEntry? entry, String careRecipientId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BudgetEntryForm(
        careRecipientId: entry?.careRecipientId ?? careRecipientId,
        editingItem: entry,
      ),
    );
  }
  
  // ADDED: A new function to show the income entry form
  void _showIncomeEntryForm(IncomeEntry? entry, String careRecipientId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => IncomeEntryForm(
        careRecipientId: entry?.careRecipientId ?? careRecipientId,
        editingItem: entry,
      ),
    );
  }

  void _showSetBudgetsForm(String? careRecipientId) {
    if (careRecipientId == null || careRecipientId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a specific care recipient to set budgets.'),
      ));
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SetBudgetsForm(
        careRecipientId: careRecipientId,
        month: _selectedMonth,
      ),
    );
  }
  
  // UPDATED: Now handles both income and expenses
  Future<void> _deleteTransaction(Transaction transaction) async {
    if (transaction.id.isEmpty) return;

    final bool? confirmed = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this ${transaction.isIncome ? 'income' : 'expense'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final firestoreService = context.read<FirestoreService>();
        if (transaction.isIncome) {
          await firestoreService.deleteIncomeEntry(transaction.id);
        } else {
          await firestoreService.deleteBudgetEntry(transaction.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${transaction.isIncome ? 'Income' : 'Expense'} deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting entry: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeElder = Provider.of<ActiveElderProvider>(context).activeElder;
    final currentUserId = AuthService.currentUser?.uid;

    if (currentUserId == null) {
      return const Scaffold(body: Center(child: Text('Error: Not logged in')));
    }

    final String? filteredCareRecipientId = _selectedFilter == BudgetFilter.activeRecipient ? activeElder?.id : null;
    
    final String screenTitle;
    final bool canSetBudgets;
    if (_selectedFilter == BudgetFilter.activeRecipient) {
        screenTitle = "Financials for ${activeElder?.profileName ?? '...'}";
        canSetBudgets = activeElder != null;
    } else {
        screenTitle = 'Financials for All';
        canSetBudgets = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100.0),
          child: Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Column(
              children: [
                SegmentedButton<BudgetFilter>(
                    segments: const [
                        ButtonSegment(value: BudgetFilter.activeRecipient, label: Text('Active')),
                        ButtonSegment(value: BudgetFilter.all, label: Text('All')),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (newSelection) {
                        setState(() {
                            _selectedFilter = newSelection.first;
                        });
                    },
                    style: SegmentedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.24),
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        selectedForegroundColor: Theme.of(context).primaryColor,
                        selectedBackgroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onPrimary),
                      onPressed: () => _changeMonth(-1),
                    ),
                    Text(
                      DateFormat.yMMMM().format(_selectedMonth),
                      style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onPrimary),
                      onPressed: () => _changeMonth(1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopSection(context, currentUserId, filteredCareRecipientId, canSetBudgets),
          const Divider(height: 1),
          Expanded(
            // UPDATED: This now calls the combined transaction list builder
            child: _buildTransactionList(context, currentUserId: currentUserId, careRecipientId: filteredCareRecipientId),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'budgetAddFab',
        onPressed: () => _showAddEntryMenu(activeElder?.id),
        backgroundColor: _kBudgetColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, String currentUserId, String? careRecipientId, bool canSetBudgets) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildNetWorthCard(context, currentUserId, careRecipientId),
          const SizedBox(height: 16),
          _buildInsuranceSection(context, currentUserId, careRecipientId),
          const SizedBox(height: 16),
          _buildCashFlowCard(context, currentUserId, careRecipientId),
          const SizedBox(height: 16),
          _buildBudgetStatusCard(context, currentUserId, careRecipientId, canSetBudgets),
          const SizedBox(height: 16),
          _buildTaxDeductionCard(context, currentUserId, careRecipientId),
          const SizedBox(height: 16),
          _buildExpenseBreakdownSection(context, currentUserId, careRecipientId),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Insurance OOP tracker
  // ─────────────────────────────────────────────────────────

  Widget _buildInsuranceSection(
      BuildContext context, String currentUserId, String? careRecipientId) {
    if (!_planLoaded) {
      return const SizedBox.shrink();
    }
    final firestoreService = context.read<FirestoreService>();
    final year = DateTime.now().year;
    return StreamBuilder<List<BudgetEntry>>(
      stream: firestoreService.getBudgetStreamForYear(
        userId: currentUserId,
        careRecipientId: careRecipientId,
        year: year,
      ),
      builder: (context, snap) {
        final entries = snap.data ?? const <BudgetEntry>[];
        final medical = entries
            .where((e) => e.category == 'Medical & Health')
            .toList();
        final ytdMedicalSpend =
            medical.fold<double>(0, (s, e) => s + e.amount);
        final ytdTaxDeductible = entries
            .where((e) => e.isTaxDeductible)
            .fold<double>(0, (s, e) => s + e.amount);
        final monthsElapsed = DateTime.now().month;
        final monthlyAvg =
            monthsElapsed > 0 ? ytdMedicalSpend / monthsElapsed : 0.0;
        return InsuranceTrackerCard(
          plan: _insurancePlan,
          ytdMedicalSpend: ytdMedicalSpend,
          ytdTaxDeductible: ytdTaxDeductible,
          monthlyAverage: monthlyAvg,
          onSetup: _showInsuranceSetupSheet,
        );
      },
    );
  }

  void _showInsuranceSetupSheet() {
    final year = DateTime.now().year;
    final existing = _insurancePlan;
    final deductibleCtrl = TextEditingController(
        text: existing?.deductibleAmount.toStringAsFixed(0) ?? '');
    final oopCtrl = TextEditingController(
        text: existing?.outOfPocketMax.toStringAsFixed(0) ?? '');
    final premiumCtrl = TextEditingController(
        text: existing?.monthlyPremium?.toStringAsFixed(0) ?? '');
    final agiCtrl = TextEditingController(
        text: existing?.adjustedGrossIncome?.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Insurance Plan · $year',
                style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Saved on this device only. Update once a year.',
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deductibleCtrl,
              decoration: const InputDecoration(
                labelText: 'Annual deductible',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: oopCtrl,
              decoration: const InputDecoration(
                labelText: 'Out-of-pocket maximum',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: premiumCtrl,
              decoration: const InputDecoration(
                labelText: 'Monthly premium (optional)',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: agiCtrl,
              decoration: const InputDecoration(
                labelText: 'Adjusted Gross Income (optional)',
                helperText:
                    'Used for the IRS 7.5% medical-deduction threshold',
                prefixText: '\$',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (existing != null)
                  TextButton(
                    onPressed: () async {
                      await InsurancePlan.clear(year);
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      setState(() => _insurancePlan = null);
                    },
                    child: const Text('Clear',
                        style: TextStyle(color: AppTheme.dangerColor)),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    final deductible =
                        double.tryParse(deductibleCtrl.text.trim()) ?? 0;
                    final oop =
                        double.tryParse(oopCtrl.text.trim()) ?? 0;
                    if (deductible <= 0 || oop <= 0) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Please enter both deductible and OOP max.')),
                      );
                      return;
                    }
                    final plan = InsurancePlan(
                      year: year,
                      deductibleAmount: deductible,
                      outOfPocketMax: oop,
                      monthlyPremium:
                          double.tryParse(premiumCtrl.text.trim()),
                      adjustedGrossIncome:
                          double.tryParse(agiCtrl.text.trim()),
                    );
                    await plan.save();
                    if (!ctx.mounted) return;
                    Navigator.of(ctx).pop();
                    setState(() => _insurancePlan = plan);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Tax deduction summary
  // ─────────────────────────────────────────────────────────

  Widget _buildTaxDeductionCard(
      BuildContext context, String currentUserId, String? careRecipientId) {
    final firestoreService = context.read<FirestoreService>();
    final year = DateTime.now().year;
    final money = NumberFormat.simpleCurrency(decimalDigits: 0);
    return StreamBuilder<List<BudgetEntry>>(
      stream: firestoreService.getBudgetStreamForYear(
        userId: currentUserId,
        careRecipientId: careRecipientId,
        year: year,
      ),
      builder: (context, snap) {
        final all = snap.data ?? const <BudgetEntry>[];
        final deductible = all.where((e) => e.isTaxDeductible).toList();
        final ytd = deductible.fold<double>(0, (s, e) => s + e.amount);
        final plan = _insurancePlan;
        final hasAgi = plan?.hasAgi ?? false;
        final threshold = plan?.irsMedicalThreshold ?? 0;
        final aboveThreshold =
            hasAgi ? (ytd - threshold).clamp(0, double.infinity) : 0;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF7B1FA2).withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          const Color(0xFF7B1FA2).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined,
                        color: Color(0xFF7B1FA2), size: 18),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('Tax Deductions · YTD',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                  if (deductible.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => _exportTaxDeductibleCsv(deductible, year),
                      icon: const Icon(Icons.ios_share, size: 14),
                      label: const Text('Export',
                          style: TextStyle(fontSize: 11)),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF7B1FA2),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              if (deductible.isEmpty)
                const Text(
                  'No tax-deductible expenses logged this year. Toggle "Potentially Tax-Deductible" on relevant expenses.',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total deductible',
                        style: TextStyle(fontSize: 12)),
                    Text(money.format(ytd),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7B1FA2))),
                  ],
                ),
                Text('${deductible.length} entries',
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
                if (hasAgi) ...[
                  const Divider(height: 18),
                  _kvRow('IRS threshold (7.5% AGI)',
                      money.format(threshold)),
                  const SizedBox(height: 4),
                  _kvRow(
                    'Deductible above threshold',
                    money.format(aboveThreshold),
                    highlight: aboveThreshold > 0,
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    'Add your AGI in the Insurance settings to see how much of this is actually deductible (IRS allows medical expenses above 7.5% of AGI).',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _kvRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: highlight
                  ? const Color(0xFF43A047)
                  : AppTheme.textPrimary,
            )),
      ],
    );
  }

  void _exportTaxDeductibleCsv(List<BudgetEntry> entries, int year) {
    final money = NumberFormat.currency(decimalDigits: 2, symbol: '\$');
    final buf = StringBuffer();
    buf.writeln('Date,Category,Subcategory,Description,Amount');
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    double total = 0;
    for (final e in sorted) {
      buf.writeln('${DateFormat('yyyy-MM-dd').format(e.date)},'
          '"${e.category}",'
          '"${e.subCategory ?? ''}",'
          '"${e.description.replaceAll('"', '""')}",'
          '${e.amount.toStringAsFixed(2)}');
      total += e.amount;
    }
    buf.writeln(',,,,${total.toStringAsFixed(2)}');
    Share.share(buf.toString(),
        subject: 'Tax-Deductible Expenses $year — ${money.format(total)}');
  }

  // ─────────────────────────────────────────────────────────
  // Expense breakdown chart
  // ─────────────────────────────────────────────────────────

  Widget _buildExpenseBreakdownSection(
      BuildContext context, String currentUserId, String? careRecipientId) {
    final firestoreService = context.read<FirestoreService>();
    return StreamBuilder<List<BudgetEntry>>(
      stream: firestoreService.getBudgetStreamForMonth(
        userId: currentUserId,
        careRecipientId: careRecipientId,
        month: _selectedMonth,
      ),
      builder: (context, snap) {
        final entries = snap.data ?? const <BudgetEntry>[];
        if (entries.isEmpty) return const SizedBox.shrink();
        return ExpenseBreakdownChart(
          expenses: entries,
          monthLabel: DateFormat.yMMM().format(_selectedMonth),
        );
      },
    );
  }
  
  Widget _buildNetWorthCard(BuildContext context, String currentUserId, String? careRecipientId) {
    final firestoreService = context.read<FirestoreService>();
    final stream = CombineLatestStream.combine2(
      firestoreService.getAssetsStream(userId: currentUserId, careRecipientId: careRecipientId),
      firestoreService.getLiabilitiesStream(userId: currentUserId, careRecipientId: careRecipientId),
      (List<FinancialAsset> assets, List<FinancialLiability> liabilities) {
        final totalAssets = assets.fold<double>(0, (sum, item) => sum + item.value);
        final totalLiabilities = liabilities.fold<double>(0, (sum, item) => sum + item.amount);
        return totalAssets - totalLiabilities;
      }
    );

    return StreamBuilder<double>(
      stream: stream,
      builder: (context, snapshot) {
        final netWorth = snapshot.data ?? 0.0;
        final formattedNetWorth = NumberFormat.simpleCurrency(decimalDigits: 2).format(netWorth);
        final color = netWorth >= 0 ? const Color(0xFF43A047) : AppTheme.dangerColor;
        return _StyledCard(
          color: _kBudgetColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kBudgetColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.account_balance_outlined,
                      color: _kBudgetColor, size: 18),
                ),
                const SizedBox(width: 10),
                const Text('Net Worth',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
              Text(formattedNetWorth,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCashFlowCard(BuildContext context, String currentUserId, String? careRecipientId) {
    final firestoreService = context.read<FirestoreService>();
    final stream = CombineLatestStream.combine2(
      firestoreService.getIncomeStreamForMonth(userId: currentUserId, careRecipientId: careRecipientId, month: _selectedMonth),
      firestoreService.getBudgetStreamForMonth(userId: currentUserId, careRecipientId: careRecipientId, month: _selectedMonth),
      (List<IncomeEntry> income, List<BudgetEntry> expenses) {
        final totalIncome = income.fold<double>(0, (sum, item) => sum + item.amount);
        final totalExpenses = expenses.fold<double>(0, (sum, item) => sum + item.amount);
        return totalIncome - totalExpenses;
      }
    );
     return StreamBuilder<double>(
      stream: stream,
      builder: (context, snapshot) {
        final cashFlow = snapshot.data ?? 0.0;
        final formattedCashFlow = NumberFormat.simpleCurrency(decimalDigits: 2).format(cashFlow);
        final isPositive = cashFlow >= 0;
        final color = isPositive ? const Color(0xFF43A047) : AppTheme.dangerColor;
        return _StyledCard(
          color: _kBudgetColor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _kBudgetColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: _kBudgetColor, size: 18),
                ),
                const SizedBox(width: 10),
                Text('Cash Flow · ${DateFormat.yMMM().format(_selectedMonth)}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ]),
              Text(formattedCashFlow,
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBudgetStatusCard(BuildContext context, String currentUserId, String? careRecipientId, bool canSetBudgets) {
    if (careRecipientId == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(child: Text('Select a specific care recipient to view their budget status.', textAlign: TextAlign.center,))
        ),
      );
    }
    
    final firestoreService = context.read<FirestoreService>();
    return StreamBuilder<List<BudgetEntry>>(
      stream: firestoreService.getBudgetStreamForMonth(userId: currentUserId, careRecipientId: careRecipientId, month: _selectedMonth),
      builder: (context, expenseSnapshot) {
        final expenses = expenseSnapshot.data ?? [];
        final Map<String, double> spentAmounts = {};
        for (var expense in expenses) {
          spentAmounts.update(expense.category, (value) => value + expense.amount, ifAbsent: () => expense.amount);
        }

        return FutureBuilder<Map<String, double>>(
          future: firestoreService.getCategoryBudgets(elderId: careRecipientId, month: _selectedMonth),
          builder: (context, budgetSnapshot) {
            if (budgetSnapshot.connectionState == ConnectionState.waiting) {
              return const Card(child: Center(child: CircularProgressIndicator()));
            }
            final categoryBudgets = budgetSnapshot.data ?? {};
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Budget Categories', style: Theme.of(context).textTheme.titleLarge),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: canSetBudgets ? AppTheme.primaryColor : Colors.grey),
                          tooltip: 'Set Budgets',
                          onPressed: canSetBudgets ? () => _showSetBudgetsForm(careRecipientId) : null,
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (categoryBudgets.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('No budgets set for this month.')))
                    else
                      ...categoryBudgets.entries.map((entry) {
                        final category = entry.key;
                        final budgetAmount = entry.value;
                        final spentAmount = spentAmounts[category] ?? 0.0;
                        final ratio = (budgetAmount > 0) ? (spentAmount / budgetAmount).clamp(0.0, 1.0) : 0.0;
                        return _BudgetCategoryRow(
                          category: category,
                          spent: spentAmount,
                          total: budgetAmount,
                          progress: ratio,
                        );
                      }),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }

  // UPDATED: This method now combines income and expense streams
  Widget _buildTransactionList(BuildContext context, {required String currentUserId, String? careRecipientId}) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    // 1. Combine the two streams
    final combinedStream = CombineLatestStream.combine2(
      firestoreService.getBudgetStreamForMonth(userId: currentUserId, careRecipientId: careRecipientId, month: _selectedMonth),
      firestoreService.getIncomeStreamForMonth(userId: currentUserId, careRecipientId: careRecipientId, month: _selectedMonth),
      (List<BudgetEntry> expenses, List<IncomeEntry> income) {
        // 2. Map both lists to the common Transaction type
        final expenseTransactions = expenses.map((e) => Transaction(
          id: e.id!,
          description: e.isRecurring
              ? '${e.description} \u21BB'
              : e.description,
          category: e.category,
          amount: e.amount,
          date: e.date,
          isIncome: false,
          originalEntry: e,
        ));
        final incomeTransactions = income.map((i) => Transaction(
          id: i.id!,
          description: i.description,
          category: i.category,
          amount: i.amount,
          date: i.date,
          isIncome: true,
          originalEntry: i,
        ));
        
        // 3. Combine and sort the list
        final allTransactions = [...expenseTransactions, ...incomeTransactions];
        allTransactions.sort((a, b) => b.date.compareTo(a.date)); // Sort newest first
        return allTransactions;
      }
    );

    return StreamBuilder<List<Transaction>>(
      stream: combinedStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(padding: EdgeInsets.all(24.0), child: Text('No transactions logged for this month.')),
          );
        }
        
        final transactions = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            
            // Determine colors and icon based on whether it's income or expense
            final icon = transaction.isIncome ? Icons.add : Icons.remove;
            final amountPrefix = transaction.isIncome ? '+\$' : '-\$';

            final entryColor = transaction.isIncome
                ? const Color(0xFF43A047)
                : AppTheme.dangerColor;
            return GestureDetector(
              onTap: () {
                if (transaction.isIncome) {
                  _showIncomeEntryForm(transaction.originalEntry as IncomeEntry,
                      (transaction.originalEntry as IncomeEntry).careRecipientId);
                } else {
                  _showBudgetEntryForm(transaction.originalEntry as BudgetEntry,
                      (transaction.originalEntry as BudgetEntry).careRecipientId);
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: entryColor.withOpacity(0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: entryColor.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(width: 4, color: entryColor),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: entryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon,
                                      color: entryColor, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(transaction.description,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${transaction.category} · ${DateFormat.MMMd().format(transaction.date)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '$amountPrefix${transaction.amount.toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: entryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                                IconButton(
                                  icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppTheme.textLight,
                                      size: 18),
                                  tooltip: 'Delete',
                                  onPressed: () =>
                                      _deleteTransaction(transaction),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Styled card — matches the app's left-accent-strip card pattern.
// ---------------------------------------------------------------------------
class _StyledCard extends StatelessWidget {
  const _StyledCard({required this.child, required this.color});
  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _BudgetCategoryRow extends StatelessWidget {
  final String category;
  final double spent;
  final double total;
  final double progress;
  const _BudgetCategoryRow({ required this.category, required this.spent, required this.total, required this.progress });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(category, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('\$${spent.toStringAsFixed(0)} / \$${total.toStringAsFixed(0)}', style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade300,
            color: progress > 0.8 ? Colors.red.shade400 : AppTheme.primaryColor,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}
