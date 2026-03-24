import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../widgets/common_widgets.dart';

class StaffRosterScreen extends StatefulWidget {
  const StaffRosterScreen({super.key});

  @override
  State<StaffRosterScreen> createState() => _StaffRosterScreenState();
}

class _StaffRosterScreenState extends State<StaffRosterScreen> {
  late Future<_StaffRosterData> _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  Future<_StaffRosterData> _load() async {
    final auth = context.read<AuthProvider>();
    final results = await Future.wait<dynamic>([
      AppApiService.instance.fetchStaffShifts(auth.currentUserId),
      AppApiService.instance.fetchStaffComplaints(auth.currentUserId),
    ]);
    return _StaffRosterData(
      shifts: results[0] as List<StaffShiftItem>,
      complaints: results[1] as List<ComplaintTicketItem>,
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Shift Roster',
      subtitle: 'Duty schedule and assigned complaints',
      role: UserRole.staff,
      currentIndex: 0,
      showBottomNav: false,
      actions: [ShellAction(icon: Icons.refresh_rounded, onPressed: _reload)],
      body: FutureBuilder<_StaffRosterData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load staff roster',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final onDuty =
              data.shifts.where((item) => item.status == 'On Duty').length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.04,
                children: [
                  MetricCard(
                    label: 'Scheduled',
                    value: '${data.shifts.length}',
                    note: '$onDuty currently on duty',
                    icon: Icons.schedule_rounded,
                    iconColor: const Color(0xFF137FEC),
                  ),
                  MetricCard(
                    label: 'Assigned Tickets',
                    value: '${data.complaints.length}',
                    note: 'Resident complaints in your queue',
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFFEF4444),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionTitle('Upcoming Shifts'),
              const SizedBox(height: 12),
              if (data.shifts.isEmpty)
                const InfoCard(child: Text('No shifts assigned to you yet.'))
              else
                ...data.shifts.map(
                  (shift) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${shift.shiftDate} • ${shift.shiftLabel}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                              ),
                              statusChip(shift.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${shift.startTime}-${shift.endTime} • ${shift.zone}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if ((shift.note ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(shift.note!,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const SectionTitle('Complaint Queue'),
              const SizedBox(height: 12),
              if (data.complaints.isEmpty)
                const InfoCard(
                    child: Text('No resident complaints assigned to you.'))
              else
                ...data.complaints.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(item.title,
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                              ),
                              statusChip(item.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('${item.unitNumber} • ${item.priority}',
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Text(item.description,
                              style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              _pill(
                                'In Progress',
                                () => _setComplaint(item, 'In Progress'),
                              ),
                              _pill(
                                'Resolved',
                                () => _setComplaint(item, 'Resolved'),
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

  Widget _pill(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: const TextStyle(color: Color(0xFF137FEC))),
      ),
    );
  }

  Future<void> _setComplaint(ComplaintTicketItem item, String status) async {
    await AppApiService.instance.updateComplaintStatus(
      complaintId: item.id!,
      status: status,
      responseNote: 'Updated from staff roster view.',
    );
    if (!mounted) return;
    _reload();
    showAppSnack(context, 'Complaint updated');
  }
}

class _StaffRosterData {
  final List<StaffShiftItem> shifts;
  final List<ComplaintTicketItem> complaints;

  const _StaffRosterData({
    required this.shifts,
    required this.complaints,
  });
}
