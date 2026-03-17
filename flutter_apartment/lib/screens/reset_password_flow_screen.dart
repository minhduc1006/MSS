import 'package:flutter/material.dart';

import '../core/app_i18n.dart';
import '../services/app_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ResetPasswordResult {
  final String email;
  final String password;

  const ResetPasswordResult({
    required this.email,
    required this.password,
  });
}

class ResetPasswordFlowScreen extends StatefulWidget {
  final String initialEmail;

  const ResetPasswordFlowScreen({
    super.key,
    required this.initialEmail,
  });

  @override
  State<ResetPasswordFlowScreen> createState() => _ResetPasswordFlowScreenState();
}

enum _ResetStep { requestOtp, verifyOtp, setPassword }

class _ResetPasswordFlowScreenState extends State<ResetPasswordFlowScreen> {
  late final TextEditingController _emailController;
  late final TextEditingController _otpController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;

  _ResetStep _step = _ResetStep.requestOtp;
  bool _isSubmitting = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  String? _resetToken;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _otpController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _step == _ResetStep.setPassword ? context.t('reset_password') : context.tr('Email Verification'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(step: _step),
                    const SizedBox(height: 18),
                    _ProgressStrip(step: _step),
                    const SizedBox(height: 18),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: _buildStepContent(context),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      InfoCard(
                        color: const Color(0xFFFEF2F2),
                        child: Text(
                          _errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppTheme.line)),
              ),
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _handlePrimaryAction,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                      )
                    : Icon(_buttonIcon()),
                label: Text(_buttonLabel(context)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(BuildContext context) {
    switch (_step) {
      case _ResetStep.requestOtp:
        return _RequestOtpStep(
          key: const ValueKey('request-otp'),
          emailController: _emailController,
        );
      case _ResetStep.verifyOtp:
        return _VerifyOtpStep(
          key: const ValueKey('verify-otp'),
          email: _emailController.text.trim(),
          otpController: _otpController,
          onResend: _isSubmitting ? null : _requestOtp,
        );
      case _ResetStep.setPassword:
        return _SetPasswordStep(
          key: const ValueKey('set-password'),
          email: _emailController.text.trim(),
          newPasswordController: _newPasswordController,
          confirmPasswordController: _confirmPasswordController,
          showNewPassword: _showNewPassword,
          showConfirmPassword: _showConfirmPassword,
          onPasswordChanged: () => setState(() {}),
          onConfirmPasswordChanged: () => setState(() {}),
          onToggleNewPassword: () => setState(() => _showNewPassword = !_showNewPassword),
          onToggleConfirmPassword: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
        );
    }
  }

  String _buttonLabel(BuildContext context) {
    switch (_step) {
      case _ResetStep.requestOtp:
        return 'Send OTP';
      case _ResetStep.verifyOtp:
        return 'Verify OTP';
      case _ResetStep.setPassword:
        return 'Update Password';
    }
  }

  IconData _buttonIcon() {
    switch (_step) {
      case _ResetStep.requestOtp:
        return Icons.mark_email_read_rounded;
      case _ResetStep.verifyOtp:
        return Icons.verified_user_rounded;
      case _ResetStep.setPassword:
        return Icons.lock_reset_rounded;
    }
  }

  Future<void> _handlePrimaryAction() async {
    switch (_step) {
      case _ResetStep.requestOtp:
        await _requestOtp();
      case _ResetStep.verifyOtp:
        await _verifyOtp();
      case _ResetStep.setPassword:
        await _completeReset();
    }
  }

  Future<void> _requestOtp() async {
    final email = _emailController.text.trim();
    if (!_looksLikeEmail(email)) {
      setState(() => _errorMessage = context.tr('Enter a valid email address'));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await AppApiService.instance.requestPasswordResetOtp(email: email);
      if (!mounted) return;
      setState(() {
        _step = _ResetStep.verifyOtp;
        _otpController.clear();
      });
      showAppSnack(context, 'OTP has been sent to the user email');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _verifyOtp() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() => _errorMessage = 'OTP must contain 6 digits');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final resetToken = await AppApiService.instance.verifyPasswordResetOtp(
        email: email,
        otp: otp,
      );
      if (!mounted) return;
      setState(() {
        _resetToken = resetToken;
        _step = _ResetStep.setPassword;
      });
      showAppSnack(context, 'OTP verified successfully');
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _completeReset() async {
    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    if (newPassword.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters');
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = context.tr('Passwords do not match'));
      return;
    }
    if ((_resetToken ?? '').isEmpty) {
      setState(() => _errorMessage = 'Reset session is missing. Verify OTP again.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await AppApiService.instance.completePasswordReset(
        email: email,
        resetToken: _resetToken!,
        newPassword: newPassword,
      );
      if (!mounted) return;
      Navigator.pop(
        context,
        ResetPasswordResult(email: email, password: newPassword),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  bool _looksLikeEmail(String value) => value.contains('@') && value.contains('.');
}

class _HeaderCard extends StatelessWidget {
  final _ResetStep step;

  const _HeaderCard({required this.step});

  @override
  Widget build(BuildContext context) {
    final isPasswordStep = step == _ResetStep.setPassword;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14137FEC),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: const BoxDecoration(
              color: AppTheme.brand,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isPasswordStep ? Icons.lock_reset_rounded : Icons.mark_email_unread_rounded,
                    color: AppTheme.brand,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    isPasswordStep ? 'Create New Password' : 'Security Verification',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Text(
              isPasswordStep
                  ? 'OTP has been verified. Set a new password to complete the reset flow.'
                  : 'We will send a verification code to the user email first. Only verified email accounts can continue to the reset form.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF44566C),
                    height: 1.65,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  final _ResetStep step;

  const _ProgressStrip({required this.step});

  @override
  Widget build(BuildContext context) {
    final currentIndex = switch (step) {
      _ResetStep.requestOtp => 0,
      _ResetStep.verifyOtp => 1,
      _ResetStep.setPassword => 2,
    };

    return Row(
      children: List.generate(3, (index) {
        final active = index <= currentIndex;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppTheme.brand : const Color(0xFFDDE7F4),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        );
      }),
    );
  }
}

class _RequestOtpStep extends StatelessWidget {
  final TextEditingController emailController;

  const _RequestOtpStep({
    super.key,
    required this.emailController,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Account Email', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email_rounded),
              hintText: 'resident@example.com',
            ),
          ),
          const SizedBox(height: 14),
          _TipCard(
            icon: Icons.info_outline_rounded,
            title: 'What happens next?',
            message: 'An OTP email will be sent using the same Skyline Heights blue tone as the app and email templates.',
          ),
        ],
      ),
    );
  }
}

class _VerifyOtpStep extends StatelessWidget {
  final String email;
  final TextEditingController otpController;
  final Future<void> Function()? onResend;

  const _VerifyOtpStep({
    super.key,
    required this.email,
    required this.otpController,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Verification Code', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Text(
            'Enter the 6-digit OTP sent to $email.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD7E5F7), width: 2),
            ),
            child: Column(
              children: [
                Text(
                  'VERIFICATION CODE',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        letterSpacing: 3,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF71839D),
                      ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: otpController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: const Color(0xFFFF7A1A),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 12,
                      ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    hintText: '000000',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.schedule_rounded, size: 18, color: Color(0xFF71839D)),
              const SizedBox(width: 6),
              Text('Expires in 15 minutes', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              TextButton(
                onPressed: onResend == null ? null : () => onResend!.call(),
                child: const Text('Resend OTP'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SetPasswordStep extends StatelessWidget {
  final String email;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool showNewPassword;
  final bool showConfirmPassword;
  final VoidCallback onPasswordChanged;
  final VoidCallback onConfirmPasswordChanged;
  final VoidCallback onToggleNewPassword;
  final VoidCallback onToggleConfirmPassword;

  const _SetPasswordStep({
    super.key,
    required this.email,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.showNewPassword,
    required this.showConfirmPassword,
    required this.onPasswordChanged,
    required this.onConfirmPasswordChanged,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
  });

  @override
  Widget build(BuildContext context) {
    final password = newPasswordController.text;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasLower = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    final hasSpecial = password.contains(RegExp(r'[^A-Za-z0-9]'));
    var strengthSegments = 0;
    if (password.isNotEmpty) strengthSegments = 1;
    if (password.length >= 8) strengthSegments = 2;
    if (password.length >= 10 && hasUpper && hasLower) strengthSegments = 3;
    if (password.length >= 12 && hasUpper && hasLower && hasDigit && hasSpecial) {
      strengthSegments = 4;
    }
    final strengthLabel = switch (strengthSegments) {
      4 => 'Strong',
      3 => 'Good',
      2 => 'Fair',
      _ => 'Weak',
    };
    final strengthColor = switch (strengthSegments) {
      4 => const Color(0xFF22C55E),
      3 => AppTheme.brand,
      2 => const Color(0xFFF59E0B),
      _ => const Color(0xFFEF4444),
    };

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create New Password', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Verified account: $email',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: newPasswordController,
            obscureText: !showNewPassword,
            onChanged: (_) => onPasswordChanged(),
            decoration: InputDecoration(
              labelText: context.t('new_password'),
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: onToggleNewPassword,
                icon: Icon(showNewPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Password Strength', style: Theme.of(context).textTheme.labelMedium),
              const Spacer(),
              Text(
                strengthLabel,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(color: strengthColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(4, (index) {
              final active = index < strengthSegments;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? strengthColor : const Color(0xFFDDE7F4),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: confirmPasswordController,
            obscureText: !showConfirmPassword,
            onChanged: (_) => onConfirmPasswordChanged(),
            decoration: InputDecoration(
              labelText: context.tr('Confirm Password'),
              prefixIcon: const Icon(Icons.verified_user_rounded),
              suffixIcon: IconButton(
                onPressed: onToggleConfirmPassword,
                icon: Icon(showConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _TipCard(
            icon: Icons.shield_rounded,
            title: 'Password Requirements',
            message: 'Use at least 8 characters and keep it different from the old password.',
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _TipCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.brand.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.brand),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
