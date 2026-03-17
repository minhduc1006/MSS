import 'package:flutter/material.dart';

import '../core/app_i18n.dart';
import '../core/app_media.dart';
import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  static const _filters = ['All', 'Open', 'In-Progress', 'Resolved', 'Assigned', 'Deactivated'];

  late Future<SecurityOverviewData> _overviewFuture;
  final _draftIncidents = <IncidentItem>[];
  final _overrides = <String, IncidentItem>{};
  final _hidden = <String>{};
  final _assignments = <String, String>{};
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _filter = _filters.first;
  String? _selectedIncidentKey;
  bool _mapView = false;

  @override
  void initState() {
    super.initState();
    _overviewFuture = AppApiService.instance.fetchSecurityOverview();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _overviewFuture = AppApiService.instance.fetchSecurityOverview();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Security & Reporting',
      subtitle: 'Manage incidents and staff assignments',
      role: UserRole.admin,
      currentIndex: 4,
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _reload),
        ShellAction(icon: Icons.add_alert_rounded, onPressed: _createIncident),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: _createIncident,
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: FutureBuilder<SecurityOverviewData>(
        future: _overviewFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load security & reporting',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final incidents = _mergedIncidents(snapshot.data?.incidents ?? const <IncidentItem>[]);
          final filtered = _filteredIncidents(incidents);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.12,
                children: [
                  MetricCard(label: 'Incidents', value: '${incidents.length}', note: '${incidents.where((item) => item.status == 'Open').length} open', noteColor: const Color(0xFFF59E0B), icon: Icons.shield_rounded, iconColor: AppTheme.brand),
                  MetricCard(label: 'Assigned', value: '${incidents.where((item) => item.status == 'Assigned').length}', note: '${incidents.where((item) => item.status == 'Resolved').length} resolved', noteColor: const Color(0xFF22C55E), icon: Icons.assignment_ind_rounded, iconColor: const Color(0xFF22C55E)),
                ],
              ),
              const SizedBox(height: 16),
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(value: false, label: Text(context.tr('Incident List'))),
                  ButtonSegment<bool>(value: true, label: Text(context.tr('Map View'))),
                ],
                selected: {_mapView},
                onSelectionChanged: (value) => setState(() => _mapView = value.first),
              ),
              const SizedBox(height: 16),
              AppSearchField(
                hint: 'Search security by incident, zone, severity, or assigned team',
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
              const SectionTitle('Security Console'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionTile(label: 'Create', icon: Icons.add_alert_rounded, onTap: _createIncident, primary: true),
                  ActionTile(label: 'Search', icon: Icons.search_rounded, onTap: _focusSearch),
                  ActionTile(label: 'Export', icon: Icons.download_rounded, onTap: () => _exportIncidents(incidents)),
                ],
              ),
              const SizedBox(height: 16),
              if (_mapView) _mapCard(incidents) else ...filtered.map((incident) => _incidentCard(context, incident)),
            ],
          );
        },
      ),
    );
  }

  Widget _mapCard(List<IncidentItem> incidents) {
    return InfoCard(
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          AppNetworkImage(
            url: AppMedia.security,
            height: 200,
            borderRadius: BorderRadius.circular(20),
            overlay: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x22000000), Color(0xAA0F172A)],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(color: AppTheme.brand.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(999)),
              child: Text('${incidents.length} tracked incidents', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }

  Widget _incidentCard(BuildContext context, IncidentItem incident) {
    final key = _incidentKey(incident);
    final active = key == _selectedIncidentKey;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => setState(() => _selectedIncidentKey = key),
        child: InfoCard(
          color: active ? const Color(0xFFEAF3FF) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoftIcon(
                    icon: incident.status == 'Open'
                        ? Icons.warning_rounded
                        : incident.status == 'In-Progress'
                            ? Icons.build_circle_rounded
                            : incident.status == 'Assigned'
                                ? Icons.assignment_ind_rounded
                                : Icons.verified_rounded,
                    color: statusColor(incident.status),
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(incident.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text('${incident.zone} - ${incident.time}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  statusChip(incident.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(incident.desc, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_assignmentLabel(incident) != null) _pill(context, Icons.assignment_ind_rounded, _assignmentLabel(incident)!),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _incidentAction(context, icon: Icons.visibility_rounded, label: 'View', onTap: () => _viewIncident(incident)),
                  _incidentAction(context, icon: Icons.edit_rounded, label: 'Update', onTap: () => _updateIncident(incident)),
                  if (_isDeactivated(incident.status))
                    _incidentAction(context, icon: Icons.restart_alt_rounded, label: 'Activate', onTap: () => _activateIncident(incident))
                  else ...[
                    _incidentAction(context, icon: Icons.delete_rounded, label: 'Delete', onTap: () => _deleteIncident(incident), destructive: true),
                    _incidentAction(context, icon: Icons.assignment_ind_rounded, label: 'Assign', onTap: () => _assignIncident(incident)),
                  ],
                ],
              ),
            ],
          ),
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

  Widget _incidentAction(
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
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  List<IncidentItem> _mergedIncidents(List<IncidentItem> base) {
    final merged = <IncidentItem>[];
    for (final incident in [...base, ..._draftIncidents]) {
      final key = _incidentKey(incident);
      if (_hidden.contains(key)) continue;
      merged.add(_overrides[key] ?? incident);
    }
    return merged;
  }

  List<IncidentItem> _filteredIncidents(List<IncidentItem> incidents) {
    final query = _searchController.text.trim().toLowerCase();
    return incidents.where((incident) {
      final assignment = (_assignments[_incidentKey(incident)] ?? '').toLowerCase();
      final matchesQuery = query.isEmpty ||
          incident.title.toLowerCase().contains(query) ||
          incident.zone.toLowerCase().contains(query) ||
          (incident.severity ?? '').toLowerCase().contains(query) ||
          assignment.contains(query);
      final matchesFilter = _filter == 'All' || incident.status == _filter;
      return matchesQuery && matchesFilter;
    }).toList()
      ..sort((left, right) {
        final compare = _deactivatedSort(left.status).compareTo(_deactivatedSort(right.status));
        if (compare != 0) return compare;
        return left.title.toLowerCase().compareTo(right.title.toLowerCase());
      });
  }

  IncidentItem? _requireSelected(IncidentItem? incident, String message) {
    if (incident == null) {
      showAppSnack(context, message);
      return null;
    }
    return incident;
  }

  String _incidentKey(IncidentItem incident) => incident.id?.toString() ?? '${incident.title}|${incident.zone}|${incident.time}';

  String? _assignmentLabel(IncidentItem incident) => _assignments[_incidentKey(incident)];

  int _deactivatedSort(String status) => _isDeactivated(status) ? 1 : 0;

  bool _isDeactivated(String status) => status.toLowerCase() == 'deactivated';

  IncidentItem _copyIncident(
    IncidentItem incident, {
    String? title,
    String? zone,
    String? time,
    String? status,
    String? desc,
    String? severity,
    String? assignedStaffName,
  }) {
    return IncidentItem(
      id: incident.id,
      title: title ?? incident.title,
      zone: zone ?? incident.zone,
      time: time ?? incident.time,
      status: status ?? incident.status,
      desc: desc ?? incident.desc,
      severity: severity ?? incident.severity,
      assignedStaffName: assignedStaffName ?? incident.assignedStaffName,
    );
  }

  void _focusSearch() {
    FocusScope.of(context).requestFocus(_searchFocusNode);
    showAppSnack(context, 'Security & reporting search is ready');
  }

  Future<void> _createIncident() async {
    final titleController = TextEditingController();
    final zoneController = TextEditingController();
    final descriptionController = TextEditingController();
    String severity = 'High';

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Create Security & Reporting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(controller: zoneController, decoration: const InputDecoration(labelText: 'Zone')),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  items: const ['Low', 'Medium', 'High', 'Critical'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                  onChanged: (value) => setModalState(() => severity = value ?? 'High'),
                  decoration: const InputDecoration(labelText: 'Severity'),
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
                  final created = await AppApiService.instance.createIncident(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    zone: zoneController.text.trim(),
                    severity: severity,
                  );
                  if (!mounted) return;
                  setState(() => _selectedIncidentKey = _incidentKey(created));
                  _reload();
                  navigator.pop();
                  showAppSnack(context, 'Security & reporting created');
                } catch (error) {
                  if (!mounted) return;
                  showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateIncident(IncidentItem? incident) async {
    final current = _requireSelected(incident, 'Select an incident to update.');
    if (current == null) return;
    final titleController = TextEditingController(text: current.title);
    final zoneController = TextEditingController(text: current.zone);
    final descriptionController = TextEditingController(text: current.desc);
    String status = current.status;
    String severity = current.severity ?? 'High';
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Update Security & Reporting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                const SizedBox(height: 12),
                TextField(controller: zoneController, decoration: const InputDecoration(labelText: 'Zone')),
                const SizedBox(height: 12),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: _filters.where((item) => item != 'All').map((item) => DropdownMenuItem(value: item, child: Text(context.tr(item)))).toList(),
                  onChanged: (value) => setModalState(() => status = value ?? current.status),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: severity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: const ['Low', 'Medium', 'High', 'Critical'].map((value) => DropdownMenuItem(value: value, child: Text(context.tr(value)))).toList(),
                  onChanged: (value) => setModalState(() => severity = value ?? current.severity ?? 'High'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (current.id == null) {
                  setState(() {
                    _overrides[_incidentKey(current)] = _copyIncident(
                      current,
                      title: titleController.text.trim(),
                      zone: zoneController.text.trim(),
                      desc: descriptionController.text.trim(),
                      status: status,
                      severity: severity,
                    );
                  });
                  Navigator.pop(dialogContext);
                  showAppSnack(context, 'Security & reporting updated');
                  return;
                }
                try {
                  await AppApiService.instance.updateIncident(
                    incidentId: current.id!,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    zone: zoneController.text.trim(),
                    status: status,
                    severity: severity,
                    assignedStaffName:
                        _assignmentLabel(current) ?? current.assignedStaffName,
                  );
                  if (!dialogContext.mounted || !mounted) return;
                  Navigator.pop(dialogContext);
                  _reload();
                  showAppSnack(context, 'Security & reporting updated');
                } catch (error) {
                  if (!dialogContext.mounted || !mounted) return;
                  showAppSnack(
                      context, error.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteIncident(IncidentItem? incident) async {
    final current = _requireSelected(incident, 'Select an incident to delete.');
    if (current == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Security & Reporting'),
        content: Text('Deactivate incident "${current.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete != true) return;
    if (current.id == null) {
      if (!mounted) return;
      setState(() {
        final key = _incidentKey(current);
        _overrides[key] = _copyIncident(current, status: 'Deactivated');
        if (_selectedIncidentKey == key) {
          _selectedIncidentKey = null;
        }
      });
      showAppSnack(context, 'Security & reporting deactivated');
      return;
    }
    try {
      await AppApiService.instance.deactivateIncident(current.id!);
      if (!mounted) return;
      if (_selectedIncidentKey == _incidentKey(current)) {
        setState(() => _selectedIncidentKey = null);
      }
      _reload();
      showAppSnack(context, 'Security & reporting deactivated');
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _activateIncident(IncidentItem? incident) async {
    final current = _requireSelected(incident, 'Select an incident to activate.');
    if (current == null) return;
    if (current.id == null) {
      setState(() {
        _overrides[_incidentKey(current)] = _copyIncident(current, status: 'Open');
      });
      showAppSnack(context, 'Security & reporting activated');
      return;
    }
    try {
      await AppApiService.instance.updateIncidentStatus(
        incidentId: current.id!,
        status: 'Open',
      );
      if (!mounted) return;
      _reload();
      showAppSnack(context, 'Security & reporting activated');
    } catch (error) {
      if (!mounted) return;
      showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _viewIncident(IncidentItem? incident) async {
    final current = _requireSelected(incident, 'Select an incident to view.');
    if (current == null) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('View Security & Reporting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Incident: ${current.title}'),
            Text('Zone: ${current.zone}'),
            Text('Status: ${current.status}'),
            Text('Severity: ${current.severity ?? '-'}'),
            Text('Assigned to: ${_assignmentLabel(current) ?? current.assignedStaffName ?? 'Unassigned'}'),
            const SizedBox(height: 8),
            Text(current.desc),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _assignIncident(IncidentItem? incident) async {
    final current = _requireSelected(incident, 'Select an incident to assign.');
    if (current == null) return;
    final staffMembers = (await AppApiService.instance.fetchStaff())
        .where((staff) => staff.id != null && staff.status.toLowerCase() != 'inactive')
        .toList()
      ..sort((left, right) => left.name.compareTo(right.name));
    if (!mounted) return;
    if (staffMembers.isEmpty) {
      showAppSnack(context, 'No active staff found for assignment.');
      return;
    }
    StaffItem selectedStaff = staffMembers.firstWhere(
      (staff) => staff.name == (_assignments[_incidentKey(current)] ?? current.assignedStaffName),
      orElse: () => staffMembers.first,
    );
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Assign Security & Reporting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: double.maxFinite,
                child: DropdownButtonFormField<int>(
                  initialValue: selectedStaff.id,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Assigned Staff'),
                  items: staffMembers
                      .map(
                        (staff) => DropdownMenuItem<int>(
                          value: staff.id,
                          child: Text(
                            staff.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    final matches =
                        staffMembers.where((staff) => staff.id == value);
                    final matched = matches.isEmpty ? null : matches.first;
                    if (matched == null) return;
                    setDialogState(() => selectedStaff = matched);
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Role: ${selectedStaff.role}',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              if (selectedStaff.shift.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Shift: ${selectedStaff.shift}',
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
              if (selectedStaff.email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  selectedStaff.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(dialogContext).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                try {
                  if (current.id != null) {
                    await AppApiService.instance.updateIncident(
                      incidentId: current.id!,
                      title: current.title,
                      description: current.desc,
                      zone: current.zone,
                      status: 'Assigned',
                      severity: current.severity ?? 'High',
                      assignedStaffName: selectedStaff.name,
                    );
                  }
                  await AppApiService.instance.createStaffTask(
                    assignedStaffId: selectedStaff.id!,
                    assignedStaffName: selectedStaff.name,
                    title: 'Handle security incident: ${current.title}',
                    zone: current.zone,
                    priority: current.severity ?? 'High',
                    category: 'Security',
                    sourceType: 'security',
                    sourceId: current.id,
                  );
                  if (!dialogContext.mounted || !mounted) return;
                  setState(() {
                    _assignments[_incidentKey(current)] = selectedStaff.name;
                    _overrides[_incidentKey(current)] = _copyIncident(
                      current,
                      status: 'Assigned',
                      assignedStaffName: selectedStaff.name,
                    );
                  });
                  Navigator.pop(dialogContext);
                  _reload();
                  showAppSnack(context, 'Security & reporting assigned');
                } catch (error) {
                  if (!dialogContext.mounted || !mounted) return;
                  showAppSnack(
                      context, error.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportIncidents(List<IncidentItem> incidents) async {
    final content = StringBuffer('Title,Zone,Status,Severity,Assigned To\n');
    for (final incident in incidents) {
      final key = _incidentKey(incident);
      content.writeln('${incident.title},${incident.zone},${incident.status},${incident.severity ?? ''},${_assignments[key] ?? incident.assignedStaffName ?? ''}');
    }
    await DownloadService.saveCsvFile(filename: 'security_reporting_export', content: content.toString());
    if (mounted) showAppSnack(context, 'Security & reporting exported');
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
