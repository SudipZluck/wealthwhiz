import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Budget',
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // TODO: Show month selector
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
            // Total Budget Overview
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomCardHeader(
                    title: 'Monthly Overview',
                    subtitle: 'March 2024',
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBudgetStat(
                          context,
                          'Total Budget',
                          '\$5,000.00',
                          Icons.account_balance_wallet,
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildBudgetStat(
                          context,
                          'Spent',
                          '\$3,250.75',
                          Icons.shopping_cart,
                          Colors.red,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Expanded(
                        child: _buildBudgetStat(
                          context,
                          'Remaining',
                          '\$1,749.25',
                          Icons.savings,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.65, // 3250.75 / 5000.00
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Budget Categories
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomCardHeader(
                    title: 'Budget Categories',
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          // TODO: Add new budget category
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  _buildBudgetCategory(
                    context,
                    'Shopping',
                    850.0,
                    1000.0,
                    Colors.purple,
                    Icons.shopping_bag,
                  ),
                  _buildBudgetCategory(
                    context,
                    'Food & Dining',
                    450.0,
                    600.0,
                    Colors.orange,
                    Icons.restaurant,
                  ),
                  _buildBudgetCategory(
                    context,
                    'Transportation',
                    200.0,
                    300.0,
                    Colors.blue,
                    Icons.directions_car,
                  ),
                  _buildBudgetCategory(
                    context,
                    'Entertainment',
                    180.0,
                    250.0,
                    Colors.pink,
                    Icons.movie,
                  ),
                  _buildBudgetCategory(
                    context,
                    'Bills & Utilities',
                    1200.0,
                    1500.0,
                    Colors.green,
                    Icons.receipt_long,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'budget_fab',
        onPressed: () {
          // TODO: Add new budget
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Budget'),
      ),
    );
  }

  Widget _buildBudgetStat(
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
          style: AppConstants.bodySmall.copyWith(
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

  Widget _buildBudgetCategory(
    BuildContext context,
    String category,
    double spent,
    double total,
    Color color,
    IconData icon,
  ) {
    final progress = spent / total;
    final theme = Theme.of(context);

    return CustomCard(
      onTap: () {
        // TODO: Show category details
      },
      margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color, size: 20),
            ),
            title: Text(category),
            subtitle: Text(
              '\$${spent.toStringAsFixed(2)} of \$${total.toStringAsFixed(2)}',
              style: AppConstants.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            trailing: Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: AppConstants.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
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
}
