import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';
import '../models/goal.dart';
import '../models/user.dart';
import '../services/services.dart';
import '../utils/currency_formatter.dart';
import 'package:uuid/uuid.dart';

class AddGoalScreen extends StatefulWidget {
  const AddGoalScreen({super.key});

  @override
  State<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends State<AddGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 365));
  IconData _selectedIcon = Icons.star;
  bool _isLoading = false;
  User? _currentUser;

  final List<IconData> _availableIcons = [
    Icons.home,
    Icons.directions_car,
    Icons.flight,
    Icons.school,
    Icons.beach_access,
    Icons.phone_iphone,
    Icons.laptop,
    Icons.health_and_safety,
    Icons.star,
    Icons.favorite,
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final firebaseService = FirebaseService();
      final currentUser = await firebaseService.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          _currentUser = currentUser;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final goalService = GoalService();
        final firebaseService = FirebaseService();
        final currentUser = await firebaseService.getCurrentUser();

        if (currentUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User not found')),
            );
          }
          return;
        }

        final goal = Goal(
          id: const Uuid().v4(),
          userId: currentUser.id,
          name: _nameController.text,
          targetAmount: double.parse(_amountController.text),
          startDate: DateTime.now(),
          targetDate: _targetDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await goalService.addGoal(goal);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving goal: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = _currentUser?.preferredCurrency ?? Currency.usd;

    // Get currency symbol using a switch statement instead of the private method
    String getCurrencySymbol() {
      switch (currency) {
        case Currency.usd:
          return '\$';
        case Currency.eur:
          return '€';
        case Currency.gbp:
          return '£';
        case Currency.inr:
          return '₹';
        case Currency.jpy:
          return '¥';
        case Currency.aud:
          return 'A\$';
        case Currency.cad:
          return 'C\$';
      }
    }

    final currencySymbol = getCurrencySymbol();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Add New Goal',
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          children: [
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomCardHeader(
                    title: 'Goal Details',
                    subtitle: 'Enter your savings goal information',
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Goal Name',
                      hintText: 'e.g., New Car, Vacation, Emergency Fund',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a goal name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  TextFormField(
                    controller: _amountController,
                    decoration: InputDecoration(
                      labelText: 'Target Amount',
                      prefixText: currencySymbol,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a target amount';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter a valid number';
                      }
                      if (double.parse(value) <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomCardHeader(
                    title: 'Target Date',
                  ),
                  ListTile(
                    title: Text(
                      'Goal Target Date',
                      style: AppConstants.bodyMedium,
                    ),
                    subtitle: Text(
                      '${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
                      style: AppConstants.titleMedium,
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _targetDate,
                        firstDate: DateTime.now(),
                        lastDate:
                            DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        setState(() => _targetDate = date);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomCardHeader(
                    title: 'Goal Icon',
                    subtitle: 'Choose an icon for your goal',
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Wrap(
                    spacing: AppConstants.paddingSmall,
                    runSpacing: AppConstants.paddingSmall,
                    children: _availableIcons.map((icon) {
                      final isSelected = icon == _selectedIcon;
                      return InkWell(
                        onTap: () => setState(() => _selectedIcon = icon),
                        child: Container(
                          padding:
                              const EdgeInsets.all(AppConstants.paddingSmall),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
