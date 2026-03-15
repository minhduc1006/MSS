import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_i18n.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../services/download_service.dart';
import '../widgets/common_widgets.dart';

class ResidentBillsScreen extends StatefulWidget {
  const ResidentBillsScreen({super.key});

  @override
  State<ResidentBillsScreen> createState() => _ResidentBillsScreenState();
}

class _ResidentBillsScreenState extends State<ResidentBillsScreen>
    with WidgetsBindingObserver {
  late Future<List<BillItem>> _billsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _billsFuture = AppApiService.instance.fetchResidentBills(context.read<AuthProvider>().currentUserId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _billsFuture = AppApiService.instance.fetchResidentBills(context.read<AuthProvider>().currentUserId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Billing & Payments',
      role: UserRole.resident,
      currentIndex: 1,
      actions: [
        ShellAction(icon: Icons.search_rounded, onPressed: _reload),
        ShellAction(icon: Icons.download_rounded, onPressed: () => _exportStatement(context)),
      ],
      body: FutureBuilder<List<BillItem>>(
        future: _billsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(context, title: 'Unable to load resident bills', onRetry: _reload);
          }

          final bills = snapshot.data ?? const <BillItem>[];
          final pending = bills.where((bill) => bill.status != 'Paid').toList();
          final paidBills = bills.where((bill) => bill.status == 'Paid').toList();
          final lastPayment = _mostRecentBill(paidBills);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  MetricCard(label: 'Outstanding', value: formatMoney(pending.fold<double>(0, (sum, bill) => sum + bill.amount)), note: '${pending.length} active', noteColor: const Color(0xFFF59E0B), icon: Icons.account_balance_wallet_rounded, iconColor: const Color(0xFF137FEC)),
                  MetricCard(
                    label: 'Last Payment',
                    value: lastPayment?.date ?? 'No payments yet',
                    note: lastPayment == null ? 'Waiting for first payment' : formatMoney(lastPayment.amount),
                    noteColor: const Color(0xFF22C55E),
                    icon: Icons.event_available_rounded,
                    iconColor: const Color(0xFF22C55E),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ResponsiveButtonBar(
                children: [
                  FilledButton.icon(
                    onPressed: pending.isEmpty ? null : () => _payFirstPending(pending.first),
                    icon: const Icon(Icons.payments_rounded),
                    label: Text(context.tr('Pay Now')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _exportStatement(context),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: Text(context.tr('Statement')),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const SectionTitle('Recent Bills'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting && bills.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...bills.map(
                  (bill) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Row(
                        children: [
                          SoftIcon(
                            icon: bill.type == 'parking'
                                ? Icons.local_parking_rounded
                                : bill.type == 'maintenance'
                                    ? Icons.home_repair_service_rounded
                                    : Icons.bolt_rounded,
                            color: statusColor(bill.status),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(bill.title, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033))),
                                const SizedBox(height: 4),
                                Text(bill.date, style: Theme.of(context).textTheme.bodyMedium),
                                if ((bill.description ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(bill.description!, style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(formatMoney(bill.amount), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: const Color(0xFF172033), fontSize: 18)),
                              const SizedBox(height: 8),
                              statusChip(bill.status),
                              if (bill.status != 'Paid' && bill.id != null) ...[
                                const SizedBox(height: 8),
                                TextButton(onPressed: () => _payFirstPending(bill), child: Text(context.tr('Pay'))),
                              ],
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

  Future<void> _payFirstPending(BillItem bill) async {
    if (bill.id == null) {
      showAppSnack(context, 'Unable to pay this bill');
      return;
    }
    try {
      final checkoutUrl = await AppApiService.instance.createBillCheckout(bill.id!);
      final launched = await launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
      if (!launched) {
        throw Exception('Unable to open the PayOS checkout page.');
      }
      if (mounted) {
        showAppSnack(
          context,
          'Complete the PayOS checkout in your browser, then return to the app. Your bills will refresh automatically.',
        );
      }
    } catch (error) {
      if (mounted) {
        showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _exportStatement(BuildContext context) async {
    final bills = await _billsFuture;
    final content = StringBuffer('Title,Amount,Date,Status\n');
    for (final bill in bills) {
      content.writeln('${bill.title},${bill.amount},${bill.date},${bill.status}');
    }
    await DownloadService.saveCsvFile(filename: 'resident_statement', content: content.toString());
    if (context.mounted) {
      showAppSnack(context, 'Statement downloaded');
    }
  }

  BillItem? _mostRecentBill(List<BillItem> items) {
    if (items.isEmpty) {
      return null;
    }

    final formatter = DateFormat('MMM d, yyyy');
    final sorted = [...items]
      ..sort((left, right) {
        final leftDate = _parseDate(left.date, formatter);
        final rightDate = _parseDate(right.date, formatter);
        return rightDate.compareTo(leftDate);
      });
    return sorted.first;
  }

  DateTime _parseDate(String value, DateFormat formatter) {
    try {
      return formatter.parse(value);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }
}
