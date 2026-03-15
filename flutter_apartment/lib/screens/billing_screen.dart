import 'package:flutter/material.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../services/download_service.dart';
import '../widgets/common_widgets.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  static const _filters = ['All', 'Paid', 'Pending', 'Overdue', 'Approved', 'Rejected', 'Assigned', 'Deactivated'];

  late Future<BillingOverviewData> _overviewFuture;
  final _draftInvoices = <InvoiceItem>[];
  final _overrides = <String, InvoiceItem>{};
  final _hidden = <String>{};
  final _assignments = <String, String>{};
  final _notifications = <String, int>{};
  final _schedules = <_BillingScheduleItem>[];
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _filter = _filters.first;
  String? _selectedInvoiceKey;

  @override
  void initState() {
    super.initState();
    _overviewFuture = AppApiService.instance.fetchBillingOverview(status: 'All');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _overviewFuture = AppApiService.instance.fetchBillingOverview(status: 'All');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Billing & Payment',
      subtitle: 'Create, approve, notify, track, and manage invoice operations',
      role: UserRole.admin,
      currentIndex: 2,
      leadingIcon: Icons.arrow_back_ios_new_rounded,
      onLeadingTap: () => Navigator.pushReplacementNamed(context, '/admin'),
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _reload),
        ShellAction(icon: Icons.add_card_rounded, onPressed: _createInvoice),
      ],
      body: FutureBuilder<BillingOverviewData>(
        future: _overviewFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load billing & payment',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final invoices = _mergedInvoices(snapshot.data?.invoices ?? const <InvoiceItem>[]);
          final filtered = _filteredInvoices(invoices);
          final totalInvoiced = invoices.fold<double>(0, (sum, item) => sum + item.amount);
          final totalOutstanding = invoices.where((item) => item.status != 'Paid' && !_isDeactivated(item.status)).fold<double>(0, (sum, item) => sum + item.amount);
          final activeInvoices = invoices.where((item) => item.status != 'Paid' && item.status != 'Rejected' && !_isDeactivated(item.status)).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.12,
                children: [
                  MetricCard(
                    label: 'Total Invoiced',
                    value: formatMoney(totalInvoiced),
                    note: '${invoices.length} invoice records',
                    noteColor: const Color(0xFF22C55E),
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: const Color(0xFF137FEC),
                  ),
                  MetricCard(
                    label: 'Outstanding',
                    value: formatMoney(totalOutstanding),
                    note: '$activeInvoices active',
                    noteColor: const Color(0xFFF59E0B),
                    icon: Icons.pending_actions_rounded,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AppSearchField(
                hint: 'Search billing by resident, unit, title, category, or assignment',
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
              const SectionTitle('Billing Console'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ActionTile(label: 'Create', icon: Icons.add_card_rounded, onTap: _createInvoice, primary: true),
                  ActionTile(label: 'Search', icon: Icons.search_rounded, onTap: _focusSearch),
                  ActionTile(label: 'Export', icon: Icons.download_rounded, onTap: () => _exportInvoices(invoices)),
                  ActionTile(label: 'Import', icon: Icons.upload_rounded, onTap: _importInvoices),
                  ActionTile(label: 'Track', icon: Icons.track_changes_rounded, onTap: () => _trackInvoices(invoices)),
                  ActionTile(label: 'Monitor', icon: Icons.monitor_heart_rounded, onTap: () => _monitorInvoices(invoices)),
                  ActionTile(label: 'Generate', icon: Icons.auto_awesome_rounded, onTap: () => _generateInvoices(invoices)),
                ],
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting && invoices.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                InfoCard(
                  child: Text('No billing records match the current search/filter.', style: Theme.of(context).textTheme.bodyMedium),
                )
              else
                ...filtered.map((invoice) => _invoiceCard(context, invoice)),
            ],
          );
        },
      ),
    );
  }

  Widget _invoiceCard(BuildContext context, InvoiceItem invoice) {
    final key = _invoiceKey(invoice);
    final active = key == _selectedInvoiceKey;
    final scheduleCount = _schedules.where((item) => item.invoiceKey == key).length;
    final notificationCount = _notifications[key] ?? 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => _selectedInvoiceKey = key),
        child: InfoCard(
          color: active ? const Color(0xFFEAF3FF) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoftIcon(
                    icon: invoice.status == 'Paid'
                        ? Icons.check_circle_rounded
                        : invoice.status == 'Pending'
                            ? Icons.more_horiz_rounded
                            : invoice.status == 'Rejected'
                                ? Icons.cancel_rounded
                                : Icons.receipt_long_rounded,
                    color: statusColor(invoice.status),
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(invoice.title ?? 'Unit ${invoice.unit} Invoice', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                        const SizedBox(height: 4),
                        Text('${invoice.resident} - Unit ${invoice.unit}', style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(invoice.date, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  statusChip(invoice.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(formatMoney(invoice.amount), style: Theme.of(context).textTheme.titleLarge?.copyWith(color: const Color(0xFF172033))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (_assignmentLabel(invoice) != null) _tag(context, Icons.badge_rounded, _assignmentLabel(invoice)!),
                  _tag(context, Icons.event_note_rounded, scheduleCount == 0 ? 'No schedules' : '$scheduleCount schedules'),
                  _tag(context, Icons.notifications_rounded, notificationCount == 0 ? 'No reminders' : '$notificationCount reminders'),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _invoiceAction(context, icon: Icons.visibility_rounded, label: 'View', onTap: () => _viewInvoice(invoice)),
                  _invoiceAction(context, icon: Icons.edit_rounded, label: 'Update', onTap: () => _updateInvoice(invoice)),
                  if (_isDeactivated(invoice.status))
                    _invoiceAction(context, icon: Icons.restart_alt_rounded, label: 'Activate', onTap: () => _activateInvoice(invoice))
                  else ...[
                    _invoiceAction(context, icon: Icons.delete_rounded, label: 'Delete', onTap: () => _deleteInvoice(invoice), destructive: true),
                    _invoiceAction(context, icon: Icons.check_circle_rounded, label: 'Approve', onTap: () => _approveInvoice(invoice)),
                    _invoiceAction(context, icon: Icons.cancel_rounded, label: 'Reject', onTap: () => _rejectInvoice(invoice)),
                    _invoiceAction(context, icon: Icons.person_add_alt_1_rounded, label: 'Assign', onTap: () => _assignInvoice(invoice)),
                    _invoiceAction(context, icon: Icons.event_available_rounded, label: 'Schedule', onTap: () => _scheduleInvoice(invoice)),
                    _invoiceAction(context, icon: Icons.notifications_active_rounded, label: 'Notify', onTap: () => _notifyInvoice(invoice)),
                  ],
                ],
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

  Widget _invoiceAction(
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

  List<InvoiceItem> _mergedInvoices(List<InvoiceItem> base) {
    final merged = <InvoiceItem>[];
    for (final invoice in [...base, ..._draftInvoices]) {
      final key = _invoiceKey(invoice);
      if (_hidden.contains(key)) continue;
      merged.add(_overrides[key] ?? invoice);
    }
    return merged;
  }

  List<InvoiceItem> _filteredInvoices(List<InvoiceItem> invoices) {
    final query = _searchController.text.trim().toLowerCase();
    return invoices.where((invoice) {
      final assignment = (_assignments[_invoiceKey(invoice)] ?? '').toLowerCase();
      final matchesQuery = query.isEmpty ||
          invoice.resident.toLowerCase().contains(query) ||
          invoice.unit.toLowerCase().contains(query) ||
          (invoice.title ?? '').toLowerCase().contains(query) ||
          (invoice.category ?? '').toLowerCase().contains(query) ||
          assignment.contains(query);
      final matchesFilter = _filter == 'All' || invoice.status == _filter;
      return matchesQuery && matchesFilter;
    }).toList()
      ..sort((left, right) {
        final compare = _deactivatedSort(left.status).compareTo(_deactivatedSort(right.status));
        if (compare != 0) return compare;
        return (left.title ?? left.resident).toLowerCase().compareTo((right.title ?? right.resident).toLowerCase());
      });
  }

  InvoiceItem? _requireSelected(InvoiceItem? invoice, String message) {
    if (invoice == null) {
      showAppSnack(context, message);
      return null;
    }
    return invoice;
  }

  String _invoiceKey(InvoiceItem invoice) => invoice.id?.toString() ?? '${invoice.resident}|${invoice.unit}|${invoice.date}';

  String? _assignmentLabel(InvoiceItem invoice) => _assignments[_invoiceKey(invoice)];

  int _deactivatedSort(String status) => _isDeactivated(status) ? 1 : 0;

  bool _isDeactivated(String status) => status.toLowerCase() == 'deactivated';

  InvoiceItem _copyInvoice(
    InvoiceItem invoice, {
    String? unit,
    String? resident,
    double? amount,
    String? status,
    String? date,
    String? title,
    String? category,
    String? description,
  }) {
    return InvoiceItem(
      id: invoice.id,
      residentId: invoice.residentId,
      unit: unit ?? invoice.unit,
      resident: resident ?? invoice.resident,
      amount: amount ?? invoice.amount,
      status: status ?? invoice.status,
      date: date ?? invoice.date,
      title: title ?? invoice.title,
      category: category ?? invoice.category,
      description: description ?? invoice.description,
    );
  }

  void _focusSearch() {
    FocusScope.of(context).requestFocus(_searchFocusNode);
    showAppSnack(context, 'Billing & payment search is ready');
  }

  Future<void> _createInvoice() async {
    final residents = await AppApiService.instance.fetchResidents();
    if (!mounted) return;
    if (residents.isEmpty) {
      showAppSnack(context, 'No residents available to invoice');
      return;
    }

    final titleController = TextEditingController(text: 'Monthly dues');
    final amountController = TextEditingController(text: '2500000');
    final categoryController = TextEditingController(text: 'Maintenance');
    final descriptionController = TextEditingController(text: 'Monthly invoice generated from Flutter admin billing console.');
    ResidentItem selectedResident = residents.first;
    DateTime dueDate = DateTime.now().add(const Duration(days: 7));
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Create Billing & Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<ResidentItem>(
                  initialValue: selectedResident,
                  decoration: const InputDecoration(labelText: 'Resident'),
                  items: residents
                      .map(
                        (resident) => DropdownMenuItem<ResidentItem>(
                          value: resident,
                          child: Text('${resident.name} • Unit ${resident.unit}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => selectedResident = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Invoice Title')),
                const SizedBox(height: 12),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount (VND)')),
                const SizedBox(height: 12),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_available_rounded),
                  title: const Text('Due Date'),
                  subtitle: Text('${dueDate.day}/${dueDate.month}/${dueDate.year}'),
                  trailing: TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: dueDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setModalState(() => dueDate = picked);
                      }
                    },
                    child: const Text('Pick'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final navigator = Navigator.of(dialogContext);
                      setModalState(() => isSubmitting = true);
                      try {
                        final created = await AppApiService.instance.createInvoice(
                          residentId: selectedResident.id ?? 0,
                          residentName: selectedResident.name,
                          residentEmail: selectedResident.email,
                          unitNumber: selectedResident.unit,
                          title: titleController.text.trim(),
                          category: categoryController.text.trim(),
                          amount: double.tryParse(amountController.text.trim()) ?? 0,
                          dueDate: dueDate,
                          description: descriptionController.text.trim(),
                        );
                        if (!mounted) return;
                        navigator.pop();
                        _reload();
                        showAppSnack(context, '${created.title} created and invoice email queued');
                      } catch (error) {
                        if (!dialogContext.mounted) return;
                        setModalState(() => isSubmitting = false);
                        showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                    )
                  : const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateInvoice(InvoiceItem? invoice) async {
    final current = _requireSelected(invoice, 'Select an invoice to update.');
    if (current == null) return;
    final titleController = TextEditingController(text: current.title ?? '');
    final residentController = TextEditingController(text: current.resident);
    final unitController = TextEditingController(text: current.unit);
    final amountController = TextEditingController(text: current.amount.toStringAsFixed(0));
    final dateController = TextEditingController(text: current.date);
    String status = current.status;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Update Billing & Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Invoice Title')),
                const SizedBox(height: 12),
                TextField(controller: residentController, decoration: const InputDecoration(labelText: 'Resident')),
                const SizedBox(height: 12),
                TextField(controller: unitController, decoration: const InputDecoration(labelText: 'Unit')),
                const SizedBox(height: 12),
                TextField(controller: amountController, decoration: const InputDecoration(labelText: 'Amount (VNĐ)')),
                const SizedBox(height: 12),
                TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Due Date')),
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
                  _overrides[_invoiceKey(current)] = _copyInvoice(
                    current,
                    title: titleController.text.trim(),
                    resident: residentController.text.trim(),
                    unit: unitController.text.trim(),
                    amount: double.tryParse(amountController.text.trim()) ?? current.amount,
                    date: dateController.text.trim(),
                    status: status,
                  );
                });
                Navigator.pop(dialogContext);
                showAppSnack(context, 'Billing & payment updated');
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteInvoice(InvoiceItem? invoice) async {
    final current = _requireSelected(invoice, 'Select an invoice to delete.');
    if (current == null) return;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Billing & Payment'),
        content: Text('Deactivate invoice for ${current.resident}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Delete')),
        ],
      ),
    );
    if (shouldDelete != true) return;
    if (!mounted) return;
    setState(() {
      final key = _invoiceKey(current);
      _overrides[key] = _copyInvoice(current, status: 'Deactivated');
      if (_selectedInvoiceKey == key) {
        _selectedInvoiceKey = null;
      }
    });
    showAppSnack(context, 'Billing & payment deactivated');
  }

  void _activateInvoice(InvoiceItem? invoice) {
    final current = _requireSelected(invoice, 'Select an invoice to activate.');
    if (current == null) return;
    setState(() {
      _overrides[_invoiceKey(current)] = _copyInvoice(current, status: 'Pending');
    });
    showAppSnack(context, 'Billing & payment activated');
  }

  Future<void> _viewInvoice(InvoiceItem? invoice) async {
    final current = _requireSelected(invoice, 'Select an invoice to view.');
    if (current == null) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('View Billing & Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resident: ${current.resident}'),
            Text('Unit: ${current.unit}'),
            Text('Amount: ${formatMoney(current.amount)}'),
            Text('Status: ${current.status}'),
            Text('Due: ${current.date}'),
            Text('Category: ${current.category ?? '-'}'),
            Text('Assigned to: ${_assignmentLabel(current) ?? 'Unassigned'}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  void _approveInvoice(InvoiceItem? invoice) {
    final current = _requireSelected(invoice, 'Select an invoice to approve.');
    if (current == null) return;
    setState(() {
      _overrides[_invoiceKey(current)] = _copyInvoice(current, status: 'Approved');
    });
    showAppSnack(context, 'Billing & payment approved');
  }

  void _rejectInvoice(InvoiceItem? invoice) {
    final current = _requireSelected(invoice, 'Select an invoice to reject.');
    if (current == null) return;
    setState(() {
      _overrides[_invoiceKey(current)] = _copyInvoice(current, status: 'Rejected');
    });
    showAppSnack(context, 'Billing & payment rejected');
  }

  Future<void> _assignInvoice(InvoiceItem? invoice) async {
    final current = _requireSelected(invoice, 'Select an invoice to assign.');
    if (current == null) return;
    final controller = TextEditingController(text: _assignments[_invoiceKey(current)] ?? 'Billing Operations');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Assign Billing & Payment'),
        content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Assigned Team')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                _assignments[_invoiceKey(current)] = controller.text.trim();
                _overrides[_invoiceKey(current)] = _copyInvoice(current, status: 'Assigned');
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Billing & payment assigned');
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> _scheduleInvoice(InvoiceItem? invoice) async {
    final current = _requireSelected(invoice, 'Select an invoice to schedule.');
    if (current == null) return;
    final titleController = TextEditingController(text: 'Payment reminder');
    final dateController = TextEditingController(text: 'Tomorrow 9:00 AM');
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Schedule Billing & Payment'),
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
                _schedules.add(_BillingScheduleItem(invoiceKey: _invoiceKey(current), title: titleController.text.trim(), dateLabel: dateController.text.trim()));
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Billing & payment scheduled');
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  Future<void> _notifyInvoice(InvoiceItem? invoice) async {
    final current = _requireSelected(invoice, 'Select an invoice to notify.');
    if (current == null) return;
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Notify Billing & Payment'),
        content: Text('Queue reminder for ${current.resident} about ${current.title ?? 'invoice'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final key = _invoiceKey(current);
              setState(() {
                _notifications[key] = (_notifications[key] ?? 0) + 1;
              });
              Navigator.pop(dialogContext);
              showAppSnack(context, 'Billing & payment reminder queued');
            },
            child: const Text('Notify'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportInvoices(List<InvoiceItem> invoices) async {
    final content = StringBuffer('Resident,Unit,Amount,Status,Due Date,Assigned To,Notifications\n');
    for (final invoice in invoices) {
      final key = _invoiceKey(invoice);
      content.writeln('${invoice.resident},${invoice.unit},${invoice.amount},${invoice.status},${invoice.date},${_assignments[key] ?? ''},${_notifications[key] ?? 0}');
    }
    await DownloadService.saveCsvFile(filename: 'billing_payment_export', content: content.toString());
    if (mounted) showAppSnack(context, 'Billing & payment exported');
  }

  Future<void> _importInvoices() async {
    final controller = TextEditingController(
      text: 'Reserve Fund,John Doe,402,3200000,Next Friday,Pending\nSecurity Fee,Emma Reed,508,1800000,Tomorrow,Approved',
    );
    String? errorMessage;
    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) => AlertDialog(
          title: const Text('Import Billing & Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('One invoice per line: Title,Resident,Unit,Amount (VNĐ),Due Date,Status'),
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
                  final imported = <InvoiceItem>[];
                  for (final line in controller.text.split('\n').map((item) => item.trim()).where((item) => item.isNotEmpty)) {
                    final parts = line.split(',').map((item) => item.trim()).toList();
                    if (parts.length != 6) {
                      throw Exception('Each line must contain 6 comma-separated values.');
                    }
                    imported.add(
                      InvoiceItem(
                        title: parts[0],
                        resident: parts[1],
                        unit: parts[2],
                        amount: double.tryParse(parts[3]) ?? 0,
                        date: parts[4],
                        status: parts[5],
                      ),
                    );
                  }
                  setState(() {
                    _draftInvoices.addAll(imported);
                    if (imported.isNotEmpty) {
                      _selectedInvoiceKey = _invoiceKey(imported.first);
                    }
                  });
                  Navigator.pop(dialogContext);
                  showAppSnack(context, '${imported.length} billing records imported');
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

  Future<void> _trackInvoices(List<InvoiceItem> invoices) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Track Billing & Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invoices tracked: ${invoices.length}'),
            Text('Assigned queues: ${_assignments.length}'),
            Text('Schedules prepared: ${_schedules.length}'),
            Text('Notifications queued: ${_notifications.values.fold<int>(0, (sum, item) => sum + item)}'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _monitorInvoices(List<InvoiceItem> invoices) async {
    final overdue = invoices.where((item) => item.status == 'Overdue').length;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Monitor Billing & Payment', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text('Overdue invoices: $overdue'),
            Text('Assigned teams: ${_assignments.length}'),
            Text('Reminder schedules: ${_schedules.length}'),
          ],
        ),
      ),
    );
  }

  Future<void> _generateInvoices(List<InvoiceItem> invoices) async {
    final content = StringBuffer('metric,value\n');
    content.writeln('billing_records,${invoices.length}');
    content.writeln('total_invoiced,${invoices.fold<double>(0, (sum, item) => sum + item.amount)}');
    content.writeln('notification_jobs,${_notifications.values.fold<int>(0, (sum, item) => sum + item)}');
    content.writeln('schedule_jobs,${_schedules.length}');
    await DownloadService.saveCsvFile(filename: 'billing_payment_pack', content: content.toString());
    if (mounted) showAppSnack(context, 'Billing & payment pack generated');
  }
}

class _BillingScheduleItem {
  final String invoiceKey;
  final String title;
  final String dateLabel;

  const _BillingScheduleItem({
    required this.invoiceKey,
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
