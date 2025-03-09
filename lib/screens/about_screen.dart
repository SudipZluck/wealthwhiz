import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'About',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: AppConstants.paddingMedium),

            // App Logo
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 60,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // App Name and Version
            Text(
              AppConstants.appName,
              style: AppConstants.headlineLarge,
            ),
            Text(
              'Version ${AppConstants.appVersion}',
              style: AppConstants.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // App Description
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomCardHeader(
                      title: 'About WealthWhiz',
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      'WealthWhiz is a comprehensive personal finance management app designed to help you take control of your finances. Track your expenses, set budgets, save for goals, and gain insights into your spending habits.',
                      style: AppConstants.bodyMedium,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      'Our mission is to make financial management accessible and straightforward for everyone, helping you build wealth and achieve financial freedom.',
                      style: AppConstants.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Features
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomCardHeader(
                      title: 'Key Features',
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    _buildFeatureItem(
                      context,
                      Icons.receipt_long,
                      'Transaction Tracking',
                      'Record and categorize your income and expenses',
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.pie_chart,
                      'Spending Analysis',
                      'Visualize your spending patterns with intuitive charts',
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.account_balance,
                      'Budget Management',
                      'Create and monitor budgets for different categories',
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.savings,
                      'Savings Goals',
                      'Set financial goals and track your progress',
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.notifications,
                      'Smart Notifications',
                      'Get alerts for budget limits and bill payments',
                    ),
                    _buildFeatureItem(
                      context,
                      Icons.security,
                      'Secure Data',
                      'Your financial data is encrypted and protected',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Team
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomCardHeader(
                      title: 'Our Team',
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      'WealthWhiz was created by a team of passionate developers and financial experts who believe that everyone should have access to tools that make financial management simple and effective.',
                      style: AppConstants.bodyMedium,
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      'We are constantly working to improve the app and add new features based on user feedback.',
                      style: AppConstants.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),

            // Contact and Social
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CustomCardHeader(
                      title: 'Connect With Us',
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    _buildContactItem(
                      context,
                      Icons.language,
                      'Website',
                      'www.wealthwhiz.com',
                    ),
                    _buildContactItem(
                      context,
                      Icons.email,
                      'Email',
                      'info@wealthwhiz.com',
                    ),
                    _buildContactItem(
                      context,
                      Icons.facebook,
                      'Facebook',
                      'facebook.com/wealthwhiz',
                    ),
                    _buildContactItem(
                      context,
                      Icons.camera_alt,
                      'Instagram',
                      '@wealthwhiz',
                    ),
                    _buildContactItem(
                      context,
                      Icons.chat,
                      'Twitter',
                      '@wealthwhiz',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Copyright
            Text(
              '© ${DateTime.now().year} WealthWhiz. All rights reserved.',
              style: AppConstants.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppConstants.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    BuildContext context,
    IconData icon,
    String platform,
    String handle,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
      child: Row(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                platform,
                style: AppConstants.bodyMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                handle,
                style: AppConstants.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
