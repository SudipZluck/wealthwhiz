import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Help Center',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help Center',
              style: AppConstants.headlineMedium,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Find answers to common questions and learn how to use WealthWhiz effectively.',
              style: AppConstants.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // FAQ Categories
            _buildFaqCategory(
              context,
              'Getting Started',
              [
                _buildFaqItem(
                  'How do I create an account?',
                  'To create an account, download the WealthWhiz app from the App Store or Google Play Store, open it, and tap "Sign Up". Follow the on-screen instructions to complete your registration.',
                ),
                _buildFaqItem(
                  'Is my financial data secure?',
                  'Yes, we take security very seriously. All your data is encrypted and stored securely. We use industry-standard security measures to protect your information.',
                ),
                _buildFaqItem(
                  'Can I use WealthWhiz on multiple devices?',
                  'Yes, you can use your WealthWhiz account on multiple devices. Simply sign in with the same credentials on each device.',
                ),
              ],
            ),

            _buildFaqCategory(
              context,
              'Transactions',
              [
                _buildFaqItem(
                  'How do I add a transaction?',
                  'To add a transaction, go to the Transactions tab and tap the "+" button. Fill in the transaction details and tap "Save".',
                ),
                _buildFaqItem(
                  'Can I edit or delete transactions?',
                  'Yes, you can edit or delete transactions by tapping on the transaction in the list and selecting the appropriate option.',
                ),
                _buildFaqItem(
                  'How do I categorize transactions?',
                  'When adding or editing a transaction, you can select a category from the dropdown menu. You can also create custom categories.',
                ),
              ],
            ),

            _buildFaqCategory(
              context,
              'Budgets',
              [
                _buildFaqItem(
                  'How do I create a budget?',
                  'Go to the Budget tab and tap "Add Budget". Select a category, set your budget amount, and choose the time period.',
                ),
                _buildFaqItem(
                  'How are budget calculations made?',
                  'Budgets are calculated based on your transactions in the selected category during the specified time period.',
                ),
                _buildFaqItem(
                  'Can I set recurring budgets?',
                  'Yes, you can set budgets to recur daily, weekly, monthly, or yearly.',
                ),
              ],
            ),

            _buildFaqCategory(
              context,
              'Goals',
              [
                _buildFaqItem(
                  'How do I set a savings goal?',
                  'Go to the Goals tab and tap "Add Goal". Enter your goal details, including name, target amount, and target date.',
                ),
                _buildFaqItem(
                  'How do I track progress toward my goals?',
                  'Your goal progress is automatically updated based on the transactions you assign to that goal.',
                ),
                _buildFaqItem(
                  'Can I modify a goal after creating it?',
                  'Yes, you can edit your goals at any time by tapping on the goal and selecting "Edit".',
                ),
              ],
            ),

            _buildFaqCategory(
              context,
              'Account Settings',
              [
                _buildFaqItem(
                  'How do I change my password?',
                  'Go to Profile > Security > Change Password and follow the instructions.',
                ),
                _buildFaqItem(
                  'How do I change my currency?',
                  'Go to Profile > Account Settings > Currency and select your preferred currency.',
                ),
                _buildFaqItem(
                  'How do I delete my account?',
                  'Go to Profile > Security > Delete Account. Please note that this action is irreversible.',
                ),
              ],
            ),

            const SizedBox(height: AppConstants.paddingLarge),

            // Contact Support Button
            Center(
              child: CustomButton(
                text: 'Contact Support',
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/contact_support');
                },
                icon: Icons.support_agent,
                isFullWidth: false,
                width: 200,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCategory(
      BuildContext context, String title, List<ExpansionTile> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
          child: Text(
            title,
            style: AppConstants.titleLarge,
          ),
        ),
        ...items,
        const SizedBox(height: AppConstants.paddingMedium),
      ],
    );
  }

  ExpansionTile _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: AppConstants.titleMedium,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.paddingMedium,
            0,
            AppConstants.paddingMedium,
            AppConstants.paddingMedium,
          ),
          child: Text(
            answer,
            style: AppConstants.bodyMedium,
          ),
        ),
      ],
    );
  }
}
