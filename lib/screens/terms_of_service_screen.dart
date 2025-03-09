import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Terms of Service',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              'Acceptance of Terms',
              'By accessing or using WealthWhiz, you agree to be bound by these Terms of Service and all applicable laws and regulations. If you do not agree with any of these terms, you are prohibited from using or accessing this app.',
            ),
            _buildSection(
              'Use License',
              'Permission is granted to temporarily use the WealthWhiz application for personal, non-commercial purposes only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                  '• Modify or copy the materials\n'
                  '• Use the materials for any commercial purpose\n'
                  '• Attempt to decompile or reverse engineer any software contained in WealthWhiz\n'
                  '• Remove any copyright or other proprietary notations from the materials\n'
                  '• Transfer the materials to another person or "mirror" the materials on any other server',
            ),
            _buildSection(
              'Disclaimer',
              'The materials on WealthWhiz are provided on an \'as is\' basis. WealthWhiz makes no warranties, expressed or implied, and hereby disclaims and negates all other warranties including, without limitation, implied warranties or conditions of merchantability, fitness for a particular purpose, or non-infringement of intellectual property or other violation of rights.',
            ),
            _buildSection(
              'Limitations',
              'In no event shall WealthWhiz or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use WealthWhiz, even if WealthWhiz or a WealthWhiz authorized representative has been notified orally or in writing of the possibility of such damage.',
            ),
            _buildSection(
              'Accuracy of Materials',
              'The materials appearing on WealthWhiz could include technical, typographical, or photographic errors. WealthWhiz does not warrant that any of the materials on its app are accurate, complete or current. WealthWhiz may make changes to the materials contained on its app at any time without notice.',
            ),
            _buildSection(
              'Links',
              'WealthWhiz has not reviewed all of the sites linked to its app and is not responsible for the contents of any such linked site. The inclusion of any link does not imply endorsement by WealthWhiz of the site. Use of any such linked website is at the user\'s own risk.',
            ),
            _buildSection(
              'Modifications',
              'WealthWhiz may revise these terms of service for its app at any time without notice. By using this app you are agreeing to be bound by the then current version of these terms of service.',
            ),
            _buildSection(
              'Governing Law',
              'These terms and conditions are governed by and construed in accordance with the laws and you irrevocably submit to the exclusive jurisdiction of the courts in that location.',
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
