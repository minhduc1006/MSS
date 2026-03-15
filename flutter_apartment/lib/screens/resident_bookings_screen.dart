import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_i18n.dart';
import '../core/app_media.dart';
import '../models/app_models.dart';
import '../providers/auth_provider.dart';
import '../services/app_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ResidentBookingsScreen extends StatefulWidget {
  const ResidentBookingsScreen({super.key});

  @override
  State<ResidentBookingsScreen> createState() => _ResidentBookingsScreenState();
}

class _ResidentBookingsScreenState extends State<ResidentBookingsScreen> {
  static const _timeSlots = [
    '08:00 AM - 10:00 AM',
    '10:00 AM - 12:00 PM',
    '02:00 PM - 04:00 PM',
    '04:00 PM - 06:00 PM',
    '06:00 PM - 08:00 PM',
  ];

  late Future<_ResidentBookingsData> _screenFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenFuture = _loadData();
  }

  void _reload() {
    setState(() {
      _screenFuture = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final compactMetrics = MediaQuery.sizeOf(context).width < 390;

    return AppShell(
      title: 'Bookings',
      subtitle: 'Resident facilities and announcements',
      role: UserRole.resident,
      currentIndex: 2,
      actions: [
        ShellAction(icon: Icons.refresh_rounded, onPressed: _reload),
      ],
      body: FutureBuilder<_ResidentBookingsData>(
        future: _screenFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError && snapshot.data == null) {
            return asyncErrorView(
              context,
              title: 'Unable to load bookings',
              message: snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          final bookings = data?.bookings ?? const <BookingItem>[];
          final announcements = data?.announcements ?? const <AnnouncementItem>[];
          final services = data?.services ?? const <MaintenanceFacility>[];
          final activeCount = bookings.where((booking) => !booking.status.toLowerCase().contains('cancel')).length;
          final readyCount = bookings.where((booking) => booking.status.toLowerCase().contains('confirm')).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: compactMetrics ? 0.92 : 1.08,
                children: [
                  MetricCard(
                    label: 'Active Bookings',
                    value: '$activeCount',
                    note: bookings.isEmpty ? 'No reservations yet' : '${bookings.length} reservations',
                    noteColor: const Color(0xFF22C55E),
                    icon: Icons.book_online_rounded,
                    iconColor: AppTheme.brand,
                  ),
                  MetricCard(
                    label: 'Confirmed Slots',
                    value: '$readyCount',
                    note: bookings.isEmpty ? 'Book a facility from dashboard' : 'Ready to use',
                    noteColor: const Color(0xFFF59E0B),
                    icon: Icons.event_available_rounded,
                    iconColor: const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InfoCard(
                color: AppTheme.brand.withValues(alpha: 0.05),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SoftIcon(icon: Icons.info_outline_rounded, color: AppTheme.brand, size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Booking management'),
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr('Use the resident dashboard quick actions to create a new pool or gym reservation. This page tracks all active slots and building updates.'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('Tap a service card or use Book Now to reserve a slot.'),
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: AppTheme.brand),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('All Bookings'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting && bookings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (bookings.isEmpty)
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('No bookings yet'), style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Text(
                        context.tr('Go to the resident dashboard and use Book Pool or Book Gym to create your first reservation.'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                )
              else
                ...bookings.map(
                  (booking) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppNetworkImage(
                            url: AppMedia.bookingImage(booking.title),
                            height: 120,
                            borderRadius: BorderRadius.circular(18),
                            overlay: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Color(0x88000000)],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      booking.title,
                                      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(booking.location, style: Theme.of(context).textTheme.bodyMedium),
                                    const SizedBox(height: 4),
                                    Text(booking.time, style: Theme.of(context).textTheme.bodySmall),
                                  ],
                                ),
                              ),
                              statusChip(booking.status),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const SectionTitle('Resident Services'),
              const SizedBox(height: 12),
              if (services.isEmpty)
                InfoCard(
                  child: Text(
                    context.tr('No resident services available right now.'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _isBookable(service) ? _openServiceBookingSheet(service) : _showServiceDetails(service),
                        child: InfoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppNetworkImage(
                                url: AppMedia.facilityImage(service.name),
                                height: 104,
                                borderRadius: BorderRadius.circular(18),
                                overlay: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Align(
                                    alignment: Alignment.topRight,
                                    child: ActionChip(
                                      onPressed: _isBookable(service) ? () => _openServiceBookingSheet(service) : null,
                                      avatar: Icon(
                                        _isBookable(service) ? Icons.calendar_month_rounded : Icons.lock_clock_rounded,
                                        size: 18,
                                        color: _isBookable(service) ? AppTheme.brand : AppTheme.textMuted,
                                      ),
                                      label: Text(context.tr(_isBookable(service) ? 'Book Now' : 'Unavailable')),
                                      labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            color: _isBookable(service) ? AppTheme.brand : AppTheme.textMuted,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      backgroundColor: Colors.white.withValues(alpha: 0.94),
                                      side: BorderSide(
                                        color: _isBookable(service)
                                            ? AppTheme.brand.withValues(alpha: 0.18)
                                            : AppTheme.textMuted.withValues(alpha: 0.18),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service.name,
                                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(service.area ?? service.lastCheck, style: Theme.of(context).textTheme.bodyMedium),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Health ${service.health}% - ${context.tr(service.status)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _servicePriceLabel(service),
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: _servicePrice(service) > 0 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          context.tr(
                                            _isBookable(service)
                                                ? 'Tap this card to reserve this service.'
                                                : 'This service is currently unavailable for booking.',
                                          ),
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                                color: _isBookable(service) ? AppTheme.brand : AppTheme.textMuted,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      statusChip(service.status),
                                      const SizedBox(height: 12),
                                      Icon(
                                        _isBookable(service) ? Icons.chevron_right_rounded : Icons.visibility_rounded,
                                        color: AppTheme.textMuted,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ),
                ),
              const SizedBox(height: 20),
              const SectionTitle('Building News'),
              const SizedBox(height: 12),
              if (announcements.isEmpty)
                InfoCard(
                  child: Text(
                    context.tr('No announcements available right now.'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...announcements.map(
                  (announcement) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      color: AppTheme.brand.withValues(alpha: 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppNetworkImage(
                            url: AppMedia.announcementImage(announcement.category),
                            height: 120,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  announcement.title,
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppTheme.textPrimary),
                                ),
                              ),
                              statusChip(announcement.category),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(announcement.content, style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Text(announcement.createdAt, style: Theme.of(context).textTheme.bodySmall),
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

  Future<_ResidentBookingsData> _loadData() async {
    final auth = context.read<AuthProvider>();
    final results = await Future.wait<dynamic>([
      AppApiService.instance.fetchBookings(auth.currentUserId),
      AppApiService.instance.fetchAnnouncements(),
      AppApiService.instance.fetchFacilities(),
    ]);

    return _ResidentBookingsData(
      bookings: results[0] as List<BookingItem>,
      announcements: results[1] as List<AnnouncementItem>,
      services: results[2] as List<MaintenanceFacility>,
    );
  }

  bool _isBookable(MaintenanceFacility service) {
    final status = service.status.toLowerCase();
    return service.id != null && !status.contains('maintenance') && !status.contains('deactivated') && !status.contains('reject');
  }

  bool _isFreeService(MaintenanceFacility service) {
    final normalized = service.name.toLowerCase();
    return normalized.contains('gym') || normalized.contains('swimming') || normalized.contains('pool');
  }

  double _servicePrice(MaintenanceFacility service) {
    final normalized = service.name.toLowerCase();
    if (_isFreeService(service)) {
      return 0;
    }
    if (normalized.contains('lounge')) {
      return 120000;
    }
    if (normalized.contains('bbq')) {
      return 250000;
    }
    if (normalized.contains('party')) {
      return 450000;
    }
    if (normalized.contains('meeting')) {
      return 180000;
    }
    if (normalized.contains('court')) {
      return 90000;
    }
    if (normalized.contains('parking')) {
      return 70000;
    }
    return 150000;
  }

  String _servicePriceLabel(MaintenanceFacility service) {
    final price = _servicePrice(service);
    if (price <= 0) {
      return context.tr('Free booking');
    }
    return '${context.tr('Booking fee')}: ${formatMoney(price)}';
  }

  Future<void> _showServiceDetails(MaintenanceFacility service) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(service.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${context.tr('Zone')}: ${service.area ?? '-'}'),
            const SizedBox(height: 8),
            Text('${context.tr('Status')}: ${context.tr(service.status)}'),
            const SizedBox(height: 8),
            Text('Health: ${service.health}%'),
            const SizedBox(height: 8),
            Text('Logs: ${service.logs.isEmpty ? 'None' : service.logs.take(3).join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.t('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _openServiceBookingSheet(MaintenanceFacility service) async {
    if (!_isBookable(service)) {
      showAppSnack(context, context.tr('This service is currently unavailable for booking.'));
      return;
    }

    DateTime selectedDate = DateTime.now();
    String selectedTime = _timeSlots.first;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${context.tr('Book')} ${service.name}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                service.area ?? service.lastCheck,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _servicePriceLabel(service),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _servicePrice(service) > 0 ? const Color(0xFFF59E0B) : const Color(0xFF22C55E),
                    ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: sheetContext,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                icon: const Icon(Icons.calendar_today_rounded),
                label: Text('${context.tr('Selected Date')}: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedTime,
                items: _timeSlots.map((slot) => DropdownMenuItem(value: slot, child: Text(slot))).toList(),
                onChanged: (value) => setModalState(() => selectedTime = value ?? _timeSlots.first),
                decoration: InputDecoration(labelText: context.tr('Select a time slot')),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final navigator = Navigator.of(sheetContext);
                  final auth = context.read<AuthProvider>();
                  final confirm = await showDialog<bool>(
                    context: sheetContext,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(context.tr('Confirm Booking')),
                      content: Text(
                        _servicePrice(service) <= 0
                            ? context.tr('Confirm this free service booking?')
                            : '${context.tr('Confirm this booking and create an invoice for')} ${formatMoney(_servicePrice(service))}?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(context.t('cancel')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(context.tr('Confirm')),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) {
                    return;
                  }
                  try {
                    final created = await AppApiService.instance.createBooking(
                      residentId: auth.currentUserId,
                      facilityId: service.id!,
                      bookingDate: selectedDate,
                      timeSlot: selectedTime,
                    );
                    if (_servicePrice(service) > 0) {
                      final user = auth.currentUser;
                      await AppApiService.instance.createInvoice(
                        residentId: auth.currentUserId,
                        residentName: user?.fullName ?? 'Resident',
                        residentEmail: user?.email,
                        unitNumber: user?.unitNumber ?? 'N/A',
                        title: '${service.name} Booking Fee',
                        category: 'service',
                        amount: _servicePrice(service),
                        dueDate: selectedDate,
                        description: 'Paid service booking for ${service.name} on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} - $selectedTime',
                      );
                    }
                    if (!mounted) {
                      return;
                    }
                    navigator.pop();
                    setState(() {
                      _screenFuture = _loadData();
                    });
                    showAppSnack(
                      context,
                      _servicePrice(service) > 0
                          ? '${created.title} ${context.tr('booked successfully')}. ${context.tr('An invoice has been added to your bills.')}'
                          : '${created.title} ${context.tr('booked successfully')}',
                    );
                  } catch (error) {
                    if (!mounted) {
                      return;
                    }
                    showAppSnack(context, error.toString().replaceFirst('Exception: ', ''));
                  }
                },
                child: Text(context.tr('Confirm Booking')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResidentBookingsData {
  final List<BookingItem> bookings;
  final List<AnnouncementItem> announcements;
  final List<MaintenanceFacility> services;

  const _ResidentBookingsData({
    required this.bookings,
    required this.announcements,
    required this.services,
  });
}
