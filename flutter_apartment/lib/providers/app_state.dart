import 'package:flutter/material.dart';

import '../models/app_models.dart';

enum AppLanguage { en, vi }

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String? route;
  final String timeLabel;
  final IconData icon;
  final Color color;
  final bool unread;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.icon,
    required this.color,
    this.route,
    this.unread = true,
  });

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? route,
    String? timeLabel,
    IconData? icon,
    Color? color,
    bool? unread,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      route: route ?? this.route,
      timeLabel: timeLabel ?? this.timeLabel,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      unread: unread ?? this.unread,
    );
  }
}

class AppState extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  AppLanguage _language = AppLanguage.en;
  List<AppNotificationItem> _notifications = const [];
  String? _notificationSessionKey;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  AppLanguage get language => _language;
  Locale get locale => Locale(_language == AppLanguage.vi ? 'vi' : 'en');
  List<AppNotificationItem> get notifications => List.unmodifiable(_notifications);
  int get unreadNotificationCount => _notifications.where((item) => item.unread).length;
  String? get notificationSessionKey => _notificationSessionKey;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setLanguage(AppLanguage language) {
    if (_language == language) {
      return;
    }
    _language = language;
    if (_notificationSessionKey != null) {
      _notifications = _seedNotifications(_sessionRoleFromKey(), _sessionUserFromNotifications());
    }
    notifyListeners();
  }

  void toggleLanguage() {
    _language = _language == AppLanguage.en ? AppLanguage.vi : AppLanguage.en;
    if (_notificationSessionKey != null) {
      _notifications = _seedNotifications(_sessionRoleFromKey(), _sessionUserFromNotifications());
    }
    notifyListeners();
  }

  void ensureNotifications({
    required UserRole role,
    SessionUser? user,
  }) {
    final key = '${role.name}:${user?.email ?? 'guest'}';
    if (_notificationSessionKey == key && _notifications.isNotEmpty) {
      return;
    }

    _notificationSessionKey = key;
    _notifications = _seedNotifications(role, user);
    notifyListeners();
  }

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((item) => item.id == id);
    if (index < 0 || !_notifications[index].unread) {
      return;
    }
    _notifications = [
      for (final item in _notifications)
        if (item.id == id) item.copyWith(unread: false) else item,
    ];
    notifyListeners();
  }

  void markAllNotificationsRead() {
    if (_notifications.every((item) => !item.unread)) {
      return;
    }
    _notifications = _notifications.map((item) => item.copyWith(unread: false)).toList();
    notifyListeners();
  }

  void dismissNotification(String id) {
    _notifications = _notifications.where((item) => item.id != id).toList();
    notifyListeners();
  }

  List<AppNotificationItem> _seedNotifications(UserRole role, SessionUser? user) {
    switch (role) {
      case UserRole.admin:
        return [
          AppNotificationItem(
            id: 'admin-billing',
            title: _label(en: 'Billing review required', vi: 'Cần rà soát hóa đơn'),
            message: _label(en: 'Several invoices remain unpaid and need follow-up.', vi: 'Một số hóa đơn vẫn chưa thanh toán và cần xử lý tiếp.'),
            timeLabel: _label(en: '5 min ago', vi: '5 phút trước'),
            route: '/admin/billing',
            icon: Icons.receipt_long_rounded,
            color: const Color(0xFFEF4444),
          ),
          AppNotificationItem(
            id: 'admin-security',
            title: _label(en: 'Security incident update', vi: 'Cập nhật sự cố an ninh'),
            message: _label(en: 'A critical incident was escalated and needs reassignment.', vi: 'Một sự cố nghiêm trọng đã được nâng mức và cần phân công lại.'),
            timeLabel: _label(en: '18 min ago', vi: '18 phút trước'),
            route: '/admin/security',
            icon: Icons.shield_rounded,
            color: const Color(0xFFF59E0B),
          ),
          AppNotificationItem(
            id: 'admin-resident',
            title: _label(en: 'Resident onboarding queue', vi: 'Hàng đợi duyệt cư dân mới'),
            message: _label(en: 'New resident records are waiting for final verification.', vi: 'Các hồ sơ cư dân mới đang chờ xác minh cuối cùng.'),
            timeLabel: _label(en: '1 hr ago', vi: '1 giờ trước'),
            route: '/admin/residents',
            icon: Icons.groups_rounded,
            color: const Color(0xFF137FEC),
            unread: false,
          ),
        ];
      case UserRole.staff:
        return [
          AppNotificationItem(
            id: 'staff-task',
            title: _label(en: 'Task priority changed', vi: 'Độ ưu tiên công việc đã thay đổi'),
            message: _label(en: 'A maintenance task was marked high priority for this shift.', vi: 'Một công việc bảo trì đã được đánh dấu ưu tiên cao cho ca này.'),
            timeLabel: _label(en: '8 min ago', vi: '8 phút trước'),
            route: '/staff',
            icon: Icons.assignment_turned_in_rounded,
            color: const Color(0xFF137FEC),
          ),
          AppNotificationItem(
            id: 'staff-facility',
            title: _label(en: 'Facility health dropped', vi: 'Điểm sức khỏe tiện ích đã giảm'),
            message: _label(en: 'One monitored facility requires a follow-up inspection.', vi: 'Một tiện ích đang theo dõi cần được kiểm tra tiếp.'),
            timeLabel: _label(en: '26 min ago', vi: '26 phút trước'),
            route: '/staff/facilities',
            icon: Icons.apartment_rounded,
            color: const Color(0xFFF59E0B),
          ),
          AppNotificationItem(
            id: 'staff-security',
            title: _label(en: 'Security access alert', vi: 'Cảnh báo truy cập an ninh'),
            message: _label(en: 'Recent access history includes a flagged event.', vi: 'Lịch sử ra vào gần đây có một sự kiện bị gắn cờ.'),
            timeLabel: _label(en: '52 min ago', vi: '52 phút trước'),
            route: '/staff/security',
            icon: Icons.sos_rounded,
            color: const Color(0xFFEF4444),
            unread: false,
          ),
        ];
      case UserRole.resident:
        return [
          AppNotificationItem(
            id: 'resident-bill',
            title: _label(en: 'Upcoming bill due', vi: 'Sắp đến hạn thanh toán'),
            message: _label(en: 'Check your latest billing status and payment schedule.', vi: 'Kiểm tra trạng thái hóa đơn và lịch thanh toán mới nhất của bạn.'),
            timeLabel: _label(en: '10 min ago', vi: '10 phút trước'),
            route: '/resident/bills',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFFEF4444),
          ),
          AppNotificationItem(
            id: 'resident-booking',
            title: _label(en: 'Booking reminder', vi: 'Nhắc lịch đặt chỗ'),
            message: _label(en: 'Your amenity booking is scheduled soon. Review it before arrival.', vi: 'Lịch đặt tiện ích của bạn sắp đến. Hãy kiểm tra trước khi đến.'),
            timeLabel: _label(en: '34 min ago', vi: '34 phút trước'),
            route: '/resident',
            icon: Icons.book_online_rounded,
            color: const Color(0xFF137FEC),
          ),
          AppNotificationItem(
            id: 'resident-account',
            title: _label(en: 'Account updated', vi: 'Tài khoản đã được cập nhật'),
            message: _label(
              en: 'Profile details for ${user?.fullName ?? 'your account'} are available for review.',
              vi: 'Thông tin hồ sơ của ${user?.fullName ?? 'tài khoản của bạn'} đã sẵn sàng để xem lại.',
            ),
            timeLabel: _label(en: '2 hr ago', vi: '2 giờ trước'),
            route: '/resident/account',
            icon: Icons.person_rounded,
            color: const Color(0xFF22C55E),
            unread: false,
          ),
        ];
    }
  }

  UserRole _sessionRoleFromKey() {
    final prefix = _notificationSessionKey?.split(':').first ?? 'resident';
    return UserRole.values.firstWhere(
      (role) => role.name == prefix,
      orElse: () => UserRole.resident,
    );
  }

  SessionUser? _sessionUserFromNotifications() {
    final parts = _notificationSessionKey?.split(':') ?? const <String>[];
    final email = parts.length > 1 ? parts[1] : null;
    if (email == null || email == 'guest') {
      return null;
    }
    return SessionUser(id: 0, fullName: email.split('@').first, email: email, role: _sessionRoleFromKey());
  }

  String _label({required String en, required String vi}) {
    return _language == AppLanguage.vi ? vi : en;
  }
}
