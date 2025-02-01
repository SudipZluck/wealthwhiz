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
  BudgetFrequency _selectedFrequency = BudgetFrequency.monthly;

  @override
  void initState() {
    super.initState();
    _loadBudgets();
  }

  Future<void> _loadBudgets() async {
    setState(() => _isLoading = true);
    try {
      final budgetService = BudgetService();
      final budgets = await budgetService.getBudgets();
      setState(() {
        _budgets = budgets;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load budgets: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Budget> get _filteredBudgets {
    return _budgets.where((b) => b.frequency == _selectedFrequency).toList();
  }

  double get _totalBudget {
    return _filteredBudgets.fold(0, (sum, budget) => sum + budget.amount);
  }

  double get _totalSpent {
    // TODO: Calculate actual spent amount from transactions
    return _filteredBudgets.fold(0,
        (sum, budget) => sum + (budget.amount * 0.65)); // Temporary calculation
  }

  double get _totalRemaining {
    return _totalBudget - _totalSpent;
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
                                    budget.customCategory ??
                                        _formatCategoryName(
                                            budget.category.toString()),
                                    budget.amount *
                                        0.65, // TODO: Replace with actual spent amount
                                    budget.amount,
                                    Colors.purple, // TODO: Add category colors
                                    Icons.category, // TODO: Add category icons
                                  ))
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
    double spent,
    double total,
    Color color,
    IconData icon,
  ) {
    final progress = spent / total;
    final theme = Theme.of(context);

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
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(category),
            subtitle: Text(
              '\$${spent.toStringAsFixed(2)} of \$${total.toStringAsFixed(2)}',
              style: AppConstants.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            trailing: Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: AppConstants.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
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
              value: _totalBudget > 0 ? _totalSpent / _totalBudget : 0,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
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
                  setState(() {
                    _selectedFrequency = frequency;
                  });
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
