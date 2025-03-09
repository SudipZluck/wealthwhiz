import 'package:flutter/material.dart';
import '../constants/constants.dart';
import '../widgets/widgets.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate API call
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isLoading = false);

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Your message has been sent. We\'ll get back to you soon!'),
              duration: Duration(seconds: 3),
            ),
          );

          // Clear form
          _nameController.clear();
          _emailController.clear();
          _subjectController.clear();
          _messageController.clear();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Contact Support',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Support',
              style: AppConstants.headlineMedium,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              'Need help? We\'re here for you. Fill out the form below and our support team will get back to you as soon as possible.',
              style: AppConstants.bodyMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Contact Methods
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomCardHeader(
                    title: 'Contact Methods',
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.email_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Email'),
                    subtitle: const Text('support@wealthwhiz.com'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.phone_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Phone'),
                    subtitle: const Text('+1 (555) 123-4567'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.access_time,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: const Text('Support Hours'),
                    subtitle:
                        const Text('Monday - Friday, 9:00 AM - 5:00 PM EST'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // Contact Form
            CustomCard(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CustomCardHeader(
                        title: 'Send us a message',
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          prefixIcon: Icon(Icons.subject),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a subject';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingMedium),
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          prefixIcon: Icon(Icons.message_outlined),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your message';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                      Center(
                        child: CustomButton(
                          text: 'Send Message',
                          onPressed: _isLoading ? null : _submitForm,
                          isLoading: _isLoading,
                          icon: Icons.send,
                          isFullWidth: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),

            // FAQ Link
            Center(
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/help_center');
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('Visit our Help Center'),
              ),
            ),
            const SizedBox(height: AppConstants.paddingMedium),
          ],
        ),
      ),
    );
  }
}
