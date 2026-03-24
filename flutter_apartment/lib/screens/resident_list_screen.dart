import 'package:flutter/material.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../services/download_service.dart';
import '../widgets/common_widgets.dart';

class ResidentListScreen extends StatefulWidget {
  const ResidentListScreen({super.key});

  @override
  State<ResidentListScreen> createState() => _ResidentListScreenState();
}

class _ResidentListScreenState extends State<ResidentListScreen> {
  static const _filters = ['All', 'Active', 'Deactivated'];

  late Future<List<ResidentItem>> _residentsFuture;
  final _draftResidents = <ResidentItem>[];
  final _overrides = <String, ResidentItem>{};
  final _hidden = <String>{};
  final _assignments = <String, String>{};
  final _notifications = <String, int>{};
  final _expandedResidentKeys = <String>{};
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _filter = _filters.first;
  String? _selectedResidentKey;

  @override
  void initState() {
    super.initState();
    _residentsFuture = AppApiService.instance.fetchResidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _residentsFuture = AppApiService.instance.fetchResidents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Resident Management',
      subtitle: 'Create and manage resident records',
      role: UserRole.admin,
      currentIndex: 1,
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _reload),
        ShellAction(icon: Icons.person_add_alt_1_rounded, onPressed: () => _openCreateResidentDialog(context)),
      ],
      body: FutureBuilder<List<ResidentItem>>(
        future: _residentsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load resident management',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final residents = _mergedResidents(snapshot.data ?? const <ResidentItem>[]);
          final filtered = _filteredResidents(residents);
          final activeCount = residents.where((resident) => resident.status == 'Active').length;
          final deactivatedCount = residents.where((resident) => resident.status == 'Deactivated').length;

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
                    MetricCard(label: 'Residents', value: '${residents.length}', icon: Icons.groups_rounded, iconColor: const Color(0xFF137FEC)),
                    MetricCard(label: 'Active', value: '$activeCount', icon: Icons.verified_rounded, iconColor: const Color(0xFF22C55E)),
                    MetricCard(label: 'Deactivated', value: '$deactivatedCount', icon: Icons.block_rounded, iconColor: const Color(0xFFF59E0B)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              AppSearchField(
                hint: 'Search resident management by name, unit, or email',
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final item in _filters) ...[
                      _FilterChip(label: item, active: _filter == item, onTap: () => setState(() => _filter = item)),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Resident Console'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionTile(label: 'Create', icon: Icons.person_add_alt_1_rounded, onTap: () => _openCreateResidentDialog(context), primary: true),
                  ActionTile(label: 'Search', icon: Icons.search_rounded, onTap: _focusSearch),
                  ActionTile(label: 'Export', icon: Icons.download_rounded, onTap: () => _exportResidents(residents)),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting && residents.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                InfoCard(
                  child: Text('No resident management records match the current search/filter.', style: Theme.of(context).textTheme.bodyMedium),
                )
              else
                ...filtered.map((resident) => _residentCard(context, resident)),
            ],
          );
        },
      ),
    );
  }

  Widget _residentCard(BuildContext context, ResidentItem resident) {
    final key = _residentKey(resident);
    final isSelected = key == _selectedResidentKey;
    final isExpanded = _expandedResidentKeys.contains(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => _selectedResidentKey = key),
        child: InfoCard(
          color: isSelected ? const Color(0xFFEAF3FF) : null,
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppAvatar(name: resident.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(resident.name, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                        const SizedBox(height: 4),
                        Text('Unit ${resident.unit} - ${resident.lease}', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(resident.email, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      statusChip(resident.status),
                      const SizedBox(height: 6),
                      Material(
                        color: const Color(0xFFF3F6FA),
                        borderRadius: BorderRadius.circular(999),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedResidentKeys.remove(key);
                              } else {
                                _expandedResidentKeys.add(key);
                              }
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: const Color(0xFF137FEC),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _residentAction(context, icon: Icons.visibility_rounded, label: 'View', onTap: () => _showResidentPreview(resident)),
                    _residentAction(context, icon: Icons.edit_rounded, label: 'Update', onTap: () => _openEditResidentDialog(resident)),
                    if (_isDeactivated(resident.status))
                      _residentAction(context, icon: Icons.restart_alt_rounded, label: 'Activate', onTap: () => _activateResident(resident))
                    else ...[
                      _residentAction(context, icon: Icons.delete_rounded, label: 'Delete', onTap: () => _confirmDeleteResident(resident), destructive: true),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _residentAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? const Color(0xFFEF4444) : const Color(0xFF137FEC);
    return Material(
      color: destructive ? const Color(0xFFFEF2F2) : const Color(0xFFEAF3FF),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF5B6577)),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  List<ResidentItem> _mergedResidents(List<ResidentItem> base) {
    final merged = <ResidentItem>[];
    for (final resident in [...base, ..._draftResidents]) {
      final key = _residentKey(resident);
      if (_hidden.contains(key)) continue;
      merged.add(_overrides[key] ?? resident);
    }
    return merged;
  }

  List<ResidentItem> _filteredResidents(List<ResidentItem> residents) {
    final query = _searchController.text.trim().toLowerCase();
    return residents.where((resident) {
      final matchesQuery = query.isEmpty ||
          resident.name.toLowerCase().contains(query) ||
          resident.unit.toLowerCase().contains(query) ||
          resident.email.toLowerCase().contains(query);
      final matchesFilter = _filter == 'All' || resident.status == _filter;
      return matchesQuery && matchesFilter;
    }).toList()
      ..sort((left, right) {
        final compare = _deactivatedSort(left.status).compareTo(_deactivatedSort(right.status));
        if (compare != 0) return compare;
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
  }

  ResidentItem? _requireSelected(ResidentItem? resident, String message) {
    if (resident == null) {
      showAppSnack(context, message);
      return null;
    }
    return resident;
  }

  ResidentItem _copyResident(
    ResidentItem resident, {
    String? name,
    String? unit,
    String? lease,
    String? email,
    String? status,
  }) {
    return ResidentItem(
      id: resident.id,
      name: name ?? resident.name,
      unit: unit ?? resident.unit,
      lease: lease ?? resident.lease,
      email: email ?? resident.email,
      status: status ?? resident.status,
    );
  }

  String _residentKey(ResidentItem resident) => resident.id?.toString() ?? resident.email.toLowerCase();

  String? _assignmentLabel(ResidentItem resident) => _assignments[_residentKey(resident)];

  int _deactivatedSort(String status) => _isDeactivated(status) ? 1 : 0;

  bool _isDeactivated(String status) => status.toLowerCase() == 'deactivated';

  void _focusSearch() {
    FocusScope.of(context).requestFocus(_searchFocusNode);
    _searchController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _searchController.text.length,
    );
  }

  Future<void> _openCreateResidentDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final unitController = TextEditingController();
    final towerController = TextEditingController(text: 'Skyview Tower');
    final emailController = TextEditingController();
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Create Resident Management'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit Number')),
                const SizedBox(height: 12),
                TextField(controller: towerController, decoration: const InputDecoration(labelText: 'Tower')),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                if (errorMessage != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      errorMessage!,
                      style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(color: const Color(0xFFB91C1C)),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  final navigator = Navigator.of(dialogContext);
                  final created = await AppApiService.instance.createResident(
                    fullName: nameController.text.trim(),
                    unitNumber: unitController.text.trim(),
                    tower: towerController.text.trim(),
                    email: emailController.text.trim(),
                  );
                  if (!mounted) return;
                  navigator.pop();
                  setState(() {
                    _selectedResidentKey = _residentKey(created);
                    _draftResidents.removeWhere(
                        (item) => _residentKey(item) == _residentKey(created));
                    _draftResidents.insert(0, created);
                  });
                  showAppSnack(this.context, 'Resident management created');
                } catch (error) {
                  setModalState(() {
                    errorMessage = error.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openEditResidentDialog(ResidentItem? resident) async {
    final current = _requireSelected(resident, 'Select a resident to update.');
    if (current == null) return;

    final nameController = TextEditingController(text: current.name);
    final unitController = TextEditingController(text: current.unit);
    final emailController = TextEditingController(text: current.email);
    final leaseController = TextEditingController(text: current.lease.replaceFirst('Lease: ', ''));
    String status = current.status;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: Text('Update Resident Management: ${current.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 12),
                TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit Number')),
                const SizedBox(height: 12),
                TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 12),
                TextField(controller: leaseController, decoration: const InputDecoration(labelText: 'Lease Status')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _filters.where((item) => item != 'All').map((item) => DropdownMenuItem(value: item, child: Text(context.tr(item)))).toList(),
                  onChanged: (value) => setModalState(() => status = value ?? current.status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {
                  _overrides[_residentKey(current)] = _copyResident(
                    current,
                    name: nameController.text.trim(),
                    unit: unitController.text.trim(),
                    email: emailController.text.trim(),
                    lease: 'Lease: ${leaseController.text.trim()}',
                    status: status,
                  );
                });
                Navigator.pop(dialogContext);
                showAppSnack(context, 'Resident management updated');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openImportResidentsDialog(BuildContext context) async {
    final controller = TextEditingController(
      text: 'Emily Stone,508,emily.stone@skyline.com,Pending Approval\nMarcus Hall,610,marcus.hall@skyline.com,Active',
    );
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Import Resident Management'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('One resident per line: Full Name,Unit Number,Email,Status'),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: const InputDecoration(hintText: 'Jane Doe,402,jane@example.com,Active'),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage!, style: Theme.of(dialogContext).textTheme.bodySmall?.copyWith(color: const Color(0xFFB91C1C))),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                try {
                  final imported = <ResidentItem>[];
                  for (final line in controller.text.split('\n').map((item) => item.trim()).where((item) => item.isNotEmpty)) {
                    final parts = line.split(',').map((item) => item.trim()).toList();
                    if (parts.length != 4) {
                      throw Exception('Each line must contain 4 comma-separated values.');
                    }
                    imported.add(
                      ResidentItem(
                        name: parts[0],
                        unit: parts[1],
                        email: parts[2],
                        status: parts[3],
                        lease: 'Lease: ${parts[3] == 'Pending Approval' ? 'Pending' : 'Active'}',
                      ),
                    );
                  }
                  setState(() {
                    _draftResidents.addAll(imported);
                    if (imported.isNotEmpty) {
                      _selectedResidentKey = _residentKey(imported.first);
                    }
                  });
                  Navigator.pop(dialogContext);
                  showAppSnack(context, '${imported.length} resident records imported');
                } catch (error) {
                  setModalState(() {
                    errorMessage = error.toString().replaceFirst('Exception: ', '');
                  });
                }
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportResidents(List<ResidentItem> residents) async {
    final content = StringBuffer('Name,Unit,Lease,Email,Status,Assigned To,Notifications\n');
    for (final resident in residents) {
      final key = _residentKey(resident);
      content.writeln(
        '${resident.name},${resident.unit},${resident.lease},${resident.email},${resident.status},${_assignments[key] ?? ''},${_notifications[key] ?? 0}',
      );
    }
    await DownloadService.saveCsvFile(filename: 'resident_management_export', content: content.toString());
    if (mounted) {
      showAppSnack(context, 'Resident management exported');
    }
  }

  Future<void> _showResidentPreview(ResidentItem? resident) async {
    final current = _requireSelected(resident, 'Select a resident to view.');
    if (current == null) return;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('View Resident Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${current.name}'),
            Text('Unit: ${current.unit}'),
            Text('Lease: ${current.lease}'),
            Text('Email: ${current.email}'),
            Text('Status: ${current.status}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close')),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteResident(ResidentItem? resident) async {
    final current = _requireSelected(resident, 'Select a resident to delete.');
    if (current == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Resident Management'),
        content: Text('Deactivate ${current.name} from resident management?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final key = _residentKey(current);
    try {
      if (current.id != null) {
        await AppApiService.instance.deactivateResident(current.id!);
      }
      if (!mounted) return;
      setState(() {
        _overrides[key] = _copyResident(current, status: 'Deactivated', lease: 'Lease: Inactive');
        _expandedResidentKeys.remove(key);
        if (_selectedResidentKey == key) {
          _selectedResidentKey = null;
        }
        _residentsFuture = AppApiService.instance.fetchResidents();
      });
      showAppSnack(context, 'Resident management deactivated');
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _activateResident(ResidentItem? resident) async {
    final current = _requireSelected(resident, 'Select a resident to activate.');
    if (current == null) return;

    try {
      if (current.id != null) {
        await AppApiService.instance.activateResident(current.id!);
      }
      if (!mounted) return;
      setState(() {
        _overrides[_residentKey(current)] = _copyResident(current, status: 'Active', lease: 'Lease: Active');
      });
      _reload();
      showAppSnack(context, 'Resident management activated');
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _approveResident(ResidentItem? resident) {
    final current = _requireSelected(resident, 'Select a resident to approve.');
    if (current == null) return;
    setState(() {
      _overrides[_residentKey(current)] = _copyResident(current, status: 'Active', lease: 'Lease: Active');
    });
    showAppSnack(context, 'Resident management approved');
  }

  void _rejectResident(ResidentItem? resident) {
    final current = _requireSelected(resident, 'Select a resident to reject.');
    if (current == null) return;
    setState(() {
      _overrides[_residentKey(current)] = _copyResident(current, status: 'Rejected', lease: 'Lease: Hold');
    });
    showAppSnack(context, 'Resident management rejected');
  }

  Future<void> _assignResident(ResidentItem? resident) async {
    final current = _requireSelected(resident, 'Select a resident to assign.');
    if (current == null) return;

    final controller = TextEditingController(text: _assignments[_residentKey(current)] ?? 'Resident Care Desk');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Resident Management'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Assigned Manager / Team')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _assignments[_residentKey(current)] = controller.text.trim();
                _overrides[_residentKey(current)] = _copyResident(current, status: 'Assigned');
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Resident management assigned');
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _notifyResident(ResidentItem? resident) async {
    final current = _requireSelected(resident, 'Select a resident to notify.');
    if (current == null) return;

    final messageController = TextEditingController(text: 'Your resident record has been updated.');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notify Resident Management'),
        content: TextField(
          controller: messageController,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Notification Message'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final key = _residentKey(current);
              setState(() {
                _notifications[key] = (_notifications[key] ?? 0) + 1;
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Resident management notification queued');
            },
            child: const Text('Notify'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTracking(List<ResidentItem> residents) async {
    final assigned = residents.where((resident) => resident.status == 'Assigned').length;
    final pending = residents.where((resident) => resident.status == 'Pending Approval').length;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Track Resident Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Residents tracked: ${residents.length}'),
            Text('Assigned residents: $assigned'),
            Text('Pending approvals: $pending'),
            Text('Notifications queued: ${_notifications.values.fold<int>(0, (sum, item) => sum + item)}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _showMonitoring(List<ResidentItem> residents) async {
    final rejected = residents.where((resident) => resident.status == 'Rejected').length;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitor Resident Management', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Rejected residents: $rejected'),
            Text('Latest assignment changes: ${_assignments.length}'),
            const SizedBox(height: 12),
            const Text('Live monitor focuses on onboarding load, pending approvals, and communication backlog.'),
          ],
        ),
      ),
    );
  }

  Future<void> _generateResidentPack(List<ResidentItem> residents) async {
    final content = StringBuffer('metric,value\n');
    content.writeln('resident_records,${residents.length}');
    content.writeln('assignments,${_assignments.length}');
    content.writeln('notifications,${_notifications.values.fold<int>(0, (sum, item) => sum + item)}');
    await DownloadService.saveCsvFile(filename: 'resident_management_pack', content: content.toString());
    if (mounted) {
      showAppSnack(context, 'Resident management pack generated');
    }
  }
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEAF3FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          context.tr(label),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: active ? const Color(0xFF137FEC) : const Color(0xFF8B97AA),
              ),
        ),
      ),
    );
  }
}
