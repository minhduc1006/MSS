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
      title: 'Services',
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
              message:
                  snapshot.error.toString().replaceFirst('Exception: ', ''),
              onRetry: _reload,
            );
          }

          final data = snapshot.data;
          final bookings = data?.bookings ?? const <BookingItem>[];
          final announcements =
              data?.announcements ?? const <AnnouncementItem>[];
          final services = data?.services ?? const <MaintenanceFacility>[];
          final customRequests =
              data?.customRequests ?? const <CustomServiceRequestItem>[];
          final residentServices = services
              .where((service) => !_isRetiredService(service))
              .toList()
            ..sort((left, right) {
              if (_isParkingService(left) == _isParkingService(right)) {
                return left.name.compareTo(right.name);
              }
              return _isParkingService(left) ? -1 : 1;
            });
          final activeCount = bookings
              .where(
                  (booking) => !booking.status.toLowerCase().contains('cancel'))
              .length;
          final readyCount = bookings
              .where(
                  (booking) => booking.status.toLowerCase().contains('confirm'))
              .length;

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
                    note: bookings.isEmpty
                        ? 'No reservations yet'
                        : '${bookings.length} reservations',
                    noteColor: const Color(0xFF22C55E),
                    icon: Icons.book_online_rounded,
                    iconColor: AppTheme.brand,
                  ),
                  MetricCard(
                    label: 'Confirmed Slots',
                    value: '$readyCount',
                    note: bookings.isEmpty
                        ? 'Book a facility from dashboard'
                        : 'Ready to use',
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
                    const SoftIcon(
                        icon: Icons.info_outline_rounded,
                        color: AppTheme.brand,
                        size: 42),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Booking management'),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            context.tr(
                                'Use the resident dashboard quick actions to create a new pool or gym reservation. This page tracks all active slots and building updates.'),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            context.tr(
                                'Tap a service card or use Book Now to reserve a slot.'),
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(color: AppTheme.brand),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              InfoCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SoftIcon(
                      icon: Icons.handyman_rounded,
                      color: Color(0xFFF59E0B),
                      size: 42,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Custom Service Request',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(color: AppTheme.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Describe any in-unit request that is not listed above. Admin will assign staff, staff will quote first, and you only confirm when you agree with the price.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          FilledButton.tonalIcon(
                            onPressed: _openCustomServiceRequestSheet,
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('Request Custom Service'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionTitle('Resident Services'),
              const SizedBox(height: 12),
              if (residentServices.isEmpty)
                InfoCard(
                  child: Text(
                    context.tr('No resident services available right now.'),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...residentServices.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _isBookable(service)
                            ? _openServiceBookingSheet(service)
                            : _showServiceDetails(service),
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
                                      onPressed: _isBookable(service)
                                          ? () =>
                                              _openServiceBookingSheet(service)
                                          : null,
                                      avatar: Icon(
                                        _isBookable(service)
                                            ? Icons.calendar_month_rounded
                                            : Icons.lock_clock_rounded,
                                        size: 18,
                                        color: _isBookable(service)
                                            ? AppTheme.brand
                                            : AppTheme.textMuted,
                                      ),
                                      label: Text(context.tr(
                                          _isBookable(service)
                                              ? 'Book Now'
                                              : 'Unavailable')),
                                      labelStyle: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: _isBookable(service)
                                                ? AppTheme.brand
                                                : AppTheme.textMuted,
                                            fontWeight: FontWeight.w700,
                                          ),
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.94),
                                      side: BorderSide(
                                        color: _isBookable(service)
                                            ? AppTheme.brand
                                                .withValues(alpha: 0.18)
                                            : AppTheme.textMuted
                                                .withValues(alpha: 0.18),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                  color: AppTheme.textPrimary),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(service.area ?? service.lastCheck,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Health ${service.health}% - ${context.tr(service.status)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _servicePriceLabel(service),
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: _servicePrice(service) >
                                                        0
                                                    ? const Color(0xFFF59E0B)
                                                    : const Color(0xFF22C55E),
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
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: _isBookable(service)
                                                    ? AppTheme.brand
                                                    : AppTheme.textMuted,
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
                                        _isBookable(service)
                                            ? Icons.chevron_right_rounded
                                            : Icons.visibility_rounded,
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
              const SectionTitle('My Custom Requests'),
              const SizedBox(height: 12),
              if (customRequests.isEmpty)
                InfoCard(
                  child: Text(
                    'No custom service requests yet.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else
                ...customRequests.map(
                  (request) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      request.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                              color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${request.unitNumber} • ${request.zone}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      request.createdAt,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              statusChip(request.status),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            request.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          if ((request.preferredSchedule ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Preferred schedule: ${request.preferredSchedule}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (request.assignedStaffName != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Assigned staff: ${request.assignedStaffName}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (request.quotedPrice != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Quoted price: ${formatMoney(request.quotedPrice!)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: const Color(0xFFF59E0B),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                          if ((request.quoteNote ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Staff note: ${request.quoteNote}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if ((request.residentDecisionNote ?? '').isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Decision note: ${request.residentDecisionNote}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (request.status ==
                              'Awaiting Resident Confirmation') ...[
                            const SizedBox(height: 12),
                            ResponsiveButtonBar(
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      _respondToCustomServiceRequest(
                                    request,
                                    decision: 'reject',
                                  ),
                                  child: const Text('Reject Quote'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      _respondToCustomServiceRequest(
                                    request,
                                    decision: 'confirm',
                                  ),
                                  child: const Text('Confirm Quote'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              const SectionTitle('All Bookings'),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  bookings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (bookings.isEmpty)
                InfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(context.tr('No bookings yet'),
                          style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Text(
                        context.tr(
                            'Go to the resident dashboard and use Book Pool or Book Gym to create your first reservation.'),
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
                                  colors: [
                                    Colors.transparent,
                                    Color(0x88000000)
                                  ],
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                              color: AppTheme.textPrimary),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(booking.location,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                    const SizedBox(height: 4),
                                    Text(booking.time,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall),
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
                            url: AppMedia.announcementImage(
                                announcement.category),
                            height: 120,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  announcement.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(color: AppTheme.textPrimary),
                                ),
                              ),
                              statusChip(announcement.category),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(announcement.content,
                              style: Theme.of(context).textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Text(announcement.createdAt,
                              style: Theme.of(context).textTheme.bodySmall),
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
      _loadResidentCustomRequests(auth.currentUserId),
    ]);

    return _ResidentBookingsData(
      bookings: results[0] as List<BookingItem>,
      announcements: results[1] as List<AnnouncementItem>,
      services: results[2] as List<MaintenanceFacility>,
      customRequests: results[3] as List<CustomServiceRequestItem>,
    );
  }

  Future<List<CustomServiceRequestItem>> _loadResidentCustomRequests(
      int residentId) async {
    try {
      return await AppApiService.instance.fetchResidentCustomServiceRequests(
        residentId,
      );
    } catch (_) {
      return const <CustomServiceRequestItem>[];
    }
  }

  bool _isBookable(MaintenanceFacility service) {
    final status = service.status.toLowerCase();
    return service.id != null &&
        !status.contains('maintenance') &&
        !status.contains('deactivated') &&
        !status.contains('reject');
  }

  bool _isParkingService(MaintenanceFacility service) {
    // Thêm .trim() để xóa dấu cách thừa và dùng .contains() để bắt từ khóa bao quát hơn
    final type = service.serviceType.toLowerCase().trim();
    return type == 'parking' || type.contains('parking');
  }

  bool _isRetiredService(MaintenanceFacility service) {
    final normalized = service.name.trim().toLowerCase();
    return normalized == 'elevator b2' || normalized == 'community lounge';
  }

  bool _isFreeService(MaintenanceFacility service) {
    return service.oneTimePrice <= 0 &&
        service.monthlyPrice <= 0 &&
        service.yearlyPrice <= 0;
  }

  double _servicePrice(MaintenanceFacility service) {
    if (_isParkingService(service)) {
      return service.monthlyPrice;
    }
    return service.oneTimePrice;
  }

  String _servicePriceLabel(MaintenanceFacility service) {
    if (_isParkingService(service)) {
      return 'Monthly ${formatMoney(service.monthlyPrice)} - Yearly ${formatMoney(service.yearlyPrice)}';
    }
    if (_isFreeService(service)) {
      return context.tr('Free booking');
    }
    return '${context.tr('Booking fee')}: ${formatMoney(service.oneTimePrice)}';
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
            if ((service.description ?? '').isNotEmpty) ...[
              Text(service.description!),
              const SizedBox(height: 8),
            ],
            Text(_servicePriceLabel(service)),
            const SizedBox(height: 8),
            Text(
                'Logs: ${service.logs.isEmpty ? 'None' : service.logs.take(3).join(', ')}'),
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
      showAppSnack(context,
          context.tr('This service is currently unavailable for booking.'));
      return;
    }

    if (_isParkingService(service)) {
      await _openParkingBookingSheet(service);
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
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, 24 + MediaQuery.of(sheetContext).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${context.tr('Book')} ${service.name}',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                service.area ?? service.lastCheck,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                _servicePriceLabel(service),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: _servicePrice(service) > 0
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF22C55E),
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
                label: Text(
                    '${context.tr('Selected Date')}: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedTime,
                items: _timeSlots
                    .map((slot) =>
                        DropdownMenuItem(value: slot, child: Text(slot)))
                    .toList(),
                onChanged: (value) => setModalState(
                    () => selectedTime = value ?? _timeSlots.first),
                decoration: InputDecoration(
                    labelText: context.tr('Select a time slot')),
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
                        title: '${service.name} Service Fee',
                        category: 'service',
                        amount: service.oneTimePrice,
                        dueDate: selectedDate,
                        description:
                            'Paid service booking for ${service.name} on ${selectedDate.day}/${selectedDate.month}/${selectedDate.year} - $selectedTime',
                      );
                    }
                    if (!mounted) {
                      return;
                    }
                    final currentData = await _screenFuture.catchError(
                      (_) => const _ResidentBookingsData(
                        bookings: <BookingItem>[],
                        announcements: <AnnouncementItem>[],
                        services: <MaintenanceFacility>[],
                        customRequests: <CustomServiceRequestItem>[],
                      ),
                    );
                    if (!mounted) {
                      return;
                    }
                    navigator.pop();
                    setState(() {
                      _screenFuture = Future.value(
                        _ResidentBookingsData(
                          bookings: [created, ...currentData.bookings],
                          announcements: currentData.announcements,
                          services: currentData.services,
                          customRequests: currentData.customRequests,
                        ),
                      );
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
                    showAppSnack(context,
                        error.toString().replaceFirst('Exception: ', ''));
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

  Future<void> _openParkingBookingSheet(MaintenanceFacility service) async {
    final auth = context.read<AuthProvider>();
    DateTime selectedDate = DateTime.now();
    String selectedPlan = 'monthly';
    String? selectedSlot;
    final occupied =
        service.occupiedSlotCodes.map((slot) => slot.toUpperCase()).toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
          final selectedAmount = selectedPlan == 'yearly'
              ? service.yearlyPrice
              : service.monthlyPrice;
          final parkingRows = _parkingRows(service.slotCodes);

          Widget slotButton(String slot) {
            final isSelected = selectedSlot == slot;
            final isOccupied = occupied.contains(slot.toUpperCase());
            return GestureDetector(
              onTap: isOccupied
                  ? null
                  : () => setModalState(() => selectedSlot = slot),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 68,
                decoration: BoxDecoration(
                  color: isOccupied
                      ? const Color(0xFFD7DFEA)
                      : isSelected
                          ? const Color(0xFFE6F0FF)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.brand
                        : isOccupied
                            ? const Color(0xFF9AA9BF)
                            : const Color(0xFFD7E1EE),
                    width: isSelected ? 2.2 : 1.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: AppTheme.brand.withValues(alpha: 0.18),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.directions_car_rounded,
                      color:
                          isOccupied ? const Color(0xFF94A3B8) : AppTheme.brand,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: isOccupied
                                ? const Color(0xFF94A3B8)
                                : (isSelected
                                    ? AppTheme.brand
                                    : AppTheme.textPrimary),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF4F7FB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    decoration: const BoxDecoration(
                      color: AppTheme.brand,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Đặt chỗ đỗ xe',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800)),
                              const SizedBox(height: 8),
                              Text(
                                  service.description ??
                                      'Chọn slot đỗ xe ô tô và gói thuê phù hợp.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.88))),
                            ],
                          ),
                        ),
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(Icons.local_parking_rounded,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(20, 20, 20,
                          24 + MediaQuery.of(sheetContext).viewInsets.bottom),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('THỜI GIAN',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                            color: const Color(0xFF64748B),
                                            fontWeight: FontWeight.w800)),
                                const SizedBox(height: 14),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: sheetContext,
                                      initialDate: selectedDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)),
                                    );
                                    if (picked != null) {
                                      setModalState(
                                          () => selectedDate = picked);
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.calendar_today_rounded),
                                  label: Text(
                                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                                ),
                                const SizedBox(height: 18),
                                Text('GÓI THUÊ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                            color: const Color(0xFF64748B),
                                            fontWeight: FontWeight.w800)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _planCard(
                                        context,
                                        label: 'Theo tháng',
                                        price:
                                            '${formatMoney(service.monthlyPrice)}/tháng',
                                        active: selectedPlan == 'monthly',
                                        onTap: () => setModalState(
                                            () => selectedPlan = 'monthly'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _planCard(
                                        context,
                                        label: 'Theo năm',
                                        price:
                                            '${formatMoney(service.yearlyPrice)}/năm',
                                        active: selectedPlan == 'yearly',
                                        onTap: () => setModalState(
                                            () => selectedPlan = 'yearly'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Chọn vị trí',
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              _legendChip(context, 'Trống', Colors.white,
                                  const Color(0xFFD7E1EE)),
                              _legendChip(context, 'Đã chọn',
                                  const Color(0xFFE6F0FF), AppTheme.brand),
                              _legendChip(
                                  context,
                                  'Đã đặt',
                                  const Color(0xFFD7DFEA),
                                  const Color(0xFF9AA9BF)),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFDDE6F2),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: const Color(0xFFC8D4E4), width: 8),
                            ),
                            padding: const EdgeInsets.fromLTRB(14, 26, 14, 20),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC8D4E4),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text('LỐI VÀO',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF64748B))),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFC8D4E4),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    'ĐƯỜNG NỘI BỘ',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: const Color(0xFF64748B),
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.4,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                ...parkingRows.map(
                                  (row) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 68,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFC8D4E4),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Text(
                                            row.label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color:
                                                      const Color(0xFF64748B),
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        ...row.slots.asMap().entries.map(
                                              (entry) => Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    right: entry.key ==
                                                            row.slots.length - 1
                                                        ? 0
                                                        : 8,
                                                  ),
                                                  child:
                                                      slotButton(entry.value),
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          InfoCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('VỊ TRÍ ĐÃ CHỌN',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .labelMedium
                                                  ?.copyWith(
                                                      color: const Color(
                                                          0xFF94A3B8),
                                                      fontWeight:
                                                          FontWeight.w800)),
                                          const SizedBox(height: 8),
                                          Text(
                                            selectedSlot == null
                                                ? 'Chưa chọn slot'
                                                : '${_parkingRowLabel(selectedSlot!)} - $selectedSlot',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineSmall
                                                ?.copyWith(
                                                    color: AppTheme.brand,
                                                    fontWeight:
                                                        FontWeight.w800),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text('GIÁ DỰ KIẾN',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                    color:
                                                        const Color(0xFF94A3B8),
                                                    fontWeight:
                                                        FontWeight.w800)),
                                        const SizedBox(height: 8),
                                        Text(
                                          selectedAmount <= 0
                                              ? context.tr('Free booking')
                                              : formatMoney(selectedAmount),
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                  fontWeight: FontWeight.w800),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                FilledButton(
                                  onPressed: selectedSlot == null
                                      ? null
                                      : () async {
                                          try {
                                            final created = await AppApiService
                                                .instance
                                                .createBooking(
                                              residentId: auth.currentUserId,
                                              facilityId: service.id!,
                                              bookingDate: selectedDate,
                                              timeSlot: selectedPlan == 'yearly'
                                                  ? 'Yearly Subscription'
                                                  : 'Monthly Subscription',
                                              slotCode: selectedSlot,
                                              planType: selectedPlan,
                                            );
                                            final user = auth.currentUser;
                                            await AppApiService.instance
                                                .createInvoice(
                                              residentId: auth.currentUserId,
                                              residentName:
                                                  user?.fullName ?? 'Resident',
                                              residentEmail: user?.email,
                                              unitNumber:
                                                  user?.unitNumber ?? 'N/A',
                                              title:
                                                  'Parking Subscription - ${selectedSlot!}',
                                              category: 'parking',
                                              amount: selectedAmount,
                                              dueDate: selectedDate,
                                              description:
                                                  '${selectedPlan == 'yearly' ? 'Yearly' : 'Monthly'} parking slot booking for ${selectedSlot!}',
                                            );
                                            if (!sheetContext.mounted ||
                                                !mounted) {
                                              return;
                                            }
                                            final currentData =
                                                await _screenFuture.catchError(
                                              (_) => const _ResidentBookingsData(
                                                bookings: <BookingItem>[],
                                                announcements:
                                                    <AnnouncementItem>[],
                                                services:
                                                    <MaintenanceFacility>[],
                                              customRequests:
                                                    <CustomServiceRequestItem>[],
                                              ),
                                            );
                                            if (!sheetContext.mounted ||
                                                !mounted) {
                                              return;
                                            }
                                            Navigator.pop(sheetContext);
                                            setState(() {
                                              _screenFuture = Future.value(
                                                _ResidentBookingsData(
                                                  bookings: [
                                                    created,
                                                    ...currentData.bookings
                                                  ],
                                                  announcements:
                                                      currentData.announcements,
                                                  services:
                                                      currentData.services,
                                                  customRequests: currentData
                                                      .customRequests,
                                                ),
                                              );
                                            });
                                            showAppSnack(context,
                                                '${created.title} booked successfully. An invoice has been added to your bills.');
                                          } catch (error) {
                                            if (!mounted) {
                                              return;
                                            }
                                            showAppSnack(
                                                context,
                                                error.toString().replaceFirst(
                                                    'Exception: ', ''));
                                          }
                                        },
                                  child: const Text('Xác nhận đặt chỗ'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<_ParkingRow> _parkingRows(List<String> slots) {
    final rows = <String, List<String>>{};
    for (final slot in slots) {
      if (slot.isEmpty) {
        continue;
      }
      final key = slot.substring(0, 1).toUpperCase();
      rows.putIfAbsent(key, () => <String>[]).add(slot);
    }

    final orderedKeys = rows.keys.toList()..sort();
    return orderedKeys
        .map(
          (key) => _ParkingRow(
            label: key,
            slots: rows[key]!..sort(_compareParkingSlots),
          ),
        )
        .toList();
  }

  int _compareParkingSlots(String left, String right) {
    final leftNumber = int.tryParse(left.substring(1)) ?? 0;
    final rightNumber = int.tryParse(right.substring(1)) ?? 0;
    return leftNumber.compareTo(rightNumber);
  }

  String _parkingRowLabel(String slot) {
    final row = slot.substring(0, 1).toUpperCase();
    return 'Hàng $row';
  }

  Widget _planCard(
    BuildContext context, {
    required String label,
    required String price,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE6F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: active ? AppTheme.brand : const Color(0xFFD7E1EE),
              width: active ? 2 : 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .labelLarge
                    ?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(price,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: active ? AppTheme.brand : AppTheme.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _legendChip(
      BuildContext context, String label, Color color, Color border) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: border)),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Future<void> _openCustomServiceRequestSheet() async {
    final auth = context.read<AuthProvider>();
    final user = auth.currentUser;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final zoneController =
        TextEditingController(text: user?.unitNumber ?? 'Resident Unit');
    final scheduleController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          8,
          16,
          24 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Service title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: zoneController,
              decoration: const InputDecoration(labelText: 'Unit / Zone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: scheduleController,
              decoration: const InputDecoration(
                labelText: 'Preferred schedule',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Describe your request'),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                try {
                  final created = await AppApiService.instance.createCustomServiceRequest(
                    residentId: auth.currentUserId,
                    residentName: user?.fullName ?? 'Resident',
                    unitNumber: user?.unitNumber ?? 'N/A',
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    zone: zoneController.text.trim(),
                    preferredSchedule: scheduleController.text.trim().isEmpty
                        ? null
                        : scheduleController.text.trim(),
                  );
                  if (!sheetContext.mounted || !mounted) {
                    return;
                  }
                  final currentData = await _screenFuture.catchError(
                    (_) => const _ResidentBookingsData(
                      bookings: <BookingItem>[],
                      announcements: <AnnouncementItem>[],
                      services: <MaintenanceFacility>[],
                      customRequests: <CustomServiceRequestItem>[],
                    ),
                  );
                  if (!sheetContext.mounted || !mounted) {
                    return;
                  }
                  Navigator.pop(sheetContext);
                  setState(() {
                    _screenFuture = Future.value(
                      _ResidentBookingsData(
                        bookings: currentData.bookings,
                        announcements: currentData.announcements,
                        services: currentData.services,
                        customRequests: [created, ...currentData.customRequests],
                      ),
                    );
                  });
                  showAppSnack(context, 'Custom service request submitted');
                } catch (error) {
                  if (!mounted) {
                    return;
                  }
                  showAppSnack(
                    context,
                    error.toString().replaceFirst('Exception: ', ''),
                  );
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _respondToCustomServiceRequest(
    CustomServiceRequestItem request, {
    required String decision,
  }) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(decision == 'confirm' ? 'Confirm Quote' : 'Reject Quote'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              decision == 'confirm'
                  ? 'Confirm ${request.title} for ${formatMoney(request.quotedPrice ?? 0)}?'
                  : 'Reject the quote and send this request back for reassignment?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Note'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(decision == 'confirm' ? 'Confirm' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || request.id == null) {
      return;
    }

    try {
      await AppApiService.instance.respondCustomServiceRequest(
        requestId: request.id!,
        decision: decision,
        note: noteController.text.trim().isEmpty
            ? null
            : noteController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _screenFuture = _loadData();
      });
      showAppSnack(
        context,
        decision == 'confirm'
            ? 'Custom service quote confirmed'
            : 'Quote rejected and returned for reassignment',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnack(
        context,
        error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

class _ResidentBookingsData {
  final List<BookingItem> bookings;
  final List<AnnouncementItem> announcements;
  final List<MaintenanceFacility> services;
  final List<CustomServiceRequestItem> customRequests;

  const _ResidentBookingsData({
    required this.bookings,
    required this.announcements,
    required this.services,
    required this.customRequests,
  });
}

class _ParkingRow {
  final String label;
  final List<String> slots;

  const _ParkingRow({
    required this.label,
    required this.slots,
  });
}
