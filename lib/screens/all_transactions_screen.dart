import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import 'dart:io';
import 'transaction_form_screen.dart';

class AllTransactionsScreen extends StatefulWidget {
  @override
  _AllTransactionsScreenState createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String _selectedFilter = 'All'; // Default filter value
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final currentUser = FirebaseService().currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final transactions =
          await _databaseService.getTransactions(currentUser.id);
      setState(() {
        _allTransactions = transactions;
        _applyFilter(_selectedFilter);
      });
    } catch (e) {
      print('Error loading transactions: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading transactions: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _applyFilter(String filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All') {
        _filteredTransactions = List.from(_allTransactions);
      } else {
        _filteredTransactions = _allTransactions
            .where((transaction) =>
                transaction.type.toString().split('.').last.toLowerCase() ==
                filter.toLowerCase())
            .toList();
      }
    });
  }

  IconData _getCategoryIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.shopping:
        return Icons.shopping_cart;
      case TransactionCategory.transportation:
        return Icons.directions_car;
      case TransactionCategory.utilities:
        return Icons.power;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.salary:
        return Icons.account_balance_wallet;
      case TransactionCategory.investment:
        return Icons.trending_up;
      case TransactionCategory.other:
        return Icons.category;
      default:
        return Icons.attach_money;
    }
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatCategoryName(String category) {
    // Split by dots and take the last part (in case of enum values)
    final name = category.toString().split('.').last;
    // Capitalize first letter and keep rest lowercase
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  void _showTransactionDetails(Transaction transaction) {
    final isIncome = transaction.type == TransactionType.income;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Category Icon and Name
            Container(
              width: 60,
              height: 60,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isIncome
                    ? Colors.green.withOpacity(0.2)
                    : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                _getCategoryIcon(transaction.category),
                color: isIncome ? Colors.green : Colors.red,
                size: 30,
              ),
            ),
            Text(
              _formatCategoryName(transaction.category.toString()),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            // Amount
            Text(
              '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
            SizedBox(height: 24),
            // Details
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildDetailRow('Description', transaction.description),
                  _buildDetailRow('Date', _getRelativeDate(transaction.date)),
                  if (transaction.notes?.isNotEmpty ?? false)
                    _buildDetailRow('Note', transaction.notes!),
                  if (transaction.receiptPath?.isNotEmpty ?? false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Receipt',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(File(transaction.receiptPath!)),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Transactions',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Segment Control
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _buildSegmentButton('All'),
                  _buildSegmentButton('Income'),
                  _buildSegmentButton('Expense'),
                ],
              ),
            ),
          ),
          // Transaction List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadTransactions,
              child: _filteredTransactions.isEmpty
                  ? Center(
                      child: Text(
                        'No ${_selectedFilter.toLowerCase()} transactions found',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  : ListView.separated(
                      padding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      itemCount: _filteredTransactions.length,
                      separatorBuilder: (context, index) => Divider(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final transaction = _filteredTransactions[index];
                        final isIncome =
                            transaction.type == TransactionType.income;

                        return ListTile(
                          onTap: () => _showTransactionDetails(transaction),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getCategoryIcon(transaction.category),
                              color: isIncome ? Colors.green : Colors.red,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            _formatCategoryName(
                                transaction.category.toString()),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getRelativeDate(transaction.date),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isIncome ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionFormScreen(),
            ),
          ).then((_) => _loadTransactions());
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSegmentButton(String label) {
    final isSelected = _selectedFilter == label;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => _applyFilter(label),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDarkMode ? Colors.grey[800] : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label == 'All' ? label : _formatCategoryName(label),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? (label == 'Income'
                      ? Colors.green
                      : label == 'Expense'
                          ? Colors.red
                          : Theme.of(context).textTheme.bodyLarge?.color)
                  : Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.color
                      ?.withOpacity(0.7),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
