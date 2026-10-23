import 'package:flutter/material.dart';
import '../../core/application_widget.dart';
import 'verify_account_screen.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget
{
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
{
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String _selectedRole = 'PATIENT';
  DateTime? _dateOfBirth;
  bool _acceptedTerms = false;
  String? _formProblem;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose()
  {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 40, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => _dateOfBirth = picked);
  }

  Future<void> _handleRegister() async
  {
    final formValid = _formKey.currentState!.validate();
    String? problem;
    if (_dateOfBirth == null) {
      problem = 'Please enter your date of birth.';
    } else if (!_acceptedTerms) {
      problem = 'Please accept the privacy notice and terms.';
    }
    setState(() => _formProblem = problem);
    if (!formValid || problem != null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().register(
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _formatDate(_dateOfBirth!),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        acceptedTerms: _acceptedTerms,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
      return;
    }

    if (!mounted) return;

    setState(() => _isLoading = false);

    showApplicationFeedback(
      context,
      'Registration successful! Please verify your account.',
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => VerifyAccountScreen(
          email: _emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Up'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create account', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Join MediSchedule to track your medications or assist a family member.',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ApplicationTextFieldWidget(
                      label: 'Full Name',
                      hint: 'e.g. John Doe',
                      controller: _fullNameController,
                      prefixIcon: Icons.person_outline,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your full name.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

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

                    InkWell(
                      onTap: _pickDateOfBirth,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of birth',
                          prefixIcon: Icon(Icons.cake_outlined),
                        ),
                        child: Text(
                          _dateOfBirth == null
                              ? 'Tap to choose'
                              : _formatDate(_dateOfBirth!),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text('I am registering as:', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),

                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'PATIENT',
                          label: Text('Patient'),
                          icon: Icon(Icons.person),
                        ),
                        ButtonSegment<String>(
                          value: 'CAREGIVER',
                          label: Text('Caregiver'),
                          icon: Icon(Icons.medical_services_outlined),
                        ),
                      ],
                      selected: {_selectedRole},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _selectedRole = newSelection.first;
                        });
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
                          return 'Please enter a password.';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_clock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password.';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: _acceptedTerms,
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                      title: Text(
                        'I accept the privacy notice and terms.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),

                    if (_formProblem != null) ...[
                      const SizedBox(height: 8),
                      ApplicationFeedbackBannerWidget(
                        message: _formProblem!,
                        isError: true,
                        icon: Icons.error_outline,
                      ),
                    ],

                    const SizedBox(height: 24),

                    ApplicationButtonWidget(
                      label: 'Create Account',
                      icon: Icons.person_add_outlined,
                      isLoading: _isLoading,
                      onPressed: _handleRegister,
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
                      'Already have an account?',
                      style: theme.textTheme.bodyLarge,
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Log In',
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