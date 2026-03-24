import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_i18n.dart';
import '../core/app_media.dart';
import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import 'reset_password_flow_screen.dart';
import '../services/google_web_button.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool obscure = true;
  bool rememberMe = false;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appState = context.watch<AppState>();

    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, auth.homeRoute);
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Spacer(),
                  AppIconButton(
                    icon: Icons.language_rounded,
                    onPressed: () => _openLanguageDialog(context, appState),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Stack(
                children: [
                  AppNetworkImage(
                    url: AppMedia.loginHero,
                    height: 220,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(context.t('welcome_back'), textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                context.t('login_intro'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 20),
              if (auth.errorMessage != null) ...[
                InfoCard(
                  color: const Color(0xFFFEF2F2),
                  child: Text(auth.errorMessage!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB91C1C))),
                ),
                const SizedBox(height: 16),
              ],
              Text(context.t('email_or_username'), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_rounded),
                  hintText: 'name@apartment.com',
                ),
              ),
              const SizedBox(height: 16),
              Text(context.t('password'), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: obscure,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_rounded),
                  hintText: '********',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textMuted.withValues(alpha: 0.7),
                        letterSpacing: 2.4,
                      ),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => obscure = !obscure),
                    icon: Icon(obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: rememberMe,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (value) => setState(() => rememberMe = value ?? false),
                  ),
                  Text(context.t('remember_me')),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _openResetPasswordDialog(context),
                    child: Text(context.t('forgot_password')),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        final success = await auth.login(
                          email: _emailController.text.trim(),
                          password: _passwordController.text,
                        );
                        if (!context.mounted) {
                          return;
                        }
                        if (success) {
                          showAppSnack(context, context.t('sign_in'));
                          Navigator.pushReplacementNamed(context, auth.homeRoute);
                        }
                      },
                child: auth.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : Text(context.t('sign_in')),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(context.t('or_continue_with'), style: Theme.of(context).textTheme.bodySmall),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              if (kIsWeb)
                auth.isGoogleInitialized
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(height: 44, child: renderGoogleButton()),
                      )
                    : OutlinedButton(
                        onPressed: null,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2.2),
                            ),
                            const SizedBox(width: 10),
                            Text(context.t('sign_in_with_google')),
                          ],
                        ),
                      )
              else
                OutlinedButton(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          final success = await auth.loginWithGoogle();
                          if (!context.mounted) {
                            return;
                          }
                          if (success) {
                            showAppSnack(context, context.t('google_login_success'));
                            Navigator.pushReplacementNamed(context, auth.homeRoute);
                          }
                        },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFE3E8F0)),
                        ),
                        child: const Text(
                          'G',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4285F4),
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(context.t('sign_in_with_google')),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _FooterLink(icon: Icons.help_outline_rounded, label: context.t('help_center')),
                  const SizedBox(width: 20),
                  const SizedBox(height: 16, child: VerticalDivider(color: AppTheme.line)),
                  const SizedBox(width: 20),
                  _FooterLink(icon: Icons.language_rounded, label: appState.language == AppLanguage.vi ? context.t('vietnamese') : context.t('english')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLanguageDialog(BuildContext context, AppState appState) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.t('language')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () => context.read<AppState>().setLanguage(AppLanguage.en),
              leading: Icon(
                appState.language == AppLanguage.en ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: appState.language == AppLanguage.en ? AppTheme.brand : AppTheme.textMuted,
              ),
              title: Text(context.t('english')),
            ),
            ListTile(
              onTap: () => context.read<AppState>().setLanguage(AppLanguage.vi),
              leading: Icon(
                appState.language == AppLanguage.vi ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: appState.language == AppLanguage.vi ? AppTheme.brand : AppTheme.textMuted,
              ),
              title: Text(context.t('vietnamese')),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.t('close'))),
        ],
      ),
    );
  }

  Future<void> _openResetPasswordDialog(BuildContext context) async {
    final result = await Navigator.of(context).push<ResetPasswordResult>(
      MaterialPageRoute(
        builder: (_) => ResetPasswordFlowScreen(initialEmail: _emailController.text.trim()),
        fullscreenDialog: true,
      ),
    );
    if (!mounted || result == null) {
      return;
    }
    _emailController.text = result.email;
    _passwordController.text = result.password;
    showAppSnack(this.context, 'Password reset completed');
  }
}

class _FooterLink extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FooterLink({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppTheme.textMuted, size: 18),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
