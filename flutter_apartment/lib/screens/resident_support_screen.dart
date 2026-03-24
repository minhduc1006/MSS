import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../widgets/common_widgets.dart';

class ResidentSupportScreen extends StatefulWidget {
  const ResidentSupportScreen({super.key});

  @override
  State<ResidentSupportScreen> createState() => _ResidentSupportScreenState();
}

class _ResidentSupportScreenState extends State<ResidentSupportScreen>
    with SingleTickerProviderStateMixin {
  late Future<_ResidentSupportData> _future;
  late final TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_selectedTabIndex != _tabController.index && mounted) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<_ResidentSupportData> _load() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final results = await Future.wait<dynamic>([
      AppApiService.instance.fetchResidentPackages(auth.currentUserId),
      AppApiService.instance.fetchResidentComplaints(auth.currentUserId),
      AppApiService.instance.fetchPackages(),
      AppApiService.instance.fetchComplaints(),
    ]);

    final residentPackages = results[0] as List<PackageRecordItem>;
    final residentComplaints = results[1] as List<ComplaintTicketItem>;
    final allPackages = results[2] as List<PackageRecordItem>;
    final allComplaints = results[3] as List<ComplaintTicketItem>;

    final visiblePackages = residentPackages.isNotEmpty
        ? residentPackages
        : allPackages.where((item) => _matchesPackage(item, user)).toList();
    final visibleComplaints = residentComplaints.isNotEmpty
        ? residentComplaints
        : allComplaints.where((item) => _matchesComplaint(item, user)).toList();

    return _ResidentSupportData(
      packages: visiblePackages,
      complaints: visibleComplaints,
    );
  }

  bool _matchesPackage(PackageRecordItem item, SessionUser? user) {
    if (user == null) {
      return false;
    }
    final unitMatches = (item.unitNumber ?? '').trim().toLowerCase() ==
        (user.unitNumber ?? '').trim().toLowerCase();
    final residentMatches = (item.residentName ?? '').trim().toLowerCase() ==
        user.fullName.trim().toLowerCase();
    final idMatches = item.residentId == user.id;
    final publicLostFound =
        item.recordType.toLowerCase().contains('lost') && item.residentId == null;
    return idMatches || unitMatches || residentMatches || publicLostFound;
  }

  bool _matchesComplaint(ComplaintTicketItem item, SessionUser? user) {
    if (user == null) {
      return false;
    }
    final unitMatches =
        item.unitNumber.trim().toLowerCase() == (user.unitNumber ?? '').trim().toLowerCase();
    final residentMatches =
        item.residentName.trim().toLowerCase() == user.fullName.trim().toLowerCase();
    final idMatches = item.residentId == user.id;
    return idMatches || unitMatches || residentMatches;
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser;
    return AppShell(
      title: 'Support Desk',
      subtitle: 'Packages, feedback, and service follow-up',
      role: UserRole.resident,
      currentIndex: 0,
      showBottomNav: false,
      actions: [ShellAction(icon: Icons.refresh_rounded, onPressed: _reload)],
      body: FutureBuilder<_ResidentSupportData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load support desk',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }
          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final openComplaints = data.complaints
              .where((item) => !item.status.toLowerCase().contains('resolved'))
              .length;
          final packageCount = data.packages.length;
          final readyPackages = data.packages
              .where((item) =>
                  item.status.toLowerCase().contains('ready') ||
                  item.status.toLowerCase().contains('arrived') ||
                  item.status.toLowerCase().contains('claim'))
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
                childAspectRatio: 1.04,
                children: [
                  MetricCard(
                    label: 'Packages',
                    value: '$packageCount',
                    note: readyPackages == 0
                        ? 'No package waiting'
                        : '$readyPackages ready or pending',
                    icon: Icons.inventory_2_rounded,
                    iconColor: const Color(0xFF137FEC),
                  ),
                  MetricCard(
                    label: 'Open Tickets',
                    value: '$openComplaints',
                    note: '${data.complaints.length} feedback records',
                    icon: Icons.support_agent_rounded,
                    iconColor: const Color(0xFFEF4444),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveButtonBar(
                children: [
                  FilledButton.icon(
                    onPressed: () => _showComplaintComposer(user, data),
                    icon: const Icon(Icons.rate_review_rounded),
                    label: const Text('Submit Complaint / Feedback'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _tabController.animateTo(_selectedTabIndex == 0 ? 1 : 0),
                    icon: Icon(_selectedTabIndex == 0
                        ? Icons.support_agent_rounded
                        : Icons.inventory_2_rounded),
                    label: Text(_selectedTabIndex == 0
                        ? 'Open My Tickets'
                        : 'Open My Packages'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InfoCard(
                color: const Color(0xFFEAF3FF),
                child: Text(
                  packageCount == 0
                      ? 'No package is linked to your account yet. The app still shows public lost-and-found records when available, and new complaints will appear in My Tickets after submission.'
                      : 'Packages, lost-and-found items, and service tickets are all tracked here so you can follow the full support workflow.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Theme.of(context).cardColor,
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'My Packages'),
                    Tab(text: 'My Tickets'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.58,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _packageList(data.packages),
                    _complaintList(data.complaints),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _packageList(List<PackageRecordItem> packages) {
    if (packages.isEmpty) {
      return const InfoCard(
        child: Text(
            'No package or lost-and-found records are linked to your account yet.'),
      );
    }
    return ListView.separated(
      itemCount: packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = packages[index];
        final subtitle = [
          if ((item.carrier ?? '').isNotEmpty) item.carrier!,
          item.location,
          item.receivedAt,
        ].join(' • ');
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${item.recordType} • ${item.itemName}',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  statusChip(item.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              if ((item.trackingCode ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tracking: ${item.trackingCode}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if ((item.note ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(item.note!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _complaintList(List<ComplaintTicketItem> complaints) {
    if (complaints.isEmpty) {
      return const InfoCard(
          child: Text('No complaint or feedback tickets yet.'));
    }
    return ListView.separated(
      itemCount: complaints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = complaints[index];
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(item.title,
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  statusChip(item.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(item.description,
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                  'Category ${item.category} • ${item.assignedStaffName ?? 'Awaiting assignment'}',
                  style: Theme.of(context).textTheme.bodySmall),
              if ((item.responseNote ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Response: ${item.responseNote}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              const SizedBox(height: 10),
              if (item.residentRating != null)
                Text('Your rating: ${item.residentRating}/5',
                    style: Theme.of(context).textTheme.bodySmall)
              else if (item.status.toLowerCase().contains('resolved'))
                FilledButton.tonal(
                  onPressed: () => _rateComplaint(item),
                  child: const Text('Rate Service'),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showComplaintComposer(
    SessionUser? user,
    _ResidentSupportData currentData,
  ) async {
    if (user == null) {
      return;
    }
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String category = 'General';
    String priority = 'Medium';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Submit Complaint / Feedback',
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: category,
              items: const [
                DropdownMenuItem(value: 'General', child: Text('General')),
                DropdownMenuItem(value: 'Maintenance', child: Text('Maintenance')),
                DropdownMenuItem(value: 'Noise', child: Text('Noise')),
                DropdownMenuItem(value: 'Security', child: Text('Security')),
                DropdownMenuItem(value: 'Cleaning', child: Text('Cleaning')),
              ],
              onChanged: (value) => category = value ?? 'General',
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: priority,
              items: const [
                DropdownMenuItem(value: 'Low', child: Text('Low')),
                DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                DropdownMenuItem(value: 'High', child: Text('High')),
              ],
              onChanged: (value) => priority = value ?? 'Medium',
              decoration: const InputDecoration(labelText: 'Priority'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final navigator = Navigator.of(sheetContext);
                if (titleController.text.trim().isEmpty ||
                    descriptionController.text.trim().isEmpty) {
                  showAppSnack(sheetContext, 'Please complete the complaint form');
                  return;
                }
                final created = await AppApiService.instance.createComplaint(
                  residentId: user.id,
                  residentName: user.fullName,
                  unitNumber: user.unitNumber ?? 'Unknown',
                  category: category,
                  title: titleController.text.trim(),
                  description: descriptionController.text.trim(),
                  priority: priority,
                );
                if (!mounted) return;
                setState(() {
                  _future = Future.value(
                    _ResidentSupportData(
                      packages: currentData.packages,
                      complaints: [
                        created,
                        ...currentData.complaints.where(
                          (item) => item.id != created.id,
                        ),
                      ],
                    ),
                  );
                });
                navigator.pop();
                _tabController.animateTo(1);
                showAppSnack(context, 'Complaint submitted');
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rateComplaint(ComplaintTicketItem item) async {
    await AppApiService.instance.rateComplaint(
      complaintId: item.id!,
      rating: 5,
      review: 'Resolved smoothly through the resident support desk.',
    );
    if (!mounted) return;
    _reload();
    showAppSnack(context, 'Service rating submitted');
  }
}

class _ResidentSupportData {
  final List<PackageRecordItem> packages;
  final List<ComplaintTicketItem> complaints;

  const _ResidentSupportData({
    required this.packages,
    required this.complaints,
  });
}
