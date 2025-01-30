import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends StatefulWidget {
  @override
  _TransactionListScreenState createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  final DatabaseService _databaseService = DatabaseService();
  String? _selectedFilter = 'All'; // Default filter value
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading transactions: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _applyFilter(String? filter) {
    setState(() {
      _selectedFilter = filter;
      if (filter == 'All' || filter == null) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedFilter,
                      dropdownColor: Theme.of(context).cardColor,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        fontSize: 16,
                      ),
                      items: ['All', 'Income', 'Expense']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (value != 'All')
                                Icon(
                                  value == 'Income'
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward,
                                  color: value == 'Income'
                                      ? Colors.green
                                      : Colors.red,
                                  size: 16,
                                ),
                              if (value != 'All') SizedBox(width: 8),
                              Text(
                                value,
                                style: TextStyle(
                                  color: value == 'Income'
                                      ? Colors.green
                                      : value == 'Expense'
                                          ? Colors.red
                                          : Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _applyFilter,
                      underline: Container(),
                      icon: Icon(Icons.arrow_drop_down,
                          color: Theme.of(context).iconTheme.color),
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: _filteredTransactions.isEmpty
            ? Center(
                child: Text(
                  'No ${_selectedFilter?.toLowerCase() ?? ''} transactions found',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              )
            : ListView.builder(
                itemCount: _filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = _filteredTransactions[index];
                  return Card(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            transaction.type.toString().contains('income')
                                ? Colors.green
                                : Colors.red,
                        child: Icon(
                          transaction.type.toString().contains('income')
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(transaction.description),
                      subtitle: Text(
                        '${transaction.category.toString().split('.').last} • ${transaction.date.toString().split(' ')[0]}',
                      ),
                      trailing: Text(
                        '${transaction.type.toString().contains('income') ? '+' : '-'}\$${transaction.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: transaction.type.toString().contains('income')
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TransactionFormScreen()),
          );
          if (result != null) {
            _loadTransactions();
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
