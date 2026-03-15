import 'package:flutter/material.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AdminActivityScreen extends StatefulWidget {
  const AdminActivityScreen({super.key});

  @override
  State<AdminActivityScreen> createState() => _AdminActivityScreenState();
}

class _AdminActivityScreenState extends State<AdminActivityScreen> {
  late Future<List<ActivityItem>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = AppApiService.instance.fetchActivities();
  }

  void _reload() {
    setState(() {
      _activitiesFuture = AppApiService.instance.fetchActivities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Recent Activity',
      subtitle: 'Full admin operations feed',
      role: UserRole.admin,
      currentIndex: 0,
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _reload),
      ],
      body: FutureBuilder<List<ActivityItem>>(
        future: _activitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load activity feed',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final items = snapshot.data ?? const <ActivityItem>[];
          final billingCount = items.where((item) => item.kind == 'billing').length;
          final maintenanceCount = items.where((item) => item.kind == 'maintenance').length;
          final onboardingCount = items.where((item) => item.kind == 'onboarding').length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              LayoutBuilder(
                builder: (context, constraints) => GridView.count(
                  crossAxisCount: constraints.maxWidth < 420 ? 2 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: constraints.maxWidth < 420 ? 1.1 : 0.86,
                  children: [
                    MetricCard(
                      label: 'Billing',
                      value: '$billingCount',
                      icon: Icons.receipt_long_rounded,
                      iconColor: AppTheme.brand,
                    ),
                    MetricCard(
                      label: 'Maintenance',
                      value: '$maintenanceCount',
                      icon: Icons.handyman_rounded,
                      iconColor: const Color(0xFFF97316),
                    ),
                    MetricCard(
                      label: 'Onboarding',
                      value: '$onboardingCount',
                      icon: Icons.person_add_alt_1_rounded,
                      iconColor: const Color(0xFF22C55E),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const SectionTitle('Timeline'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting && items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (items.isEmpty)
                InfoCard(
                  child: Text(
                    context.tr('No recent activity is available right now.'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...items.map(
                  (item) {
                    final color = activityColor(item.kind);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InfoCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SoftIcon(icon: activityIcon(item.kind), color: color, size: 44),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary),
                                        ),
                                      ),
                                      statusChip(item.kind),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(item.desc, style: Theme.of(context).textTheme.bodyMedium),
                                  const SizedBox(height: 10),
                                  Text(item.time, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
