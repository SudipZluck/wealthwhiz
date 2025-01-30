import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
        onRefresh: () async {
          // TODO: Implement refresh
        },
        child: ListView(
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
                          '\$15,750.00',
                          Icons.savings,
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildSavingsStat(
                          context,
                          'Target',
                          '\$50,000.00',
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
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomCardHeader(
                    title: 'Active Goals',
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildGoalItem(
                    context,
                    'New Car',
                    25000.0,
                    15000.0,
                    DateTime(2024, 12, 31),
                    Icons.directions_car,
                    Colors.blue,
                  ),
                  _buildGoalItem(
                    context,
                    'Emergency Fund',
                    10000.0,
                    7500.0,
                    DateTime(2024, 6, 30),
                    Icons.health_and_safety,
                    Colors.orange,
                  ),
                  _buildGoalItem(
                    context,
                    'Vacation',
                    5000.0,
                    2500.0,
                    DateTime(2024, 8, 15),
                    Icons.beach_access,
                    Colors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Completed Goals
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomCardHeader(
                    title: 'Completed Goals',
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildCompletedGoalItem(
                    context,
                    'New Phone',
                    1200.0,
                    Icons.phone_iphone,
                    Colors.green,
                    DateTime(2024, 1, 15),
                  ),
                  _buildCompletedGoalItem(
                    context,
                    'Home Deposit',
                    20000.0,
                    Icons.home,
                    Colors.brown,
                    DateTime(2023, 12, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'goals_fab',
        onPressed: () {
          // TODO: Add new goal
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Goal'),
      ),
    );
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
              '\$${current.toStringAsFixed(2)} of \$${target.toStringAsFixed(2)}',
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
        '\$${amount.toStringAsFixed(2)}',
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
