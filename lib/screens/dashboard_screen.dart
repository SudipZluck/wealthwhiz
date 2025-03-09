import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../widgets/spending_charts.dart';
import '../services/services.dart';
import 'transactions_screen.dart';
import 'all_transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Transaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    try {
      final firebaseService = FirebaseService();
      final currentUser = await firebaseService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      final databaseService = DatabaseService();
      final transactions =
          await databaseService.getTransactions(currentUser.id);
      setState(() {
        _transactions = transactions;
        _transactions.sort(
            (a, b) => b.date.compareTo(a.date)); // Sort by date descending
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading transactions: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Calculate total balance, income, and expenses
    double totalIncome = 0;
    double totalExpenses = 0;
    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
      } else {
        totalExpenses += transaction.amount;
      }
    }
    double totalBalance = totalIncome - totalExpenses;

    // Calculate spending by category
    final Map<TransactionCategory, double> categorySpending = {};
    double totalSpent = 0;

    for (var transaction in _transactions) {
      if (transaction.type == TransactionType.expense) {
        categorySpending[transaction.category] =
            (categorySpending[transaction.category] ?? 0) + transaction.amount;
        totalSpent += transaction.amount;
      }
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dashboard',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Implement notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            // Balance Card
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomCardHeader(
                    title: 'Total Balance',
                    subtitle: 'Available balance',
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    '\$${totalBalance.toStringAsFixed(2)}',
                    style: AppConstants.headlineLarge.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Income',
                          '\$${totalIncome.toStringAsFixed(2)}',
                          Icons.arrow_upward,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Expenses',
                          '\$${totalExpenses.toStringAsFixed(2)}',
                          Icons.arrow_downward,
                          Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Spending Charts
            SpendingCharts(
              transactions: _transactions,
              totalSpent: totalSpent,
              categorySpending: categorySpending,
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Recent Transactions
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomCardHeader(
                    title: 'Recent Transactions',
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AllTransactionsScreen(),
                            ),
                          );
                        },
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_transactions.isEmpty)
                    const Center(
                      child: Text('No recent transactions'),
                    )
                  else
                    Column(
                      children: _transactions
                          .take(3) // Show only the 3 most recent transactions
                          .map((transaction) => _buildTransactionItem(
                                context,
                                transaction.category.toString(),
                                transaction.type == TransactionType.income
                                    ? '+\$${transaction.amount.toStringAsFixed(2)}'
                                    : '\$${transaction.amount.toStringAsFixed(2)}',
                                _getRelativeDate(transaction.date),
                                _getCategoryIcon(transaction.category),
                                transaction.type == TransactionType.income
                                    ? Colors.green
                                    : Colors.red,
                              ))
                          .toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.shopping:
        return Icons.shopping_cart;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.utilities:
        return Icons.flash_on;
      case TransactionCategory.salary:
        return Icons.work;
      case TransactionCategory.investment:
        return Icons.trending_up;
      case TransactionCategory.other:
        return Icons.category;
      default:
        return Icons.attach_money;
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppConstants.bodySmall.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: AppConstants.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    String title,
    String amount,
    String date,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(_formatCategoryName(title)),
      subtitle: Text(date),
      trailing: Text(
        amount,
        style: AppConstants.titleMedium.copyWith(
          color: amount.startsWith('+') ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatCategoryName(String category) {
    // Split by dots and take the last part (in case of enum values)
    final name = category.toString().split('.').last;
    // Capitalize first letter and keep rest lowercase
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }
}
