import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../services/download_service.dart';
import '../widgets/common_widgets.dart';

class StaffFacilitiesScreen extends StatefulWidget {
  const StaffFacilitiesScreen({super.key});

  @override
  State<StaffFacilitiesScreen> createState() => _StaffFacilitiesScreenState();
}

class _StaffFacilitiesScreenState extends State<StaffFacilitiesScreen> {
  late Future<List<MaintenanceFacility>> _facilitiesFuture;

  @override
  void initState() {
    super.initState();
    _facilitiesFuture = AppApiService.instance.fetchFacilities();
  }

  void _reload() {
    setState(() {
      _facilitiesFuture = AppApiService.instance.fetchFacilities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Facility & Service',
      role: UserRole.staff,
      currentIndex: 1,
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _reload),
      ],
      body: FutureBuilder<List<MaintenanceFacility>>(
        future: _facilitiesFuture,
        builder: (context, snapshot) {
          final facilities = snapshot.data ?? const <MaintenanceFacility>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.18,
                children: [
                  MetricCard(label: 'Open Jobs', value: '${facilities.where((facility) => !facility.status.toLowerCase().contains('operational') && !facility.status.toLowerCase().contains('available')).length}', icon: Icons.assignment_turned_in_rounded, iconColor: const Color(0xFF137FEC)),
                  MetricCard(label: 'Escalations', value: '${facilities.where((facility) => facility.health < 70).length}', icon: Icons.priority_high_rounded, iconColor: const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting && facilities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...facilities.map(
                  (facility) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(facility.name, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033)))),
                              statusChip(facility.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(facility.area ?? facility.lastCheck, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Text('Health score: ${facility.health}%', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 12),
                          ...facility.logs.take(3).map((log) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text('- $log', style: Theme.of(context).textTheme.bodyMedium),
                              )),
                          const SizedBox(height: 10),
                          ResponsiveButtonBar(
                            children: [
                              OutlinedButton(
                                onPressed: () => _openLogDialog(context, facility),
                                child: Text(context.tr('Log Note')),
                              ),
                              FilledButton.tonal(
                                onPressed: () => _dispatchFacility(facility),
                                child: Text(context.tr('Dispatch')),
                              ),
                            ],
                          ),
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

  Future<void> _openLogDialog(BuildContext context, MaintenanceFacility facility) async {
    final controller = TextEditingController();
    bool markOperational = false;
    final auth = context.read<AuthProvider>();

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('${context.tr('Update')} ${facility.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: controller, decoration: InputDecoration(hintText: context.tr('Add maintenance note'))),
              const SizedBox(height: 12),
              CheckboxListTile(
                value: markOperational,
                contentPadding: EdgeInsets.zero,
                title: Text(context.tr('Mark operational')),
                onChanged: (value) => setDialogState(() => markOperational = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.t('cancel'))),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(dialogContext);
                if (facility.id != null) {
                  await AppApiService.instance.addFacilityLog(
                    facilityId: facility.id!,
                    note: controller.text,
                    createdByName: auth.currentUser?.fullName ?? 'Staff',
                    markOperational: markOperational,
                  );
                }
                await DownloadService.saveTextFile(
                  filename: 'maintenance_log_${facility.name.toLowerCase().replaceAll(' ', '_')}',
                  content: 'Facility: ${facility.name}\nNote: ${controller.text}\nStatus: Saved',
                );
                if (!mounted) {
                  return;
                }
                navigator.pop();
                _reload();
                showAppSnack(this.context, 'Maintenance note saved');
              },
              child: Text(context.tr('Save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _dispatchFacility(MaintenanceFacility facility) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${context.tr('Dispatch')} ${facility.name}'),
        content: Text('Dispatch prepared for ${facility.area ?? facility.name}. Current backend does not expose a staff dispatch endpoint yet.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.t('close'))),
        ],
      ),
    );
  }
}
