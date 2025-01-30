import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import '../widgets/widgets.dart';
import 'transaction_form_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
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
      final currentUser = FirebaseService().currentUser;
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final databaseService = DatabaseService();
      final transactions =
          await databaseService.getTransactions(currentUser.id);
      print(
          'Loaded ${transactions.length} transactions for user ${currentUser.id}'); // Debug log

      if (mounted) {
        setState(() {
          _transactions = transactions
            ..sort((a, b) => b.date.compareTo(a.date));
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading transactions: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load transactions: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Transactions',
      ),
      body: RefreshIndicator(
        onRefresh: _loadTransactions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _transactions.isEmpty
                ? const Center(child: Text('No transactions found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      return Card(
                        margin: const EdgeInsets.only(
                            bottom: AppConstants.paddingSmall),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            child: Icon(
                              _getTransactionIcon(transaction.category),
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(transaction.description),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormatter.format(transaction.date),
                                style: AppConstants.bodySmall,
                              ),
                              Text(
                                transaction.category.toString().split('.').last,
                                style: AppConstants.bodySmall.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            transaction.type == TransactionType.income
                                ? '+${CurrencyFormatter.format(transaction.amount, Currency.usd)}'
                                : CurrencyFormatter.format(
                                    transaction.amount, Currency.usd),
                            style: AppConstants.titleMedium.copyWith(
                              color: transaction.type == TransactionType.income
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TransactionFormScreen(),
            ),
          );
          if (result == true) {
            _loadTransactions(); // Reload transactions after adding a new one
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
    );
  }

  IconData _getTransactionIcon(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.food:
        return Icons.restaurant;
      case TransactionCategory.shopping:
        return Icons.shopping_cart;
      case TransactionCategory.entertainment:
        return Icons.movie;
      case TransactionCategory.utilities:
        return Icons.power;
      case TransactionCategory.transportation:
        return Icons.directions_car;
      case TransactionCategory.health:
        return Icons.medical_services;
      case TransactionCategory.education:
        return Icons.school;
      case TransactionCategory.salary:
        return Icons.work;
      case TransactionCategory.travel:
        return Icons.flight;
      case TransactionCategory.housing:
        return Icons.home;
      case TransactionCategory.investment:
        return Icons.trending_up;
      case TransactionCategory.freelance:
        return Icons.computer;
      case TransactionCategory.business:
        return Icons.business;
      case TransactionCategory.gifts:
        return Icons.card_giftcard;
      default:
        return Icons.attach_money;
    }
  }
}
