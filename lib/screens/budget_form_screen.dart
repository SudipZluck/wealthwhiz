import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../utils/utils.dart';

class BudgetFormScreen extends StatefulWidget {
  final Budget? budget;

  const BudgetFormScreen({
    super.key,
    this.budget,
  });

  @override
  State<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends State<BudgetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TransactionCategory _selectedCategory;
  late BudgetFrequency _selectedFrequency;
  late TextEditingController _amountController;
  late TextEditingController _customCategoryController;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isCustomCategory = false;
  bool _isLoading = false;

  // List of available categories (excluding ones that already have active budgets)
  List<TransactionCategory> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.budget?.category ?? TransactionCategory.food;
    _selectedFrequency = widget.budget?.frequency ?? BudgetFrequency.monthly;
    _amountController = TextEditingController(
      text: widget.budget?.amount.toString() ?? '',
    );
    _customCategoryController = TextEditingController(
      text: widget.budget?.customCategory ?? '',
    );
    _startDate = widget.budget?.startDate ?? DateTime.now();
    _endDate =
        widget.budget?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _isCustomCategory = widget.budget?.customCategory != null;
    _loadAvailableCategories();
  }

  Future<void> _loadAvailableCategories() async {
    setState(() => _isLoading = true);
    try {
      final budgetService = BudgetService();
      final activeBudgets = await budgetService.getBudgets();
      final usedCategories =
          activeBudgets.where((b) => b.isActive).map((b) => b.category).toSet();

      _availableCategories = TransactionCategory.values
          .where((c) => !usedCategories.contains(c))
          .toList();

      if (_availableCategories.isEmpty) {
        _availableCategories = [TransactionCategory.other];
      }

      setState(() {});
    } catch (e) {
      _showErrorSnackBar('Failed to load categories: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _customCategoryController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final budgetService = BudgetService();
      final firebaseService = FirebaseService();
      final currentUser = await firebaseService.getCurrentUser();

      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      final budget = Budget(
        id: widget.budget?.id,
        userId: currentUser.id,
        category: _selectedCategory,
        customCategory:
            _isCustomCategory ? _customCategoryController.text : null,
        amount: double.parse(_amountController.text),
        startDate: _startDate,
        endDate: _endDate,
        frequency: _selectedFrequency,
      );

      await budgetService.saveBudget(budget);

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully')),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to save budget: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  void _onCategoryChanged(TransactionCategory? value) {
    if (value != null) {
      setState(() {
        _selectedCategory = value;
        _isCustomCategory = value == TransactionCategory.other;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.budget == null ? 'Create Budget' : 'Edit Budget',
      ),
      body: _isLoading && _availableCategories.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                children: [
                  // Category Display or Dropdown
                  if (widget.budget != null)
                    // Show category as text when editing
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      child: Text(
                        widget.budget!.customCategory ??
                            widget.budget!.category.toString().split('.').last,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    )
                  else
                    // Show dropdown when creating new budget
                    DropdownButtonFormField<TransactionCategory>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _availableCategories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category
                                    .toString()
                                    .split('.')
                                    .last[0]
                                    .toUpperCase() +
                                category
                                    .toString()
                                    .split('.')
                                    .last
                                    .substring(1),
                          ),
                        );
                      }).toList(),
                      onChanged: _onCategoryChanged,
                      validator: (value) {
                        if (value == null) return 'Please select a category';
                        return null;
                      },
                    ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Custom Category Field (shown only when "Other" is selected)
                  if (_isCustomCategory && widget.budget == null) ...[
                    CustomTextField(
                      controller: _customCategoryController,
                      label: 'Custom Category Name',
                      prefixIcon: const Icon(Icons.edit),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a category name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                  ],

                  // Amount Field
                  CustomTextField(
                    controller: _amountController,
                    label: 'Budget Amount',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.attach_money),
                    validator: Validator.validateAmount,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Frequency Dropdown
                  DropdownButtonFormField<BudgetFrequency>(
                    value: _selectedFrequency,
                    decoration: const InputDecoration(
                      labelText: 'Frequency',
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    items: BudgetFrequency.values.map((frequency) {
                      return DropdownMenuItem(
                        value: frequency,
                        child: Text(frequency
                                .toString()
                                .split('.')
                                .last[0]
                                .toUpperCase() +
                            frequency.toString().split('.').last.substring(1)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedFrequency = value;
                        // Update end date based on frequency
                        switch (value) {
                          case BudgetFrequency.daily:
                            _endDate = _startDate;
                            break;
                          case BudgetFrequency.weekly:
                            _endDate = _startDate.add(const Duration(days: 7));
                            break;
                          case BudgetFrequency.monthly:
                            _endDate = DateTime(_startDate.year,
                                _startDate.month + 1, _startDate.day);
                            break;
                          case BudgetFrequency.yearly:
                            _endDate = DateTime(_startDate.year + 1,
                                _startDate.month, _startDate.day);
                            break;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Date Range
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Start Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: DateFormatter.format(
                              _startDate,
                              format: AppConstants.dateFormatShort,
                            ),
                          ),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _startDate,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                _startDate = date;
                                // Update end date based on frequency
                                switch (_selectedFrequency) {
                                  case BudgetFrequency.daily:
                                    _endDate = date;
                                    break;
                                  case BudgetFrequency.weekly:
                                    _endDate =
                                        date.add(const Duration(days: 7));
                                    break;
                                  case BudgetFrequency.monthly:
                                    _endDate = DateTime(
                                        date.year, date.month + 1, date.day);
                                    break;
                                  case BudgetFrequency.yearly:
                                    _endDate = DateTime(
                                        date.year + 1, date.month, date.day);
                                    break;
                                }
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'End Date',
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          controller: TextEditingController(
                            text: DateFormatter.format(
                              _endDate,
                              format: AppConstants.dateFormatShort,
                            ),
                          ),
                          enabled: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Save Button
                  CustomButton(
                    text: widget.budget == null
                        ? 'Create Budget'
                        : 'Update Budget',
                    onPressed: _isLoading ? null : _saveBudget,
                    isLoading: _isLoading,
                  ),
                ],
              ),
            ),
    );
  }
}
