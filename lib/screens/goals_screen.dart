import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';
import '../models/goal.dart';
import '../models/user.dart';
import '../services/services.dart';
import '../utils/currency_formatter.dart';
import 'add_goal_screen.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final GoalService _goalService = GoalService();
  List<Goal> _goals = [];
  bool _isLoading = true;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserAndGoals();
  }

  Future<void> _loadUserAndGoals() async {
    setState(() => _isLoading = true);
    try {
      // Load user data
      final firebaseService = FirebaseService();
      final currentUser = await firebaseService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _currentUser = currentUser;
        });
      }

      await _loadGoals();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await _goalService.getGoals();
      if (mounted) {
        setState(() {
          _goals = goals;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading goals: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = _currentUser?.preferredCurrency ?? Currency.usd;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Savings Goals',
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Show filter options
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserAndGoals,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                children: [
                  // Total Savings Overview
                  CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CustomCardHeader(
                          title: 'Total Savings',
                          subtitle: 'Across all goals',
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        Row(
                          children: [
                            Expanded(
                              child: _buildSavingsStat(
                                context,
                                'Current',
                                CurrencyFormatter.format(
                                    _calculateTotalCurrentAmount(), currency),
                                Icons.savings,
                                theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: AppConstants.paddingMedium),
                            Expanded(
                              child: _buildSavingsStat(
                                context,
                                'Target',
                                CurrencyFormatter.format(
                                    _calculateTotalTargetAmount(), currency),
                                Icons.flag,
                                Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Active Goals
                  if (_activeGoals.isNotEmpty)
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomCardHeader(
                            title: 'Active Goals',
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          ..._activeGoals.map((goal) => _buildGoalItem(
                                context,
                                goal.name,
                                goal.targetAmount,
                                goal.currentAmount,
                                goal.targetDate,
                                _getIconForGoal(goal.name),
                                _getColorForGoal(goal.name),
                                currency,
                              )),
                        ],
                      ),
                    ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Completed Goals
                  if (_completedGoals.isNotEmpty)
                    CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CustomCardHeader(
                            title: 'Completed Goals',
                          ),
                          const SizedBox(height: AppConstants.paddingMedium),
                          ..._completedGoals
                              .map((goal) => _buildCompletedGoalItem(
                                    context,
                                    goal.name,
                                    goal.targetAmount,
                                    _getIconForGoal(goal.name),
                                    _getColorForGoal(goal.name),
                                    goal.updatedAt ?? goal.createdAt,
                                    currency,
                                  )),
                        ],
                      ),
                    ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddGoalScreen()),
          );
          _loadGoals();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
  }

  List<Goal> get _activeGoals =>
      _goals.where((goal) => !goal.isCompleted).toList();
  List<Goal> get _completedGoals =>
      _goals.where((goal) => goal.isCompleted).toList();

  double _calculateTotalCurrentAmount() {
    return _goals.fold(0.0, (sum, goal) => sum + goal.currentAmount);
  }

  double _calculateTotalTargetAmount() {
    return _goals.fold(0.0, (sum, goal) => sum + goal.targetAmount);
  }

  IconData _getIconForGoal(String goalName) {
    final name = goalName.toLowerCase();
    if (name.contains('car')) return Icons.directions_car;
    if (name.contains('house') || name.contains('home')) return Icons.home;
    if (name.contains('vacation') || name.contains('travel'))
      return Icons.beach_access;
    if (name.contains('education') || name.contains('school'))
      return Icons.school;
    if (name.contains('emergency')) return Icons.health_and_safety;
    if (name.contains('phone')) return Icons.phone_iphone;
    if (name.contains('laptop') || name.contains('computer'))
      return Icons.laptop;
    return Icons.star;
  }

  Color _getColorForGoal(String goalName) {
    final name = goalName.toLowerCase();
    if (name.contains('car')) return Colors.blue;
    if (name.contains('house') || name.contains('home')) return Colors.brown;
    if (name.contains('vacation') || name.contains('travel'))
      return Colors.purple;
    if (name.contains('education') || name.contains('school'))
      return Colors.orange;
    if (name.contains('emergency')) return Colors.red;
    if (name.contains('phone')) return Colors.green;
    if (name.contains('laptop') || name.contains('computer'))
      return Colors.indigo;
    return Colors.teal;
  }

  Widget _buildSavingsStat(
    BuildContext context,
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: AppConstants.bodyMedium.copyWith(
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: AppConstants.titleMedium.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGoalItem(
    BuildContext context,
    String title,
    double target,
    double current,
    DateTime targetDate,
    IconData icon,
    Color color,
    Currency currency,
  ) {
    final progress = current / target;
    final theme = Theme.of(context);
    final daysLeft = targetDate.difference(DateTime.now()).inDays;

    return CustomCard(
      onTap: () {
        // TODO: Show goal details
      },
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(title),
            subtitle: Text(
              '${CurrencyFormatter.format(current, currency)} of ${CurrencyFormatter.format(target, currency)}',
              style: AppConstants.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: AppConstants.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$daysLeft days left',
                  style: AppConstants.bodySmall.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedGoalItem(
    BuildContext context,
    String title,
    double amount,
    IconData icon,
    Color color,
    DateTime completedDate,
    Currency currency,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(
        'Completed on ${_formatDate(completedDate)}',
        style: AppConstants.bodySmall.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Text(
        CurrencyFormatter.format(amount, currency),
        style: AppConstants.titleMedium.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
