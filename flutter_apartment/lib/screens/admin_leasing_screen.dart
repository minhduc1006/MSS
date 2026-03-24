import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../services/app_api_service.dart';
import '../widgets/common_widgets.dart';

class AdminLeasingScreen extends StatefulWidget {
  const AdminLeasingScreen({super.key});

  @override
  State<AdminLeasingScreen> createState() => _AdminLeasingScreenState();
}

class _AdminLeasingScreenState extends State<AdminLeasingScreen> {
  late Future<_LeasingBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LeasingBundle> _load() async {
    final results = await Future.wait<dynamic>([
      AppApiService.instance.fetchTenancyOverview(),
      AppApiService.instance.fetchUtilityMeters(),
      AppApiService.instance.fetchResidents(),
    ]);
    return _LeasingBundle(
      tenancies: results[0] as TenancyOverviewData,
      utilities: results[1] as UtilityMeterOverviewData,
      residents: results[2] as List<ResidentItem>,
    );
  }

  void _reload() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Leasing & Utilities',
      subtitle: 'Lease portfolio and utility submissions',
      role: UserRole.admin,
      currentIndex: 0,
      showBottomNav: false,
      actions: [ShellAction(icon: Icons.refresh_rounded, onPressed: _reload)],
      body: FutureBuilder<_LeasingBundle>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load leasing hub',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Expanded(
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
                            label: 'Active Leases',
                            value: '${data.tenancies.activeLeases}',
                            note: '${data.tenancies.leases.length} records',
                            icon: Icons.description_rounded,
                            iconColor: const Color(0xFF137FEC),
                          ),
                          MetricCard(
                            label: 'Recurring Rent',
                            value: formatMoney(
                                data.tenancies.monthlyRecurringRevenue),
                            note: 'Monthly lease revenue',
                            icon: Icons.home_work_rounded,
                            iconColor: const Color(0xFF22C55E),
                          ),
                          MetricCard(
                            label: 'Meter Total',
                            value: formatMoney(data.utilities.totalBilled),
                            note: '${data.utilities.meters.length} submissions',
                            icon: Icons.bolt_rounded,
                            iconColor: const Color(0xFFF59E0B),
                          ),
                          MetricCard(
                            label: 'Pending Review',
                            value: '${data.utilities.pendingSubmissions}',
                            note: 'Awaiting approval',
                            icon: Icons.speed_rounded,
                            iconColor: const Color(0xFFA855F7),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ResponsiveButtonBar(
                        children: [
                          FilledButton.icon(
                            onPressed: () => _showCreateLeaseSheet(data),
                            icon: const Icon(Icons.person_add_alt_1_rounded),
                            label: const Text('Create Lease'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _showCreateMeterSheet(data),
                            icon: const Icon(Icons.water_drop_rounded),
                            label: const Text('Submit Meter'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          color: Theme.of(context).cardColor,
                          border:
                              Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: const TabBar(
                          tabs: [
                            Tab(text: 'Lease Portfolio'),
                            Tab(text: 'Utility Meters'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.58,
                        child: TabBarView(
                          children: [
                            _leaseList(data.tenancies.leases),
                            _meterList(data.utilities.meters),
                          ],
                        ),
                      ),
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

  Widget _leaseList(List<TenancyItem> leases) {
    if (leases.isEmpty) {
      return const InfoCard(child: Text('No lease records available yet.'));
    }
    return ListView.separated(
      itemCount: leases.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lease = leases[index];
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('${lease.residentName} • Unit ${lease.unitNumber}',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  statusChip(lease.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('${lease.startDate} - ${lease.endDate} • ${lease.leaseType}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(
                  'Rent ${formatMoney(lease.monthlyRent)} • Deposit ${formatMoney(lease.securityDeposit)}',
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _pill('Active', () => _setLeaseStatus(lease, 'Active')),
                  _pill('Expiring', () => _setLeaseStatus(lease, 'Expiring')),
                  _pill('Closed', () => _setLeaseStatus(lease, 'Closed')),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _meterList(List<UtilityMeterItem> meters) {
    if (meters.isEmpty) {
      return const InfoCard(child: Text('No utility meter submissions yet.'));
    }
    return ListView.separated(
      itemCount: meters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final meter = meters[index];
        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                        '${meter.meterType} • ${meter.billingMonth} • Unit ${meter.unitNumber}',
                        style: Theme.of(context).textTheme.labelLarge),
                  ),
                  statusChip(meter.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  '${meter.previousReading.toStringAsFixed(0)} -> ${meter.currentReading.toStringAsFixed(0)} • Usage ${meter.usageAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              Text(formatMoney(meter.totalAmount),
                  style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  _pill('Approve',
                      () => _setMeterStatus(meter, 'Approved')),
                  if (meter.status.toLowerCase() != 'invoiced')
                    _pill('Generate Invoice',
                        () => _generateInvoice(meter)),
                ],
              ),
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

  Future<void> _showCreateLeaseSheet(_LeasingBundle data) async {
    final residents = data.residents.where((item) => item.id != null).toList();
    if (residents.isEmpty) {
      showAppSnack(context, 'No resident records available for lease creation');
      return;
    }

    ResidentItem selectedResident = residents.first;
    String leaseType = 'Lease';
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 365));
    final rentController = TextEditingController(text: '9500000');
    final depositController = TextEditingController(text: '19000000');
    final notesController =
        TextEditingController(text: 'Created from admin leasing hub.');
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
              Text('Create Lease',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<ResidentItem>(
                initialValue: selectedResident,
                items: residents
                    .map(
                      (resident) => DropdownMenuItem(
                        value: resident,
                        child: Text('${resident.name} • ${resident.unit}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => selectedResident = value);
                  }
                },
                decoration:
                    const InputDecoration(labelText: 'Resident / Unit'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: leaseType,
                items: const ['Lease', 'Owner Occupied', 'Renewal']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => leaseType = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Lease Type'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: startDate,
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setModalState(() => startDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today_rounded),
                      label: Text(DateFormat('MMM d, yyyy').format(startDate)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: sheetContext,
                          initialDate: endDate,
                          firstDate: startDate,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setModalState(() => endDate = picked);
                        }
                      },
                      icon: const Icon(Icons.event_available_rounded),
                      label: Text(DateFormat('MMM d, yyyy').format(endDate)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rentController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Monthly Rent'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: depositController,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Security Deposit'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final rent = double.tryParse(rentController.text.trim());
                        final deposit =
                            double.tryParse(depositController.text.trim());
                        if (rent == null || deposit == null) {
                          showAppSnack(sheetContext,
                              'Please enter valid rent and deposit amounts');
                          return;
                        }
                        setModalState(() => isSubmitting = true);
                        try {
                          final created =
                              await AppApiService.instance.createTenancy(
                            residentId: selectedResident.id!,
                            residentName: selectedResident.name,
                            residentEmail: selectedResident.email,
                            unitNumber: selectedResident.unit,
                            tower: 'Skyline Heights',
                            leaseType: leaseType,
                            startDate: startDate,
                            endDate: endDate,
                            monthlyRent: rent,
                            securityDeposit: deposit,
                            notes: notesController.text.trim().isEmpty
                                ? null
                                : notesController.text.trim(),
                          );
                          if (!mounted || !sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          _applyLeaseCreated(data, created);
                          showAppSnack(context, 'Lease record created');
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
                    : const Text('Save Lease'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateMeterSheet(_LeasingBundle data) async {
    final residents = data.residents.where((item) => item.id != null).toList();
    if (residents.isEmpty) {
      showAppSnack(context, 'No resident records available for meter input');
      return;
    }

    ResidentItem selectedResident = residents.first;
    String meterType = 'Electricity';
    final billingMonthController =
        TextEditingController(text: DateFormat('yyyy-MM').format(DateTime.now()));
    final previousController = TextEditingController(text: '1000');
    final currentController = TextEditingController(text: '1140');
    final unitPriceController = TextEditingController(text: '3200');
    final submittedByController = TextEditingController(text: 'Building Staff');
    final noteController =
        TextEditingController(text: 'Quick submission from admin hub.');
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
              Text('Submit Meter',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              DropdownButtonFormField<ResidentItem>(
                initialValue: selectedResident,
                items: residents
                    .map(
                      (resident) => DropdownMenuItem(
                        value: resident,
                        child: Text('${resident.name} • ${resident.unit}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => selectedResident = value);
                  }
                },
                decoration:
                    const InputDecoration(labelText: 'Resident / Unit'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: meterType,
                items: const ['Electricity', 'Water', 'Gas']
                    .map(
                      (value) => DropdownMenuItem(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setModalState(() => meterType = value);
                  }
                },
                decoration: const InputDecoration(labelText: 'Meter Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: billingMonthController,
                decoration:
                    const InputDecoration(labelText: 'Billing Month (yyyy-MM)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: previousController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Previous Reading'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: currentController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'Current Reading'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Unit Price'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: submittedByController,
                decoration: const InputDecoration(labelText: 'Submitted By'),
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
                        final previous =
                            double.tryParse(previousController.text.trim());
                        final current =
                            double.tryParse(currentController.text.trim());
                        final unitPrice =
                            double.tryParse(unitPriceController.text.trim());
                        if (previous == null ||
                            current == null ||
                            unitPrice == null ||
                            current < previous) {
                          showAppSnack(sheetContext,
                              'Please enter valid meter values');
                          return;
                        }
                        setModalState(() => isSubmitting = true);
                        try {
                          final created =
                              await AppApiService.instance.createUtilityMeter(
                            residentId: selectedResident.id!,
                            residentName: selectedResident.name,
                            residentEmail: selectedResident.email,
                            unitNumber: selectedResident.unit,
                            meterType: meterType,
                            billingMonth: billingMonthController.text.trim(),
                            previousReading: previous,
                            currentReading: current,
                            unitPrice: unitPrice,
                            submittedByName: submittedByController.text.trim(),
                            note: noteController.text.trim().isEmpty
                                ? null
                                : noteController.text.trim(),
                          );
                          if (!mounted || !sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          _applyMeterCreated(data, created);
                          showAppSnack(context, 'Utility meter submitted');
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
                    : const Text('Save Meter'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setLeaseStatus(TenancyItem lease, String status) async {
    final updated = await AppApiService.instance.updateTenancyStatus(
      tenancyId: lease.id!,
      status: status,
    );
    if (!mounted) return;
    final data = await _future;
    final leases = data.tenancies.leases
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    if (!mounted) return;
    setState(
      () => _future = Future.value(
        _LeasingBundle(
          residents: data.residents,
          tenancies: _tenancyOverviewFor(leases),
          utilities: data.utilities,
        ),
      ),
    );
    showAppSnack(context, 'Lease status updated');
  }

  Future<void> _setMeterStatus(UtilityMeterItem meter, String status) async {
    final updated = await AppApiService.instance.updateUtilityMeterStatus(
      meterId: meter.id!,
      status: status,
    );
    if (!mounted) return;
    final data = await _future;
    final meters = data.utilities.meters
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    if (!mounted) return;
    setState(
      () => _future = Future.value(
        _LeasingBundle(
          residents: data.residents,
          tenancies: data.tenancies,
          utilities: _utilityOverviewFor(meters),
        ),
      ),
    );
    showAppSnack(context, 'Meter status updated');
  }

  Future<void> _generateInvoice(UtilityMeterItem meter) async {
    final bill = await AppApiService.instance.generateUtilityInvoice(meter.id!);
    if (!mounted) return;
    final data = await _future;
    final meters = data.utilities.meters
        .map((item) => item.id == meter.id
            ? UtilityMeterItem(
                id: item.id,
                residentId: item.residentId,
                residentName: item.residentName,
                residentEmail: item.residentEmail,
                unitNumber: item.unitNumber,
                meterType: item.meterType,
                billingMonth: item.billingMonth,
                previousReading: item.previousReading,
                currentReading: item.currentReading,
                usageAmount: item.usageAmount,
                unitPrice: item.unitPrice,
                totalAmount: item.totalAmount,
                submittedByName: item.submittedByName,
                status: 'Invoiced',
                note: item.note,
              )
            : item)
        .toList();
    if (!mounted) return;
    setState(
      () => _future = Future.value(
        _LeasingBundle(
          residents: data.residents,
          tenancies: data.tenancies,
          utilities: _utilityOverviewFor(meters),
        ),
      ),
    );
    showAppSnack(context, '${bill.title} created');
  }

  void _applyLeaseCreated(_LeasingBundle data, TenancyItem created) {
    final leases = [created, ...data.tenancies.leases];
    setState(
      () => _future = Future.value(
        _LeasingBundle(
          residents: data.residents,
          tenancies: _tenancyOverviewFor(leases),
          utilities: data.utilities,
        ),
      ),
    );
  }

  void _applyMeterCreated(_LeasingBundle data, UtilityMeterItem created) {
    final meters = [created, ...data.utilities.meters];
    setState(
      () => _future = Future.value(
        _LeasingBundle(
          residents: data.residents,
          tenancies: data.tenancies,
          utilities: _utilityOverviewFor(meters),
        ),
      ),
    );
  }

  TenancyOverviewData _tenancyOverviewFor(List<TenancyItem> leases) {
    final active = leases
        .where((item) => item.status.toLowerCase() == 'active')
        .toList();
    return TenancyOverviewData(
      activeLeases: active.length,
      monthlyRecurringRevenue:
          active.fold<double>(0, (sum, item) => sum + item.monthlyRent),
      leases: leases,
    );
  }

  UtilityMeterOverviewData _utilityOverviewFor(List<UtilityMeterItem> meters) {
    return UtilityMeterOverviewData(
      totalBilled: meters.fold<double>(0, (sum, item) => sum + item.totalAmount),
      pendingSubmissions: meters
          .where((item) => item.status.toLowerCase() == 'submitted')
          .length,
      meters: meters,
    );
  }
}

class _LeasingBundle {
  final TenancyOverviewData tenancies;
  final UtilityMeterOverviewData utilities;
  final List<ResidentItem> residents;

  const _LeasingBundle({
    required this.tenancies,
    required this.utilities,
    required this.residents,
  });
}
