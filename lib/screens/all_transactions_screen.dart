import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Transactions'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterChip('All'),
                _buildFilterChip('Income'),
                _buildFilterChip('Expense'),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: _filteredTransactions.isEmpty
            ? Center(
                child: Text(
                  'No ${_selectedFilter.toLowerCase()} transactions found',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : ListView.builder(
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _filteredTransactions[index];
                  final isIncome = transaction.type == TransactionType.income;

                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isIncome ? Colors.green : Colors.red,
                        child: Icon(
                          _getCategoryIcon(transaction.category),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(transaction.description),
                      subtitle: Text(
                        '${transaction.category.toString().split('.').last} • ${transaction.date.toString().split(' ')[0]}',
                      ),
                      trailing: Text(
                        '${isIncome ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isIncome ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : Theme.of(context).textTheme.bodyLarge?.color,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          _applyFilter(label);
        }
      },
      selectedColor: label == 'Income'
          ? Colors.green
          : label == 'Expense'
              ? Colors.red
              : Theme.of(context).primaryColor,
      backgroundColor: Theme.of(context).cardColor,
      checkmarkColor: Colors.white,
      elevation: 2,
    );
  }
}
