import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../widgets/widgets.dart';
import '../widgets/spending_charts.dart';
import 'transactions_screen.dart';
import 'all_transactions_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sample data - Replace with actual data from your backend
    final transactions = [
      Transaction(
        userId: '1',
        amount: 120.50,
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: TransactionType.expense,
        category: TransactionCategory.shopping,
        description: 'Grocery Shopping',
      ),
      Transaction(
        userId: '1',
        amount: 45.00,
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.expense,
        category: TransactionCategory.food,
        description: 'Restaurant',
      ),
      Transaction(
        userId: '1',
        amount: 3500.00,
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.income,
        category: TransactionCategory.salary,
        description: 'Salary Deposit',
      ),
      Transaction(
        userId: '1',
        amount: 89.99,
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: TransactionType.expense,
        category: TransactionCategory.entertainment,
        description: 'Movie and Dinner',
      ),
      Transaction(
        userId: '1',
        amount: 15.99,
        date: DateTime.now().subtract(const Duration(days: 3)),
        type: TransactionType.expense,
        category: TransactionCategory.entertainment,
        description: 'Netflix Subscription',
      ),
      Transaction(
        userId: '1',
        amount: 250.00,
        date: DateTime.now().subtract(const Duration(days: 4)),
        type: TransactionType.expense,
        category: TransactionCategory.utilities,
        description: 'Electricity Bill',
      ),
    ];

    // Calculate spending by category
    final Map<TransactionCategory, double> categorySpending = {};
    double totalSpent = 0;

    for (var transaction in transactions) {
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
        onRefresh: () async {
          // TODO: Implement refresh
        },
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
                    '\$12,345.67',
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
                          '\$8,250.00',
                          Icons.arrow_upward,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Expenses',
                          '\$3,850.00',
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
              transactions: transactions,
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
                  _buildTransactionItem(
                    context,
                    'Grocery Shopping',
                    '\$120.50',
                    'Today',
                    Icons.shopping_cart,
                    Colors.orange,
                  ),
                  _buildTransactionItem(
                    context,
                    'Salary Deposit',
                    '+\$3,500.00',
                    'Yesterday',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                  _buildTransactionItem(
                    context,
                    'Netflix Subscription',
                    '\$15.99',
                    '2 days ago',
                    Icons.movie,
                    Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      title: Text(title),
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
}
