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
  late Future<_AssignedFacilitiesData> _screenFuture;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _screenFuture = _loadData();
    _initialized = true;
  }

  void _reload() {
    setState(() {
      _screenFuture = _loadData();
    });
  }

  Future<_AssignedFacilitiesData> _loadData() async {
    final auth = context.read<AuthProvider>();
    final results = await Future.wait<dynamic>([
      AppApiService.instance.fetchStaffTasks(auth.currentUserId),
      AppApiService.instance.fetchFacilities(),
      AppApiService.instance.fetchStaffCustomServiceRequests(
        auth.currentUserId,
      ),
    ]);
    final bundle = results[0] as TaskBundleData;
    final facilities = results[1] as List<MaintenanceFacility>;
    final customRequests = results[2] as List<CustomServiceRequestItem>;
    final facilitiesById = <int, MaintenanceFacility>{
      for (final facility in facilities)
        if (facility.id != null) facility.id!: facility,
    };
    final jobs = bundle.tasks
        .where(_isFacilityAssignment)
        .map(
          (task) => _AssignedFacilityJob(
            task: task,
            facility: task.sourceId == null ? null : facilitiesById[task.sourceId!],
          ),
        )
        .toList();
    return _AssignedFacilitiesData(
      bundle: bundle,
      jobs: jobs,
      customRequests: customRequests,
    );
  }

  bool _isFacilityAssignment(TaskItem task) {
    final category = (task.category ?? '').toLowerCase();
    final sourceType = (task.sourceType ?? '').toLowerCase();
    return task.sourceId != null ||
        sourceType == 'parking' ||
        sourceType == 'in_unit' ||
        sourceType == 'operations' ||
        category.contains('facility') ||
        category.contains('service') ||
        category.contains('parking');
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
      body: FutureBuilder<_AssignedFacilitiesData>(
        future: _screenFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load assigned facility work',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          final jobs = data?.jobs ?? const <_AssignedFacilityJob>[];
          final customRequests =
              data?.customRequests ?? const <CustomServiceRequestItem>[];
          final activeJobs = jobs
              .where((job) => !job.task.status.toLowerCase().contains('done'))
              .length;
          final escalations = jobs
              .where((job) => job.task.priority.toLowerCase().contains('high'))
              .length;
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
                  MetricCard(
                    label: 'Open Jobs',
                    value: '$activeJobs',
                    icon: Icons.assignment_turned_in_rounded,
                    iconColor: const Color(0xFF137FEC),
                  ),
                  MetricCard(
                    label: 'Escalations',
                    value: '$escalations',
                    icon: Icons.priority_high_rounded,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  jobs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (jobs.isEmpty)
                const InfoCard(
                  child: Text(
                    'No facility work has been assigned yet. Admin assignments will appear here automatically.',
                  ),
                )
              else
                ...jobs.map(
                  (job) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  job.facility?.name ?? job.task.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(color: const Color(0xFF172033)),
                                ),
                              ),
                              statusChip(job.task.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            job.facility?.area ?? job.task.zone,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              statusChip(job.task.priority),
                              if (job.task.category != null &&
                                  job.task.category!.isNotEmpty)
                                statusChip(job.task.category!),
                              if (job.facility != null)
                                statusChip(job.facility!.serviceType.replaceAll('_', ' ')),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (job.facility?.description case final description?)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ...(job.facility?.logs ?? const <String>[])
                              .take(3)
                              .map(
                                (log) => Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Text(
                                    '- $log',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ),
                          ResponsiveButtonBar(
                            children: [
                              OutlinedButton(
                                onPressed: job.facility == null
                                    ? null
                                    : () => _openLogDialog(context, job.facility!),
                                child: Text(context.tr('Log Note')),
                              ),
                              FilledButton.tonal(
                                onPressed: () => _openAssignmentDialog(job),
                                child: const Text('Assignment'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              const SectionTitle('Custom Service Quotes'),
              const SizedBox(height: 12),
              if (customRequests.isEmpty)
                const InfoCard(
                  child: Text(
                    'No custom service requests are currently assigned to you.',
                  ),
                )
              else
                ...customRequests.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  request.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                          color: const Color(0xFF172033)),
                                ),
                              ),
                              statusChip(request.status),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${request.residentName} • ${request.unitNumber}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            request.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if ((request.preferredSchedule ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Preferred schedule: ${request.preferredSchedule}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (request.quotedPrice != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Quoted price: ${formatMoney(request.quotedPrice!)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                          if ((request.quoteNote ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Quote note: ${request.quoteNote}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 12),
                          ResponsiveButtonBar(
                            children: [
                              OutlinedButton(
                                onPressed: () => _openCustomServiceDetails(
                                  request,
                                ),
                                child: const Text('View'),
                              ),
                              FilledButton.tonal(
                                onPressed: request.id == null ||
                                        request.status != 'Awaiting Quote'
                                    ? null
                                    : () => _openQuoteDialog(request),
                                child: const Text('Quote Resident'),
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

  Future<void> _openAssignmentDialog(_AssignedFacilityJob job) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(job.facility?.name ?? job.task.title),
        content: Text(
          'Assigned by admin to ${job.task.assignedStaffName ?? 'staff'}.\n'
          'Zone: ${job.facility?.area ?? job.task.zone}\n'
          'Priority: ${job.task.priority}\n'
          'Category: ${job.task.category ?? 'General'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(context.t('close'))),
        ],
      ),
    );
  }

  Future<void> _openCustomServiceDetails(
      CustomServiceRequestItem request) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(request.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resident: ${request.residentName}'),
            Text('Unit: ${request.unitNumber}'),
            Text('Zone: ${request.zone}'),
            Text('Status: ${request.status}'),
            if ((request.preferredSchedule ?? '').isNotEmpty)
              Text('Preferred schedule: ${request.preferredSchedule}'),
            const SizedBox(height: 12),
            Text(request.description),
            if ((request.quoteNote ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Quote note: ${request.quoteNote}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.t('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _openQuoteDialog(CustomServiceRequestItem request) async {
    final priceController = TextEditingController(
      text: request.quotedPrice?.toStringAsFixed(0) ?? '',
    );
    final noteController = TextEditingController(text: request.quoteNote ?? '');

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Submit Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              decoration: const InputDecoration(labelText: 'Quoted price'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Quote note'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final quotedPrice =
                  double.tryParse(priceController.text.trim()) ?? 0;
              try {
                await AppApiService.instance.quoteCustomServiceRequest(
                  requestId: request.id!,
                  quotedPrice: quotedPrice,
                  quoteNote: noteController.text.trim().isEmpty
                      ? null
                      : noteController.text.trim(),
                );
                if (!dialogContext.mounted || !mounted) {
                  return;
                }
                Navigator.pop(dialogContext);
                _reload();
                showAppSnack(context, 'Quote sent to resident');
              } catch (error) {
                if (!dialogContext.mounted || !mounted) {
                  return;
                }
                showAppSnack(
                  context,
                  error.toString().replaceFirst('Exception: ', ''),
                );
              }
            },
            child: const Text('Submit Quote'),
          ),
        ],
      ),
    );
  }
}

class _AssignedFacilitiesData {
  final TaskBundleData bundle;
  final List<_AssignedFacilityJob> jobs;
  final List<CustomServiceRequestItem> customRequests;

  const _AssignedFacilitiesData({
    required this.bundle,
    required this.jobs,
    required this.customRequests,
  });
}

class _AssignedFacilityJob {
  final TaskItem task;
  final MaintenanceFacility? facility;

  const _AssignedFacilityJob({
    required this.task,
    required this.facility,
  });
}
