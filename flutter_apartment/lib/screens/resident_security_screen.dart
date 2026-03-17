import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../widgets/common_widgets.dart';

class ResidentSecurityScreen extends StatefulWidget {
  const ResidentSecurityScreen({super.key});

  @override
  State<ResidentSecurityScreen> createState() => _ResidentSecurityScreenState();
}

class _ResidentSecurityScreenState extends State<ResidentSecurityScreen> {
  late Future<List<SecurityLog>> _historyFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _historyFuture = _loadHistory();
  }

  Future<List<SecurityLog>> _loadHistory() {
    return AppApiService.instance.fetchSecurityHistory(
      userId: context.read<AuthProvider>().currentUserId,
      audience: 'resident',
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Security & Support',
      role: UserRole.resident,
      currentIndex: 3,
      actions: [
        ShellAction(
          icon: Icons.refresh_rounded,
          onPressed: () => setState(() {
            _historyFuture = _loadHistory();
          }),
        ),
      ],
      body: FutureBuilder<List<SecurityLog>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          final logs = snapshot.data ?? const <SecurityLog>[];
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              InfoCard(
                child: Row(
                  children: [
                    const SoftIcon(icon: Icons.sos_rounded, color: Color(0xFFEF4444), size: 48),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency SOS', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                          const SizedBox(height: 4),
                          Text('Alert on-site security immediately', style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => _triggerSos(),
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFFEF4444), minimumSize: const Size(96, 48)),
                      child: const Text('ACTIVATE'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ResponsiveButtonBar(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _openIncidentForm(context),
                    icon: const Icon(Icons.report_gmailerrorred_rounded),
                    label: const Text('Report Incident'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _callDesk,
                    icon: const Icon(Icons.support_agent_rounded),
                    label: Text(context.tr('Call Desk')),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const SectionTitle('Access History'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting && logs.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...logs.map(
                  (log) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Row(
                        children: [
                          const SoftIcon(icon: Icons.shield_outlined, color: Color(0xFF137FEC), size: 42),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log.event, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                                const SizedBox(height: 4),
                                Text('${log.visitor} - ${log.time}', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                          statusChip(log.status),
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

  Future<void> _triggerSos() async {
    final auth = context.read<AuthProvider>();
    await AppApiService.instance.triggerSos(userId: auth.currentUserId, audience: 'resident');
    if (mounted) {
      showAppSnack(context, 'SOS alert sent');
      setState(() {
        _historyFuture = _loadHistory();
      });
    }
  }

  Future<void> _callDesk() async {
    List<AdminContactItem> admins = const <AdminContactItem>[];
    try {
      admins = await AppApiService.instance.fetchAdminContacts();
    } catch (_) {
      // If auth-service isn't reachable, fall back to extension 100.
    }

    final callable = admins
        .where((admin) => admin.phone.trim().isNotEmpty && admin.status.toLowerCase() != 'deactivated')
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    Future<void> callPhone(String phone) async {
      final normalized = phone.trim();
      final callUri = Uri.parse('tel:$normalized');
      final launched = await launchUrl(callUri);
      if (!mounted) return;
      if (launched) {
        showAppSnack(context, 'Calling desk contact');
        return;
      }
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('Guard Desk')),
          content: Text('Phone: $normalized'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.t('close')),
            ),
          ],
        ),
      );
    }

    if (callable.length == 1) {
      await callPhone(callable.first.phone);
      return;
    }

    if (callable.isNotEmpty) {
      await showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              ListTile(
                title: Text(context.tr('Guard Desk')),
                subtitle: const Text('Choose an admin to call'),
              ),
              ...callable.map(
                (admin) => ListTile(
                  leading: const Icon(Icons.admin_panel_settings_rounded),
                  title: Text(admin.name.isEmpty ? admin.email : admin.name),
                  subtitle: Text(admin.phone),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await callPhone(admin.phone);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
      return;
    }

    // Final fallback: extension 100.
    await callPhone('100');
  }

  Future<void> _openIncidentForm(BuildContext context) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final zoneController = TextEditingController(text: 'Resident Tower');
    String severity = 'Medium';

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: InputDecoration(labelText: context.tr('Title'))),
              const SizedBox(height: 12),
              TextField(controller: zoneController, decoration: InputDecoration(labelText: context.tr('Zone'))),
              const SizedBox(height: 12),
              TextField(controller: descriptionController, decoration: InputDecoration(labelText: context.tr('Description')), maxLines: 3),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: severity,
                items: const ['Low', 'Medium', 'High', 'Critical'].map((value) => DropdownMenuItem(value: value, child: Text(context.tr(value)))).toList(),
                onChanged: (value) => setSheetState(() => severity = value ?? 'Medium'),
                decoration: InputDecoration(labelText: context.tr('Severity')),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(sheetContext);
                  await AppApiService.instance.createIncident(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    zone: zoneController.text.trim(),
                    severity: severity,
                    userId: context.read<AuthProvider>().currentUserId,
                    audience: 'resident',
                  );
                  if (!mounted) {
                    return;
                  }
                  navigator.pop();
                  setState(() {
                    _historyFuture = _loadHistory();
                  });
                  showAppSnack(this.context, 'Incident reported');
                },
                child: Text(context.tr('Submit Report')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
