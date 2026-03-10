import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/active_elder_provider.dart';
import 'package:cecelia_care_flutter/utils/app_theme.dart';
import 'package:cecelia_care_flutter/utils/app_styles.dart';

class _ExpenseDoc {
  final String id;
  final DateTime timestamp;
  final String? dateString;
  final String category;
  final double amount;
  final String description;
  final String? loggedByUserId;
  final String? loggedByDisplayName;
  final String? elderId;

  _ExpenseDoc({
    required this.id,
    required this.timestamp,
    this.dateString,
    required this.category,
    required this.amount,
    required this.description,
    this.loggedByUserId,
    this.loggedByDisplayName,
    this.elderId,
  });

  factory _ExpenseDoc.fromJson(
    Map<String, dynamic> json,
    AppLocalizations l10n,
  ) {
    final serverTs = json['stamp'] as Timestamp?;
    final parsedDateString = json['date'] as String?;
    DateTime effectiveTimestamp;
    if (serverTs != null) {
      effectiveTimestamp = serverTs.toDate();
    } else if (parsedDateString != null) {
      try {
        effectiveTimestamp = DateTime.parse('${parsedDateString}T00:00:00Z');
      } catch (_) {
        effectiveTimestamp = DateTime.now();
      }
    } else {
      effectiveTimestamp = DateTime.now();
    }

    return _ExpenseDoc(
      id: json['id'] as String,
      timestamp: effectiveTimestamp,
      dateString: parsedDateString,
      category: (json['category'] as String?) ?? l10n.expenseUncategorized,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: (json['description'] as String?) ?? '',
      loggedByUserId: json['loggedByUserId'] as String?,
      loggedByDisplayName: json['loggedBy'] as String?,
      elderId: json['elderId'] as String?,
    );
  }
}

class _WeeklySummary {
  final String weekDisplay;
  final Map<String, double> totalsByCategory;
  final Map<String, _UserSummary> users;
  final double totalForWeek;
  final List<_ExpenseDoc> expenses;

  _WeeklySummary({
    required this.weekDisplay,
    required this.totalsByCategory,
    required this.users,
    required this.totalForWeek,
    required this.expenses,
  });
}

class _UserSummary {
  final String displayName;
  double total;
  final List<_ExpenseDoc> expenses;

  _UserSummary({
    required this.displayName,
    required this.total,
    required this.expenses,
  });
}

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  late AppLocalizations _l10n;
  late ThemeData _theme;

  List<_ExpenseDoc> _allRawExpenses = [];
  bool _isLoadingExpenses = true;
  int _weekOffset = 0;
  _WeeklySummary _currentWeekSummary = _WeeklySummary(
    weekDisplay: '',
    totalsByCategory: {},
    users: {},
    totalForWeek: 0.0,
    expenses: [],
  );
  late ActiveElderProvider _elderProv;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _expensesSubscription;
  String? _activeElderIdPrevious;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _theme = Theme.of(context);

    final newElderProv = Provider.of<ActiveElderProvider>(context);
    final currentActiveElderId = newElderProv.activeElder?.id;

    _elderProv = newElderProv;

    if (_activeElderIdPrevious != currentActiveElderId) {
      _activeElderIdPrevious = currentActiveElderId;
      _listenToExpenses();
    } else if (_allRawExpenses.isEmpty && _isLoadingExpenses) {
      _listenToExpenses();
    }
  }

  @override
  void dispose() {
    _expensesSubscription?.cancel();
    super.dispose();
  }

  Map<String, DateTime> _getWeekDateRange(int offset) {
    final tz.TZDateTime nowInLocalTz = tz.TZDateTime.now(tz.local);
    final int daysToSubtract = (nowInLocalTz.weekday == DateTime.sunday) ? 0 : nowInLocalTz.weekday;
    final DateTime startOfWeekUtc = DateTime.utc(nowInLocalTz.year, nowInLocalTz.month, nowInLocalTz.day).subtract(Duration(days: daysToSubtract));
    final DateTime startDate = startOfWeekUtc.add(Duration(days: offset * 7));
    final DateTime endDate = startDate.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59, milliseconds: 999));
    return {'start': startDate, 'end': endDate};
  }

  String _formatDateRangeForDisplay(DateTime start, DateTime end) {
    final fmtShort = DateFormat('MMM d', _l10n.localeName);
    if (start.year == end.year) {
      if (start.month == end.month && start.day == end.day) {
        return '${fmtShort.format(start)}, ${start.year}';
      }
      return '${fmtShort.format(start)} - ${fmtShort.format(end)}, ${start.year}';
    }
    final fmtFull = DateFormat('MMM d, yyyy', _l10n.localeName);
    return '${fmtFull.format(start)} - ${fmtFull.format(end)}';
  }

  void _listenToExpenses() {
    _expensesSubscription?.cancel();
    if (!mounted) return;

    final activeElder = _elderProv.activeElder;

    if (activeElder == null || activeElder.id.isEmpty) {
      setState(() {
        _allRawExpenses = [];
        _isLoadingExpenses = false;
      });
      _computeWeeklySummary();
      return;
    }

    setState(() {
      _isLoadingExpenses = true;
    });

    final queryRef = FirebaseFirestore.instance
        .collectionGroup('expense')
        .where('elderId', isEqualTo: activeElder.id)
        .orderBy('stamp', descending: true);

    _expensesSubscription = queryRef.snapshots().listen(
      (snapshot) {
        if (!mounted) return;
        try {
          final docs = snapshot.docs.map((doc) {
            final Map<String, dynamic> jsonData = {'id': doc.id, ...doc.data()};
            return _ExpenseDoc.fromJson(jsonData, _l10n);
          }).toList();
          setState(() {
            _allRawExpenses = docs;
            _isLoadingExpenses = false;
          });
        } catch (e) {
          debugPrint('Error parsing expense documents: $e');
          if (mounted) {
            setState(() {
              _allRawExpenses = [];
              _isLoadingExpenses = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(_l10n.expenseErrorProcessingData(e.toString()))),
            );
          }
        }
        _computeWeeklySummary();
      },
      onError: (error) {
        if (!mounted) return;
        debugPrint('Error fetching expenses: $error');
        if (mounted) {
          setState(() {
            _isLoadingExpenses = false;
            _allRawExpenses = [];
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_l10n.expenseErrorFetching(error.toString()))),
          );
        }
        _computeWeeklySummary();
      },
    );
  }

  void _computeWeeklySummary() {
    if (!mounted) return;

    final range = _getWeekDateRange(_weekOffset);
    final start = range['start']!;
    final end = range['end']!;
    final display = _formatDateRangeForDisplay(start, end);

    final filteredForWeek = _allRawExpenses.where((e) {
      final expenseDate = DateTime.utc(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      return !expenseDate.isBefore(start) && !expenseDate.isAfter(end);
    }).toList();

    final Map<String, double> totalsByCategory = {};
    final Map<String, _UserSummary> usersMap = {};
    double weekTotal = 0.0;

    for (final exp in filteredForWeek) {
      final category = exp.category;
      final amt = exp.amount;
      final userId = exp.loggedByUserId ?? 'unknown_user_${exp.id}';
      final name = exp.loggedByDisplayName ?? _l10n.expenseUnknownUser;

      if (amt > 0) {
        totalsByCategory[category] = (totalsByCategory[category] ?? 0.0) + amt;
        weekTotal += amt;

        if (!usersMap.containsKey(userId)) {
          usersMap[userId] = _UserSummary(displayName: name, total: 0.0, expenses: []);
        }
        usersMap[userId]!.total += amt;
        usersMap[userId]!.expenses.add(exp);
      }
    }

    setState(() {
      _currentWeekSummary = _WeeklySummary(
        weekDisplay: display,
        totalsByCategory: totalsByCategory,
        users: usersMap,
        totalForWeek: weekTotal,
        expenses: filteredForWeek,
      );
    });
  }

  void _changeWeek(int dir) {
    if (dir == 1 && _weekOffset >= 0) return;

    if (mounted) {
      setState(() {
        _weekOffset += dir;
      });
      _computeWeeklySummary();
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeElder = _elderProv.activeElder;

    // --- I18N UPDATE ---
    // Create a currency formatter that respects the current locale.
    final currencyFormatter = NumberFormat.simpleCurrency(locale: _l10n.localeName);

    Widget screenContent;

    if (activeElder == null) {
      screenContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            _l10n.expenseSelectElderPrompt,
            style: AppStyles.emptyStateText,
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (_isLoadingExpenses && _allRawExpenses.isEmpty) {
      screenContent = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_l10n.expenseLoading),
          ],
        ),
      );
    } else {
      screenContent = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _l10n.expenseForElder(activeElder.profileName),
              style: _theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(onPressed: () => _changeWeek(-1), child: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text(
                    _currentWeekSummary.weekDisplay,
                    style: _theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                OutlinedButton(onPressed: _weekOffset >= 0 ? null : () => _changeWeek(1), child: const Icon(Icons.chevron_right)),
              ],
            ),
            const SizedBox(height: 20),
            if (!_isLoadingExpenses && _currentWeekSummary.expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Center(
                  child: Text(
                    _l10n.expenseNoExpensesThisWeek,
                    style: AppStyles.emptyStateText,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_isLoadingExpenses && _currentWeekSummary.expenses.isEmpty && activeElder.id.isNotEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundGray,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _theme.dividerColor.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _l10n.expenseSummaryByCategoryTitle,
                          style: _theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        if (_currentWeekSummary.totalsByCategory.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(_l10n.expenseNoExpensesInCategoryThisWeek, style: AppStyles.emptyStateText),
                          )
                        else
                          ..._currentWeekSummary.totalsByCategory.entries.map((e) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(e.key, style: _theme.textTheme.bodyLarge),
                                  // --- I18N UPDATE ---
                                  Text(
                                    currencyFormatter.format(e.value),
                                    style: _theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            );
                          }),
                        const Divider(height: 24, thickness: 1),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _l10n.expenseWeekTotalLabel,
                              style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                            ),
                            // --- I18N UPDATE ---
                            Text(
                              currencyFormatter.format(_currentWeekSummary.totalForWeek),
                              style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_currentWeekSummary.users.isNotEmpty) ...[
                    Text(
                      _l10n.expenseDetailedByUserTitle,
                      style: _theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ..._currentWeekSummary.users.entries.map((entry) {
                      final userSummary = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _theme.dividerColor.withOpacity(0.5)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 3,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  userSummary.displayName,
                                  style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                // --- I18N UPDATE ---
                                Text(
                                  currencyFormatter.format(userSummary.total),
                                  style: _theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            ...userSummary.expenses.map((exp) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            exp.description,
                                            style: _theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(_l10n.expenseCategoryLabel(exp.category), style: _theme.textTheme.bodySmall),
                                          const SizedBox(height: 2),
                                          Text(
                                            DateFormat.yMMMd(_l10n.localeName).add_jm().format(exp.timestamp),
                                            style: _theme.textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // --- I18N UPDATE ---
                                    Text(
                                      currencyFormatter.format(exp.amount),
                                      style: _theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      );
    }

    return Scaffold(
      body: screenContent,
      floatingActionButton: null,
    );
  }
}