import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../utils/pdf_export_util.dart';
import '../widgets/widgets.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  User? _currentUser;
  List<Transaction> _transactions = [];
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    _loadUserAndTransactions();
  }

  Future<void> _loadUserAndTransactions() async {
    setState(() => _isLoading = true);
    try {
      // Load user data
      final firebaseService = FirebaseService();
      final currentUser = await firebaseService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      setState(() {
        _currentUser = currentUser;
      });

      // Load transactions
      await _loadTransactions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadTransactions() async {
    try {
      if (_currentUser == null) return;

      final databaseService = DatabaseService();
      final transactions =
          await databaseService.getTransactions(_currentUser!.id);

      if (mounted) {
        setState(() {
          _transactions = transactions;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading transactions: $e')),
        );
      }
    }
  }

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _exportData() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not available')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Filter transactions by date range
      final filteredTransactions = _transactions.where((transaction) {
        return transaction.date
                .isAfter(_startDate.subtract(const Duration(days: 1))) &&
            transaction.date.isBefore(_endDate.add(const Duration(days: 1)));
      }).toList();

      // Generate and open PDF
      await PdfExportUtil.exportTransactionsToPdf(
        filteredTransactions,
        _currentUser!,
        _startDate,
        _endDate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Financial report generated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
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
      appBar: const CustomAppBar(
        title: 'Export Data',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Export Financial Data',
                    style: AppConstants.headlineMedium,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'Generate a PDF report of your income and expenses for a selected time period.',
                    style: AppConstants.bodyMedium.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Date Range Selection
                  CustomCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomCardHeader(
                            title: 'Select Date Range',
                            subtitle:
                                'Choose the period for your financial report',
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),

                          // Start Date
                          ListTile(
                            title: const Text('Start Date'),
                            subtitle: Text(_dateFormat.format(_startDate)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _selectStartDate,
                          ),

                          // End Date
                          ListTile(
                            title: const Text('End Date'),
                            subtitle: Text(_dateFormat.format(_endDate)),
                            trailing: const Icon(Icons.calendar_today),
                            onTap: _selectEndDate,
                          ),

                          const SizedBox(height: AppConstants.paddingMedium),

                          // Transaction Count
                          Center(
                            child: Text(
                              'Transactions in selected period: ${_getTransactionCount()}',
                              style: AppConstants.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Report Options
                  CustomCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomCardHeader(
                            title: 'Report Contents',
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          _buildReportFeature(
                            'Financial Summary',
                            'Total income, expenses, and balance',
                            Icons.summarize,
                          ),
                          _buildReportFeature(
                            'Category Breakdown',
                            'Expenses grouped by category',
                            Icons.pie_chart,
                          ),
                          _buildReportFeature(
                            'Transaction List',
                            'Detailed list of all transactions',
                            Icons.receipt_long,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Export Button
                  Center(
                    child: CustomButton(
                      text: 'Generate PDF Report',
                      onPressed: _exportData,
                      icon: Icons.picture_as_pdf,
                      isLoading: _isLoading,
                      isFullWidth: true,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Note
                  Center(
                    child: Text(
                      'The report will open automatically when generated',
                      style: AppConstants.bodySmall.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  int _getTransactionCount() {
    return _transactions.where((transaction) {
      return transaction.date
              .isAfter(_startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).length;
  }

  Widget _buildReportFeature(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppConstants.titleMedium,
                ),
                Text(
                  description,
                  style: AppConstants.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green),
        ],
      ),
    );
  }
}
