import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../widgets/common_widgets.dart';

class AdminOperationsHubScreen extends StatefulWidget {
  const AdminOperationsHubScreen({super.key});

  @override
  State<AdminOperationsHubScreen> createState() =>
      _AdminOperationsHubScreenState();
}

class _AdminOperationsHubScreenState extends State<AdminOperationsHubScreen> {
  late Future<_OpsBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_OpsBundle> _load() async {
    final results = await Future.wait<dynamic>([
      AppApiService.instance.fetchPackages(),
      AppApiService.instance.fetchComplaints(),
      AppApiService.instance.fetchShifts(),
      AppApiService.instance.fetchStaff(),
    ]);
    return _OpsBundle(
      packages: results[0] as List<PackageRecordItem>,
      complaints: results[1] as List<ComplaintTicketItem>,
      shifts: results[2] as List<StaffShiftItem>,
      staff: results[3] as List<StaffItem>,
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Operations Hub',
      subtitle: 'Packages, complaints, and duty roster',
      role: UserRole.admin,
      currentIndex: 0,
      showBottomNav: false,
      actions: [ShellAction(icon: Icons.refresh_rounded, onPressed: _reload)],
      body: FutureBuilder<_OpsBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load operations hub',
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
          final onDuty =
              data.shifts.where((item) => item.status == 'On Duty').length;

          return DefaultTabController(
            length: 3,
            child: ListView(
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
                      value: '${data.packages.length}',
                      note: 'Parcel and lost-found queue',
                      icon: Icons.inventory_2_rounded,
                      iconColor: const Color(0xFF137FEC),
                    ),
                    MetricCard(
                      label: 'Complaints',
                      value: '$openComplaints',
                      note: '${data.complaints.length} total tickets',
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFFEF4444),
                    ),
                    MetricCard(
                      label: 'On Duty',
                      value: '$onDuty',
                      note: '${data.shifts.length} roster entries',
                      icon: Icons.badge_rounded,
                      iconColor: const Color(0xFF22C55E),
                    ),
                    MetricCard(
                      label: 'Team Size',
                      value: '${data.staff.length}',
                      note: 'Assignable staff records',
                      icon: Icons.groups_rounded,
                      iconColor: const Color(0xFFA855F7),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ResponsiveButtonBar(
                  children: [
                    FilledButton.icon(
                      onPressed: () => _showCreatePackageSheet(data),
                      icon: const Icon(Icons.add_box_rounded),
                      label: const Text('Log Package'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showCreateShiftSheet(data),
                      icon: const Icon(Icons.schedule_rounded),
                      label: const Text('Create Shift'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(context).cardColor,
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: const TabBar(
                    tabs: [
                      Tab(text: 'Packages'),
                      Tab(text: 'Complaints'),
                      Tab(text: 'Roster'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.58,
                  child: TabBarView(
                    children: [
                      _packageList(data.packages),
                      _complaintList(data),
                      _shiftList(data.shifts),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _packageList(List<PackageRecordItem> packages) {
    if (packages.isEmpty) {
      return const InfoCard(child: Text('No package records available.'));
    }
    return ListView.separated(
      itemCount: packages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = packages[index];
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
              Text(
                  '${item.unitNumber ?? 'Common Area'} • ${item.location} • ${item.receivedAt}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _pill(
                    'Ready',
                    () => _setPackageStatus(item, 'Ready for Pickup'),
                  ),
                  _pill(
                    'Claimed',
                    () => _setPackageStatus(item, 'Claimed'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _complaintList(_OpsBundle data) {
    if (data.complaints.isEmpty) {
      return const InfoCard(child: Text('No complaint tickets available.'));
    }
    return ListView.separated(
      itemCount: data.complaints.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = data.complaints[index];
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${item.title} • ${item.unitNumber}',
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
                  'Priority ${item.priority} • ${item.assignedStaffName ?? 'Unassigned'}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  if (item.assignedStaffId == null)
                    _pill('Assign', () => _assignComplaint(item, data.staff)),
                  _pill(
                    'Resolve',
                    () => _setComplaintStatus(item, 'Resolved'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shiftList(List<StaffShiftItem> shifts) {
    if (shifts.isEmpty) {
      return const InfoCard(child: Text('No roster entries available.'));
    }
    return ListView.separated(
      itemCount: shifts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final shift = shifts[index];
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${shift.staffName} • ${shift.shiftDate}',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  statusChip(shift.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  '${shift.shiftLabel} shift • ${shift.startTime}-${shift.endTime} • ${shift.zone}',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        );
      },
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

  Future<void> _showCreatePackageSheet(_OpsBundle data) async {
    final residentPackages =
        data.packages.where((item) => item.residentId != null).toList();
    PackageRecordItem? selectedResidentPackage =
        residentPackages.isNotEmpty ? residentPackages.first : null;
    String recordType = 'Parcel';
    final itemNameController = TextEditingController();
    final carrierController = TextEditingController(text: 'Front Desk');
    final locationController = TextEditingController(text: 'Mailroom Shelf A');
    final trackingController = TextEditingController();
    final reporterController = TextEditingController(text: 'Operations Hub');
    final noteController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Log Package',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: recordType,
                items: const ['Parcel', 'Lost & Found']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => recordType = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Record Type'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PackageRecordItem?>(
                initialValue: selectedResidentPackage,
                items: [
                  const DropdownMenuItem<PackageRecordItem?>(
                    value: null,
                    child: Text('Common Area / No Resident'),
                  ),
                  ...residentPackages.map(
                    (item) => DropdownMenuItem<PackageRecordItem?>(
                      value: item,
                      child: Text(
                        '${item.residentName ?? 'Resident'} • ${item.unitNumber ?? 'N/A'}',
                      ),
                    ),
                  ),
                ],
                onChanged: (value) =>
                    setModalState(() => selectedResidentPackage = value),
                decoration:
                    const InputDecoration(labelText: 'Resident / Unit'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: itemNameController,
                decoration: const InputDecoration(labelText: 'Item Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: carrierController,
                decoration: const InputDecoration(labelText: 'Carrier'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: trackingController,
                decoration: const InputDecoration(labelText: 'Tracking Code'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reporterController,
                decoration: const InputDecoration(labelText: 'Reported By'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (itemNameController.text.trim().isEmpty ||
                            locationController.text.trim().isEmpty) {
                          showAppSnack(
                              sheetContext, 'Please complete the package form');
                          return;
                        }
                        setModalState(() => isSubmitting = true);
                        try {
                          final created =
                              await AppApiService.instance.createPackageRecord(
                            residentId: selectedResidentPackage?.residentId,
                            residentName: selectedResidentPackage?.residentName,
                            unitNumber: selectedResidentPackage?.unitNumber,
                            recordType: recordType,
                            carrier: carrierController.text.trim().isEmpty
                                ? null
                                : carrierController.text.trim(),
                            itemName: itemNameController.text.trim(),
                            trackingCode: trackingController.text.trim().isEmpty
                                ? null
                                : trackingController.text.trim(),
                            location: locationController.text.trim(),
                            reportedByName: reporterController.text.trim(),
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          );
                          if (!mounted || !sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          setState(
                            () => _future = Future.value(
                              _OpsBundle(
                                packages: [created, ...data.packages],
                                complaints: data.complaints,
                                shifts: data.shifts,
                                staff: data.staff,
                              ),
                            ),
                          );
                          showAppSnack(context, 'Package record created');
                        } catch (error) {
                          if (!sheetContext.mounted) return;
                          setModalState(() => isSubmitting = false);
                          showAppSnack(sheetContext,
                              error.toString().replaceFirst('Exception: ', ''));
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Package'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setPackageStatus(
      PackageRecordItem item, String status) async {
    final updated = await AppApiService.instance.updatePackageRecordStatus(
      packageId: item.id!,
      status: status,
    );
    if (!mounted) return;
    final data = await _future;
    setState(
      () => _future = Future.value(
        _OpsBundle(
          packages: data.packages
              .map((entry) => entry.id == updated.id ? updated : entry)
              .toList(),
          complaints: data.complaints,
          shifts: data.shifts,
          staff: data.staff,
        ),
      ),
    );
    if (!mounted) return;
    showAppSnack(context, 'Package status updated');
  }

  Future<void> _assignComplaint(
      ComplaintTicketItem item, List<StaffItem> staff) async {
    final candidates = staff.where((member) => member.id != null).toList();
    if (candidates.isEmpty) {
      showAppSnack(context, 'No staff records available for assignment');
      return;
    }

    StaffItem selected = candidates.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Complaint'),
        content: DropdownButtonFormField<StaffItem>(
          initialValue: selected,
          items: candidates
              .map(
                (member) => DropdownMenuItem(
                  value: member,
                  child: Text('${member.name} • ${member.role}'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value != null) {
              selected = value;
            }
          },
          decoration: const InputDecoration(labelText: 'Assign to'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final updated = await AppApiService.instance.assignComplaint(
      complaintId: item.id!,
      staffId: selected.id!,
      staffName: selected.name,
    );
    if (!mounted) return;
    final data = await _future;
    if (!mounted) return;
    setState(
      () => _future = Future.value(
        _OpsBundle(
          packages: data.packages,
          complaints: data.complaints
              .map((entry) => entry.id == updated.id ? updated : entry)
              .toList(),
          shifts: data.shifts,
          staff: data.staff,
        ),
      ),
    );
    showAppSnack(context, 'Complaint assigned');
  }

  Future<void> _setComplaintStatus(
      ComplaintTicketItem item, String status) async {
    final updated = await AppApiService.instance.updateComplaintStatus(
      complaintId: item.id!,
      status: status,
      responseNote: 'Updated from admin operations hub.',
    );
    if (!mounted) return;
    final data = await _future;
    if (!mounted) return;
    setState(
      () => _future = Future.value(
        _OpsBundle(
          packages: data.packages,
          complaints: data.complaints
              .map((entry) => entry.id == updated.id ? updated : entry)
              .toList(),
          shifts: data.shifts,
          staff: data.staff,
        ),
      ),
    );
    showAppSnack(context, 'Complaint updated');
  }

  Future<void> _showCreateShiftSheet(_OpsBundle data) async {
    final candidates = data.staff.where((item) => item.id != null).toList();
    if (candidates.isEmpty) {
      showAppSnack(context, 'No staff records available for roster creation');
      return;
    }

    StaffItem selectedStaff = candidates.first;
    DateTime shiftDate = DateTime.now().add(const Duration(days: 1));
    String shiftLabel =
        selectedStaff.shift.isEmpty ? 'Day' : selectedStaff.shift;
    final zoneController = TextEditingController(text: 'Main Lobby');
    final startController = TextEditingController(text: '08:00');
    final endController = TextEditingController(text: '17:00');
    final noteController =
        TextEditingController(text: 'Created from operations hub.');
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create Shift',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<StaffItem>(
                initialValue: selectedStaff,
                items: candidates
                    .map(
                      (member) => DropdownMenuItem(
                        value: member,
                        child: Text('${member.name} • ${member.role}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() {
                      selectedStaff = value;
                      shiftLabel = value.shift.isEmpty ? 'Day' : value.shift;
                    });
                  }
                },
                decoration: const InputDecoration(labelText: 'Staff Member'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: shiftDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setModalState(() => shiftDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text(DateFormat('MMM d, yyyy').format(shiftDate)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: shiftLabel,
                items: const ['Day', 'Night', 'Swing']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => shiftLabel = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Shift Label'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: zoneController,
                decoration: const InputDecoration(labelText: 'Zone'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startController,
                      decoration:
                          const InputDecoration(labelText: 'Start Time'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: endController,
                      decoration: const InputDecoration(labelText: 'End Time'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (zoneController.text.trim().isEmpty ||
                            startController.text.trim().isEmpty ||
                            endController.text.trim().isEmpty) {
                          showAppSnack(
                              sheetContext, 'Please complete the shift form');
                          return;
                        }
                        setModalState(() => isSubmitting = true);
                        try {
                          final created =
                              await AppApiService.instance.createStaffShift(
                            staffId: selectedStaff.id!,
                            staffName: selectedStaff.name,
                            role: selectedStaff.role,
                            shiftDate: shiftDate,
                            shiftLabel: shiftLabel,
                            zone: zoneController.text.trim(),
                            startTime: startController.text.trim(),
                            endTime: endController.text.trim(),
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          );
                          if (!mounted || !sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          setState(
                            () => _future = Future.value(
                              _OpsBundle(
                                packages: data.packages,
                                complaints: data.complaints,
                                shifts: [created, ...data.shifts],
                                staff: data.staff,
                              ),
                            ),
                          );
                          showAppSnack(context, 'Shift created');
                        } catch (error) {
                          if (!sheetContext.mounted) return;
                          setModalState(() => isSubmitting = false);
                          showAppSnack(sheetContext,
                              error.toString().replaceFirst('Exception: ', ''));
                        }
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Shift'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpsBundle {
  final List<PackageRecordItem> packages;
  final List<ComplaintTicketItem> complaints;
  final List<StaffShiftItem> shifts;
  final List<StaffItem> staff;

  const _OpsBundle({
    required this.packages,
    required this.complaints,
    required this.shifts,
    required this.staff,
  });
}
