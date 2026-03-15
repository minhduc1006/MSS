import 'package:flutter/material.dart';

import '../core/app_i18n.dart';
import '../core/app_media.dart';
import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class FacilitiesScreen extends StatefulWidget {
  const FacilitiesScreen({super.key});

  @override
  State<FacilitiesScreen> createState() => _FacilitiesScreenState();
}

class _FacilitiesScreenState extends State<FacilitiesScreen> {
  static const _filters = [
    'All',
    'Operational',
    'Maintenance',
    'Pending Approval',
    'Assigned',
    'Rejected',
    'Deactivated'
  ];

  late Future<List<MaintenanceFacility>> _facilitiesFuture;
  final _draftFacilities = <MaintenanceFacility>[];
  final _overrides = <String, MaintenanceFacility>{};
  final _hidden = <String>{};
  final _assignments = <String, String>{};
  final _notifications = <String, int>{};
  final _schedules = <_FacilityScheduleItem>[];
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _filter = _filters.first;
  String? _selectedFacilityKey;
  bool _autoApprove = false;
  bool _liveMonitor = true;

  @override
  void initState() {
    super.initState();
    _facilitiesFuture = AppApiService.instance.fetchFacilities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _facilitiesFuture = AppApiService.instance.fetchFacilities();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Facility & Service Management',
      subtitle:
          'Manage facilities, services, schedules, approvals, and monitoring',
      role: UserRole.admin,
      currentIndex: 3,
      leadingIcon: Icons.arrow_back_ios_new_rounded,
      onLeadingTap: () => Navigator.pushReplacementNamed(context, '/admin'),
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _reload),
        ShellAction(
            icon: Icons.add_business_rounded, onPressed: _createFacility),
      ],
      body: FutureBuilder<List<MaintenanceFacility>>(
        future: _facilitiesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load facility & service management',
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final facilities =
              _mergedFacilities(snapshot.data ?? const <MaintenanceFacility>[]);
          final filtered = _filteredFacilities(facilities);
          final selected = _selectedFacility(facilities);
          final maintenanceCount =
              facilities.where((item) => item.status == 'Maintenance').length;
          final pendingCount = facilities
              .where((item) => item.status == 'Pending Approval')
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
                childAspectRatio: 1.12,
                children: [
                  MetricCard(
                      label: 'Facilities',
                      value: '${facilities.length}',
                      note:
                          '${facilities.where((item) => item.status == 'Operational').length} operational',
                      noteColor: const Color(0xFF22C55E),
                      icon: Icons.apartment_rounded,
                      iconColor: AppTheme.brand),
                  MetricCard(
                      label: 'Attention',
                      value: '$maintenanceCount',
                      note: '$pendingCount pending',
                      noteColor: const Color(0xFFF59E0B),
                      icon: Icons.build_circle_rounded,
                      iconColor: const Color(0xFFF59E0B)),
                ],
              ),
              const SizedBox(height: 16),
              AppSearchField(
                hint:
                    'Search facilities by name, area, status, or assigned team',
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
                      _FilterChip(
                          label: item,
                          active: _filter == item,
                          onTap: () => setState(() => _filter = item)),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const SectionTitle('Facility Console'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionTile(
                      label: 'Create',
                      icon: Icons.add_business_rounded,
                      onTap: _createFacility,
                      primary: true),
                  ActionTile(
                      label: 'Search',
                      icon: Icons.search_rounded,
                      onTap: _focusSearch),
                  ActionTile(
                      label: 'Export',
                      icon: Icons.download_rounded,
                      onTap: () => _exportFacilities(facilities)),
                  ActionTile(
                      label: 'Import',
                      icon: Icons.upload_rounded,
                      onTap: _importFacilities),
                  ActionTile(
                      label: 'Track',
                      icon: Icons.track_changes_rounded,
                      onTap: () => _trackFacilities(facilities)),
                  ActionTile(
                      label: 'Monitor',
                      icon: Icons.monitor_heart_rounded,
                      onTap: () => _monitorFacilities(facilities)),
                  ActionTile(
                      label: 'Generate',
                      icon: Icons.auto_awesome_rounded,
                      onTap: () => _generateFacilities(facilities)),
                  ActionTile(
                      label: 'Manage',
                      icon: Icons.dashboard_customize_rounded,
                      onTap: () => _manageFacilities(facilities, selected)),
                  ActionTile(
                      label: 'Configure',
                      icon: Icons.settings_rounded,
                      onTap: _configureFacilities),
                  ActionTile(
                      label: 'Validate',
                      icon: Icons.fact_check_rounded,
                      onTap: () => _validateFacilities(facilities)),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  facilities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                InfoCard(
                  child: Text('No facilities match the current search/filter.',
                      style: Theme.of(context).textTheme.bodyMedium),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth < 720 ? 1 : 2;
                    final aspectRatio = columns == 1 ? 1.42 : 0.94;
                    if (columns == 1) {
                      return Column(
                        children: [
                          for (final facility in filtered) ...[
                            _facilityCard(
                              context,
                              facility,
                              compactActions: true,
                            ),
                            if (facility != filtered.last)
                              const SizedBox(height: 14),
                          ],
                        ],
                      );
                    }
                    return GridView.builder(
                      itemCount: filtered.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: aspectRatio,
                      ),
                      itemBuilder: (context, index) =>
                          _facilityCard(context, filtered[index]),
                    );
                  },
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _facilityCard(
    BuildContext context,
    MaintenanceFacility facility, {
    bool compactActions = false,
  }) {
    final key = _facilityKey(facility);
    final active = key == _selectedFacilityKey;
    final scheduleCount =
        _schedules.where((item) => item.facilityKey == key).length;
    final notificationCount = _notifications[key] ?? 0;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedFacilityKey = key),
      child: InfoCard(
        color: active ? const Color(0xFFEAF3FF) : null,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  url: AppMedia.facilityImage(facility.name),
                  height: 104,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                Positioned(
                    right: 10, top: 10, child: statusChip(facility.status)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(facility.name,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Text(facility.area ?? facility.lastCheck,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 6),
                  Text(
                      'Health ${facility.health}% - ${facility.logs.length} logs',
                      style: Theme.of(context).textTheme.bodySmall),
                  if (_assignmentLabel(facility) != null) ...[
                    const SizedBox(height: 8),
                    Text(_assignmentLabel(facility)!,
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _pill(
                          context,
                          Icons.event_note_rounded,
                          scheduleCount == 0
                              ? 'No schedules'
                              : '$scheduleCount schedules'),
                      _pill(
                          context,
                          Icons.notifications_rounded,
                          notificationCount == 0
                              ? 'No alerts'
                              : '$notificationCount alerts'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _facilityActionWidgets(
                      context,
                      facility,
                      compactActions: compactActions,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, IconData icon, String label) {
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

  Widget _facilityAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color =
        destructive ? const Color(0xFFEF4444) : const Color(0xFF137FEC);
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
              Text(label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _facilityActionWidgets(
    BuildContext context,
    MaintenanceFacility facility, {
    required bool compactActions,
  }) {
    final widgets = <Widget>[
      _facilityAction(
        context,
        icon: Icons.visibility_rounded,
        label: 'View',
        onTap: () => _viewFacility(facility),
      ),
      _facilityAction(
        context,
        icon: Icons.edit_rounded,
        label: 'Update',
        onTap: () => _updateFacility(facility),
      ),
    ];

    if (_isDeactivated(facility.status)) {
      widgets.add(
        _facilityAction(
          context,
          icon: Icons.restart_alt_rounded,
          label: 'Activate',
          onTap: () => _activateFacility(facility),
        ),
      );
      return widgets;
    }

    widgets.add(
      _facilityAction(
        context,
        icon: Icons.delete_rounded,
        label: 'Delete',
        onTap: () => _deleteFacility(facility),
        destructive: true,
      ),
    );

    if (compactActions) {
      widgets.add(
        _facilityAction(
          context,
          icon: Icons.more_horiz_rounded,
          label: 'Manage',
          onTap: () => _showFacilityActionSheet(facility),
        ),
      );
      return widgets;
    }

    widgets.addAll([
      _facilityAction(
        context,
        icon: Icons.check_circle_rounded,
        label: 'Approve',
        onTap: () => _approveFacility(facility),
      ),
      _facilityAction(
        context,
        icon: Icons.cancel_rounded,
        label: 'Reject',
        onTap: () => _rejectFacility(facility),
      ),
      _facilityAction(
        context,
        icon: Icons.assignment_ind_rounded,
        label: 'Assign',
        onTap: () => _assignFacility(facility),
      ),
      _facilityAction(
        context,
        icon: Icons.event_available_rounded,
        label: 'Schedule',
        onTap: () => _scheduleFacility(facility),
      ),
      _facilityAction(
        context,
        icon: Icons.notifications_active_rounded,
        label: 'Notify',
        onTap: () => _notifyFacility(facility),
      ),
    ]);
    return widgets;
  }

  Future<void> _showFacilityActionSheet(MaintenanceFacility facility) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle_rounded),
                title: Text(context.tr('Approve')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _approveFacility(facility);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_rounded),
                title: Text(context.tr('Reject')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _rejectFacility(facility);
                },
              ),
              ListTile(
                leading: const Icon(Icons.assignment_ind_rounded),
                title: Text(context.tr('Assign')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _assignFacility(facility);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_available_rounded),
                title: Text(context.tr('Schedule')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _scheduleFacility(facility);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded),
                title: Text(context.tr('Notify')),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _notifyFacility(facility);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<MaintenanceFacility> _mergedFacilities(List<MaintenanceFacility> base) {
    final merged = <MaintenanceFacility>[];
    for (final facility in [...base, ..._draftFacilities]) {
      final key = _facilityKey(facility);
      if (_hidden.contains(key)) continue;
      merged.add(_overrides[key] ?? facility);
    }
    return merged;
  }

  List<MaintenanceFacility> _filteredFacilities(
      List<MaintenanceFacility> facilities) {
    final query = _searchController.text.trim().toLowerCase();
    return facilities.where((facility) {
      final assignment =
          (_assignments[_facilityKey(facility)] ?? '').toLowerCase();
      final matchesQuery = query.isEmpty ||
          facility.name.toLowerCase().contains(query) ||
          (facility.area ?? '').toLowerCase().contains(query) ||
          facility.status.toLowerCase().contains(query) ||
          assignment.contains(query);
      final matchesFilter = _filter == 'All' || facility.status == _filter;
      return matchesQuery && matchesFilter;
    }).toList()
      ..sort((left, right) {
        final compare = _deactivatedSort(left.status)
            .compareTo(_deactivatedSort(right.status));
        if (compare != 0) return compare;
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
  }

  MaintenanceFacility? _selectedFacility(List<MaintenanceFacility> facilities) {
    for (final facility in facilities) {
      if (_facilityKey(facility) == _selectedFacilityKey) return facility;
    }
    return null;
  }

  MaintenanceFacility? _requireSelected(
      MaintenanceFacility? facility, String message) {
    if (facility == null) {
      showAppSnack(context, message);
      return null;
    }
    return facility;
  }

  String _facilityKey(MaintenanceFacility facility) =>
      facility.id?.toString() ??
      '${facility.name}|${facility.area ?? facility.lastCheck}';

  String? _assignmentLabel(MaintenanceFacility facility) =>
      _assignments[_facilityKey(facility)];

  int _deactivatedSort(String status) => _isDeactivated(status) ? 1 : 0;

  bool _isDeactivated(String status) => status.toLowerCase() == 'deactivated';

  MaintenanceFacility _copyFacility(
    MaintenanceFacility facility, {
    String? name,
    String? status,
    String? lastCheck,
    int? health,
    List<String>? logs,
    String? area,
  }) {
    return MaintenanceFacility(
      id: facility.id,
      name: name ?? facility.name,
      status: status ?? facility.status,
      lastCheck: lastCheck ?? facility.lastCheck,
      health: health ?? facility.health,
      logs: logs ?? facility.logs,
      area: area ?? facility.area,
      icon: facility.icon,
    );
  }

  void _focusSearch() {
    FocusScope.of(context).requestFocus(_searchFocusNode);
    showAppSnack(context, 'Facility & service management search is ready');
  }

  Future<void> _createFacility() async {
    final nameController = TextEditingController();
    final areaController = TextEditingController(text: 'Level 1');
    final healthController = TextEditingController(text: '92');
    bool requireApproval = !_autoApprove;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Create Facility & Service Management'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Facility Name')),
                const SizedBox(height: 12),
                TextField(
                    controller: areaController,
                    decoration: const InputDecoration(labelText: 'Area')),
                const SizedBox(height: 12),
                TextField(
                    controller: healthController,
                    decoration:
                        const InputDecoration(labelText: 'Health Score')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Require approval'),
                  value: requireApproval,
                  onChanged: (value) =>
                      setModalState(() => requireApproval = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final facility = MaintenanceFacility(
                  name: nameController.text.trim(),
                  status: requireApproval ? 'Pending Approval' : 'Operational',
                  lastCheck: 'Just now',
                  health: int.tryParse(healthController.text.trim()) ?? 0,
                  logs: const ['Created from admin console'],
                  area: areaController.text.trim(),
                );
                setState(() {
                  _draftFacilities.add(facility);
                  _selectedFacilityKey = _facilityKey(facility);
                });
                Navigator.pop(dialogContext);
                showAppSnack(context, 'Facility & service management created');
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateFacility(MaintenanceFacility? facility) async {
    final current = _requireSelected(facility, 'Select a facility to update.');
    if (current == null) return;
    final nameController = TextEditingController(text: current.name);
    final areaController = TextEditingController(text: current.area ?? '');
    final healthController =
        TextEditingController(text: current.health.toString());
    String status = current.status;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Update Facility & Service Management'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration:
                        const InputDecoration(labelText: 'Facility Name')),
                const SizedBox(height: 12),
                TextField(
                    controller: areaController,
                    decoration: const InputDecoration(labelText: 'Area')),
                const SizedBox(height: 12),
                TextField(
                    controller: healthController,
                    decoration:
                        const InputDecoration(labelText: 'Health Score')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _filters
                      .where((item) => item != 'All')
                      .map((item) => DropdownMenuItem(
                          value: item, child: Text(context.tr(item))))
                      .toList(),
                  onChanged: (value) =>
                      setModalState(() => status = value ?? current.status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {
                  _overrides[_facilityKey(current)] = _copyFacility(
                    current,
                    name: nameController.text.trim(),
                    area: areaController.text.trim(),
                    health: int.tryParse(healthController.text.trim()) ??
                        current.health,
                    status: status,
                  );
                });
                Navigator.pop(dialogContext);
                showAppSnack(context, 'Facility & service management updated');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteFacility(MaintenanceFacility? facility) async {
    final current = _requireSelected(facility, 'Select a facility to delete.');
    if (current == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Facility & Service Management'),
        content: Text('Deactivate ${current.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete != true) return;
    if (!mounted) return;
    setState(() {
      final key = _facilityKey(current);
      _overrides[key] = _copyFacility(current, status: 'Deactivated');
      if (_selectedFacilityKey == key) {
        _selectedFacilityKey = null;
      }
    });
    showAppSnack(context, 'Facility & service management deactivated');
  }

  void _activateFacility(MaintenanceFacility? facility) {
    final current =
        _requireSelected(facility, 'Select a facility to activate.');
    if (current == null) return;
    setState(() {
      _overrides[_facilityKey(current)] =
          _copyFacility(current, status: 'Operational');
    });
    showAppSnack(context, 'Facility & service management activated');
  }

  Future<void> _viewFacility(MaintenanceFacility? facility) async {
    final current = _requireSelected(facility, 'Select a facility to view.');
    if (current == null) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('View Facility & Service Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Facility: ${current.name}'),
            Text('Area: ${current.area ?? '-'}'),
            Text('Status: ${current.status}'),
            Text('Health: ${current.health}%'),
            Text('Assigned to: ${_assignmentLabel(current) ?? 'Unassigned'}'),
            Text(
                'Logs: ${current.logs.isEmpty ? 'None' : current.logs.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'))
        ],
      ),
    );
  }

  void _approveFacility(MaintenanceFacility? facility) {
    final current = _requireSelected(facility, 'Select a facility to approve.');
    if (current == null) return;
    setState(() {
      _overrides[_facilityKey(current)] =
          _copyFacility(current, status: 'Operational');
    });
    showAppSnack(context, 'Facility & service management approved');
  }

  void _rejectFacility(MaintenanceFacility? facility) {
    final current = _requireSelected(facility, 'Select a facility to reject.');
    if (current == null) return;
    setState(() {
      _overrides[_facilityKey(current)] =
          _copyFacility(current, status: 'Rejected');
    });
    showAppSnack(context, 'Facility & service management rejected');
  }

  Future<void> _assignFacility(MaintenanceFacility? facility) async {
    final current = _requireSelected(facility, 'Select a facility to assign.');
    if (current == null) return;
    final controller = TextEditingController(
        text: _assignments[_facilityKey(current)] ?? 'Maintenance Team');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Facility & Service Management'),
        content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Assigned Team')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _assignments[_facilityKey(current)] = controller.text.trim();
                _overrides[_facilityKey(current)] =
                    _copyFacility(current, status: 'Assigned');
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Facility & service management assigned');
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleFacility(MaintenanceFacility? facility) async {
    final current =
        _requireSelected(facility, 'Select a facility to schedule.');
    if (current == null) return;
    final titleController = TextEditingController(text: 'Maintenance window');
    final dateController = TextEditingController(text: 'Friday 10:00 AM');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Schedule Facility & Service Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Schedule Title')),
            const SizedBox(height: 12),
            TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date / Slot')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _schedules.add(_FacilityScheduleItem(
                    facilityKey: _facilityKey(current),
                    title: titleController.text.trim(),
                    dateLabel: dateController.text.trim()));
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Facility & service management scheduled');
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _notifyFacility(MaintenanceFacility? facility) async {
    final current = _requireSelected(facility, 'Select a facility to notify.');
    if (current == null) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notify Facility & Service Management'),
        content: Text('Notify teams about ${current.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final key = _facilityKey(current);
              setState(() {
                _notifications[key] = (_notifications[key] ?? 0) + 1;
              });
              Navigator.pop(dialogContext);
              showAppSnack(
                  context, 'Facility & service management notification queued');
            },
            child: const Text('Notify'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportFacilities(List<MaintenanceFacility> facilities) async {
    final content = StringBuffer(
        'Name,Area,Status,Health,Assigned To,Schedules,Notifications\n');
    for (final facility in facilities) {
      final key = _facilityKey(facility);
      content.writeln(
          '${facility.name},${facility.area ?? ''},${facility.status},${facility.health},${_assignments[key] ?? ''},${_schedules.where((item) => item.facilityKey == key).length},${_notifications[key] ?? 0}');
    }
    await DownloadService.saveCsvFile(
        filename: 'facility_service_management_export',
        content: content.toString());
    if (mounted) {
      showAppSnack(context, 'Facility & service management exported');
    }
  }

  Future<void> _importFacilities() async {
    final controller = TextEditingController(
      text:
          'Sky Lounge,Level 32,Operational,95\nIndoor Court,Level 5,Pending Approval,84',
    );
    String? errorMessage;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Import Facility & Service Management'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('One facility per line: Name,Area,Status,Health'),
                const SizedBox(height: 12),
                TextField(controller: controller, maxLines: 6),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(errorMessage!,
                      style: Theme.of(dialogContext)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: const Color(0xFFB91C1C))),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                try {
                  final imported = <MaintenanceFacility>[];
                  for (final line in controller.text
                      .split('\n')
                      .map((item) => item.trim())
                      .where((item) => item.isNotEmpty)) {
                    final parts =
                        line.split(',').map((item) => item.trim()).toList();
                    if (parts.length != 4) {
                      throw Exception(
                          'Each line must contain 4 comma-separated values.');
                    }
                    imported.add(
                      MaintenanceFacility(
                        name: parts[0],
                        area: parts[1],
                        status: parts[2],
                        health: int.tryParse(parts[3]) ?? 0,
                        lastCheck: 'Imported now',
                        logs: const ['Imported from facility console'],
                      ),
                    );
                  }
                  setState(() {
                    _draftFacilities.addAll(imported);
                    if (imported.isNotEmpty) {
                      _selectedFacilityKey = _facilityKey(imported.first);
                    }
                  });
                  Navigator.pop(dialogContext);
                  showAppSnack(
                      context, '${imported.length} facility records imported');
                } catch (error) {
                  setModalState(() {
                    errorMessage =
                        error.toString().replaceFirst('Exception: ', '');
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

  Future<void> _trackFacilities(List<MaintenanceFacility> facilities) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Track Facility & Service Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Facilities tracked: ${facilities.length}'),
            Text('Schedules prepared: ${_schedules.length}'),
            Text(
                'Notifications queued: ${_notifications.values.fold<int>(0, (sum, item) => sum + item)}'),
            Text('Assigned teams: ${_assignments.length}'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'))
        ],
      ),
    );
  }

  Future<void> _monitorFacilities(List<MaintenanceFacility> facilities) async {
    final rejected =
        facilities.where((item) => item.status == 'Rejected').length;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitor Facility & Service Management',
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Live monitor: ${_liveMonitor ? 'Enabled' : 'Disabled'}'),
            Text('Rejected facilities: $rejected'),
            Text(
                'Health average: ${facilities.isEmpty ? 0 : (facilities.fold<int>(0, (sum, item) => sum + item.health) / facilities.length).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    );
  }

  Future<void> _generateFacilities(List<MaintenanceFacility> facilities) async {
    final content = StringBuffer('metric,value\n');
    content.writeln('facility_records,${facilities.length}');
    content.writeln('schedules,${_schedules.length}');
    content.writeln(
        'notifications,${_notifications.values.fold<int>(0, (sum, item) => sum + item)}');
    content.writeln(
        'average_health,${facilities.isEmpty ? 0 : (facilities.fold<int>(0, (sum, item) => sum + item.health) / facilities.length).toStringAsFixed(2)}');
    await DownloadService.saveCsvFile(
        filename: 'facility_service_management_pack',
        content: content.toString());
    if (mounted) {
      showAppSnack(context, 'Facility & service management pack generated');
    }
  }

  Future<void> _manageFacilities(List<MaintenanceFacility> facilities,
      MaintenanceFacility? selected) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Facility & Service Management',
                style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Selected facility: ${selected?.name ?? 'None'}'),
            Text('Assigned teams: ${_assignments.length}'),
            Text('Prepared schedules: ${_schedules.length}'),
            Text(
                'Operational facilities: ${facilities.where((item) => item.status == 'Operational').length}'),
          ],
        ),
      ),
    );
  }

  Future<void> _configureFacilities() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Configure Facility & Service Management'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto approve new facilities'),
                value: _autoApprove,
                onChanged: (value) => setModalState(() => _autoApprove = value),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Live monitoring'),
                value: _liveMonitor,
                onChanged: (value) => setModalState(() => _liveMonitor = value),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(dialogContext);
                showAppSnack(
                    context, 'Facility & service management configured');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateFacilities(List<MaintenanceFacility> facilities) async {
    final issues = <String>[];
    for (final facility in facilities) {
      if (facility.health < 50) {
        issues.add('${facility.name} health is below 50%.');
      }
      if (facility.status == 'Assigned' &&
          (_assignments[_facilityKey(facility)] ?? '').isEmpty) {
        issues.add('${facility.name} is assigned without a team.');
      }
    }
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Validate Facility & Service Management'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Facilities checked: ${facilities.length}'),
            Text('Schedules checked: ${_schedules.length}'),
            const SizedBox(height: 12),
            if (issues.isEmpty)
              const Text('No validation issues found.')
            else
              ...issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('- $issue'),
                  )),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'))
        ],
      ),
    );
  }
}

class _FacilityScheduleItem {
  final String facilityKey;
  final String title;
  final String dateLabel;

  const _FacilityScheduleItem({
    required this.facilityKey,
    required this.title,
    required this.dateLabel,
  });
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
                color:
                    active ? const Color(0xFF137FEC) : const Color(0xFF8B97AA),
              ),
        ),
      ),
    );
  }
}
