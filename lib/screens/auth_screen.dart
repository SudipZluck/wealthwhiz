import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../constants/constants.dart';
import '../services/firebase_service.dart';
import '../widgets/widgets.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackbar(String message) {
    print('Showing Error Snackbar: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppConstants.paddingMedium),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _handleEmailAuth() async {
    if (!_formKey.currentState!.validate()) {
      print('Form Validation Failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Email Auth: ${_isLogin ? 'Login' : 'SignUp'}');
      final firebaseService = FirebaseService();
      if (_isLogin) {
        print('Attempting Login with Email: ${_emailController.text}');
        await firebaseService.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        print('Attempting SignUp with Email: ${_emailController.text}');
        await firebaseService.signUp(
          _emailController.text,
          _passwordController.text,
        );
      }
      print('Authentication Successful');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('FirebaseAuthException in Auth Screen: ${e.code} - ${e.message}');
      if (!mounted) return;
      _showErrorSnackbar(e.message ?? 'Authentication failed');
    } catch (e, stackTrace) {
      print('General Error in Auth Screen: $e');
      print('Error Stack Trace: $stackTrace');
      if (!mounted) return;
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting Google Sign In');
      final firebaseService = FirebaseService();
      final user = await firebaseService.signInWithGoogle();
      print('Google Sign In Result: ${user != null ? 'Success' : 'Cancelled'}');
      if (user != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      print(
          'FirebaseAuthException in Google Sign In: ${e.code} - ${e.message}');
      if (!mounted) return;
      _showErrorSnackbar(e.message ?? 'Authentication failed');
    } catch (e, stackTrace) {
      print('General Error in Google Sign In: $e');
      print('Error Stack Trace: $stackTrace');
      if (!mounted) return;
      _showErrorSnackbar(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        // Unfocus any text field when tapping outside
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App Logo and Name
                  Icon(
                    Icons.account_balance_wallet,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'WealthWhiz',
                    style: AppConstants.headlineLarge.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Smart Money Management',
                    style: AppConstants.titleMedium.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Email/Password Form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.paddingMedium),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppConstants.paddingLarge),
                        // Login/Signup Button
                        Padding(
                          padding: const EdgeInsets.only(
                              bottom: AppConstants.paddingLarge),
                          child: SizedBox(
                            height: 56,
                            child: CustomButton(
                              text: _isLogin ? 'Login' : 'Sign Up',
                              onPressed: _isLoading ? null : _handleEmailAuth,
                              isLoading: _isLoading,
                              isFullWidth: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Switch between Login/Signup
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                    child: Text(
                      _isLogin
                          ? 'Don\'t have an account? Sign Up'
                          : 'Already have an account? Login',
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // OR Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color:
                              theme.colorScheme.onBackground.withOpacity(0.2),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.paddingMedium,
                        ),
                        child: Text(
                          'OR',
                          style: AppConstants.bodyMedium.copyWith(
                            color:
                                theme.colorScheme.onBackground.withOpacity(0.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color:
                              theme.colorScheme.onBackground.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Google Sign In Button
                  Padding(
                    padding: const EdgeInsets.only(
                        bottom: AppConstants.paddingLarge),
                    child: SizedBox(
                      height: 56,
                      child: CustomButton(
                        text: 'Continue with Google',
                        onPressed: _isLoading ? null : _handleGoogleSignIn,
                        isLoading: _isLoading,
                        type: CustomButtonType.outline,
                        icon: Icons.g_mobiledata,
                        isFullWidth: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
