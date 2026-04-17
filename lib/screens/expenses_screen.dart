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
import 'package:cecelia_care_flutter/screens/forms/expense_form.dart';
import 'package:cecelia_care_flutter/providers/journal_service_provider.dart';

// Expenses accent color — amber, matching the nav tab.
const _kExpenseColor = AppTheme.tileOrange;

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
        effectiveTimestamp =
            DateTime.parse('${parsedDateString}T00:00:00Z');
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
      category:
          (json['category'] as String?) ?? l10n.expenseUncategorized,
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
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _expensesSubscription;
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
    final int daysToSubtract =
        (nowInLocalTz.weekday == DateTime.sunday)
            ? 0
            : nowInLocalTz.weekday;
    final DateTime startOfWeekUtc = DateTime.utc(
      nowInLocalTz.year,
      nowInLocalTz.month,
      nowInLocalTz.day,
    ).subtract(Duration(days: daysToSubtract));
    final DateTime startDate =
        startOfWeekUtc.add(Duration(days: offset * 7));
    final DateTime endDate = startDate.add(const Duration(
        days: 6,
        hours: 23,
        minutes: 59,
        seconds: 59,
        milliseconds: 999));
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

    setState(() => _isLoadingExpenses = true);

    _expensesSubscription = FirebaseFirestore.instance
        .collectionGroup('expense')
        .where('elderId', isEqualTo: activeElder.id)
        .orderBy('stamp', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;
        try {
          final docs = snapshot.docs.map((doc) {
            final Map<String, dynamic> jsonData = {
              'id': doc.id,
              ...doc.data(),
            };
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
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content:
                  Text(_l10n.expenseErrorProcessingData(e.toString())),
            ));
          }
        }
        _computeWeeklySummary();
      },
      onError: (error) {
        if (!mounted) return;
        debugPrint('Error fetching expenses: $error');
        setState(() {
          _isLoadingExpenses = false;
          _allRawExpenses = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_l10n.expenseErrorFetching(error.toString())),
        ));
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
      final expenseDate = DateTime.utc(
          e.timestamp.year, e.timestamp.month, e.timestamp.day);
      return !expenseDate.isBefore(start) && !expenseDate.isAfter(end);
    }).toList();

    final Map<String, double> totalsByCategory = {};
    final Map<String, _UserSummary> usersMap = {};
    double weekTotal = 0.0;

    for (final exp in filteredForWeek) {
      final amt = exp.amount;
      final userId =
          exp.loggedByUserId ?? 'unknown_user_${exp.id}';
      final name =
          exp.loggedByDisplayName ?? _l10n.expenseUnknownUser;
      if (amt > 0) {
        totalsByCategory[exp.category] =
            (totalsByCategory[exp.category] ?? 0.0) + amt;
        weekTotal += amt;
        if (!usersMap.containsKey(userId)) {
          usersMap[userId] = _UserSummary(
              displayName: name, total: 0.0, expenses: []);
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
    setState(() => _weekOffset += dir);
    _computeWeeklySummary();
  }

  @override
  Widget build(BuildContext context) {
    final activeElder = _elderProv.activeElder;
    final currency =
        NumberFormat.simpleCurrency(locale: _l10n.localeName);

    Widget screenContent;

    if (activeElder == null) {
      screenContent = Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_l10n.expenseSelectElderPrompt,
              style: AppStyles.emptyStateText,
              textAlign: TextAlign.center),
        ),
      );
    } else if (_isLoadingExpenses && _allRawExpenses.isEmpty) {
      screenContent = Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(_l10n.expenseLoading),
        ]),
      );
    } else {
      screenContent = SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Elder sub-label
            Text(
              _l10n.expenseForElder(activeElder.profileName),
              style: _theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),

            // ── Week navigator ─────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: _kExpenseColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                border: Border.all(
                    color: _kExpenseColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeWeek(-1),
                    color: _kExpenseColor,
                  ),
                  Expanded(
                    child: Text(
                      _currentWeekSummary.weekDisplay,
                      style: _theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _kExpenseColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _weekOffset >= 0
                        ? null
                        : () => _changeWeek(1),
                    color: _weekOffset >= 0
                        ? AppTheme.textLight
                        : _kExpenseColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Empty / loading states ─────────────────────────
            if (!_isLoadingExpenses &&
                _currentWeekSummary.expenses.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                    child: Text(_l10n.expenseNoExpensesThisWeek,
                        style: AppStyles.emptyStateText,
                        textAlign: TextAlign.center)),
              )
            else if (_isLoadingExpenses &&
                _currentWeekSummary.expenses.isEmpty &&
                activeElder.id.isNotEmpty)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                          strokeWidth: 2)))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Category summary card ──────────────────
                  _SectionLabel(
                      label:
                          _l10n.expenseSummaryByCategoryTitle),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _kExpenseColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(
                          color: _kExpenseColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      children: [
                        if (_currentWeekSummary
                            .totalsByCategory.isEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                                    vertical: 8),
                            child: Text(
                                _l10n
                                    .expenseNoExpensesInCategoryThisWeek,
                                style: AppStyles.emptyStateText),
                          )
                        else
                          ..._currentWeekSummary
                              .totalsByCategory.entries
                              .map((e) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            vertical: 5),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceBetween,
                                      children: [
                                        Row(children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _kExpenseColor
                                                  .withValues(alpha: 0.6),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(e.key,
                                              style: _theme.textTheme
                                                  .bodyLarge),
                                        ]),
                                        Text(
                                          currency.format(e.value),
                                          style: _theme.textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                  )),
                        Divider(
                            height: 24,
                            thickness: 1,
                            color:
                                _kExpenseColor.withValues(alpha: 0.2)),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _l10n.expenseWeekTotalLabel,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _kExpenseColor,
                              ),
                            ),
                            Text(
                              currency.format(
                                  _currentWeekSummary
                                      .totalForWeek),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _kExpenseColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Per-user cards ─────────────────────────
                  if (_currentWeekSummary.users.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionLabel(
                        label:
                            _l10n.expenseDetailedByUserTitle),
                    const SizedBox(height: 8),
                    ..._currentWeekSummary.users.entries.map(
                      (entry) => _UserCard(
                        userSummary: entry.value,
                        currency: currency,
                        theme: _theme,
                        l10n: _l10n,
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      );
    }

    return Scaffold(
      body: screenContent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'expensesAddFab',
        onPressed: () {
          final activeElder = _elderProv.activeElder;
          if (activeElder == null) return;
          final journalService =
              context.read<JournalServiceProvider>();
          final currentDateStr =
              DateFormat('yyyy-MM-dd').format(DateTime.now());
          // Open the expense form directly as a bottom sheet —
          // bypasses the entry-type picker dialog entirely.
          showModalBottomSheet(
            context: context,
            useRootNavigator: true,
            isScrollControlled: true,
            useSafeArea: true,
            backgroundColor: Colors.transparent,
            builder: (sheetContext) {
              return Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(sheetContext).scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 20,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  constraints: BoxConstraints(
                    maxHeight:
                        MediaQuery.of(sheetContext).size.height * 0.92,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Flexible(
                        child: ChangeNotifierProvider.value(
                          value: journalService,
                          child: ExpenseForm(
                            onClose: () => Navigator.of(sheetContext).pop(),
                            currentDate: currentDateStr,
                            activeElder: activeElder,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        tooltip: _l10n.careScreenButtonAddExpense,
        icon: const Icon(Icons.add),
        label: Text(_l10n.careScreenButtonAddExpense),
        backgroundColor: _kExpenseColor,
        foregroundColor: Colors.white,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-user expense card — left amber border strip
// ---------------------------------------------------------------------------

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.userSummary,
    required this.currency,
    required this.theme,
    required this.l10n,
  });

  final _UserSummary userSummary;
  final NumberFormat currency;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: _kExpenseColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: _kExpenseColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: _kExpenseColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(userSummary.displayName,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _kExpenseColor)),
                          Text(currency.format(userSummary.total),
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: _kExpenseColor)),
                        ],
                      ),
                      Divider(
                          height: 14,
                          thickness: 1,
                          color: _kExpenseColor.withValues(alpha: 0.15)),
                      ...userSummary.expenses.map((exp) => Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(exp.description,
                                          style: theme.textTheme
                                              .bodyLarge
                                              ?.copyWith(
                                                  fontWeight:
                                                      FontWeight.w500)),
                                      const SizedBox(height: 2),
                                      Text(
                                        l10n.expenseCategoryLabel(
                                            exp.category),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: _kExpenseColor
                                                    .withValues(alpha: 0.8)),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        DateFormat.yMMMd(
                                                l10n.localeName)
                                            .add_jm()
                                            .format(exp.timestamp),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                                color: AppTheme
                                                    .textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  currency.format(exp.amount),
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(
                                          fontWeight:
                                              FontWeight.w600),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SectionLabel — matches the dashboard / calendar section label style
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppTheme.textSecondary,
      ),
    );
  }
}
