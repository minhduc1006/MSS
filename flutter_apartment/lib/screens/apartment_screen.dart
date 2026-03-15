import 'package:flutter/material.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../services/download_service.dart';
import '../widgets/common_widgets.dart';

class ApartmentScreen extends StatefulWidget {
  const ApartmentScreen({super.key});

  @override
  State<ApartmentScreen> createState() => _ApartmentScreenState();
}

class _ApartmentScreenState extends State<ApartmentScreen> {
  static const _filters = [
    'All',
    'Occupied',
    'Vacant',
    'Pending Approval',
    'Rejected',
    'Assigned',
    'Deactivated'
  ];

  late Future<ApartmentStatsData> _statsFuture;
  final _draftUnits = <ApartmentUnitItem>[];
  final _overrides = <String, ApartmentUnitItem>{};
  final _hidden = <String>{};
  final _schedules = <_ApartmentScheduleItem>[];
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _filter = _filters.first;
  String? _selectedUnit;
  bool _autoApprove = false;
  bool _emailNotifications = true;
  bool _liveMonitoring = true;

  @override
  void initState() {
    super.initState();
    _statsFuture = AppApiService.instance.fetchApartmentStats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _statsFuture = AppApiService.instance.fetchApartmentStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Apartment Administration',
      subtitle: 'Create, approve, assign, monitor, and configure units',
      role: UserRole.admin,
      currentIndex: 0,
      showBottomNav: false,
      actions: [ShellAction(icon: Icons.refresh_rounded, onPressed: _reload)],
      body: FutureBuilder<ApartmentStatsData>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load apartment administration',
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final units = _units(snapshot.data);
          final filtered = _filteredUnits(units);
          final selected = _selected(units);
          final occupied =
              units.where((u) => u.occupancyStatus == 'Occupied').length;
          final pending = units
              .where((u) => u.occupancyStatus == 'Pending Approval')
              .length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  MetricCard(
                    label: 'Occupancy',
                    value: units.isEmpty
                        ? '0%'
                        : '${((occupied / units.length) * 100).toStringAsFixed(0)}%',
                    note: '$occupied/${units.length} occupied',
                    noteColor: const Color(0xFF22C55E),
                    icon: Icons.apartment_rounded,
                    iconColor: const Color(0xFF137FEC),
                  ),
                  MetricCard(
                    label: 'Pending',
                    value: '$pending',
                    note: _draftUnits.isEmpty
                        ? 'No draft changes'
                        : '${_draftUnits.length} draft units',
                    noteColor: const Color(0xFFF59E0B),
                    icon: Icons.pending_actions_rounded,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppSearchField(
                hint:
                    'Search apartment administration by unit, tower, type, or resident',
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
              const SectionTitle('Administration Console'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionTile(
                      label: 'Create',
                      icon: Icons.add_home_rounded,
                      onTap: _createUnit,
                      primary: true),
                  ActionTile(
                      label: 'Search',
                      icon: Icons.search_rounded,
                      onTap: _focusSearch),
                  ActionTile(
                      label: 'Export',
                      icon: Icons.download_rounded,
                      onTap: () => _exportUnits(units)),
                  ActionTile(
                      label: 'Import',
                      icon: Icons.upload_rounded,
                      onTap: _importUnits),
                  ActionTile(
                      label: 'Track',
                      icon: Icons.track_changes_rounded,
                      onTap: () => _showTracking(units)),
                  ActionTile(
                      label: 'Monitor',
                      icon: Icons.monitor_heart_rounded,
                      onTap: () => _showMonitoring(units)),
                  ActionTile(
                      label: 'Generate',
                      icon: Icons.auto_awesome_rounded,
                      onTap: () => _generatePack(units)),
                  ActionTile(
                      label: 'Manage',
                      icon: Icons.dashboard_customize_rounded,
                      onTap: () => _showManagement(units, selected)),
                  ActionTile(
                      label: 'Configure',
                      icon: Icons.settings_rounded,
                      onTap: _configureAdmin),
                  ActionTile(
                      label: 'Validate',
                      icon: Icons.fact_check_rounded,
                      onTap: () => _validateAdmin(units)),
                ],
              ),
              const SizedBox(height: 18),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  units.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                InfoCard(
                  child: Text(
                      'No apartment administration records match the current search/filter.',
                      style: Theme.of(context).textTheme.bodyMedium),
                )
              else
                ..._byFloor(filtered).entries.map(
                    (entry) => _floorSection(context, entry.key, entry.value)),
            ],
          );
        },
      ),
    );
  }

  Widget _floorSection(
      BuildContext context, String floor, List<ApartmentUnitItem> units) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        children: [
          Row(
            children: [
              Text(floor, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                  '${units.where((u) => u.occupancyStatus == 'Occupied').length}/${units.length} occupied',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 720 ? 1 : 2;
              final aspectRatio = columns == 1 ? 1.75 : 1.12;
              if (columns == 1) {
                return Column(
                  children: [
                    for (final unit in units) ...[
                      _unitCard(context, unit, units.length),
                      if (unit != units.last) const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return GridView.builder(
                itemCount: units.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: aspectRatio,
                ),
                itemBuilder: (context, index) =>
                    _unitCard(context, units[index], units.length),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _unitCard(
      BuildContext context, ApartmentUnitItem unit, int totalUnits) {
    final active = unit.unitNumber == _selectedUnit;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _selectedUnit = unit.unitNumber),
      child: InfoCard(
        color: active ? const Color(0xFFEAF3FF) : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(unit.unitNumber,
                    style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                statusChip(
                  unit.occupancyStatus == 'Occupied'
                      ? 'Resident'
                      : unit.occupancyStatus,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              unit.residentName ?? 'Available',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033)),
            ),
            const SizedBox(height: 4),
            Text(
              '${unit.tower} - ${unit.unitType}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            Text(
              unit.balance == 0
                  ? 'No balance'
                  : 'Balance ${formatMoney(unit.balance)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _unitAction(
                  context,
                  icon: Icons.visibility_rounded,
                  label: 'View',
                  onTap: () => _viewUnit(unit),
                ),
                _unitAction(
                  context,
                  icon: Icons.edit_rounded,
                  label: 'Update',
                  onTap: () => _updateUnit(unit),
                ),
                if (_isDeactivated(unit.occupancyStatus))
                  _unitAction(
                    context,
                    icon: Icons.restart_alt_rounded,
                    label: 'Activate',
                    onTap: () => _activateUnit(unit),
                  )
                else ...[
                  _unitAction(
                    context,
                    icon: Icons.delete_rounded,
                    label: 'Delete',
                    onTap: () => _deleteUnit(unit),
                    destructive: true,
                  ),
                  _unitAction(
                    context,
                    icon: Icons.check_circle_rounded,
                    label: 'Approve',
                    onTap: () => _approveUnit(unit),
                  ),
                  _unitAction(
                    context,
                    icon: Icons.cancel_rounded,
                    label: 'Reject',
                    onTap: () => _rejectUnit(unit),
                  ),
                  _unitAction(
                    context,
                    icon: Icons.person_add_alt_1_rounded,
                    label: 'Assign',
                    onTap: () => _assignUnit(unit),
                  ),
                  _unitAction(
                    context,
                    icon: Icons.event_available_rounded,
                    label: 'Schedule',
                    onTap: () => _scheduleUnit(unit),
                  ),
                  _unitAction(
                    context,
                    icon: Icons.notifications_active_rounded,
                    label: 'Notify',
                    onTap: () => _notifyUnit(unit, totalUnits),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitAction(
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

  List<ApartmentUnitItem> _units(ApartmentStatsData? stats) {
    final result = <ApartmentUnitItem>[];
    for (final unit in [...?stats?.units, ..._draftUnits]) {
      if (_hidden.contains(unit.unitNumber)) continue;
      result.add(_overrides[unit.unitNumber] ?? unit);
    }
    return result;
  }

  List<ApartmentUnitItem> _filteredUnits(List<ApartmentUnitItem> units) {
    final q = _searchController.text.trim().toLowerCase();
    return units.where((u) {
      final matchesQuery = q.isEmpty ||
          u.unitNumber.toLowerCase().contains(q) ||
          u.tower.toLowerCase().contains(q) ||
          u.unitType.toLowerCase().contains(q) ||
          (u.residentName ?? '').toLowerCase().contains(q);
      final matchesFilter = _filter == 'All' || u.occupancyStatus == _filter;
      return matchesQuery && matchesFilter;
    }).toList()
      ..sort((left, right) {
        final compare = _deactivatedSort(left.occupancyStatus)
            .compareTo(_deactivatedSort(right.occupancyStatus));
        if (compare != 0) return compare;
        return left.unitNumber
            .toLowerCase()
            .compareTo(right.unitNumber.toLowerCase());
      });
  }

  Map<String, List<ApartmentUnitItem>> _byFloor(List<ApartmentUnitItem> units) {
    final map = <String, List<ApartmentUnitItem>>{};
    for (final unit in units) {
      final floor =
          unit.unitNumber.isNotEmpty ? unit.unitNumber.substring(0, 1) : '0';
      map.putIfAbsent('Floor 0$floor', () => []).add(unit);
    }
    return map;
  }

  ApartmentUnitItem? _selected(List<ApartmentUnitItem> units) {
    for (final unit in units) {
      if (unit.unitNumber == _selectedUnit) return unit;
    }
    return null;
  }

  ApartmentUnitItem? _requireSelected(ApartmentUnitItem? unit, String message) {
    if (unit == null) {
      showAppSnack(context, message);
      return null;
    }
    return unit;
  }

  int _deactivatedSort(String status) => _isDeactivated(status) ? 1 : 0;

  bool _isDeactivated(String status) => status.toLowerCase() == 'deactivated';

  ApartmentUnitItem _copy(ApartmentUnitItem unit,
      {String? status, String? residentName, String? tower, String? type}) {
    return ApartmentUnitItem(
      id: unit.id,
      unitNumber: unit.unitNumber,
      tower: tower ?? unit.tower,
      unitType: type ?? unit.unitType,
      occupancyStatus: status ?? unit.occupancyStatus,
      residentName: residentName ?? unit.residentName,
      balance: unit.balance,
    );
  }

  void _focusSearch() {
    FocusScope.of(context).requestFocus(_searchFocusNode);
    showAppSnack(context, 'Search apartment administration is ready');
  }

  Future<void> _createUnit() async {
    final unitController = TextEditingController();
    final towerController = TextEditingController(text: 'Skyview Tower');
    final typeController = TextEditingController(text: 'Standard');
    final residentController = TextEditingController();
    bool pending = !_autoApprove;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Create Apartment Administration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: unitController,
                    decoration:
                        const InputDecoration(labelText: 'Unit Number')),
                const SizedBox(height: 12),
                TextField(
                    controller: towerController,
                    decoration: const InputDecoration(labelText: 'Tower')),
                const SizedBox(height: 12),
                TextField(
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Unit Type')),
                const SizedBox(height: 12),
                TextField(
                    controller: residentController,
                    decoration:
                        const InputDecoration(labelText: 'Resident Name')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Require approval'),
                  value: pending,
                  onChanged: (value) => setModalState(() => pending = value),
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
                final unit = ApartmentUnitItem(
                  id: null,
                  unitNumber: unitController.text.trim(),
                  tower: towerController.text.trim(),
                  unitType: typeController.text.trim(),
                  occupancyStatus: pending
                      ? 'Pending Approval'
                      : (residentController.text.trim().isEmpty
                          ? 'Vacant'
                          : 'Occupied'),
                  residentName: residentController.text.trim().isEmpty
                      ? null
                      : residentController.text.trim(),
                  balance: 0,
                );
                setState(() {
                  _draftUnits.add(unit);
                  _selectedUnit = unit.unitNumber;
                });
                Navigator.pop(dialogContext);
                showAppSnack(context, 'Apartment administration created');
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUnit(ApartmentUnitItem? unit) async {
    final current =
        _requireSelected(unit, 'Select an apartment unit to update.');
    if (current == null) return;
    final towerController = TextEditingController(text: current.tower);
    final typeController = TextEditingController(text: current.unitType);
    final residentController =
        TextEditingController(text: current.residentName ?? '');
    String status = current.occupancyStatus;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: Text('Update Apartment Administration: ${current.unitNumber}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: towerController,
                    decoration: const InputDecoration(labelText: 'Tower')),
                const SizedBox(height: 12),
                TextField(
                    controller: typeController,
                    decoration: const InputDecoration(labelText: 'Unit Type')),
                const SizedBox(height: 12),
                TextField(
                    controller: residentController,
                    decoration:
                        const InputDecoration(labelText: 'Resident Name')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _filters
                      .where((item) => item != 'All')
                      .map((item) => DropdownMenuItem(
                          value: item, child: Text(context.tr(item))))
                      .toList(),
                  onChanged: (value) => setModalState(
                      () => status = value ?? current.occupancyStatus),
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
                  _overrides[current.unitNumber] = _copy(
                    current,
                    tower: towerController.text.trim(),
                    type: typeController.text.trim(),
                    residentName: residentController.text.trim().isEmpty
                        ? null
                        : residentController.text.trim(),
                    status: status,
                  );
                });
                Navigator.pop(dialogContext);
                showAppSnack(context, 'Apartment administration updated');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUnit(ApartmentUnitItem? unit) async {
    final current =
        _requireSelected(unit, 'Select an apartment unit to delete.');
    if (current == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Apartment Administration'),
        content: Text('Deactivate unit ${current.unitNumber}?'),
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
    setState(() {
      _overrides[current.unitNumber] = _copy(current, status: 'Deactivated');
      if (_selectedUnit == current.unitNumber) _selectedUnit = null;
    });
    if (!mounted) return;
    showAppSnack(context, 'Apartment administration deactivated');
  }

  void _activateUnit(ApartmentUnitItem? unit) {
    final current =
        _requireSelected(unit, 'Select an apartment unit to activate.');
    if (current == null) return;
    setState(() {
      _overrides[current.unitNumber] = _copy(current,
          status: current.residentName == null ? 'Vacant' : 'Occupied');
    });
    showAppSnack(context, 'Apartment administration activated');
  }

  Future<void> _viewUnit(ApartmentUnitItem? unit) async {
    final current = _requireSelected(unit, 'Select an apartment unit to view.');
    if (current == null) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('View Apartment Administration: ${current.unitNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tower: ${current.tower}'),
            Text('Type: ${current.unitType}'),
            Text('Status: ${current.occupancyStatus}'),
            Text('Resident: ${current.residentName ?? 'Unassigned'}'),
            Text('Balance: ${formatMoney(current.balance)}'),
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

  void _approveUnit(ApartmentUnitItem? unit) {
    final current =
        _requireSelected(unit, 'Select an apartment unit to approve.');
    if (current == null) return;
    setState(() {
      _overrides[current.unitNumber] = _copy(current,
          status: current.residentName == null ? 'Vacant' : 'Occupied');
    });
    showAppSnack(context, 'Apartment administration approved');
  }

  void _rejectUnit(ApartmentUnitItem? unit) {
    final current =
        _requireSelected(unit, 'Select an apartment unit to reject.');
    if (current == null) return;
    setState(() {
      _overrides[current.unitNumber] = _copy(current, status: 'Rejected');
    });
    showAppSnack(context, 'Apartment administration rejected');
  }

  Future<void> _assignUnit(ApartmentUnitItem? unit) async {
    final current =
        _requireSelected(unit, 'Select an apartment unit to assign.');
    if (current == null) return;
    final residentController =
        TextEditingController(text: current.residentName ?? '');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Assign Apartment Administration: ${current.unitNumber}'),
        content: TextField(
            controller: residentController,
            decoration: const InputDecoration(labelText: 'Resident Name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _overrides[current.unitNumber] = _copy(
                  current,
                  residentName: residentController.text.trim().isEmpty
                      ? null
                      : residentController.text.trim(),
                  status: residentController.text.trim().isEmpty
                      ? 'Vacant'
                      : 'Assigned',
                );
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Apartment administration assigned');
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleUnit(ApartmentUnitItem? unit) async {
    final current =
        _requireSelected(unit, 'Select an apartment unit to schedule.');
    if (current == null) return;
    final titleController = TextEditingController(text: 'Inspection');
    final dateController = TextEditingController(text: '2026-03-20');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Schedule Apartment Administration: ${current.unitNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Action')),
            const SizedBox(height: 12),
            TextField(
                controller: dateController,
                decoration: const InputDecoration(labelText: 'Date')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _schedules.add(_ApartmentScheduleItem(
                    unitNumber: current.unitNumber,
                    title: titleController.text.trim(),
                    dateLabel: dateController.text.trim()));
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Apartment administration scheduled');
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _notifyUnit(ApartmentUnitItem? unit, int total) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notify Apartment Administration'),
        content: Text(unit == null
            ? 'Prepared notification draft for $total apartment records.'
            : 'Prepared notification draft for unit ${unit.unitNumber}.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'))
        ],
      ),
    );
  }

  Future<void> _importUnits() async {
    final controller = TextEditingController(
        text:
            '701,Skyview Tower,Duplex,Pending Approval,,0\n702,Ocean Tower,Studio,Vacant,,0');
    String? error;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Import Apartment Administration'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Format: Unit,Tower,Type,Status,Resident,Balance'),
                const SizedBox(height: 12),
                TextField(controller: controller, maxLines: 6),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error!,
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
                  final items = controller.text
                      .split('\n')
                      .where((line) => line.trim().isNotEmpty)
                      .map((line) {
                    final parts =
                        line.split(',').map((part) => part.trim()).toList();
                    if (parts.length != 6) {
                      throw Exception(
                          'Each line needs 6 comma-separated values.');
                    }
                    return ApartmentUnitItem(
                      id: null,
                      unitNumber: parts[0],
                      tower: parts[1],
                      unitType: parts[2],
                      occupancyStatus: parts[3],
                      residentName: parts[4].isEmpty ? null : parts[4],
                      balance: double.tryParse(parts[5]) ?? 0,
                    );
                  }).toList();
                  setState(() {
                    _draftUnits.addAll(items);
                    if (items.isNotEmpty) {
                      _selectedUnit = items.first.unitNumber;
                    }
                  });
                  Navigator.pop(dialogContext);
                  showAppSnack(context, 'Apartment administration imported');
                } catch (e) {
                  setModalState(() =>
                      error = e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Import'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportUnits(List<ApartmentUnitItem> units) async {
    final content = StringBuffer('Unit,Tower,Type,Status,Resident,Balance\n');
    for (final unit in units) {
      content.writeln(
          '${unit.unitNumber},${unit.tower},${unit.unitType},${unit.occupancyStatus},${unit.residentName ?? ''},${unit.balance}');
    }
    await DownloadService.saveCsvFile(
        filename: 'apartment_administration_export',
        content: content.toString());
    if (mounted) showAppSnack(context, 'Apartment administration exported');
  }

  Future<void> _showTracking(List<ApartmentUnitItem> units) async {
    final byTower = <String, List<ApartmentUnitItem>>{};
    for (final unit in units) {
      byTower.putIfAbsent(unit.tower, () => []).add(unit);
    }
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Track Apartment Administration',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              ...byTower.entries.map((entry) {
                final occupied = entry.value
                    .where((u) => u.occupancyStatus == 'Occupied')
                    .length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoCard(
                      child: Text(
                          '${entry.key}: $occupied/${entry.value.length} occupied')),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showMonitoring(List<ApartmentUnitItem> units) async {
    final pending =
        units.where((u) => u.occupancyStatus == 'Pending Approval').length;
    final rejected = units.where((u) => u.occupancyStatus == 'Rejected').length;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Monitor Apartment Administration',
                    style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(
                    'Live monitoring: ${_liveMonitoring ? 'Enabled' : 'Disabled'}'),
                Text(
                    'Email notifications: ${_emailNotifications ? 'Enabled' : 'Disabled'}'),
                Text('Pending approvals: $pending'),
                Text('Rejected records: $rejected'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePack(List<ApartmentUnitItem> units) async {
    final content = StringBuffer('summary,value\n');
    content.writeln('total_units,${units.length}');
    content.writeln(
        'occupied_units,${units.where((u) => u.occupancyStatus == 'Occupied').length}');
    content.writeln(
        'pending_approvals,${units.where((u) => u.occupancyStatus == 'Pending Approval').length}');
    content.writeln('scheduled_actions,${_schedules.length}');
    await DownloadService.saveCsvFile(
        filename: 'apartment_administration_pack', content: content.toString());
    if (mounted) {
      showAppSnack(context, 'Apartment administration pack generated');
    }
  }

  Future<void> _showManagement(
      List<ApartmentUnitItem> units, ApartmentUnitItem? selected) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: ListView(
            shrinkWrap: true,
            children: [
              Text('Manage Apartment Administration',
                  style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 12),
              InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visible units: ${units.length}'),
                    Text('Selected unit: ${selected?.unitNumber ?? 'None'}'),
                    Text('Scheduled actions: ${_schedules.length}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _configureAdmin() async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Configure Apartment Administration',
                    style: Theme.of(sheetContext).textTheme.titleLarge),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _autoApprove,
                  title: const Text('Auto approve new records'),
                  onChanged: (value) =>
                      setModalState(() => _autoApprove = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _emailNotifications,
                  title: const Text('Email notifications'),
                  onChanged: (value) =>
                      setModalState(() => _emailNotifications = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _liveMonitoring,
                  title: const Text('Live monitoring'),
                  onChanged: (value) =>
                      setModalState(() => _liveMonitoring = value),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {});
                    Navigator.pop(sheetContext);
                    showAppSnack(
                        context, 'Apartment administration configured');
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _validateAdmin(List<ApartmentUnitItem> units) async {
    final issues = <String>[];
    final seen = <String>{};
    for (final unit in units) {
      if (!seen.add(unit.unitNumber)) {
        issues.add('Duplicate unit number: ${unit.unitNumber}');
      }
      if (unit.occupancyStatus == 'Occupied' &&
          (unit.residentName ?? '').isEmpty) {
        issues
            .add('Occupied unit ${unit.unitNumber} has no resident assigned.');
      }
    }
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Validate Apartment Administration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Units checked: ${units.length}'),
            Text('Schedules checked: ${_schedules.length}'),
            const SizedBox(height: 12),
            if (issues.isEmpty) const Text('Validation passed with no issues.'),
            if (issues.isNotEmpty) ...issues.map((issue) => Text('- $issue')),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label, required this.active, required this.onTap});

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
            context.tr(label),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color:
                    active ? const Color(0xFF137FEC) : const Color(0xFF8B97AA)),
          ),
        ),
      ),
    );
  }
}

class _ApartmentScheduleItem {
  final String unitNumber;
  final String title;
  final String dateLabel;

  const _ApartmentScheduleItem({
    required this.unitNumber,
    required this.title,
    required this.dateLabel,
  });
}
