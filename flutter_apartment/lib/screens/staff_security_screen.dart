import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../widgets/common_widgets.dart';

class StaffSecurityScreen extends StatefulWidget {
  const StaffSecurityScreen({super.key});

  @override
  State<StaffSecurityScreen> createState() => _StaffSecurityScreenState();
}

class _StaffSecurityScreenState extends State<StaffSecurityScreen> {
  late Future<List<SecurityLog>> _historyFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyFuture = AppApiService.instance.fetchSecurityHistory(
      userId: context.read<AuthProvider>().currentUserId,
      audience: 'staff',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Security',
      role: UserRole.staff,
      currentIndex: 2,
      actions: [
        ShellAction(icon: Icons.filter_alt_outlined, onPressed: _reload),
      ],
      body: FutureBuilder<List<SecurityLog>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && (snapshot.data == null || snapshot.data!.isEmpty)) {
            return asyncErrorView(context, title: 'Unable to load staff security history', onRetry: _reload);
          }

          final logs = snapshot.data ?? const <SecurityLog>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              AppSearchField(hint: context.tr('Search security log')),
              const SizedBox(height: 16),
              InfoCard(
                child: Row(
                  children: [
                    const SoftIcon(icon: Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency SOS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                          const SizedBox(height: 4),
                          Text('Alert security team immediately', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: _triggerSos,
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), minimumSize: const Size(110, 48)),
                      child: const Text('ACTIVATE'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Access History'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting && logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...logs.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Row(
                        children: [
                          const SoftIcon(icon: Icons.shield_outlined, color: Color(0xFF137FEC), size: 42),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log.event, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                                const SizedBox(height: 4),
                                Text('${log.visitor} - ${log.time}', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          statusChip(log.status),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _reload() {
    setState(() {
      _historyFuture = AppApiService.instance.fetchSecurityHistory(
        userId: context.read<AuthProvider>().currentUserId,
        audience: 'staff',
      );
    });
  }

  Future<void> _triggerSos() async {
    final auth = context.read<AuthProvider>();
    try {
      await AppApiService.instance.triggerSos(userId: auth.currentUserId, audience: 'staff');
      if (!mounted) {
        return;
      }
      showAppSnack(context, 'Staff SOS alert sent');
      _reload();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnack(context, 'Failed to send SOS: $error');
    }
  }
}
