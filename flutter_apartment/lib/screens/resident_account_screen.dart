import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../providers/app_state.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../widgets/common_widgets.dart';

class ResidentAccountScreen extends StatefulWidget {
  const ResidentAccountScreen({super.key});

  @override
  State<ResidentAccountScreen> createState() => _ResidentAccountScreenState();
}

class _ResidentAccountScreenState extends State<ResidentAccountScreen> {
  late Future<AccountSummary> _accountFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _accountFuture = AppApiService.instance.fetchAccountSummary(context.read<AuthProvider>().currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final auth = context.read<AuthProvider>();

    return AppShell(
      title: 'Account',
      role: UserRole.resident,
      currentIndex: 4,
      actions: [
        ShellAction(icon: Icons.settings_rounded, onPressed: () => setState(() {})),
      ],
      body: FutureBuilder<AccountSummary>(
        future: _accountFuture,
        builder: (context, snapshot) {
          final summary = snapshot.data;
          final user = summary?.user;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              InfoCard(
                child: Row(
                  children: [
                    AppAvatar(name: user?.fullName ?? 'John Doe', radius: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.fullName ?? 'John Doe', style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 4),
                          Text('${context.t('resident')} - Unit ${user?.unitNumber ?? '402'}', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    statusChip('Active'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (summary != null)
                ResponsiveButtonBar(
                  maxColumns: 3,
                  children: [
                    MetricCard(label: 'Bills', value: '${summary.stats.billCount}', icon: Icons.receipt_long_rounded, iconColor: const Color(0xFF137FEC)),
                    MetricCard(label: 'Guests', value: '${summary.stats.guestCount}', icon: Icons.badge_rounded, iconColor: const Color(0xFF22C55E)),
                    MetricCard(label: 'Issues', value: '${summary.stats.openIssueCount}', icon: Icons.warning_rounded, iconColor: const Color(0xFFF59E0B)),
                  ],
                ),
              const SizedBox(height: 18),
              _settingTile(context, Icons.person_outline_rounded, 'Profile Details', user?.email ?? 'No email loaded'),
              _settingTile(
                context,
                Icons.password_rounded,
                'Change Password',
                'Update your account password',
                onTap: () => _openChangePasswordDialog(auth.currentUserId),
              ),
              _settingTile(context, Icons.credit_card_rounded, 'Payment Preferences', 'Manage auto-pay and saved methods'),
              _settingTile(context, Icons.notifications_none_rounded, 'Notifications', 'Email and in-app alerts'),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InfoCard(
                  child: Row(
                    children: [
                      const SoftIcon(icon: Icons.dark_mode_rounded, color: Color(0xFF137FEC)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.t('dark_mode'), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                            const SizedBox(height: 4),
                            Text(context.tr('Toggle app appearance'), style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      ),
                      Switch(value: appState.isDarkMode, onChanged: (_) => appState.toggleTheme()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () {
                  auth.logout(context);
                  showAppSnack(context, 'Logged out');
                },
                icon: const Icon(Icons.logout_rounded),
                label: Text(context.t('sign_out')),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openChangePasswordDialog(int userId) async {
    final currentController = TextEditingController();
    final nextController = TextEditingController();
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: Text(context.tr('Change Password')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: currentController, decoration: InputDecoration(labelText: context.tr('Current Password'))),
                const SizedBox(height: 12),
                TextField(controller: nextController, decoration: InputDecoration(labelText: context.t('new_password'))),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage!, style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(color: const Color(0xFFB91C1C))),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.t('cancel'))),
            FilledButton(
              onPressed: () async {
                try {
                  final navigator = Navigator.of(dialogContext);
                  await AppApiService.instance.changePassword(
                    userId: userId,
                    currentPassword: currentController.text.trim(),
                    newPassword: nextController.text.trim(),
                  );
                  if (!mounted) {
                    return;
                  }
                  navigator.pop();
                  showAppSnack(context, 'Password changed successfully');
                } catch (error) {
                  setModalState(() {
                    errorMessage = error.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              child: Text(context.tr('Change')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingTile(BuildContext context, IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: InfoCard(
          child: Row(
            children: [
              SoftIcon(icon: icon, color: const Color(0xFF137FEC)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr(title), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                    const SizedBox(height: 4),
                    Text(context.tr(subtitle), style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8B97AA)),
            ],
          ),
        ),
      ),
    );
  }
}
