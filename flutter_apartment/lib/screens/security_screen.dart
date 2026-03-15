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
  static const _filters = ['All', 'Open', 'In-Progress', 'Resolved', 'Approved', 'Rejected', 'Assigned', 'Deactivated'];

  late Future<SecurityOverviewData> _overviewFuture;
  final _draftIncidents = <IncidentItem>[];
  final _overrides = <String, IncidentItem>{};
  final _hidden = <String>{};
  final _assignments = <String, String>{};
  final _notifications = <String, int>{};
  final _schedules = <_SecurityScheduleItem>[];
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _filter = _filters.first;
  String? _selectedIncidentKey;
  bool _mapView = false;
  bool _autoApprove = false;
  bool _liveMonitor = true;

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
      subtitle: 'Manage incidents, reporting queues, assignments, and live monitoring',
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
          final selected = _selectedIncident(incidents);

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
                  MetricCard(label: 'Resolved', value: '${incidents.where((item) => item.status == 'Resolved').length}', note: '${_notifications.values.fold<int>(0, (sum, item) => sum + item)} notifications', noteColor: const Color(0xFF22C55E), icon: Icons.verified_rounded, iconColor: const Color(0xFF22C55E)),
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
                  ActionTile(label: 'Import', icon: Icons.upload_rounded, onTap: _importIncidents),
                  ActionTile(label: 'Track', icon: Icons.track_changes_rounded, onTap: () => _trackIncidents(incidents)),
                  ActionTile(label: 'Monitor', icon: Icons.monitor_heart_rounded, onTap: () => _monitorIncidents(incidents)),
                  ActionTile(label: 'Generate', icon: Icons.auto_awesome_rounded, onTap: () => _generateIncidentPack(incidents)),
                  ActionTile(label: 'Manage', icon: Icons.dashboard_customize_rounded, onTap: () => _manageIncidents(incidents, selected)),
                  ActionTile(label: 'Configure', icon: Icons.settings_rounded, onTap: _configureSecurity),
                  ActionTile(label: 'Validate', icon: Icons.fact_check_rounded, onTap: () => _validateIncidents(incidents)),
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
    final scheduleCount = _schedules.where((item) => item.incidentKey == key).length;
    final notificationCount = _notifications[key] ?? 0;
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
                            : incident.status == 'Rejected'
                                ? Icons.cancel_rounded
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
                  _pill(context, Icons.event_note_rounded, scheduleCount == 0 ? 'No schedules' : '$scheduleCount schedules'),
                  _pill(context, Icons.notifications_active_rounded, notificationCount == 0 ? 'No alerts' : '$notificationCount alerts'),
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
                    _incidentAction(context, icon: Icons.check_circle_rounded, label: 'Approve', onTap: () => _approveIncident(incident)),
                    _incidentAction(context, icon: Icons.cancel_rounded, label: 'Reject', onTap: () => _rejectIncident(incident)),
                    _incidentAction(context, icon: Icons.assignment_ind_rounded, label: 'Assign', onTap: () => _assignIncident(incident)),
                    _incidentAction(context, icon: Icons.event_available_rounded, label: 'Schedule', onTap: () => _scheduleIncident(incident)),
                    _incidentAction(context, icon: Icons.notifications_active_rounded, label: 'Notify', onTap: () => _notifyIncident(incident)),
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

  IncidentItem? _selectedIncident(List<IncidentItem> incidents) {
    for (final incident in incidents) {
      if (_incidentKey(incident) == _selectedIncidentKey) return incident;
    }
    return null;
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
                  if (_autoApprove) {
                    final incident = IncidentItem(
                      title: titleController.text.trim(),
                      zone: zoneController.text.trim(),
                      time: 'Just now',
                      status: 'Open',
                      desc: descriptionController.text.trim(),
                      severity: severity,
                    );
                    setState(() {
                      _draftIncidents.add(incident);
                      _selectedIncidentKey = _incidentKey(incident);
                    });
                  } else {
                    final created = await AppApiService.instance.createIncident(
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      zone: zoneController.text.trim(),
                      severity: severity,
                    );
                    if (!mounted) return;
                    setState(() => _selectedIncidentKey = _incidentKey(created));
                    _reload();
                  }
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
              onPressed: () {
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
    if (!mounted) return;
    setState(() {
      final key = _incidentKey(current);
      _overrides[key] = _copyIncident(current, status: 'Deactivated');
      if (_selectedIncidentKey == key) {
        _selectedIncidentKey = null;
      }
    });
    showAppSnack(context, 'Security & reporting deactivated');
  }

  void _activateIncident(IncidentItem? incident) {
    final current = _requireSelected(incident, 'Select an incident to activate.');
    if (current == null) return;
    setState(() {
      _overrides[_incidentKey(current)] = _copyIncident(current, status: 'Open');
    });
    showAppSnack(context, 'Security & reporting activated');
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

  void _approveIncident(IncidentItem? incident) {
    final current = _requireSelected(incident, 'Select an incident to approve.');
    if (current == null) return;
    setState(() {
      _overrides[_incidentKey(current)] = _copyIncident(current, status: 'Approved');
    });
    showAppSnack(context, 'Security & reporting approved');
  }

  void _rejectIncident(IncidentItem? incident) {
    final current = _requireSelected(incident, 'Select an incident to reject.');
    if (current == null) return;
    setState(() {
      _overrides[_incidentKey(current)] = _copyIncident(current, status: 'Rejected');
    });
    showAppSnack(context, 'Security & reporting rejected');
  }

  Future<void> _assignIncident(IncidentItem? incident) async {
    final current = _requireSelected(incident, 'Select an incident to assign.');
    if (current == null) return;
    final controller = TextEditingController(text: _assignments[_incidentKey(current)] ?? current.assignedStaffName ?? 'Security Patrol A');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Security & Reporting'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Assigned Team / Staff')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _assignments[_incidentKey(current)] = controller.text.trim();
                _overrides[_incidentKey(current)] = _copyIncident(current, status: 'Assigned', assignedStaffName: controller.text.trim());
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Security & reporting assigned');
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleIncident(IncidentItem? incident) async {
    final current = _requireSelected(incident, 'Select an incident to schedule.');
    if (current == null) return;
    final titleController = TextEditingController(text: 'Follow-up patrol');
    final dateController = TextEditingController(text: 'Tonight 8:00 PM');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Schedule Security & Reporting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Schedule Title')),
            const SizedBox(height: 12),
            TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Date / Slot')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _schedules.add(_SecurityScheduleItem(incidentKey: _incidentKey(current), title: titleController.text.trim(), dateLabel: dateController.text.trim()));
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Security & reporting scheduled');
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _notifyIncident(IncidentItem? incident) async {
    final current = _requireSelected(incident, 'Select an incident to notify.');
    if (current == null) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notify Security & Reporting'),
        content: Text('Send security update for "${current.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final key = _incidentKey(current);
              setState(() {
                _notifications[key] = (_notifications[key] ?? 0) + 1;
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Security & reporting notification queued');
            },
            child: const Text('Notify'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportIncidents(List<IncidentItem> incidents) async {
    final content = StringBuffer('Title,Zone,Status,Severity,Assigned To,Notifications\n');
    for (final incident in incidents) {
      final key = _incidentKey(incident);
      content.writeln('${incident.title},${incident.zone},${incident.status},${incident.severity ?? ''},${_assignments[key] ?? incident.assignedStaffName ?? ''},${_notifications[key] ?? 0}');
    }
    await DownloadService.saveCsvFile(filename: 'security_reporting_export', content: content.toString());
    if (mounted) showAppSnack(context, 'Security & reporting exported');
  }

  Future<void> _importIncidents() async {
    final controller = TextEditingController(
      text: 'Parking gate tailgating,North Gate,Open,High\nPool deck slip hazard,Pool Zone,In-Progress,Medium',
    );
    String? errorMessage;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Import Security & Reporting'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('One incident per line: Title,Zone,Status,Severity'),
                const SizedBox(height: 12),
                TextField(controller: controller, maxLines: 6),
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
                  final imported = <IncidentItem>[];
                  for (final line in controller.text.split('\n').map((item) => item.trim()).where((item) => item.isNotEmpty)) {
                    final parts = line.split(',').map((item) => item.trim()).toList();
                    if (parts.length != 4) {
                      throw Exception('Each line must contain 4 comma-separated values.');
                    }
                    imported.add(
                      IncidentItem(
                        title: parts[0],
                        zone: parts[1],
                        time: 'Imported now',
                        status: parts[2],
                        severity: parts[3],
                        desc: 'Imported from security console',
                      ),
                    );
                  }
                  setState(() {
                    _draftIncidents.addAll(imported);
                    if (imported.isNotEmpty) {
                      _selectedIncidentKey = _incidentKey(imported.first);
                    }
                  });
                  Navigator.pop(dialogContext);
                  showAppSnack(context, '${imported.length} incidents imported');
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

  Future<void> _trackIncidents(List<IncidentItem> incidents) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Track Security & Reporting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Incidents tracked: ${incidents.length}'),
            Text('Assignments: ${_assignments.length}'),
            Text('Schedules: ${_schedules.length}'),
            Text('Notifications queued: ${_notifications.values.fold<int>(0, (sum, item) => sum + item)}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _monitorIncidents(List<IncidentItem> incidents) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitor Security & Reporting', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Live monitor: ${_liveMonitor ? 'Enabled' : 'Disabled'}'),
            Text('Open incidents: ${incidents.where((item) => item.status == 'Open').length}'),
            Text('Assigned incidents: ${_assignments.length}'),
          ],
        ),
      ),
    );
  }

  Future<void> _generateIncidentPack(List<IncidentItem> incidents) async {
    final content = StringBuffer('metric,value\n');
    content.writeln('incident_records,${incidents.length}');
    content.writeln('schedules,${_schedules.length}');
    content.writeln('notifications,${_notifications.values.fold<int>(0, (sum, item) => sum + item)}');
    content.writeln('open_incidents,${incidents.where((item) => item.status == 'Open').length}');
    await DownloadService.saveCsvFile(filename: 'security_reporting_pack', content: content.toString());
    if (mounted) showAppSnack(context, 'Security & reporting pack generated');
  }

  Future<void> _manageIncidents(List<IncidentItem> incidents, IncidentItem? selected) async {
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Manage Security & Reporting', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Selected incident: ${selected?.title ?? 'None'}'),
            Text('Assignments: ${_assignments.length}'),
            Text('Schedules: ${_schedules.length}'),
            Text('Resolved incidents: ${incidents.where((item) => item.status == 'Resolved').length}'),
          ],
        ),
      ),
    );
  }

  Future<void> _configureSecurity() async {
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Configure Security & Reporting'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Auto approve local incident drafts'),
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(dialogContext);
                showAppSnack(context, 'Security & reporting configured');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateIncidents(List<IncidentItem> incidents) async {
    final issues = <String>[];
    for (final incident in incidents) {
      if ((incident.severity ?? '').isEmpty) {
        issues.add('${incident.title} is missing severity.');
      }
      if (incident.status == 'Assigned' && (_assignments[_incidentKey(incident)] ?? incident.assignedStaffName ?? '').isEmpty) {
        issues.add('${incident.title} is assigned without staff.');
      }
    }
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Validate Security & Reporting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Incidents checked: ${incidents.length}'),
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
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }
}

class _SecurityScheduleItem {
  final String incidentKey;
  final String title;
  final String dateLabel;

  const _SecurityScheduleItem({
    required this.incidentKey,
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
                  color: active ? const Color(0xFF137FEC) : const Color(0xFF8B97AA),
                ),
          ),
      ),
    );
  }
}
