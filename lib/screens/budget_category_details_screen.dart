import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../utils/utils.dart';
import '../services/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'budget_form_screen.dart';

class BudgetCategoryDetailsScreen extends StatefulWidget {
  final Budget budget;
  final String category;
  final double totalBudget;

  const BudgetCategoryDetailsScreen({
    super.key,
    required this.budget,
    required this.category,
    required this.totalBudget,
  });

  @override
  State<BudgetCategoryDetailsScreen> createState() =>
      _BudgetCategoryDetailsScreenState();
}

class _BudgetCategoryDetailsScreenState
    extends State<BudgetCategoryDetailsScreen> {
  List<FlSpot> _dailySpending = [];
  List<Transaction> _transactions = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndTransactionData();
  }

  Future<void> _loadUserAndTransactionData() async {
    setState(() => _isLoading = true);
    try {
      // Load user data
      final firebaseService = FirebaseService();
      final currentUser = await firebaseService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentUser = currentUser;
        });
      }

      await _loadTransactionData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load user data: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTransactionData() async {
    try {
      final now = DateTime.now();
      final startDate = DateTime(now.year, now.month, 1);
      final endDate = DateTime(now.year, now.month + 1, 0);

      final transactions = (await TransactionService.instance.getTransactions())
          .where((t) =>
              t.category.toString().split('.').last == widget.category &&
              t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
              t.date.isBefore(endDate.add(const Duration(days: 1))))
          .toList();

      // Sort transactions by date, most recent first
      transactions.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _transactions = transactions;
      });

      // Group transactions by day for the chart
      final dailyTotals = <int, double>{};
      for (var transaction in transactions) {
        final day = transaction.date.day;
        dailyTotals[day] = (dailyTotals[day] ?? 0) + transaction.amount;
      }

      // Create spots for each day of the month
      _dailySpending = List.generate(endDate.day, (index) {
        final day = index + 1;
        return FlSpot(
          index.toDouble(),
          dailyTotals[day] ?? 0,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load transaction data: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = _currentUser?.preferredCurrency ?? Currency.usd;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.category[0].toUpperCase() + widget.category.substring(1),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BudgetFormScreen(
                    budget: widget.budget,
                  ),
                ),
              );
              if (result == true) {
                Navigator.pop(context, true);
              }
            },
            tooltip: 'Edit Budget',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Budget'),
                  content: Text(
                      'Are you sure you want to delete the ${widget.category} budget?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                try {
                  final budgetService = BudgetService();
                  await budgetService.deleteBudget(widget.budget.id);
                  if (mounted) {
                    Navigator.pop(context, true);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete budget: $e'),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              }
            },
            tooltip: 'Delete Budget',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              children: [
                CustomCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomCardHeader(
                        title: 'Monthly Overview',
                        subtitle: DateFormatter.getMonthYear(DateTime.now()),
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      SizedBox(
                        height: 300,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      CurrencyFormatter.formatCompact(
                                          value, currency),
                                      style: AppConstants.bodySmall,
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 5 == 0) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: AppConstants.bodySmall,
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _dailySpending,
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                CustomCard(
                  child: Column(
                    children: [
                      CustomCardHeader(
                        title: 'Recent Transactions',
                      ),
                      if (_transactions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppConstants.paddingMedium),
                          child:
                              Text('No transactions found for this category'),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _transactions[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primary.withOpacity(0.1),
                                child: Icon(
                                  Icons.shopping_cart,
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                              title: Text(transaction.description),
                              subtitle: Text(
                                DateFormatter.format(transaction.date),
                              ),
                              trailing: Text(
                                CurrencyFormatter.format(
                                    transaction.amount, currency),
                                style: AppConstants.titleMedium.copyWith(
                                  color: transaction.type ==
                                          TransactionType.expense
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
