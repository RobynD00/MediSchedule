import 'package:flutter/material.dart';
import '../../core/application_widget.dart';

// Screen for requesting a password reset code and setting a new password.
class ForgotPasswordScreen extends StatefulWidget 
{
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> 
{
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() 
  {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestResetCode() async 
  {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulated API call to POST /api/auth/forgot-password
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _codeSent = true;
    });

    showApplicationFeedback(
      context,
      'A password reset code has been sent to your email.',
    );
  }

  Future<void> _handleResetPassword() async 
  {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simulated API call to reset password with code
    await Future<void>.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    setState(() => _isLoading = false);

    showApplicationFeedback(
      context,
      'Your password has been reset successfully. Please log in.',
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) 
  {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _codeSent ? 'Reset your password' : 'Forgot password?',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Enter the code sent to your email along with your new password.'
                    : 'Enter your registered email address and we will send you a reset code.',
                style: theme.textTheme.bodyLarge,
              ),

              const SizedBox(height: 24),

              if (_errorMessage != null) ...[
                ApplicationFeedbackBannerWidget(
                  message: _errorMessage!,
                  isError: true,
                  icon: Icons.error_outline,
                ),
                const SizedBox(height: 16),
              ],

              ApplicationCardWidget(
                child: Column(
                  children: [
                    ApplicationTextFieldWidget(
                      label: 'Email address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email address.';
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),

                    if (_codeSent) ...[
                      const SizedBox(height: 16),

                      ApplicationTextFieldWidget(
                        label: 'Reset Code',
                        hint: 'e.g. 123456',
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        prefixIcon: Icons.lock_reset_outlined,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter the reset code.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: _obscurePassword,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password.';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters.';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmNewPasswordController,
                        obscureText: _obscureConfirmPassword,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock_clock_outlined),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password.';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match.';
                          }
                          return null;
                        },
                      ),
                    ],

                    const SizedBox(height: 24),

                    ApplicationButtonWidget(
                      label: _codeSent ? 'Reset Password' : 'Send Reset Code',
                      icon: _codeSent ? Icons.check_circle_outline : Icons.send,
                      isLoading: _isLoading,
                      onPressed: _codeSent
                          ? _handleResetPassword
                          : _handleRequestResetCode,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Back to Log In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
