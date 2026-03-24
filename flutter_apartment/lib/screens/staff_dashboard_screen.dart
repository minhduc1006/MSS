import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../widgets/common_widgets.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  late Future<TaskBundleData> _taskFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _taskFuture = AppApiService.instance.fetchStaffTasks(context.read<AuthProvider>().currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Operations Center',
      subtitle: 'Staff Dashboard',
      role: UserRole.staff,
      currentIndex: 0,
      actions: [
        ShellAction(
          icon: Icons.refresh_rounded,
          onPressed: () => setState(() {
            _taskFuture = AppApiService.instance.fetchStaffTasks(context.read<AuthProvider>().currentUserId);
          }),
        ),
      ],
      body: FutureBuilder<TaskBundleData>(
        future: _taskFuture,
        builder: (context, snapshot) {
          final bundle = snapshot.data;
          final tasks = bundle?.tasks ?? const <TaskItem>[];
          final schedule = _buildSchedule(tasks);
          final inProgress = tasks.where((task) => task.status.toLowerCase().contains('progress')).length;
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
                  childAspectRatio: constraints.maxWidth < 420 ? 1.1 : 0.9,
                  children: [
                    MetricCard(label: 'Pending', value: '${tasks.where((task) => task.status.toLowerCase().contains('pending')).length}', icon: Icons.pending_actions_rounded, iconColor: const Color(0xFFF59E0B)),
                    MetricCard(label: 'In Progress', value: '$inProgress', icon: Icons.timelapse_rounded, iconColor: const Color(0xFF137FEC)),
                    MetricCard(label: 'Done', value: '${bundle?.completedTasks ?? 0}', icon: Icons.check_circle_rounded, iconColor: const Color(0xFF22C55E)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ResponsiveButtonBar(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.pushNamed(context, '/staff/facilities'),
                    icon: const Icon(Icons.apartment_rounded),
                    label: Text(context.tr('Facilities')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/staff/security'),
                    icon: const Icon(Icons.shield_rounded),
                    label: Text(context.tr('Security')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/staff/roster'),
                    icon: const Icon(Icons.schedule_rounded),
                    label: const Text('Roster'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionTitle('Today\'s Work Schedule'),
              const SizedBox(height: 12),
              ...schedule.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoCard(
                    color: item.isCurrent ? const Color(0xFFF0F7FF) : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 56,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          decoration: BoxDecoration(
                            color: item.isCurrent ? const Color(0xFF137FEC) : const Color(0xFFF4F7FB),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            item.time,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: item.isCurrent ? Colors.white : const Color(0xFF172033),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
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
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033)),
                                    ),
                                  ),
                                  if (item.isCurrent) statusChip('In Progress'),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(item.subtitle, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Today\'s Tasks'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting && tasks.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...tasks.map(
                  (task) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(task.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033)))),
                              statusChip(task.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(task.zone, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              statusChip(task.priority),
                              const Spacer(),
                              TextButton(
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(task.title),
                                    content: Text('${task.zone}\nPriority: ${task.priority}\nStatus: ${task.status}\nCategory: ${task.category ?? 'General'}'),
                                    actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.t('close')))],
                                  ),
                                ),
                                child: Text(context.tr('Open')),
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

  List<_WorkScheduleItem> _buildSchedule(List<TaskItem> tasks) {
    final defaults = <_WorkScheduleItem>[
      const _WorkScheduleItem(time: '07:30', title: 'Shift Check-in', subtitle: 'Review tools, notices, and assignment board'),
      const _WorkScheduleItem(time: '09:00', title: 'Resident Support Window', subtitle: 'Handle walk-ins and urgent resident requests'),
      const _WorkScheduleItem(time: '13:30', title: 'Facility Round', subtitle: 'Inspect shared facilities and log issues'),
      const _WorkScheduleItem(time: '16:30', title: 'Shift Handover', subtitle: 'Update progress and hand over open tasks'),
    ];
    if (tasks.isEmpty) {
      return defaults;
    }

    final slots = ['08:00', '10:00', '13:30', '15:30', '17:00'];
    final generated = <_WorkScheduleItem>[];
    for (var i = 0; i < tasks.length && i < slots.length; i++) {
      final task = tasks[i];
      generated.add(
        _WorkScheduleItem(
          time: slots[i],
          title: task.title,
          subtitle: '${task.zone} • ${task.category ?? 'General'} • ${task.priority}',
          isCurrent: i == 1 && task.status.toLowerCase().contains('progress'),
        ),
      );
    }
    if (generated.length < defaults.length) {
      generated.addAll(defaults.skip(generated.length));
    }
    return generated;
  }
}

class _WorkScheduleItem {
  final String time;
  final String title;
  final String subtitle;
  final bool isCurrent;

  const _WorkScheduleItem({
    required this.time,
    required this.title,
    required this.subtitle,
    this.isCurrent = false,
  });
}
