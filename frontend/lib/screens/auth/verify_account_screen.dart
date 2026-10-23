import 'package:flutter/material.dart';
import '../../core/application_widget.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';

class VerifyAccountScreen extends StatefulWidget
{
  final String? email;

  const VerifyAccountScreen({
    this.email,
    super.key,
  });

  @override
  State<VerifyAccountScreen> createState() => _VerifyAccountScreenState();
}

class _VerifyAccountScreenState extends State<VerifyAccountScreen>
{
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  final _codeController = TextEditingController();

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;

  @override
  void initState()
  {
    super.initState();
    _emailController = TextEditingController(text: widget.email ?? '');
  }

  @override
  void dispose()
  {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async
  {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().verifyOtp(
        email: _emailController.text.trim(),
        code: _codeController.text.trim(),
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
      'Account verified successfully! You can now log in.',
    );

    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _handleResendCode() async
  {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showApplicationFeedback(
        context,
        'Please enter a valid email address to resend code.',
        isError: true,
      );
      return;
    }

    setState(() => _isResending = true);

    try {
      await AuthService().resendOtp(email: email);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      showApplicationFeedback(context, e.message, isError: true);
      return;
    }

    if (!mounted) return;

    setState(() => _isResending = false);

    showApplicationFeedback(
      context,
      'A new verification code has been sent to $email.',
    );
  }

  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Account'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enter verification code', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'We have sent a verification code to your email address. Please enter it below.',
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
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    ApplicationTextFieldWidget(
                      label: 'Verification Code',
                      hint: 'e.g. 123456',
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.mark_email_read_outlined,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the verification code.';
                        }
                        if (value.trim().length < 4) {
                          return 'Please enter a valid verification code.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    ApplicationButtonWidget(
                      label: 'Verify Account',
                      icon: Icons.check_circle_outline,
                      isLoading: _isLoading,
                      onPressed: _handleVerify,
                    ),

                    const SizedBox(height: 12),

                    ApplicationButtonWidget(
                      label: 'Resend Code',
                      secondary: true,
                      icon: Icons.refresh_outlined,
                      isLoading: _isResending,
                      onPressed: _handleResendCode,
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