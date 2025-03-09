import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Privacy Policy',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: AppConstants.headlineMedium,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Last Updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              style: AppConstants.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            _buildSection(
              'Introduction',
              'Welcome to WealthWhiz. We respect your privacy and are committed to protecting your personal data. This privacy policy will inform you about how we look after your personal data when you use our application and tell you about your privacy rights and how the law protects you.',
            ),
            _buildSection(
              'Data We Collect',
              'We may collect, use, store and transfer different kinds of personal data about you which we have grouped together as follows:\n\n'
                  '• Personal Data: Name, email address, and profile picture\n'
                  '• Financial Data: Transaction details, budgets, and financial goals\n'
                  '• Technical Data: Device information, IP address, and app usage statistics\n'
                  '• User Preferences: App settings and preferences',
            ),
            _buildSection(
              'How We Use Your Data',
              'We use your data to provide and improve our services, including:\n\n'
                  '• Delivering the core functionality of the app\n'
                  '• Personalizing your experience\n'
                  '• Improving our services\n'
                  '• Communicating with you about updates and features',
            ),
            _buildSection(
              'Data Security',
              'We have implemented appropriate security measures to prevent your personal data from being accidentally lost, used, or accessed in an unauthorized way. We limit access to your personal data to those employees and third parties who have a business need to know.',
            ),
            _buildSection(
              'Your Rights',
              'Under certain circumstances, you have rights under data protection laws in relation to your personal data, including the right to:\n\n'
                  '• Request access to your personal data\n'
                  '• Request correction of your personal data\n'
                  '• Request erasure of your personal data\n'
                  '• Object to processing of your personal data\n'
                  '• Request restriction of processing your personal data\n'
                  '• Request transfer of your personal data\n'
                  '• Right to withdraw consent',
            ),
            _buildSection(
              'Contact Us',
              'If you have any questions about this privacy policy or our privacy practices, please contact us at:\n\n'
                  'Email: privacy@wealthwhiz.com\n'
                  'Address: 123 Finance Street, Money City, MC 12345',
            ),
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppConstants.titleLarge,
          ),
          const SizedBox(height: AppConstants.paddingSmall),
          Text(
            content,
            style: AppConstants.bodyMedium,
          ),
        ],
      ),
    );
  }
}
