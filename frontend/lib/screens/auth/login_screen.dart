import 'package:flutter/material.dart';
import '../../core/application_widget.dart';
import 'sign_up_screen.dart';
import 'forgot_password_screen.dart';
import '../../services/auth_service.dart';

// Screen for authenticating existing users via email/username and password.
class LoginScreen extends StatefulWidget 
{
  final VoidCallback? onLoginSuccess;

  const LoginScreen({
    this.onLoginSuccess,
    super.key,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
{
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() 
  {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;
 
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
 
  try {
    await AuthService().login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
 
    if (!mounted) return;
 
    showApplicationFeedback(
      context,
      'Login successful! Welcome back.',
    );
 
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.of(context).pop();
    }
  } catch (error) {
    if (!mounted) return;
 
    setState(() {
      _errorMessage =
          'Login failed. Please check your details and connection, then try again.';
    });
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}
 

    showApplicationFeedback(context, 'Login successful! Welcome back.');

    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) 
  {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log In'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Please sign in to access your medication reminders and health info.',
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
                      hint: 'e.g. user@example.com',
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

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Password',
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
                          return 'Please enter your password.';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 8),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    ApplicationButtonWidget(
                      label: 'Log In',
                      icon: Icons.login,
                      isLoading: _isLoading,
                      onPressed: _handleLogin,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: theme.textTheme.bodyLarge,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
