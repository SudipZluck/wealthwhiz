import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/constants.dart';
import '../models/user.dart';
import '../widgets/widgets.dart';
import '../services/firebase_service.dart';
import '../widgets/theme_picker_dialog.dart';
import '../widgets/currency_picker_dialog.dart';
import '../providers/theme_provider.dart';
import '../utils/currency_formatter.dart';
import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'help_center_screen.dart';
import 'contact_support_screen.dart';
import 'about_screen.dart';
import 'export_data_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  late User _user;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final firebaseService = FirebaseService();
      final currentUser = await firebaseService.getCurrentUser();
      if (currentUser != null && mounted) {
        setState(() {
          _user = currentUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Profile',
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          // Profile Header
          CustomCard(
            child: Column(
              children: [
                const SizedBox(height: AppConstants.paddingMedium),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: _user.photoUrl != null
                      ? NetworkImage(_user.photoUrl!)
                      : null,
                  backgroundColor: _user.photoUrl == null
                      ? theme.colorScheme.primary.withOpacity(0.1)
                      : null,
                  child: _user.photoUrl == null
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Text(
                  _user.displayName ?? 'No Name',
                  style: AppConstants.headlineMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  _user.email,
                  style: AppConstants.bodyLarge.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                  ),
                  child: CustomButton(
                    text: 'Edit Profile',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(user: _user),
                        ),
                      );

                      if (result == true) {
                        _loadUserData(); // Refresh profile data
                      }
                    },
                    type: CustomButtonType.outline,
                    icon: Icons.edit,
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(height: AppConstants.paddingMedium),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Account Settings
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomCardHeader(
                  title: 'Account Settings',
                ),
                _buildSettingsTile(
                  context,
                  'Notifications',
                  Icons.notifications_outlined,
                  onTap: () {
                    // TODO: Navigate to notifications settings
                  },
                ),
                _buildSettingsTile(
                  context,
                  'Security',
                  Icons.security_outlined,
                  onTap: () {
                    // TODO: Navigate to security settings
                  },
                ),
                _buildSettingsTile(
                  context,
                  'Language',
                  Icons.language_outlined,
                  value: 'English',
                  onTap: () {
                    // TODO: Show language picker
                  },
                ),
                _buildSettingsTile(
                  context,
                  'Theme',
                  Icons.palette_outlined,
                  value: Provider.of<ThemeProvider>(context).getThemeModeName(),
                  onTap: () {
                    final themeProvider =
                        Provider.of<ThemeProvider>(context, listen: false);
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (dialogContext) => ThemePickerDialog(
                        currentTheme: themeProvider.themeMode,
                        onThemeChanged: (ThemeMode mode) async {
                          try {
                            // Update theme using provider
                            await themeProvider.setThemeMode(mode);

                            if (!mounted) return;

                            // Show feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Theme updated to ${themeProvider.getThemeModeName()}',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update theme: $e'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  'Currency',
                  Icons.attach_money,
                  value: _getCurrencyName(_user.preferredCurrency),
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (dialogContext) => CurrencyPickerDialog(
                        currentCurrency: _user.preferredCurrency,
                        onCurrencyChanged: (Currency currency) async {
                          try {
                            // Update user's preferred currency
                            final updatedUser = _user.copyWith(
                              preferredCurrency: currency,
                              updatedAt: DateTime.now(),
                            );

                            final firebaseService = FirebaseService();
                            await firebaseService.updateUserData(updatedUser);

                            // Refresh user data
                            await _loadUserData();

                            if (!mounted) return;

                            // Show feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Currency updated to ${_getCurrencyName(currency)}',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update currency: $e'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                              ),
                            );
                          }
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Data & Privacy
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomCardHeader(
                  title: 'Data & Privacy',
                ),
                _buildSettingsTile(
                  context,
                  'Export Data',
                  Icons.download_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ExportDataScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  'Privacy Policy',
                  Icons.privacy_tip_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  'Terms of Service',
                  Icons.description_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsOfServiceScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Support & About
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CustomCardHeader(
                  title: 'Support & About',
                ),
                _buildSettingsTile(
                  context,
                  'Help Center',
                  Icons.help_outline,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpCenterScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  'Contact Support',
                  Icons.support_agent_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ContactSupportScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  'About',
                  Icons.info_outline,
                  value: 'Version ${AppConstants.appVersion}',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),

          // Sign Out Button
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.paddingMedium,
            ),
            child: CustomButton(
              text: 'Sign Out',
              onPressed: () async {
                try {
                  print('Starting Sign Out Process...');
                  final firebaseService = FirebaseService();
                  await firebaseService.signOut();
                  print('Sign Out Successful');
                  if (!mounted) return;
                  // Navigate to auth screen and clear navigation stack
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/auth',
                    (route) => false,
                  );
                } catch (e) {
                  print('Sign Out Error: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to sign out: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(AppConstants.paddingMedium),
                    ),
                  );
                }
              },
              type: CustomButtonType.outline,
              icon: Icons.logout,
              color: AppConstants.errorColor,
              isFullWidth: true,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    IconData icon, {
    String? value,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      trailing: value != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppConstants.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            )
          : Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
      onTap: onTap,
    );
  }

  String _getCurrencyName(Currency currency) {
    switch (currency) {
      case Currency.usd:
        return 'US Dollar (USD)';
      case Currency.eur:
        return 'Euro (EUR)';
      case Currency.gbp:
        return 'British Pound (GBP)';
      case Currency.inr:
        return 'Indian Rupee (INR)';
      case Currency.jpy:
        return 'Japanese Yen (JPY)';
      case Currency.aud:
        return 'Australian Dollar (AUD)';
      case Currency.cad:
        return 'Canadian Dollar (CAD)';
    }
  }
}
