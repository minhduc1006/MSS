import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/app_models.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AppApiService {
  AppApiService._();

  static final AppApiService instance = AppApiService._();

  static const _apiHostOverride =
      String.fromEnvironment('API_HOST', defaultValue: '');
  static const _gatewayApiOverride =
      String.fromEnvironment('GATEWAY_API_URL', defaultValue: '');
  static const _authApiOverride =
      String.fromEnvironment('AUTH_API_URL', defaultValue: '');
  static const _billingApiOverride =
      String.fromEnvironment('BILLING_API_URL', defaultValue: '');
  static const _facilityApiOverride =
      String.fromEnvironment('FACILITY_API_URL', defaultValue: '');
  static const _securityApiOverride =
      String.fromEnvironment('SECURITY_API_URL', defaultValue: '');
  static const _operationsApiOverride =
      String.fromEnvironment('OPERATIONS_API_URL', defaultValue: '');

  static Uri get authBaseUri => _serviceUri(_authApiOverride);
  static Uri get billingBaseUri => _serviceUri(_billingApiOverride);
  static Uri get facilityBaseUri => _serviceUri(_facilityApiOverride);
  static Uri get securityBaseUri => _serviceUri(_securityApiOverride);
  static Uri get operationsBaseUri => _serviceUri(_operationsApiOverride);

  static String get resolvedApiHost => _resolveDefaultHost();

  final http.Client _client = http.Client();
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  final DateFormat _dateTimeFormat = DateFormat('MMM d, h:mm a');

  Future<SessionUser> login({
    required String email,
    required String password,
    UserRole? role,
  }) async {
    final payload = <String, Object?>{
      'email': email,
      'password': password,
    };
    if (role != null) {
      payload['role'] = role.name;
    }
    final json = await _postJson(
      authBaseUri,
      '/api/auth/login',
      payload,
    );
    return _sessionUserFromJson(json);
  }

  Future<void> requestPasswordResetOtp({
    required String email,
  }) async {
    await _postJson(
      authBaseUri,
      '/api/auth/reset-password/request-otp',
      {
        'email': email,
      },
    );
  }

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final json = await _postJson(
      authBaseUri,
      '/api/auth/reset-password/verify-otp',
      {
        'email': email,
        'otp': otp,
      },
    ) as Map<String, dynamic>;
    return json['resetToken'] as String? ?? '';
  }

  Future<void> completePasswordReset({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    await _postJson(
      authBaseUri,
      '/api/auth/reset-password/complete',
      {
        'email': email,
        'resetToken': resetToken,
        'newPassword': newPassword,
      },
    );
  }

  Future<void> changePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _postJson(
      authBaseUri,
      '/api/users/$userId/change-password',
      {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<SessionUser> fetchUserByEmail(String email) async {
    final json = await _getJson(authBaseUri,
        '/api/users/by-email?email=${Uri.encodeQueryComponent(email)}');
    return _sessionUserFromJson(json);
  }

  Future<List<ActivityItem>> fetchActivities() async {
    final json = await _getJson(operationsBaseUri, '/api/operations/activity')
        as List<dynamic>;
    return json
        .map(
          (item) => ActivityItem(
            id: item['id'] as int?,
            title: item['title'] as String? ?? '',
            desc: item['description'] as String? ?? '',
            time: _formatDateTime(item['createdAt']),
            kind: item['type'] as String? ?? 'info',
          ),
        )
        .toList();
  }

  Future<List<ResidentItem>> fetchResidents() async {
    final json =
        await _getJson(authBaseUri, '/api/users/residents') as List<dynamic>;
    return json
        .map(
          (item) => ResidentItem(
            id: item['id'] as int?,
            name: item['fullName'] as String? ?? '',
            unit: item['unitNumber'] as String? ?? '',
            lease: 'Lease: ${item['leaseStatus'] ?? 'Active'}',
            email: item['email'] as String? ?? '',
            status: item['status'] as String? ?? 'Active',
          ),
        )
        .toList();
  }

  Future<ResidentItem> createResident({
    required String fullName,
    required String unitNumber,
    required String tower,
    required String email,
  }) async {
    final json = await _postJson(
      authBaseUri,
      '/api/users/residents',
      {
        'fullName': fullName,
        'unitNumber': unitNumber,
        'tower': tower,
        'email': email,
      },
    );
    return ResidentItem(
      id: json['id'] as int?,
      name: json['fullName'] as String? ?? fullName,
      unit: json['unitNumber'] as String? ?? unitNumber,
      lease: 'Lease: ${json['leaseStatus'] ?? 'Active'}',
      email: json['email'] as String? ?? email,
      status: json['status'] as String? ?? 'Active',
    );
  }

  Future<void> deactivateResident(int residentId) async {
    await _delete(authBaseUri, '/api/users/residents/$residentId');
  }

  Future<void> activateResident(int residentId) async {
    await _postJson(
        authBaseUri, '/api/users/residents/$residentId/activate', const {});
  }

  Future<List<StaffItem>> fetchStaff() async {
    final json =
        await _getJson(authBaseUri, '/api/users/staff') as List<dynamic>;
    return json
        .map(
          (item) => StaffItem(
            id: item['id'] as int?,
            name: item['fullName'] as String? ?? '',
            role: item['role'] as String? ?? '',
            shift: item['shift'] as String? ?? '',
            email: item['email'] as String? ?? '',
            phone: item['phone'] as String? ?? '',
            status: item['status'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<List<AdminContactItem>> fetchAdminContacts() async {
    final json =
        await _getJson(authBaseUri, '/api/users/admins') as List<dynamic>;
    return json
        .map(
          (item) => AdminContactItem(
            id: item['id'] as int?,
            name: item['fullName'] as String? ?? '',
            email: item['email'] as String? ?? '',
            phone: item['phone'] as String? ?? '',
            status: item['status'] as String? ?? '',
          ),
        )
        .toList();
  }

  Future<StaffItem> createStaff({
    required String fullName,
    required String jobTitle,
    required String shift,
    required String email,
    required String phone,
  }) async {
    final json = await _postJson(
      authBaseUri,
      '/api/users/staff',
      {
        'fullName': fullName,
        'jobTitle': jobTitle,
        'shift': shift,
        'email': email,
        'phone': phone,
      },
    );
    return _staffFromJson(json);
  }

  Future<StaffItem> updateStaff({
    required int staffId,
    required String fullName,
    required String jobTitle,
    required String shift,
    required String email,
    required String phone,
    required String status,
  }) async {
    final json = await _putJson(
      authBaseUri,
      '/api/users/staff/$staffId',
      {
        'fullName': fullName,
        'jobTitle': jobTitle,
        'shift': shift,
        'email': email,
        'phone': phone,
        'status': status,
      },
    );
    return _staffFromJson(json);
  }

  Future<void> deactivateStaff(int staffId) async {
    await _delete(authBaseUri, '/api/users/staff/$staffId');
  }

  Future<void> activateStaff(int staffId) async {
    await _postJson(
        authBaseUri, '/api/users/staff/$staffId/activate', const {});
  }

  Future<BillingOverviewData> fetchBillingOverview(
      {String status = 'All'}) async {
    final json =
        await _getJson(billingBaseUri, '/api/billing/overview?status=$status')
            as Map<String, dynamic>;
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    final invoices = (json['invoices'] as List<dynamic>? ?? const [])
        .map(_invoiceFromJson)
        .toList();
    return BillingOverviewData(
      totalInvoiced: _toDouble(summary['totalInvoiced']),
      totalOutstanding: _toDouble(summary['totalOutstanding']),
      activeInvoices: (summary['activeInvoices'] as num?)?.toInt() ?? 0,
      invoices: invoices,
    );
  }

  Future<List<BillItem>> fetchResidentBills(int residentId) async {
    final json =
        await _getJson(billingBaseUri, '/api/billing/resident/$residentId')
            as List<dynamic>;
    return json.map(_billFromJson).toList();
  }

  Future<Uri> createBillCheckout(int invoiceId) async {
    final returnUrl =
        billingBaseUri.resolve('/api/billing/payos/return').toString();
    final cancelUrl =
        billingBaseUri.resolve('/api/billing/payos/cancel').toString();
    final json = await _postJson(
      billingBaseUri,
      '/api/billing/$invoiceId/checkout',
      {
        'returnUrl': returnUrl,
        'cancelUrl': cancelUrl,
      },
    ) as Map<String, dynamic>;
    final checkoutUrl = json['checkoutUrl'] as String?;
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception(
          'Billing checkout URL is missing from the PayOS response.');
    }
    return Uri.parse(checkoutUrl);
  }

  Future<BillItem> payBill(int invoiceId) async {
    final json = await _postJson(
        billingBaseUri, '/api/billing/$invoiceId/pay', const {});
    return _billFromJson(json);
  }

  Future<BillItem> createInvoice({
    required int residentId,
    required String residentName,
    String? residentEmail,
    required String unitNumber,
    required String title,
    required String category,
    required double amount,
    required DateTime dueDate,
    String? description,
  }) async {
    final json = await _postJson(
      billingBaseUri,
      '/api/billing/invoices',
      {
        'residentId': residentId,
        'residentName': residentName,
        'residentEmail': residentEmail,
        'unitNumber': unitNumber,
        'title': title,
        'category': category,
        'amount': amount,
        'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
        'description': description,
      },
    );
    if (json is Map<String, dynamic> && json['invoice'] != null) {
      return _billFromJson(json['invoice']);
    }
    return _billFromJson(json);
  }

  Future<BillItem> updateInvoice({
    required int invoiceId,
    int? residentId,
    required String residentName,
    String? residentEmail,
    required String unitNumber,
    required String title,
    required String category,
    required double amount,
    required String dueDate,
    String? description,
  }) async {
    final json = await _putJson(
      billingBaseUri,
      '/api/billing/invoices/$invoiceId',
      {
        'residentId': residentId,
        'residentName': residentName,
        'residentEmail': residentEmail,
        'unitNumber': unitNumber,
        'title': title,
        'category': category,
        'amount': amount,
        'dueDate': DateFormat('yyyy-MM-dd').format(_parseDateInput(dueDate)),
        'description': description,
      },
    );
    return _billFromJson(json);
  }

  Future<BillItem> updateInvoiceStatus({
    required int invoiceId,
    required String status,
  }) async {
    final json = await _postJson(
      billingBaseUri,
      '/api/billing/invoices/$invoiceId/status',
      {'status': status},
    );
    return _billFromJson(json);
  }

  Future<BillItem> deactivateInvoice(int invoiceId) async {
    final json = await _deleteWithResponse(
      billingBaseUri,
      '/api/billing/invoices/$invoiceId',
    );
    return _billFromJson(json);
  }

  Future<ApartmentStatsData> fetchApartmentStats() async {
    final json = await _getJson(billingBaseUri, '/api/apartments')
        as Map<String, dynamic>;
    final units = (json['units'] as List<dynamic>? ?? const [])
        .map(
          (item) => ApartmentUnitItem(
            id: item['id'] as int?,
            unitNumber: item['unitNumber'] as String? ?? '',
            tower: item['tower'] as String? ?? '',
            unitType: item['unitType'] as String? ?? '',
            occupancyStatus: item['occupancyStatus'] as String? ?? '',
            residentName: item['residentName'] as String?,
            balance: _toDouble(item['balance']),
          ),
        )
        .toList();
    return ApartmentStatsData(
      totalUnits: (json['totalUnits'] as num?)?.toInt() ?? units.length,
      occupiedUnits: (json['occupiedUnits'] as num?)?.toInt() ?? 0,
      units: units,
    );
  }

  Future<ApartmentUnitItem> createApartmentUnit({
    required String unitNumber,
    required String tower,
    required String unitType,
    required String occupancyStatus,
    String? residentName,
    double balance = 0,
  }) async {
    final json = await _postJson(
      billingBaseUri,
      '/api/apartments',
      {
        'unitNumber': unitNumber,
        'tower': tower,
        'unitType': unitType,
        'occupancyStatus': occupancyStatus,
        'residentName': residentName,
        'balance': balance,
      },
    );
    return _apartmentUnitFromJson(json);
  }

  Future<ApartmentUnitItem> updateApartmentUnit({
    required int unitId,
    required String unitNumber,
    required String tower,
    required String unitType,
    required String occupancyStatus,
    String? residentName,
    required double balance,
  }) async {
    final json = await _putJson(
      billingBaseUri,
      '/api/apartments/$unitId',
      {
        'unitNumber': unitNumber,
        'tower': tower,
        'unitType': unitType,
        'occupancyStatus': occupancyStatus,
        'residentName': residentName,
        'balance': balance,
      },
    );
    return _apartmentUnitFromJson(json);
  }

  Future<ApartmentUnitItem> updateApartmentUnitStatus({
    required int unitId,
    required String status,
  }) async {
    final json = await _postJson(
      billingBaseUri,
      '/api/apartments/$unitId/status',
      {'status': status},
    );
    return _apartmentUnitFromJson(json);
  }

  Future<ApartmentUnitItem> deactivateApartmentUnit(int unitId) async {
    final json = await _deleteWithResponse(
      billingBaseUri,
      '/api/apartments/$unitId',
    );
    return _apartmentUnitFromJson(json);
  }

  Future<TenancyOverviewData> fetchTenancyOverview() async {
    final json = await _getJson(billingBaseUri, '/api/tenancies')
        as Map<String, dynamic>;
    final leases = (json['leases'] as List<dynamic>? ?? const [])
        .map(_tenancyFromJson)
        .toList();
    return TenancyOverviewData(
      activeLeases: (json['activeLeases'] as num?)?.toInt() ?? 0,
      monthlyRecurringRevenue:
          _toDouble(json['monthlyRecurringRevenue']),
      leases: leases,
    );
  }

  Future<TenancyItem> createTenancy({
    required int residentId,
    required String residentName,
    String? residentEmail,
    required String unitNumber,
    required String tower,
    required String leaseType,
    required DateTime startDate,
    required DateTime endDate,
    required double monthlyRent,
    required double securityDeposit,
    String status = 'Active',
    String? notes,
  }) async {
    final json = await _postJson(
      billingBaseUri,
      '/api/tenancies',
      {
        'residentId': residentId,
        'residentName': residentName,
        'residentEmail': residentEmail,
        'unitNumber': unitNumber,
        'tower': tower,
        'leaseType': leaseType,
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        'monthlyRent': monthlyRent,
        'securityDeposit': securityDeposit,
        'status': status,
        'notes': notes,
      },
    );
    return _tenancyFromJson(json);
  }

  Future<TenancyItem> updateTenancy({
    required int tenancyId,
    required int residentId,
    required String residentName,
    String? residentEmail,
    required String unitNumber,
    required String tower,
    required String leaseType,
    required DateTime startDate,
    required DateTime endDate,
    required double monthlyRent,
    required double securityDeposit,
    required String status,
    String? notes,
  }) async {
    final json = await _putJson(
      billingBaseUri,
      '/api/tenancies/$tenancyId',
      {
        'residentId': residentId,
        'residentName': residentName,
        'residentEmail': residentEmail,
        'unitNumber': unitNumber,
        'tower': tower,
        'leaseType': leaseType,
        'startDate': DateFormat('yyyy-MM-dd').format(startDate),
        'endDate': DateFormat('yyyy-MM-dd').format(endDate),
        'monthlyRent': monthlyRent,
        'securityDeposit': securityDeposit,
        'status': status,
        'notes': notes,
      },
    );
    return _tenancyFromJson(json);
  }

  Future<TenancyItem> updateTenancyStatus({
    required int tenancyId,
    required String status,
  }) async {
    final json = await _postJson(
      billingBaseUri,
      '/api/tenancies/$tenancyId/status',
      {'status': status},
    );
    return _tenancyFromJson(json);
  }

  Future<UtilityMeterOverviewData> fetchUtilityMeters() async {
    final json = await _getJson(billingBaseUri, '/api/utilities/meters')
        as Map<String, dynamic>;
    final meters = (json['meters'] as List<dynamic>? ?? const [])
        .map(_utilityMeterFromJson)
        .toList();
    return UtilityMeterOverviewData(
      totalBilled: _toDouble(json['totalBilled']),
      pendingSubmissions:
          (json['pendingSubmissions'] as num?)?.toInt() ?? 0,
      meters: meters,
    );
  }

  Future<UtilityMeterItem> createUtilityMeter({
    required int residentId,
    required String residentName,
    String? residentEmail,
    required String unitNumber,
    required String meterType,
    required String billingMonth,
    required double previousReading,
    required double currentReading,
    required double unitPrice,
    required String submittedByName,
    String status = 'Submitted',
    String? note,
  }) async {
    final json = await _postJson(
      billingBaseUri,
      '/api/utilities/meters',
      {
        'residentId': residentId,
        'residentName': residentName,
        'residentEmail': residentEmail,
        'unitNumber': unitNumber,
        'meterType': meterType,
        'billingMonth': billingMonth,
        'previousReading': previousReading,
        'currentReading': currentReading,
        'unitPrice': unitPrice,
        'submittedByName': submittedByName,
        'status': status,
        'note': note,
      },
    );
    return _utilityMeterFromJson(json);
  }

  Future<UtilityMeterItem> updateUtilityMeter({
    required int meterId,
    required int residentId,
    required String residentName,
    String? residentEmail,
    required String unitNumber,
    required String meterType,
    required String billingMonth,
    required double previousReading,
    required double currentReading,
    required double unitPrice,
    required String submittedByName,
    required String status,
    String? note,
  }) async {
    final json = await _putJson(
      billingBaseUri,
      '/api/utilities/meters/$meterId',
      {
        'residentId': residentId,
        'residentName': residentName,
        'residentEmail': residentEmail,
        'unitNumber': unitNumber,
        'meterType': meterType,
        'billingMonth': billingMonth,
        'previousReading': previousReading,
        'currentReading': currentReading,
        'unitPrice': unitPrice,
        'submittedByName': submittedByName,
        'status': status,
        'note': note,
      },
    );
    return _utilityMeterFromJson(json);
  }

  Future<UtilityMeterItem> updateUtilityMeterStatus({
    required int meterId,
    required String status,
  }) async {
    final json = await _postJson(
      billingBaseUri,
      '/api/utilities/meters/$meterId/status',
      {'status': status},
    );
    return _utilityMeterFromJson(json);
  }

  Future<BillItem> generateUtilityInvoice(int meterId) async {
    final json = await _postJson(
      billingBaseUri,
      '/api/utilities/meters/$meterId/generate-invoice',
      const {},
    );
    return _billFromJson(json);
  }

  Future<List<MaintenanceFacility>> fetchFacilities() async {
    final json = await _getJson(facilityBaseUri, '/api/facilities')
        as Map<String, dynamic>;
    final facilities = (json['facilities'] as List<dynamic>? ?? const [])
        .map(_facilityFromJson)
        .toList();
    return facilities;
  }

  Future<MaintenanceFacility> createFacility({
    required String name,
    required String area,
    required String status,
    required int health,
    String? icon,
    String? description,
    String serviceType = 'shared',
    String bookingMode = 'timeslot',
    double oneTimePrice = 0,
    double monthlyPrice = 0,
    double yearlyPrice = 0,
    String? slotLayout,
  }) async {
    final json = await _postJson(
      facilityBaseUri,
      '/api/facilities',
      {
        'name': name,
        'area': area,
        'status': status,
        'health': health,
        'icon': icon,
        'description': description,
        'serviceType': serviceType,
        'bookingMode': bookingMode,
        'oneTimePrice': oneTimePrice,
        'monthlyPrice': monthlyPrice,
        'yearlyPrice': yearlyPrice,
        'slotLayout': slotLayout,
      },
    );
    return _facilityFromJson(json);
  }

  Future<MaintenanceFacility> updateFacility({
    required int facilityId,
    required String name,
    required String area,
    required String status,
    required int health,
    String? icon,
    String? description,
    required String serviceType,
    required String bookingMode,
    required double oneTimePrice,
    required double monthlyPrice,
    required double yearlyPrice,
    String? slotLayout,
  }) async {
    final json = await _putJson(
      facilityBaseUri,
      '/api/facilities/$facilityId',
      {
        'name': name,
        'area': area,
        'status': status,
        'health': health,
        'icon': icon,
        'description': description,
        'serviceType': serviceType,
        'bookingMode': bookingMode,
        'oneTimePrice': oneTimePrice,
        'monthlyPrice': monthlyPrice,
        'yearlyPrice': yearlyPrice,
        'slotLayout': slotLayout,
      },
    );
    return _facilityFromJson(json);
  }

  Future<MaintenanceFacility> updateFacilityStatus({
    required int facilityId,
    required String status,
  }) async {
    final json = await _postJson(
      facilityBaseUri,
      '/api/facilities/$facilityId/status',
      {'status': status},
    );
    return _facilityFromJson(json);
  }

  Future<MaintenanceFacility> deactivateFacility(int facilityId) async {
    final json = await _deleteWithResponse(
      facilityBaseUri,
      '/api/facilities/$facilityId',
    );
    return _facilityFromJson(json);
  }

  Future<void> addFacilityLog({
    required int facilityId,
    required String note,
    required String createdByName,
    bool markOperational = false,
  }) async {
    await _postJson(
      facilityBaseUri,
      '/api/facilities/$facilityId/logs',
      {
        'note': note,
        'createdByName': createdByName,
        'markOperational': markOperational,
      },
    );
  }

  Future<List<BookingItem>> fetchBookings(int residentId) async {
    final json =
        await _getJson(facilityBaseUri, '/api/bookings/resident/$residentId')
            as List<dynamic>;
    return json
        .map(
          (item) => BookingItem(
            id: item['id'] as int?,
            facilityId: item['facilityId'] as int?,
            title: item['title'] as String? ??
                item['facilityName'] as String? ??
                '',
            time:
                '${_formatDate(item['bookingDate'])} - ${item['timeSlot'] ?? ''}',
            location: item['facilityName'] as String? ?? '',
            status: item['status'] as String? ?? 'Confirmed',
            slotCode: item['slotCode'] as String?,
            planType: item['planType'] as String?,
            amount: _toDouble(item['amount']),
          ),
        )
        .toList();
  }

  Future<BookingItem> createBooking({
    required int residentId,
    required int facilityId,
    required DateTime bookingDate,
    required String timeSlot,
    String? slotCode,
    String? planType,
  }) async {
    final json = await _postJson(
      facilityBaseUri,
      '/api/bookings/resident/$residentId',
      {
        'facilityId': facilityId,
        'bookingDate': DateFormat('yyyy-MM-dd').format(bookingDate),
        'timeSlot': timeSlot,
        'slotCode': slotCode,
        'planType': planType,
      },
    );
    return BookingItem(
      id: json['id'] as int?,
      facilityId: json['facilityId'] as int?,
      title: json['title'] as String? ?? '',
      time: '${_formatDate(json['bookingDate'])} - ${json['timeSlot'] ?? ''}',
      location: json['facilityName'] as String? ?? '',
      status: json['status'] as String? ?? 'Confirmed',
      slotCode: json['slotCode'] as String?,
      planType: json['planType'] as String?,
      amount: _toDouble(json['amount']),
    );
  }

  Future<List<AnnouncementItem>> fetchAnnouncements() async {
    final json =
        await _getJson(facilityBaseUri, '/api/announcements') as List<dynamic>;
    return json
        .map(
          (item) => AnnouncementItem(
            id: item['id'] as int?,
            title: item['title'] as String? ?? '',
            content: item['content'] as String? ?? '',
            category: item['category'] as String? ?? '',
            createdAt: _formatDateTime(item['createdAt']),
          ),
        )
        .toList();
  }

  Future<SecurityOverviewData> fetchSecurityOverview() async {
    final json = await _getJson(securityBaseUri, '/api/security/overview')
        as Map<String, dynamic>;
    final incidents = (json['incidents'] as List<dynamic>? ?? const [])
        .map(_incidentFromJson)
        .toList();
    final logs = (json['recentLogs'] as List<dynamic>? ?? const [])
        .map(_securityLogFromJson)
        .toList();
    return SecurityOverviewData(incidents: incidents, recentLogs: logs);
  }

  Future<IncidentItem> createIncident({
    required String title,
    required String description,
    required String zone,
    required String severity,
    int? userId,
    String? audience,
  }) async {
    final json = await _postJson(
      securityBaseUri,
      '/api/security/incidents',
      {
        'title': title,
        'description': description,
        'zone': zone,
        'severity': severity,
        'userId': userId,
        'audience': audience,
      },
    );
    return _incidentFromJson(json);
  }

  Future<IncidentItem> updateIncident({
    required int incidentId,
    required String title,
    required String description,
    required String zone,
    required String status,
    required String severity,
    String? assignedStaffName,
  }) async {
    final json = await _putJson(
      securityBaseUri,
      '/api/security/incidents/$incidentId',
      {
        'title': title,
        'description': description,
        'zone': zone,
        'status': status,
        'severity': severity,
        'assignedStaffName': assignedStaffName,
      },
    );
    return _incidentFromJson(json);
  }

  Future<IncidentItem> updateIncidentStatus({
    required int incidentId,
    required String status,
  }) async {
    final json = await _postJson(
      securityBaseUri,
      '/api/security/incidents/$incidentId/status',
      {'status': status},
    );
    return _incidentFromJson(json);
  }

  Future<IncidentItem> deactivateIncident(int incidentId) async {
    final json = await _deleteWithResponse(
      securityBaseUri,
      '/api/security/incidents/$incidentId',
    );
    return _incidentFromJson(json);
  }

  Future<IncidentItem> triggerSos({
    required int userId,
    required String audience,
  }) async {
    final json = await _postJson(
      securityBaseUri,
      '/api/security/sos',
      {
        'userId': userId,
        'audience': audience,
      },
    );
    return _incidentFromJson(json);
  }

  Future<List<SecurityLog>> fetchSecurityHistory({
    required int userId,
    required String audience,
  }) async {
    final json = await _getJson(
            securityBaseUri, '/api/security/history/$audience/$userId')
        as Map<String, dynamic>;
    final logs = (json['logs'] as List<dynamic>? ?? const [])
        .map(_securityLogFromJson)
        .toList();
    return logs;
  }

  Future<AccountSummary> fetchAccountSummary(int userId) async {
    final json = await _getJson(authBaseUri, '/api/users/$userId/account')
        as Map<String, dynamic>;
    final userJson = json['user'] as Map<String, dynamic>? ?? const {};
    final statsJson = json['stats'] as Map<String, dynamic>? ?? const {};
    return AccountSummary(
      user: _sessionUserFromJson(userJson),
      stats: AccountStatsData(
        billCount: (statsJson['billCount'] as num?)?.toInt() ?? 0,
        guestCount: (statsJson['guestCount'] as num?)?.toInt() ?? 0,
        openIssueCount: (statsJson['openIssueCount'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Future<TaskBundleData> fetchStaffTasks(int staffId) async {
    final json = await _getJson(
            operationsBaseUri, '/api/operations/staff/$staffId/tasks')
        as Map<String, dynamic>;
    final tasks = (json['tasks'] as List<dynamic>? ?? const [])
        .map(
          (item) => TaskItem(
            id: item['id'] as int?,
            sourceId: item['sourceId'] as int?,
            sourceType: item['sourceType'] as String?,
            assignedStaffName: item['assignedStaffName'] as String?,
            title: item['title'] as String? ?? '',
            zone: item['zone'] as String? ?? '',
            priority: item['priority'] as String? ?? '',
            status: item['status'] as String? ?? '',
            category: item['category'] as String?,
          ),
        )
        .toList();
    return TaskBundleData(
      totalTasks: (json['totalTasks'] as num?)?.toInt() ?? tasks.length,
      completedTasks: (json['completedTasks'] as num?)?.toInt() ?? 0,
      tasks: tasks,
    );
  }

  Future<TaskItem> createStaffTask({
    required int assignedStaffId,
    required String assignedStaffName,
    required String title,
    required String zone,
    required String priority,
    required String category,
    required String sourceType,
    int? sourceId,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/tasks',
      {
        'assignedStaffId': assignedStaffId,
        'assignedStaffName': assignedStaffName,
        'title': title,
        'zone': zone,
        'priority': priority,
        'category': category,
        'sourceType': sourceType,
        'sourceId': sourceId,
      },
    );
    return TaskItem(
      id: json['id'] as int?,
      sourceId: json['sourceId'] as int?,
      sourceType: json['sourceType'] as String?,
      assignedStaffName: json['assignedStaffName'] as String?,
      title: json['title'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      priority: json['priority'] as String? ?? 'Medium',
      status: json['status'] as String? ?? 'Pending',
      category: json['category'] as String?,
    );
  }

  Future<List<PackageRecordItem>> fetchPackages() async {
    final json = await _getJson(operationsBaseUri, '/api/operations/packages')
        as List<dynamic>;
    return json.map(_packageRecordFromJson).toList();
  }

  Future<List<PackageRecordItem>> fetchResidentPackages(int residentId) async {
    final json = await _getJson(
      operationsBaseUri,
      '/api/operations/packages/resident/$residentId',
    ) as List<dynamic>;
    return json.map(_packageRecordFromJson).toList();
  }

  Future<PackageRecordItem> createPackageRecord({
    int? residentId,
    String? residentName,
    String? unitNumber,
    required String recordType,
    String? carrier,
    required String itemName,
    String? trackingCode,
    required String location,
    String? status,
    required String reportedByName,
    String? note,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/packages',
      {
        'residentId': residentId,
        'residentName': residentName,
        'unitNumber': unitNumber,
        'recordType': recordType,
        'carrier': carrier,
        'itemName': itemName,
        'trackingCode': trackingCode,
        'location': location,
        'status': status,
        'reportedByName': reportedByName,
        'note': note,
      },
    );
    return _packageRecordFromJson(json);
  }

  Future<PackageRecordItem> updatePackageRecordStatus({
    required int packageId,
    required String status,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/packages/$packageId/status',
      {'status': status},
    );
    return _packageRecordFromJson(json);
  }

  Future<List<ComplaintTicketItem>> fetchComplaints() async {
    final json =
        await _getJson(operationsBaseUri, '/api/operations/complaints')
            as List<dynamic>;
    return json.map(_complaintFromJson).toList();
  }

  Future<List<ComplaintTicketItem>> fetchResidentComplaints(
      int residentId) async {
    final json = await _getJson(
      operationsBaseUri,
      '/api/operations/complaints/resident/$residentId',
    ) as List<dynamic>;
    return json.map(_complaintFromJson).toList();
  }

  Future<List<ComplaintTicketItem>> fetchStaffComplaints(int staffId) async {
    final json = await _getJson(
      operationsBaseUri,
      '/api/operations/complaints/staff/$staffId',
    ) as List<dynamic>;
    return json.map(_complaintFromJson).toList();
  }

  Future<ComplaintTicketItem> createComplaint({
    required int residentId,
    required String residentName,
    required String unitNumber,
    required String category,
    required String title,
    required String description,
    String priority = 'Medium',
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/complaints',
      {
        'residentId': residentId,
        'residentName': residentName,
        'unitNumber': unitNumber,
        'category': category,
        'title': title,
        'description': description,
        'priority': priority,
      },
    );
    return _complaintFromJson(json);
  }

  Future<ComplaintTicketItem> assignComplaint({
    required int complaintId,
    required int staffId,
    required String staffName,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/complaints/$complaintId/assign',
      {
        'staffId': staffId,
        'staffName': staffName,
      },
    );
    return _complaintFromJson(json);
  }

  Future<ComplaintTicketItem> updateComplaintStatus({
    required int complaintId,
    required String status,
    String? responseNote,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/complaints/$complaintId/status',
      {
        'status': status,
        'responseNote': responseNote,
      },
    );
    return _complaintFromJson(json);
  }

  Future<ComplaintTicketItem> rateComplaint({
    required int complaintId,
    required int rating,
    String? review,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/complaints/$complaintId/rating',
      {
        'rating': rating,
        'review': review,
      },
    );
    return _complaintFromJson(json);
  }

  Future<List<StaffShiftItem>> fetchShifts() async {
    final json = await _getJson(operationsBaseUri, '/api/operations/shifts')
        as List<dynamic>;
    return json.map(_staffShiftFromJson).toList();
  }

  Future<List<StaffShiftItem>> fetchStaffShifts(int staffId) async {
    final json = await _getJson(
      operationsBaseUri,
      '/api/operations/shifts/staff/$staffId',
    ) as List<dynamic>;
    return json.map(_staffShiftFromJson).toList();
  }

  Future<StaffShiftItem> createStaffShift({
    required int staffId,
    required String staffName,
    required String role,
    required DateTime shiftDate,
    required String shiftLabel,
    required String zone,
    required String startTime,
    required String endTime,
    String status = 'Scheduled',
    String? note,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/shifts',
      {
        'staffId': staffId,
        'staffName': staffName,
        'role': role,
        'shiftDate': DateFormat('yyyy-MM-dd').format(shiftDate),
        'shiftLabel': shiftLabel,
        'zone': zone,
        'startTime': startTime,
        'endTime': endTime,
        'status': status,
        'note': note,
      },
    );
    return _staffShiftFromJson(json);
  }

  Future<StaffShiftItem> updateStaffShift({
    required int shiftId,
    required int staffId,
    required String staffName,
    required String role,
    required DateTime shiftDate,
    required String shiftLabel,
    required String zone,
    required String startTime,
    required String endTime,
    required String status,
    String? note,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/shifts/$shiftId',
      {
        'staffId': staffId,
        'staffName': staffName,
        'role': role,
        'shiftDate': DateFormat('yyyy-MM-dd').format(shiftDate),
        'shiftLabel': shiftLabel,
        'zone': zone,
        'startTime': startTime,
        'endTime': endTime,
        'status': status,
        'note': note,
      },
    );
    return _staffShiftFromJson(json);
  }

  Future<List<CustomServiceRequestItem>> fetchCustomServiceRequests() async {
    final json = await _getJson(
            operationsBaseUri, '/api/operations/custom-service-requests')
        as List<dynamic>;
    return json.map(_customServiceRequestFromJson).toList();
  }

  Future<List<CustomServiceRequestItem>> fetchResidentCustomServiceRequests(
      int residentId) async {
    final json = await _getJson(
      operationsBaseUri,
      '/api/operations/custom-service-requests/resident/$residentId',
    ) as List<dynamic>;
    return json.map(_customServiceRequestFromJson).toList();
  }

  Future<List<CustomServiceRequestItem>> fetchStaffCustomServiceRequests(
      int staffId) async {
    final json = await _getJson(
      operationsBaseUri,
      '/api/operations/custom-service-requests/staff/$staffId',
    ) as List<dynamic>;
    return json.map(_customServiceRequestFromJson).toList();
  }

  Future<CustomServiceRequestItem> createCustomServiceRequest({
    required int residentId,
    required String residentName,
    required String unitNumber,
    required String title,
    required String description,
    required String zone,
    String? preferredSchedule,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/custom-service-requests',
      {
        'residentId': residentId,
        'residentName': residentName,
        'unitNumber': unitNumber,
        'title': title,
        'description': description,
        'zone': zone,
        'preferredSchedule': preferredSchedule,
      },
    );
    return _customServiceRequestFromJson(json);
  }

  Future<CustomServiceRequestItem> assignCustomServiceRequest({
    required int requestId,
    required int staffId,
    required String staffName,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/custom-service-requests/$requestId/assign',
      {
        'staffId': staffId,
        'staffName': staffName,
      },
    );
    return _customServiceRequestFromJson(json);
  }

  Future<CustomServiceRequestItem> quoteCustomServiceRequest({
    required int requestId,
    required double quotedPrice,
    String? quoteNote,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/custom-service-requests/$requestId/quote',
      {
        'quotedPrice': quotedPrice,
        'quoteNote': quoteNote,
      },
    );
    return _customServiceRequestFromJson(json);
  }

  Future<CustomServiceRequestItem> respondCustomServiceRequest({
    required int requestId,
    required String decision,
    String? note,
  }) async {
    final json = await _postJson(
      operationsBaseUri,
      '/api/operations/custom-service-requests/$requestId/resident-decision',
      {
        'decision': decision,
        'note': note,
      },
    );
    return _customServiceRequestFromJson(json);
  }

  Future<dynamic> _getJson(Uri base, String path) async {
    return _sendWithFallback(
      base,
      (uri) => _client.get(uri.resolve(path), headers: {
        'Content-Type': 'application/json'
      }).timeout(const Duration(seconds: 8)),
    );
  }

  Future<dynamic> _postJson(
      Uri base, String path, Map<String, dynamic> body) async {
    return _sendWithFallback(
      base,
      (uri) => _client
          .post(
            uri.resolve(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8)),
    );
  }

  Future<dynamic> _putJson(
      Uri base, String path, Map<String, dynamic> body) async {
    return _sendWithFallback(
      base,
      (uri) => _client
          .put(
            uri.resolve(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 8)),
    );
  }

  Future<void> _delete(Uri base, String path) async {
    await _sendWithFallback(
      base,
      (uri) => _client.delete(
        uri.resolve(path),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8)),
    );
  }

  Future<dynamic> _deleteWithResponse(Uri base, String path) async {
    return _sendWithFallback(
      base,
      (uri) => _client.delete(
        uri.resolve(path),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 8)),
    );
  }

  Future<dynamic> _sendWithFallback(
    Uri primaryBase,
    Future<http.Response> Function(Uri base) send,
  ) async {
    Object? lastError;
    for (final base in _candidateBases(primaryBase)) {
      try {
        final response = await send(base);
        return _decodeResponse(response);
      } on TimeoutException catch (error) {
        lastError = error;
      } on http.ClientException catch (error) {
        lastError = error;
      }
    }

    throw Exception(
      'Unable to reach backend. Tried ${_candidateBases(primaryBase).map((uri) => uri.toString()).join(', ')}. '
      'Original error: ${lastError ?? 'unknown network error'}',
    );
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    }
    final responseBody = response.body.trim();
    String message = 'Request failed: ${response.statusCode}';
    if (responseBody.isNotEmpty) {
      try {
        final parsed = jsonDecode(responseBody);
        if (parsed is Map<String, dynamic>) {
          final parsedMessage = (parsed['message'] as String?)?.trim();
          final parsedError = (parsed['error'] as String?)?.trim();
          final parsedPath = (parsed['path'] as String?)?.trim();
          final parsedStatus =
              parsed['status'] is int ? parsed['status'] as int : null;

          message = parsedMessage?.isNotEmpty == true
              ? parsedMessage!
              : (parsedError?.isNotEmpty == true ? parsedError! : responseBody);

          // Spring Boot default error payloads include `status` + `path`, which is
          // very helpful when debugging "Not Found" issues from the mobile app.
          if (parsedStatus != null ||
              (parsedPath != null && parsedPath.isNotEmpty)) {
            final suffix = <String>[];
            if (parsedStatus != null) {
              suffix.add('($parsedStatus)');
            }
            if (parsedPath != null && parsedPath.isNotEmpty) {
              suffix.add(parsedPath);
            }
            message = '$message ${suffix.join(' ')}'.trim();
          }
        } else {
          message = responseBody;
        }
      } catch (_) {
        message = responseBody;
      }
    }
    throw ApiException(message, statusCode: response.statusCode);
  }

  static Uri _serviceUri(String serviceOverride) {
    if (serviceOverride.isNotEmpty) {
      return Uri.parse(_normalizeBaseUrl(serviceOverride));
    }
    if (_gatewayApiOverride.isNotEmpty) {
      return Uri.parse(_normalizeBaseUrl(_gatewayApiOverride));
    }
    final hostOverride = _apiHostOverride;
    if (hostOverride.isNotEmpty) {
      return Uri.parse('${_normalizeBaseUrl(hostOverride)}:8080');
    }
    return Uri.parse('${_resolveDefaultHost()}:8080');
  }

  static List<Uri> _candidateBases(Uri primaryBase) {
    final candidates = <Uri>[primaryBase];
    final port = primaryBase.hasPort ? primaryBase.port : null;
    if (port == null ||
        _apiHostOverride.isNotEmpty ||
        _hasExplicitServiceOverride(primaryBase)) {
      return candidates;
    }

    for (final host in _fallbackHostsForPlatform(primaryBase.host)) {
      final candidate = primaryBase.replace(host: host);
      if (!candidates.contains(candidate)) {
        candidates.add(candidate);
      }
    }
    return candidates;
  }

  static bool _hasExplicitServiceOverride(Uri primaryBase) {
    return primaryBase == authBaseUri && _authApiOverride.isNotEmpty ||
        primaryBase == billingBaseUri && _billingApiOverride.isNotEmpty ||
        primaryBase == facilityBaseUri && _facilityApiOverride.isNotEmpty ||
        primaryBase == securityBaseUri && _securityApiOverride.isNotEmpty ||
        primaryBase == operationsBaseUri && _operationsApiOverride.isNotEmpty;
  }

  static String _resolveDefaultHost() {
    if (kIsWeb) {
      return 'http://127.0.0.1';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return 'http://127.0.0.1';
      case TargetPlatform.fuchsia:
        return 'http://127.0.0.1';
    }
  }

  static List<String> _fallbackHostsForPlatform(String primaryHost) {
    final hosts = <String>[];
    void add(String host) {
      if (host != primaryHost && !hosts.contains(host)) {
        hosts.add(host);
      }
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        add('10.0.2.2');
        add('10.0.3.2');
        add('127.0.0.1');
        add('localhost');
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        add('127.0.0.1');
        add('localhost');
    }

    if (kIsWeb) {
      add('127.0.0.1');
      add('localhost');
    }

    return hosts;
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return 'http://$trimmed';
  }

  DateTime _parseDateInput(String value) {
    final trimmed = value.trim();
    final formats = [
      DateFormat('yyyy-MM-dd'),
      DateFormat('MMM d, yyyy'),
      DateFormat('d/M/yyyy'),
      DateFormat('M/d/yyyy'),
    ];
    for (final format in formats) {
      try {
        return format.parseStrict(trimmed);
      } catch (_) {
        continue;
      }
    }
    return DateTime.now();
  }

  SessionUser _sessionUserFromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: _userRoleFromString(json['role'] as String?),
      unitNumber: json['unitNumber'] as String?,
      tower: json['tower'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  UserRole _userRoleFromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'staff':
        return UserRole.staff;
      default:
        return UserRole.resident;
    }
  }

  StaffItem _staffFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return StaffItem(
      id: (json['id'] as num?)?.toInt(),
      name: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      shift: json['shift'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? '',
    );
  }

  InvoiceItem _invoiceFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return InvoiceItem(
      id: (json['id'] as num?)?.toInt(),
      residentId: (json['residentId'] as num?)?.toInt(),
      unit: json['unitNumber'] as String? ?? '',
      resident: json['residentName'] as String? ?? '',
      amount: _toDouble(json['amount']),
      status: json['status'] as String? ?? '',
      date: _formatDate(json['dueDate']),
      title: json['title'] as String?,
      category: json['category'] as String?,
      description: json['description'] as String?,
    );
  }

  BillItem _billFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return BillItem(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String? ?? '',
      amount: _toDouble(json['amount']),
      date: _formatDate(json['dueDate']),
      status: json['status'] as String? ?? '',
      type: json['category'] as String? ?? '',
      description: json['description'] as String?,
      residentId: (json['residentId'] as num?)?.toInt(),
      residentName: json['residentName'] as String?,
      unitNumber: json['unitNumber'] as String?,
    );
  }

  ApartmentUnitItem _apartmentUnitFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return ApartmentUnitItem(
      id: (json['id'] as num?)?.toInt(),
      unitNumber: json['unitNumber'] as String? ?? '',
      tower: json['tower'] as String? ?? '',
      unitType: json['unitType'] as String? ?? '',
      occupancyStatus: json['occupancyStatus'] as String? ?? '',
      residentName: json['residentName'] as String?,
      balance: _toDouble(json['balance']),
    );
  }

  TenancyItem _tenancyFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return TenancyItem(
      id: (json['id'] as num?)?.toInt(),
      residentId: (json['residentId'] as num?)?.toInt(),
      residentName: json['residentName'] as String? ?? '',
      residentEmail: json['residentEmail'] as String?,
      unitNumber: json['unitNumber'] as String? ?? '',
      tower: json['tower'] as String? ?? '',
      leaseType: json['leaseType'] as String? ?? 'Lease',
      startDate: _formatDate(json['startDate']),
      endDate: _formatDate(json['endDate']),
      monthlyRent: _toDouble(json['monthlyRent']),
      securityDeposit: _toDouble(json['securityDeposit']),
      status: json['status'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }

  UtilityMeterItem _utilityMeterFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return UtilityMeterItem(
      id: (json['id'] as num?)?.toInt(),
      residentId: (json['residentId'] as num?)?.toInt(),
      residentName: json['residentName'] as String? ?? '',
      residentEmail: json['residentEmail'] as String?,
      unitNumber: json['unitNumber'] as String? ?? '',
      meterType: json['meterType'] as String? ?? '',
      billingMonth: json['billingMonth'] as String? ?? '',
      previousReading: _toDouble(json['previousReading']),
      currentReading: _toDouble(json['currentReading']),
      usageAmount: _toDouble(json['usageAmount']),
      unitPrice: _toDouble(json['unitPrice']),
      totalAmount: _toDouble(json['totalAmount']),
      submittedByName: json['submittedByName'] as String? ?? '',
      status: json['status'] as String? ?? '',
      note: json['note'] as String?,
    );
  }

  PackageRecordItem _packageRecordFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return PackageRecordItem(
      id: (json['id'] as num?)?.toInt(),
      residentId: (json['residentId'] as num?)?.toInt(),
      residentName: json['residentName'] as String?,
      unitNumber: json['unitNumber'] as String?,
      recordType: json['recordType'] as String? ?? '',
      carrier: json['carrier'] as String?,
      itemName: json['itemName'] as String? ?? '',
      trackingCode: json['trackingCode'] as String?,
      location: json['location'] as String? ?? '',
      status: json['status'] as String? ?? '',
      reportedByName: json['reportedByName'] as String? ?? '',
      receivedAt: _formatDateTime(json['receivedAt']),
      pickedUpAt: json['pickedUpAt'] == null
          ? null
          : _formatDateTime(json['pickedUpAt']),
      note: json['note'] as String?,
    );
  }

  ComplaintTicketItem _complaintFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return ComplaintTicketItem(
      id: (json['id'] as num?)?.toInt(),
      residentId: (json['residentId'] as num?)?.toInt() ?? 0,
      residentName: json['residentName'] as String? ?? '',
      unitNumber: json['unitNumber'] as String? ?? '',
      category: json['category'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      priority: json['priority'] as String? ?? '',
      status: json['status'] as String? ?? '',
      assignedStaffId: (json['assignedStaffId'] as num?)?.toInt(),
      assignedStaffName: json['assignedStaffName'] as String?,
      responseNote: json['responseNote'] as String?,
      residentRating: (json['residentRating'] as num?)?.toInt(),
      residentReview: json['residentReview'] as String?,
      createdAt: _formatDateTime(json['createdAt']),
      resolvedAt:
          json['resolvedAt'] == null ? null : _formatDateTime(json['resolvedAt']),
    );
  }

  StaffShiftItem _staffShiftFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return StaffShiftItem(
      id: (json['id'] as num?)?.toInt(),
      staffId: (json['staffId'] as num?)?.toInt() ?? 0,
      staffName: json['staffName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      shiftDate: _formatDate(json['shiftDate']),
      shiftLabel: json['shiftLabel'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '',
      endTime: json['endTime'] as String? ?? '',
      status: json['status'] as String? ?? '',
      note: json['note'] as String?,
    );
  }

  MaintenanceFacility _facilityFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    final logs = (json['logs'] as List<dynamic>? ?? const [])
        .map((log) => log['note'] as String? ?? '')
        .toList();
    return MaintenanceFacility(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      lastCheck: _formatDateTime(json['lastCheckAt']),
      health: (json['health'] as num?)?.toInt() ?? 0,
      logs: logs,
      area: json['area'] as String?,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      serviceType: json['serviceType'] as String? ?? 'shared',
      bookingMode: json['bookingMode'] as String? ?? 'timeslot',
      oneTimePrice: _toDouble(json['oneTimePrice']),
      monthlyPrice: _toDouble(json['monthlyPrice']),
      yearlyPrice: _toDouble(json['yearlyPrice']),
      slotCodes: (json['slotCodes'] as List<dynamic>? ?? const [])
          .map((slot) => slot.toString())
          .toList(),
      occupiedSlotCodes:
          (json['occupiedSlotCodes'] as List<dynamic>? ?? const [])
              .map((slot) => slot.toString())
              .toList(),
    );
  }

  IncidentItem _incidentFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return IncidentItem(
      id: (json['id'] as num?)?.toInt(),
      title: json['title'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      time: _formatDateTime(json['createdAt']),
      status: json['status'] as String? ?? '',
      desc: json['description'] as String? ?? '',
      severity: json['severity'] as String?,
      assignedStaffName: json['assignedStaffName'] as String?,
    );
  }

  SecurityLog _securityLogFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return SecurityLog(
      id: (json['id'] as num?)?.toInt(),
      event: json['event'] as String? ?? '',
      visitor: json['visitor'] as String? ?? '',
      time: _formatDateTime(json['accessTime']),
      status: json['status'] as String? ?? '',
      audience: json['audience'] as String?,
    );
  }

  CustomServiceRequestItem _customServiceRequestFromJson(dynamic item) {
    final json = item as Map<String, dynamic>;
    return CustomServiceRequestItem(
      id: (json['id'] as num?)?.toInt(),
      residentId: (json['residentId'] as num?)?.toInt() ?? 0,
      residentName: json['residentName'] as String? ?? '',
      unitNumber: json['unitNumber'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      zone: json['zone'] as String? ?? '',
      preferredSchedule: json['preferredSchedule'] as String?,
      status: json['status'] as String? ?? '',
      assignedStaffId: (json['assignedStaffId'] as num?)?.toInt(),
      assignedStaffName: json['assignedStaffName'] as String?,
      quotedPrice:
          json['quotedPrice'] == null ? null : _toDouble(json['quotedPrice']),
      quoteNote: json['quoteNote'] as String?,
      residentDecisionNote: json['residentDecisionNote'] as String?,
      createdAt: _formatDateTime(json['createdAt']),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '';
    }
    try {
      return _dateFormat.format(DateTime.parse(value.toString()));
    } catch (_) {
      return value.toString();
    }
  }

  String _formatDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return '';
    }
    try {
      return _dateTimeFormat.format(DateTime.parse(value.toString()).toLocal());
    } catch (_) {
      return value.toString();
    }
  }

  double _toDouble(dynamic value) {
    if (value == null) {
      return 0;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString()) ?? 0;
  }
}
