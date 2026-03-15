import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../services/download_service.dart';
import '../widgets/common_widgets.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  static const _statusOptions = ['All', 'On Duty', 'Off Duty', 'Deactivated'];
  static const _shiftOptions = ['All', 'Day', 'Night'];

  late Future<List<StaffItem>> _staffFuture;
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = _statusOptions.first;
  String _shiftFilter = _shiftOptions.first;

  @override
  void initState() {
    super.initState();
    _staffFuture = AppApiService.instance.fetchStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _staffFuture = AppApiService.instance.fetchStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Staff Directory',
      subtitle: 'Operations team management',
      role: UserRole.admin,
      currentIndex: 0,
      showBottomNav: false,
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _reload),
        ShellAction(icon: Icons.person_add_alt_1_rounded, onPressed: () => _openStaffDialog(context)),
      ],
      body: FutureBuilder<List<StaffItem>>(
        future: _staffFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load staff directory',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final staff = snapshot.data ?? const <StaffItem>[];
          final filtered = _filteredStaff(staff);
          final onDutyCount = staff.where((member) => member.status.toLowerCase().contains('on duty')).length;
          final dayShiftCount = staff.where((member) => member.shift.toLowerCase().contains('day')).length;

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
                  childAspectRatio: constraints.maxWidth < 420 ? 1.12 : 0.92,
                  children: [
                    MetricCard(label: 'Staff', value: '${staff.length}', icon: Icons.badge_rounded, iconColor: const Color(0xFF137FEC)),
                    MetricCard(label: 'On Duty', value: '$onDutyCount', icon: Icons.check_circle_rounded, iconColor: const Color(0xFF22C55E)),
                    MetricCard(label: 'Day Shift', value: '$dayShiftCount', icon: Icons.wb_sunny_rounded, iconColor: const Color(0xFFF59E0B)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSearchField(
                hint: 'Search by staff name, title, email, or phone',
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              ResponsiveButtonBar(
                maxColumns: 3,
                spacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _openStaffDialog(context),
                    icon: const Icon(Icons.person_add_alt_1_rounded),
                    label: const Text('Add Staff'),
                  ),
                  OutlinedButton.icon(
                    onPressed: staff.isEmpty ? null : () => _exportStaff(staff),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Export'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _statusFilter = _statusOptions.first;
                        _shiftFilter = _shiftOptions.first;
                      });
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded),
                    label: const Text('Reset Filters'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option in _statusOptions) ...[
                      _FilterChip(
                        label: option,
                        active: _statusFilter == option,
                        onTap: () => setState(() => _statusFilter = option),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const SizedBox(width: 8),
                    for (final option in _shiftOptions) ...[
                      _FilterChip(
                        label: option == 'All' ? 'All Shifts' : '$option Shift',
                        active: _shiftFilter == option,
                        onTap: () => setState(() => _shiftFilter = option),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting && staff.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No staff match your filters', style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Text(
                        'Try a different search term or clear the status and shift filters.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              else
                ...filtered.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppAvatar(name: member.name),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      member.name,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${member.role} - ${member.shift} shift', style: Theme.of(context).textTheme.bodyMedium),
                                  ],
                                ),
                              ),
                              statusChip(member.status),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('CONTACT', style: Theme.of(context).textTheme.bodySmall),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(minWidth: 180, maxWidth: 240),
                                child: Text(member.email, style: Theme.of(context).textTheme.bodyLarge),
                              ),
                              Text(member.phone, style: Theme.of(context).textTheme.bodyMedium),
                              _miniAction(context, Icons.visibility_rounded, () => _showStaffDetails(context, member)),
                              _miniAction(context, Icons.edit_rounded, () => _openStaffDialog(context, existing: member)),
                              if (_isDeactivated(member.status))
                                _miniAction(context, Icons.restart_alt_rounded, () => _activateStaff(member))
                              else
                                _miniAction(context, Icons.delete_rounded, () => _confirmDeleteStaff(member)),
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

  List<StaffItem> _filteredStaff(List<StaffItem> staff) {
    final query = _searchController.text.trim().toLowerCase();
    return staff.where((member) {
      final matchesQuery = query.isEmpty ||
          member.name.toLowerCase().contains(query) ||
          member.role.toLowerCase().contains(query) ||
          member.email.toLowerCase().contains(query) ||
          member.phone.toLowerCase().contains(query);
      final matchesStatus = _statusFilter == 'All' || member.status == _statusFilter;
      final matchesShift = _shiftFilter == 'All' || member.shift == _shiftFilter;
      return matchesQuery && matchesStatus && matchesShift;
    }).toList()
      ..sort((left, right) {
        final compare = _deactivatedSort(left.status).compareTo(_deactivatedSort(right.status));
        if (compare != 0) return compare;
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
  }

  Future<void> _openStaffDialog(BuildContext context, {StaffItem? existing}) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    final jobTitleController = TextEditingController(text: existing?.role ?? '');
    final emailController = TextEditingController(text: existing?.email ?? '');
    final phoneController = TextEditingController(text: existing?.phone ?? '');
    String selectedShift = existing?.shift.isNotEmpty == true ? existing!.shift : 'Day';
    String selectedStatus = existing?.status.isNotEmpty == true ? existing!.status : 'On Duty';
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add Staff Member' : 'Edit Staff Member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: jobTitleController, decoration: const InputDecoration(labelText: 'Job Title')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedShift,
                  decoration: const InputDecoration(labelText: 'Shift'),
                  items: const [
                    DropdownMenuItem(value: 'Day', child: Text('Day')),
                    DropdownMenuItem(value: 'Night', child: Text('Night')),
                  ],
                  onChanged: (value) => setModalState(() => selectedShift = value ?? 'Day'),
                ),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone')),
                if (existing != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'On Duty', child: Text('On Duty')),
                      DropdownMenuItem(value: 'Off Duty', child: Text('Off Duty')),
                      DropdownMenuItem(value: 'Deactivated', child: Text('Deactivated')),
                    ],
                    onChanged: (value) => setModalState(() => selectedStatus = value ?? 'On Duty'),
                  ),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorMessage!,
                      style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(color: const Color(0xFFB91C1C)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  final navigator = Navigator.of(dialogContext);
                  if (existing == null) {
                    await AppApiService.instance.createStaff(
                      fullName: nameController.text.trim(),
                      jobTitle: jobTitleController.text.trim(),
                      shift: selectedShift,
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                    );
                  } else {
                    await AppApiService.instance.updateStaff(
                      staffId: existing.id!,
                      fullName: nameController.text.trim(),
                      jobTitle: jobTitleController.text.trim(),
                      shift: selectedShift,
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim(),
                      status: selectedStatus,
                    );
                  }
                  if (!mounted) {
                    return;
                  }
                  navigator.pop();
                  _reload();
                  showAppSnack(this.context, existing == null ? 'Staff member created' : 'Staff member updated');
                } catch (error) {
                  setModalState(() {
                    errorMessage = error.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              child: Text(existing == null ? 'Create' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStaffDetails(BuildContext context, StaffItem member) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(member.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${member.role}'),
            Text('Shift: ${member.shift}'),
            Text('Email: ${member.email}'),
            Text('Phone: ${member.phone}'),
            Text('Status: ${member.status}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteStaff(StaffItem member) async {
    if (member.id == null) {
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text('Deactivate ${member.name} from the staff directory?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete != true) {
      return;
    }

    try {
      await AppApiService.instance.deactivateStaff(member.id!);
      if (!mounted) {
        return;
      }
      _reload();
      showAppSnack(context, '${member.name} deactivated');
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _activateStaff(StaffItem member) async {
    if (member.id == null) return;
    try {
      await AppApiService.instance.activateStaff(member.id!);
      if (!mounted) return;
      _reload();
      showAppSnack(context, '${member.name} activated');
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _exportStaff(List<StaffItem> staff) async {
    final content = StringBuffer('Name,Title,Shift,Email,Phone,Status\n');
    for (final member in staff) {
      content.writeln('${member.name},${member.role},${member.shift},${member.email},${member.phone},${member.status}');
    }
    await DownloadService.saveCsvFile(filename: 'staff_directory', content: content.toString());
    if (mounted) {
      showAppSnack(context, 'Staff directory exported');
    }
  }

  Widget _miniAction(BuildContext context, IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFF3F6FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }

  int _deactivatedSort(String status) => _isDeactivated(status) ? 1 : 0;

  bool _isDeactivated(String status) => status.toLowerCase() == 'deactivated';
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? const Color(0xFFEAF3FF) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: active ? const Color(0xFF137FEC) : const Color(0xFF8B97AA),
                ),
          ),
        ),
      ),
    );
  }
}
