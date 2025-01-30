import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../utils/utils.dart';
import '../services/database_service.dart';
import '../services/firebase_service.dart';

class TransactionFormScreen extends StatefulWidget {
  final Transaction? transaction;

  const TransactionFormScreen({super.key, this.transaction});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _sourceController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _databaseService = DatabaseService();
  bool _isLoading = false;

  TransactionType _type = TransactionType.expense;
  TransactionCategory _category = TransactionCategory.food;
  DateTime _date = DateTime.now();
  File? _receiptImage;
  bool _isRecurring = false;

  Budget? _selectedBudget;
  List<Budget> _availableBudgets = [];

  @override
  void initState() {
    super.initState();
    _loadBudgets();
    if (widget.transaction != null) {
      _type = widget.transaction!.type;
      _category = widget.transaction!.category;
      _date = widget.transaction!.date;
      _amountController.text = widget.transaction!.amount.toString();
      _notesController.text = widget.transaction!.notes ?? '';
      if (_category == TransactionCategory.other) {
        _sourceController.text = widget.transaction!.description;
      }
      if (widget.transaction!.receiptPath != null) {
        _receiptImage = File(widget.transaction!.receiptPath!);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() {
          _receiptImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to capture image')),
      );
    }
  }

  Future<String?> _saveReceiptImage() async {
    print('_saveReceiptImage: Starting to save receipt image');
    if (_receiptImage == null) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = 'receipt_${const Uuid().v4()}.jpg';
      final String filePath = '${directory.path}/$fileName';
      await _receiptImage!.copy(filePath);
      print('_saveReceiptImage: Successfully saved image to $filePath');
      return filePath;
    } catch (e) {
      print('_saveReceiptImage: Error saving image - $e');
      return null;
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final budgetService = BudgetService();
      final budgets = await budgetService.getBudgets();
      setState(() {
        _availableBudgets = budgets;
      });
    } catch (e) {
      print('Failed to load budgets: $e');
    }
  }

  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        final transaction = Transaction(
          id: '', // Will be set by Firestore
          userId: '', // Will be set by DatabaseService
          amount: double.parse(_amountController.text),
          date: _date,
          type: _type,
          category: _category,
          description: _sourceController.text,
          notes: _notesController.text,
          receiptPath: await _saveReceiptImage(),
          isRecurring: _isRecurring,
          recurringId: '', // Assuming no recurring ID for now
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final (savedTransaction, isFullySynced) =
            await _databaseService.insertTransaction(transaction);

        if (!mounted) return;

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFullySynced
                  ? 'Transaction saved successfully!'
                  : 'Transaction saved locally. Will sync when online.',
            ),
            backgroundColor: isFullySynced ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        Navigator.pop(context, savedTransaction);
      } catch (e) {
        print('Error saving transaction: $e');
        if (!mounted) return;

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null
            ? 'Add Transaction'
            : 'Edit Transaction'),
        actions: [
          if (widget.transaction != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _isLoading ? null : _deleteTransaction,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                children: [
                  // Transaction Type
                  SegmentedButton<TransactionType>(
                    segments: const [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text('Expense'),
                        icon: Icon(Icons.remove_circle_outline),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text('Income'),
                        icon: Icon(Icons.add_circle_outline),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: _onTypeChanged,
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Amount
                  if (_type == TransactionType.expense &&
                      _availableBudgets.isNotEmpty) ...[
                    const SizedBox(height: AppConstants.paddingMedium),
                    DropdownButtonFormField<Budget>(
                      value: _selectedBudget,
                      decoration: const InputDecoration(
                        labelText: 'Apply to Budget',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      items: [
                        const DropdownMenuItem<Budget>(
                          value: null,
                          child: Text('No Budget'),
                        ),
                        ..._availableBudgets
                            .where((b) => b.category == _category)
                            .map((budget) {
                          final amount = CurrencyFormatter.format(
                              budget.amount, Currency.usd);
                          return DropdownMenuItem<Budget>(
                            value: budget,
                            child: Text(
                                '${budget.customCategory ?? budget.category.name} ($amount)'),
                          );
                        }).toList(),
                      ],
                      onChanged: (Budget? value) {
                        setState(() {
                          _selectedBudget = value;
                        });
                      },
                    ),
                  ],
                  TextFormField(
                    controller: _amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '\$',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Category
                  DropdownButtonFormField<TransactionCategory>(
                    value: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: _type == TransactionType.expense
                        ? [
                            TransactionCategory.food,
                            TransactionCategory.shopping,
                            TransactionCategory.entertainment,
                            TransactionCategory.utilities,
                            TransactionCategory.transportation,
                            TransactionCategory.health,
                            TransactionCategory.education,
                            TransactionCategory.travel,
                            TransactionCategory.housing,
                            TransactionCategory.gifts,
                          ].map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category.toString().split('.').last),
                            );
                          }).toList()
                        : [
                            TransactionCategory.salary,
                            TransactionCategory.business,
                            TransactionCategory.investment,
                            TransactionCategory.freelance,
                          ].map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category.toString().split('.').last),
                            );
                          }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _category = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Custom Source Field (for 'other' category)
                  if (_category == TransactionCategory.other) ...[
                    TextFormField(
                      controller: _sourceController,
                      decoration: const InputDecoration(
                        labelText: 'Source',
                        hintText: 'Enter source of income/expense',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the source';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                  ],

                  // Date
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Date'),
                    subtitle: Text(
                      '${_date.day}/${_date.month}/${_date.year}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      alignLabelWithHint: true,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Receipt Image
                  Card(
                    child: InkWell(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: _receiptImage != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    _receiptImage!,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() => _receiptImage = null);
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.camera_alt, size: 48),
                                  SizedBox(height: 8),
                                  Text('Add Receipt'),
                                ],
                              ),
                      ),
                    ),
                  ),

                  // Is Recurring
                  SwitchListTile(
                    title: const Text('Recurring Transaction'),
                    value: _isRecurring,
                    onChanged: (bool value) {
                      setState(() => _isRecurring = value);
                    },
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: FilledButton(
            onPressed: _isLoading ? null : _saveTransaction,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save'),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction() async {
    print('_deleteTransaction: Starting to delete transaction');
    if (widget.transaction == null) {
      print('_deleteTransaction: No transaction to delete');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await TransactionService.instance
          .deleteTransaction(widget.transaction!.id);
      print('_deleteTransaction: Deleted from local storage');

      await TransactionService.instance.syncTransactions();
      print('_deleteTransaction: Synced with Firestore');

      if (mounted) {
        print('_deleteTransaction: Successfully completed, closing screen');
        Navigator.pop(context);
      }
    } catch (e) {
      print('_deleteTransaction: Error occurred - $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete transaction: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onTypeChanged(Set<TransactionType> selected) {
    setState(() {
      _type = selected.first;
      // Set default category based on type
      _category = _type == TransactionType.expense
          ? TransactionCategory.food
          : TransactionCategory.salary;
    });
  }
}
