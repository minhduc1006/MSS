import 'package:flutter/material.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_AdminDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _dashboardFuture = _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Skyline Heights',
      subtitle: 'Admin Dashboard',
      role: UserRole.admin,
      currentIndex: 0,
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _reload),
      ],
      body: FutureBuilder<_AdminDashboardData>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(context, title: 'Unable to load admin dashboard', onRetry: _reload);
          }

          final dashboard = snapshot.data;
          final items = dashboard?.activities ?? const <ActivityItem>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.98,
                children: [
                  MetricCard(
                    label: 'Total Residents',
                    value: '${dashboard?.residentCount ?? 0}',
                    note: '${dashboard?.occupiedUnits ?? 0} units occupied',
                    noteColor: const Color(0xFF22C55E),
                    icon: Icons.groups_rounded,
                    iconColor: AppTheme.brand,
                  ),
                  MetricCard(
                    label: 'Occupancy Rate',
                    value: dashboard == null || dashboard.totalUnits == 0 ? '0%' : '${((dashboard.occupiedUnits / dashboard.totalUnits) * 100).toStringAsFixed(1)}%',
                    note: '${dashboard?.occupiedUnits ?? 0}/${dashboard?.totalUnits ?? 0} occupied',
                    icon: Icons.bed_rounded,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                  MetricCard(
                    label: 'Pending Billing',
                    value: '${dashboard?.activeInvoices ?? 0}',
                    note: formatMoney(dashboard?.totalOutstanding ?? 0),
                    noteColor: const Color(0xFFEF4444),
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFFEF4444),
                  ),
                  MetricCard(
                    label: 'Open Requests',
                    value: '${dashboard?.openIncidents ?? 0}',
                    note: '${dashboard?.criticalIncidents ?? 0} critical',
                    noteColor: const Color(0xFFF59E0B),
                    icon: Icons.build_rounded,
                    iconColor: const Color(0xFFA855F7),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/admin/residents'),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: Text(context.tr('Add New Resident')),
              ),
              const SizedBox(height: 12),
              ResponsiveButtonBar(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin/apartment'),
                    icon: const Icon(Icons.apartment_rounded),
                    label: Text(context.tr('Unit Map')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin/staff'),
                    icon: const Icon(Icons.badge_rounded),
                    label: Text(context.tr('Staff')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin/leasing'),
                    icon: const Icon(Icons.description_rounded),
                    label: const Text('Leasing & Utilities'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/admin/ops'),
                    icon: const Icon(Icons.hub_rounded),
                    label: const Text('Operations Hub'),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SectionTitle('Recent Activity', actionLabel: 'View All', onAction: () => Navigator.pushNamed(context, '/admin/activity')),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting && dashboard == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...items.map((item) {
                  final color = activityColor(item.kind);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SoftIcon(icon: activityIcon(item.kind), color: color, size: 42),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary)),
                                const SizedBox(height: 4),
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
                }),
            ],
          );
        },
      ),
    );
  }

  void _reload() {
    setState(() {
      _dashboardFuture = _loadDashboard();
    });
  }

  Future<_AdminDashboardData> _loadDashboard() async {
    final results = await Future.wait<dynamic>([
      AppApiService.instance.fetchActivities(),
      AppApiService.instance.fetchResidents(),
      AppApiService.instance.fetchApartmentStats(),
      AppApiService.instance.fetchBillingOverview(),
      AppApiService.instance.fetchSecurityOverview(),
    ]);

    final securityOverview = results[4] as SecurityOverviewData;
    final incidents = securityOverview.incidents;
    return _AdminDashboardData(
      activities: results[0] as List<ActivityItem>,
      residentCount: (results[1] as List<ResidentItem>).length,
      totalUnits: (results[2] as ApartmentStatsData).totalUnits,
      occupiedUnits: (results[2] as ApartmentStatsData).occupiedUnits,
      activeInvoices: (results[3] as BillingOverviewData).activeInvoices,
      totalOutstanding: (results[3] as BillingOverviewData).totalOutstanding,
      openIncidents: incidents.where((incident) => !incident.status.toLowerCase().contains('resolved')).length,
      criticalIncidents: incidents.where((incident) => (incident.severity ?? '').toLowerCase() == 'critical').length,
    );
  }
}

class _AdminDashboardData {
  final List<ActivityItem> activities;
  final int residentCount;
  final int totalUnits;
  final int occupiedUnits;
  final int activeInvoices;
  final double totalOutstanding;
  final int openIncidents;
  final int criticalIncidents;

  const _AdminDashboardData({
    required this.activities,
    required this.residentCount,
    required this.totalUnits,
    required this.occupiedUnits,
    required this.activeInvoices,
    required this.totalOutstanding,
    required this.openIncidents,
    required this.criticalIncidents,
  });
}
