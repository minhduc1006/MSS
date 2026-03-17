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
    final callUri = Uri.parse('tel:100');
    final launched = await launchUrl(callUri);
    if (!mounted) {
      return;
    }
    if (launched) {
      showAppSnack(context, 'Opening guard desk line');
      return;
    }
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('Guard Desk')),
        content: Text(context.tr('Call extension 100 or use the lobby intercom for immediate assistance.')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.t('close')),
          ),
        ],
      ),
    );
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
