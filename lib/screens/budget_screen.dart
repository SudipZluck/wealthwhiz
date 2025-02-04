import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../utils/utils.dart';
import 'budget_form_screen.dart';
import 'budget_category_details_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _isLoading = false;
  List<Budget> _budgets = [];
  List<Budget> _filteredBudgets = [];
  Map<String, double> _budgetSpending = {};
  BudgetFrequency _selectedFrequency = BudgetFrequency.monthly;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  void _onFrequencyChanged(BudgetFrequency? frequency) {
    if (frequency != null) {
      setState(() {
        _selectedFrequency = frequency;
        _filteredBudgets = _filterBudgetsByFrequency(_budgets);
      });
    }
  }

  List<Budget> _filterBudgetsByFrequency(List<Budget> budgets) {
    return budgets
        .where((budget) => budget.frequency == _selectedFrequency)
        .toList();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    try {
      final firebaseService = FirebaseService();
      final currentUser = await firebaseService.getCurrentUser();
      if (currentUser != null) {
        final budgetService = BudgetService();
        final databaseService = DatabaseService();

        final budgets = await budgetService.getBudgets();
        final transactions =
            await databaseService.getTransactions(currentUser.id);

        // Calculate spending for each budget
        final Map<String, double> budgetSpending = {};
        for (var budget in budgets) {
          final budgetTransactions = transactions.where((t) =>
              t.type == TransactionType.expense &&
              t.category == budget.category &&
              t.date.isAfter(budget.startDate) &&
              t.date.isBefore(budget.endDate));

          final spent = budgetTransactions.fold<double>(
              0, (sum, transaction) => sum + transaction.amount);

          budgetSpending[budget.id] = spent;
        }

        if (mounted) {
          setState(() {
            _budgets = budgets;
            _budgetSpending = budgetSpending;
            _filteredBudgets = _filterBudgetsByFrequency(budgets);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading budgets: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  double get _totalBudget {
    return _filteredBudgets.fold(0, (sum, budget) => sum + budget.amount);
  }

  double get _totalSpent {
    return _filteredBudgets.fold(
        0, (sum, budget) => sum + (_budgetSpending[budget.id] ?? 0));
  }

  double get _totalRemaining {
    return _totalBudget - _totalSpent;
  }

  double get _spendingProgress {
    return _totalBudget > 0
        ? (_totalSpent / _totalBudget).clamp(0.0, 1.0)
        : 0.0;
  }

  Future<void> _addBudget() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BudgetFormScreen(),
      ),
    );

    if (result == true) {
      _loadBudgets();
    }
  }

  String _formatCategoryName(String category) {
    final name = category.split('.').last;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  String _formatFrequencyName(BudgetFrequency frequency) {
    final name = frequency.toString().split('.').last;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Budget',
      ),
      body: RefreshIndicator(
        onRefresh: _loadBudgets,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                children: [
                  // Frequency Filter
                  _buildFrequencyFilter(),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Total Budget Overview
                  _buildOverviewCard(),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Budget Categories
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomCardHeader(
                          title: 'Budget Categories',
                          actions: _filteredBudgets.isNotEmpty
                              ? [
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: _addBudget,
                                    tooltip: 'Add Budget Category',
                                  ),
                                ]
                              : null,
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        if (_filteredBudgets.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingMedium,
                              vertical: AppConstants.paddingLarge,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'No ${_formatFrequencyName(_selectedFrequency)} budget categories set up yet',
                                  textAlign: TextAlign.center,
                                  style: AppConstants.bodyLarge,
                                ),
                                const SizedBox(
                                    height: AppConstants.paddingLarge),
                                SizedBox(
                                  width: double.infinity,
                                  child: CustomButton(
                                    text: 'Add Budget',
                                    onPressed: _addBudget,
                                    icon: Icons.add,
                                    height: 54.0,
                                  ),
                                ),
                                const SizedBox(
                                    height: AppConstants.paddingMedium),
                              ],
                            ),
                          )
                        else
                          ..._filteredBudgets
                              .map((budget) => _buildBudgetCategory(
                                  context,
                                  _formatCategoryName(
                                      budget.category.toString()),
                                  [budget]))
                              .toList(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBudgetStat(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppConstants.bodySmall.copyWith(
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: AppConstants.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBudgetCategory(
    BuildContext context,
    String category,
    List<Budget> budgets,
  ) {
    final theme = Theme.of(context);
    double total = 0;
    double spent = 0;

    for (var budget in budgets) {
      total += budget.amount;
      spent += _budgetSpending[budget.id] ?? 0;
    }

    final progress = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = spent > total;

    return CustomCard(
      onTap: () {
        final selectedBudget = _filteredBudgets.firstWhere(
          (b) => _formatCategoryName(b.category.toString()) == category,
          orElse: () => throw Exception('Budget not found'),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BudgetCategoryDetailsScreen(
              budget: selectedBudget,
              category: category,
              totalBudget: total,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category,
                style: AppConstants.titleMedium,
              ),
              Text(
                '${CurrencyFormatter.format(spent, Currency.usd)} / ${CurrencyFormatter.format(total, Currency.usd)}',
                style: AppConstants.bodyMedium.copyWith(
                  color:
                      isOverBudget ? Colors.red : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget ? Colors.red : theme.colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    final theme = Theme.of(context);
    final isOverBudget = _totalSpent > _totalBudget;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomCardHeader(
            title: '${_formatFrequencyName(_selectedFrequency)} Overview',
            subtitle: DateFormatter.getMonthYear(DateTime.now()),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                child: _buildBudgetStat(
                  context,
                  'Total Budget',
                  CurrencyFormatter.format(_totalBudget, Currency.usd),
                  Icons.account_balance_wallet,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildBudgetStat(
                  context,
                  'Spent',
                  CurrencyFormatter.format(_totalSpent, Currency.usd),
                  Icons.shopping_cart,
                  Colors.red,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildBudgetStat(
                  context,
                  'Remaining',
                  CurrencyFormatter.format(_totalRemaining, Currency.usd),
                  Icons.savings,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _spendingProgress,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverBudget
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyFilter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: BudgetFrequency.values.map((frequency) {
        final isSelected = frequency == _selectedFrequency;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingSmall / 2,
            ),
            child: FilterChip(
              label: Text(
                _formatFrequencyName(frequency),
                textAlign: TextAlign.center,
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  _onFrequencyChanged(frequency);
                }
              },
              labelPadding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        );
      }).toList(),
    );
  }
}
