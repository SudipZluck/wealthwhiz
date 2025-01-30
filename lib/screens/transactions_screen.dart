import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';
import '../models/transaction.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Income', 'Expense'];

  // Sample transactions list - Replace with actual data from your backend
  final List<Transaction> _transactions = [
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
      amount: 3500.00,
      date: DateTime.now().subtract(const Duration(days: 2)),
      type: TransactionType.income,
      category: TransactionCategory.salary,
      description: 'Salary Deposit',
    ),
    Transaction(
      userId: '1',
      amount: 15.99,
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: TransactionType.expense,
      category: TransactionCategory.entertainment,
      description: 'Netflix Subscription',
    ),
  ];

  List<Transaction> get filteredTransactions {
    if (_selectedFilter == 'All') {
      return _transactions;
    } else if (_selectedFilter == 'Income') {
      return _transactions
          .where((t) => t.type == TransactionType.income)
          .toList();
    } else {
      return _transactions
          .where((t) => t.type == TransactionType.expense)
          .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Transactions',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter options
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Show search
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
              vertical: AppConstants.paddingSmall,
            ),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding:
                      const EdgeInsets.only(right: AppConstants.paddingSmall),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          // Transactions list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // TODO: Implement refresh
              },
              child: ListView.separated(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                itemCount: filteredTransactions.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final transaction = filteredTransactions[index];
                  final isExpense = transaction.type == TransactionType.expense;
                  final amount = isExpense
                      ? '-\$${transaction.amount.toStringAsFixed(2)}'
                      : '+\$${transaction.amount.toStringAsFixed(2)}';

                  return _buildTransactionItem(
                    context,
                    transaction.description,
                    amount,
                    transaction.category.toString().split('.').last,
                    transaction.date,
                    _getCategoryIcon(transaction.category),
                    isExpense ? Colors.red : Colors.green,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'transactions_fab',
        onPressed: () {
          // TODO: Add new transaction
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.transportation:
        return Icons.directions_car;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.shopping:
        return Icons.shopping_cart;
      case TransactionCategory.utilities:
        return Icons.receipt_long;
      case TransactionCategory.health:
        return Icons.health_and_safety;
      case TransactionCategory.education:
        return Icons.school;
      case TransactionCategory.travel:
        return Icons.flight;
      case TransactionCategory.housing:
        return Icons.home;
      case TransactionCategory.investment:
        return Icons.trending_up;
      case TransactionCategory.salary:
        return Icons.account_balance_wallet;
      case TransactionCategory.freelance:
        return Icons.work;
      case TransactionCategory.business:
        return Icons.business;
      case TransactionCategory.gifts:
        return Icons.card_giftcard;
      case TransactionCategory.other:
        return Icons.more_horiz;
    }
  }

  Widget _buildTransactionItem(
    BuildContext context,
    String title,
    String amount,
    String category,
    DateTime date,
    IconData icon,
    Color color,
  ) {
    return CustomCard(
      onTap: () {
        // TODO: Show transaction details
      },
      margin: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category),
            Text(
              _formatDate(date),
              style: AppConstants.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: Text(
          amount,
          style: AppConstants.titleMedium.copyWith(
            color: amount.startsWith('+') ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
