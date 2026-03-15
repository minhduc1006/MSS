import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/app_i18n.dart';
import '../core/app_media.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  static const _residentTimeSlots = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  List<BookingItem> bookings = const [];
  List<AnnouncementItem> announcements = const [];
  List<BillItem> bills = const [];
  String? selectedTime;
  bool _loaded = false;
  bool _isLoading = true;
  String? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    _loadResidentData();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.currentUser;
    final outstandingBills =
        bills.where((bill) => bill.status != 'Paid').toList();
    final outstandingTotal =
        outstandingBills.fold<double>(0, (sum, bill) => sum + bill.amount);
    final nextDueBill = _nextDueBill(outstandingBills);
    return AppShell(
      title: currentUser?.fullName ?? 'John Doe',
      subtitle: 'Welcome back,',
      role: UserRole.resident,
      currentIndex: 0,
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _loadResidentData),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${currentUser?.unitNumber ?? '402'} - ${currentUser?.tower ?? 'Skyview Tower'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              statusChip('Active'),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.05,
            children: [
              MetricCard(
                label: 'Balance',
                value: formatMoney(outstandingTotal),
                note: outstandingBills.isEmpty
                    ? 'No unpaid bills'
                    : '${outstandingBills.length} unpaid',
                noteColor: Color(0xFFEF4444),
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppTheme.brand,
              ),
              MetricCard(
                label: 'Next Due',
                value: nextDueBill?.date ?? 'Up to date',
                note: nextDueBill?.title ?? 'No upcoming payment',
                icon: Icons.event_rounded,
                iconColor: AppTheme.brand,
              ),
            ],
          ),
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ] else if (_loadError != null) ...[
            const SizedBox(height: 16),
            InfoCard(
              color: const Color(0xFFFEF2F2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.tr('Resident data could not be loaded'),
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: const Color(0xFFB91C1C))),
                  const SizedBox(height: 6),
                  Text(_loadError!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: const Color(0xFF7F1D1D))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          const SectionTitle('Quick Actions'),
          const SizedBox(height: 12),
          SizedBox(
            height: 116,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ActionTile(
                    label: 'Pay Now',
                    icon: Icons.payments_rounded,
                    onTap: () =>
                        Navigator.pushNamed(context, '/resident/bills'),
                    primary: true),
                const SizedBox(width: 12),
                ActionTile(
                    label: 'Book Pool',
                    icon: Icons.pool_rounded,
                    onTap: () => _openBookingModal(context, 'Swimming Pool')),
                const SizedBox(width: 12),
                ActionTile(
                    label: 'Book Gym',
                    icon: Icons.fitness_center_rounded,
                    onTap: () => _openBookingModal(context, 'Gym Session')),
                const SizedBox(width: 12),
                ActionTile(
                    label: 'Help Desk',
                    icon: Icons.support_agent_rounded,
                    onTap: () =>
                        Navigator.pushNamed(context, '/resident/security')),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionTitle('Active Bookings',
              actionLabel: 'View All',
              onAction: () =>
                  Navigator.pushNamed(context, '/resident/bookings')),
          const SizedBox(height: 12),
          ...bookings.map(
            (booking) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppNetworkImage(
                      url: AppMedia.bookingImage(booking.title),
                      height: 110,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(booking.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(color: AppTheme.textPrimary)),
                              const SizedBox(height: 4),
                              Text(booking.time,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: AppTheme.textMuted),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const SectionTitle('Building News'),
          const SizedBox(height: 12),
          if (announcements.isNotEmpty)
            InfoCard(
              color: AppTheme.brand.withValues(alpha: 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppNetworkImage(
                    url: AppMedia.announcementImage(
                        announcements.first.category),
                    height: 128,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  const SizedBox(height: 12),
                  Text(announcements.first.title,
                      style: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Text(announcements.first.content,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 10),
                  Text(announcements.first.createdAt,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openBookingModal(BuildContext context, String title) async {
    selectedTime = _residentTimeSlots.first;
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${context.tr('Book')} $title',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedTime,
                items: [
                  for (final slot in _residentTimeSlots)
                    DropdownMenuItem(value: slot, child: Text(slot))
                ],
                onChanged: (value) => setModalState(() => selectedTime = value),
                decoration: InputDecoration(
                    labelText: context.tr('Select a time slot')),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final auth = context.read<AuthProvider>();
                  final navigator = Navigator.of(sheetContext);
                  final facilities =
                      await AppApiService.instance.fetchFacilities();
                  final matchedFacility = facilities.firstWhere(
                    (facility) => title.toLowerCase().contains('gym')
                        ? facility.name.toLowerCase().contains('gym')
                        : facility.name.toLowerCase().contains('pool'),
                    orElse: () => const MaintenanceFacility(
                        id: 1,
                        name: 'Swimming Pool',
                        status: 'Operational',
                        lastCheck: '',
                        health: 100,
                        logs: []),
                  );
                  final created = await AppApiService.instance.createBooking(
                    residentId: auth.currentUserId,
                    facilityId: matchedFacility.id ?? 1,
                    bookingDate: DateTime.now(),
                    timeSlot: selectedTime ?? _residentTimeSlots.first,
                  );
                  if (!mounted) {
                    return;
                  }
                  navigator.pop();
                  setState(() {
                    bookings.insert(0, created);
                  });
                  showAppSnack(this.context, '$title booked successfully');
                },
                child: Text(context.tr('Confirm Booking')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadResidentData() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        AppApiService.instance.fetchBookings(auth.currentUserId),
        AppApiService.instance.fetchAnnouncements(),
        AppApiService.instance.fetchResidentBills(auth.currentUserId),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        bookings = results[0] as List<BookingItem>;
        announcements = results[1] as List<AnnouncementItem>;
        bills = results[2] as List<BillItem>;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  BillItem? _nextDueBill(List<BillItem> items) {
    if (items.isEmpty) {
      return null;
    }

    final formatter = DateFormat('MMM d, yyyy');
    final sorted = [...items]..sort((left, right) {
        final leftDate = _parseBillDate(left.date, formatter);
        final rightDate = _parseBillDate(right.date, formatter);
        return leftDate.compareTo(rightDate);
      });
    return sorted.first;
  }

  DateTime _parseBillDate(String value, DateFormat formatter) {
    try {
      return formatter.parse(value);
    } catch (_) {
      return DateTime(9999);
    }
  }
}
