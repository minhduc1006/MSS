import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';

class AppI18n {
  static const _strings = <String, Map<AppLanguage, String>>{
    'language': {AppLanguage.en: 'Language', AppLanguage.vi: 'Ngôn ngữ'},
    'english': {AppLanguage.en: 'English', AppLanguage.vi: 'Tiếng Anh'},
    'vietnamese': {AppLanguage.en: 'Vietnamese', AppLanguage.vi: 'Tiếng Việt'},
    'resident': {AppLanguage.en: 'Resident', AppLanguage.vi: 'Cư dân'},
    'staff': {AppLanguage.en: 'Staff', AppLanguage.vi: 'Nhân viên'},
    'admin': {AppLanguage.en: 'Admin', AppLanguage.vi: 'Quản trị'},
    'welcome_back': {
      AppLanguage.en: 'Welcome Back',
      AppLanguage.vi: 'Chào mừng quay lại'
    },
    'login_intro': {
      AppLanguage.en: 'Enter your credentials to access the management portal',
      AppLanguage.vi: 'Nhập thông tin đăng nhập để truy cập cổng quản lý',
    },
    'email_or_username': {
      AppLanguage.en: 'Email or Username',
      AppLanguage.vi: 'Email hoặc tên đăng nhập'
    },
    'password': {AppLanguage.en: 'Password', AppLanguage.vi: 'Mật khẩu'},
    'remember_me': {
      AppLanguage.en: 'Remember me',
      AppLanguage.vi: 'Ghi nhớ đăng nhập'
    },
    'forgot_password': {
      AppLanguage.en: 'Forgot password?',
      AppLanguage.vi: 'Quên mật khẩu?'
    },
    'sign_in': {AppLanguage.en: 'Sign In', AppLanguage.vi: 'Đăng nhập'},
    'or_continue_with': {
      AppLanguage.en: 'or continue with',
      AppLanguage.vi: 'hoặc tiếp tục với'
    },
    'sign_in_with_google': {
      AppLanguage.en: 'Sign in with Google',
      AppLanguage.vi: 'Đăng nhập với Google'
    },
    'contact_message': {
      AppLanguage.en:
          'Need help with onboarding, payments, or resident services? Contact management directly.',
      AppLanguage.vi:
          'Cần hỗ trợ về kích hoạt tài khoản, thanh toán hoặc dịch vụ cư dân? Hãy liên hệ trực tiếp ban quản lý.',
    },
    'help_center': {
      AppLanguage.en: 'Help Center',
      AppLanguage.vi: 'Trung tâm trợ giúp'
    },
    'reset_password': {
      AppLanguage.en: 'Reset Password',
      AppLanguage.vi: 'Đặt lại mật khẩu'
    },
    'new_password': {
      AppLanguage.en: 'New Password',
      AppLanguage.vi: 'Mật khẩu mới'
    },
    'cancel': {AppLanguage.en: 'Cancel', AppLanguage.vi: 'Hủy'},
    'reset': {AppLanguage.en: 'Reset', AppLanguage.vi: 'Đặt lại'},
    'close': {AppLanguage.en: 'Close', AppLanguage.vi: 'Đóng'},
    'light_mode': {AppLanguage.en: 'Light mode', AppLanguage.vi: 'Chế độ sáng'},
    'dark_mode': {AppLanguage.en: 'Dark mode', AppLanguage.vi: 'Chế độ tối'},
    'sign_out': {AppLanguage.en: 'Sign Out', AppLanguage.vi: 'Đăng xuất'},
    'contact_email': {AppLanguage.en: 'Email', AppLanguage.vi: 'Email'},
    'google_login_success': {
      AppLanguage.en: 'Logged in with Google',
      AppLanguage.vi: 'Đã đăng nhập bằng Google'
    },
  };

  static const _rawStrings = <String, Map<AppLanguage, String>>{
    'Skyline Heights': {AppLanguage.vi: 'Skyline Heights'},
    'Overview': {AppLanguage.vi: 'Tổng quan'},
    'Residents': {AppLanguage.vi: 'Cư dân'},
    'Staff Directory': {AppLanguage.vi: 'Danh sách nhân viên'},
    'Billing': {AppLanguage.vi: 'Hóa đơn'},
    'Facilities': {AppLanguage.vi: 'Tiện ích'},
    'Unit Map': {AppLanguage.vi: 'Sơ đồ căn hộ'},
    'Security': {AppLanguage.vi: 'An ninh'},
    'Tasks': {AppLanguage.vi: 'Công việc'},
    'Settings': {AppLanguage.vi: 'Cài đặt'},
    'Home': {AppLanguage.vi: 'Trang chủ'},
    'Bills': {AppLanguage.vi: 'Hóa đơn'},
    'Bookings': {AppLanguage.vi: 'Dịch vụ'},
    'Services': {AppLanguage.vi: 'Dịch vụ'},
    'Account': {AppLanguage.vi: 'Tài khoản'},
    'Notifications': {AppLanguage.vi: 'Thông báo'},
    'Mark all read': {AppLanguage.vi: 'Đánh dấu đã đọc'},
    'No notifications right now.': {AppLanguage.vi: 'Hiện chưa có thông báo.'},
    'Retry': {AppLanguage.vi: 'Thử lại'},
    'Admin Dashboard': {AppLanguage.vi: 'Bảng điều khiển quản trị'},
    'Recent Activity': {AppLanguage.vi: 'Hoạt động gần đây'},
    'View All': {AppLanguage.vi: 'Xem tất cả'},
    'Timeline': {AppLanguage.vi: 'Dòng thời gian'},
    'No recent activity is available right now.': {
      AppLanguage.vi: 'Hiện chưa có hoạt động nào.'
    },
    'Resident Management': {AppLanguage.vi: 'Quản lý cư dân'},
    'Create, assign, approve, monitor, and manage resident records': {
      AppLanguage.vi:
          'Tạo, phân công, phê duyệt, theo dõi và quản lý hồ sơ cư dân'
    },
    'Resident Console': {AppLanguage.vi: 'Bảng điều khiển cư dân'},
    'Billing & Payment': {AppLanguage.vi: 'Hóa đơn và thanh toán'},
    'Create, approve, notify, track, and manage invoice operations': {
      AppLanguage.vi: 'Tạo, phê duyệt, thông báo, theo dõi và quản lý hóa đơn'
    },
    'Billing Console': {AppLanguage.vi: 'Bảng điều khiển hóa đơn'},
    'Facility & Service Management': {
      AppLanguage.vi: 'Quản lý tiện ích và dịch vụ'
    },
    'Manage facilities, services, schedules, approvals, and monitoring': {
      AppLanguage.vi: 'Quản lý tiện ích, dịch vụ, lịch, phê duyệt và giám sát'
    },
    'Facility Console': {AppLanguage.vi: 'Bảng điều khiển tiện ích'},
    'Security & Reporting': {AppLanguage.vi: 'An ninh và báo cáo'},
    'Manage incidents, reporting queues, assignments, and live monitoring': {
      AppLanguage.vi:
          'Quản lý sự cố, hàng đợi báo cáo, phân công và giám sát trực tiếp'
    },
    'Security Console': {AppLanguage.vi: 'Bảng điều khiển an ninh'},
    'Apartment Administration': {AppLanguage.vi: 'Quản trị căn hộ'},
    'Create, approve, assign, monitor, and configure units': {
      AppLanguage.vi: 'Tạo, phê duyệt, phân công, giám sát và cấu hình căn hộ'
    },
    'Administration Console': {AppLanguage.vi: 'Bảng điều khiển quản trị'},
    'Operations team management': {AppLanguage.vi: 'Quản lý đội vận hành'},
    'Resident Bookings': {AppLanguage.vi: 'Dịch vụ của cư dân'},
    'Resident Services Hub': {AppLanguage.vi: 'Trung tâm dịch vụ cư dân'},
    'Resident facilities and announcements': {
      AppLanguage.vi: 'Tiện ích và thông báo dành cho cư dân'
    },
    'Resident Services': {AppLanguage.vi: 'Dịch vụ cư dân'},
    'Building News': {AppLanguage.vi: 'Tin tức tòa nhà'},
    'Create': {AppLanguage.vi: 'Tạo'},
    'Update': {AppLanguage.vi: 'Cập nhật'},
    'Delete': {AppLanguage.vi: 'Xóa'},
    'View': {AppLanguage.vi: 'Xem'},
    'Search': {AppLanguage.vi: 'Tìm kiếm'},
    'Approve': {AppLanguage.vi: 'Phê duyệt'},
    'Reject': {AppLanguage.vi: 'Từ chối'},
    'Assign': {AppLanguage.vi: 'Phân công'},
    'Schedule': {AppLanguage.vi: 'Lên lịch'},
    'Notify': {AppLanguage.vi: 'Thông báo'},
    'Export': {AppLanguage.vi: 'Xuất'},
    'Import': {AppLanguage.vi: 'Nhập'},
    'Track': {AppLanguage.vi: 'Theo dõi'},
    'Monitor': {AppLanguage.vi: 'Giám sát'},
    'Generate': {AppLanguage.vi: 'Tạo gói'},
    'Manage': {AppLanguage.vi: 'Quản lý'},
    'Configure': {AppLanguage.vi: 'Cấu hình'},
    'Validate': {AppLanguage.vi: 'Kiểm tra'},
    'Activate': {AppLanguage.vi: 'Kích hoạt'},
    'Active': {AppLanguage.vi: 'Đang hoạt động'},
    'Pending Approval': {AppLanguage.vi: 'Chờ phê duyệt'},
    'Assigned': {AppLanguage.vi: 'Đã phân công'},
    'Rejected': {AppLanguage.vi: 'Đã từ chối'},
    'Deactivated': {AppLanguage.vi: 'Đã vô hiệu hóa'},
    'Paid': {AppLanguage.vi: 'Đã thanh toán'},
    'Pending': {AppLanguage.vi: 'Đang chờ'},
    'Overdue': {AppLanguage.vi: 'Quá hạn'},
    'Approved': {AppLanguage.vi: 'Đã duyệt'},
    'Operational': {AppLanguage.vi: 'Đang hoạt động'},
    'Maintenance': {AppLanguage.vi: 'Bảo trì'},
    'Open': {AppLanguage.vi: 'Mở'},
    'In-Progress': {AppLanguage.vi: 'Đang xử lý'},
    'Resolved': {AppLanguage.vi: 'Đã xử lý'},
    'Occupied': {AppLanguage.vi: 'Đã có người ở'},
    'Vacant': {AppLanguage.vi: 'Trống'},
    'On Duty': {AppLanguage.vi: 'Đang trực'},
    'Off Duty': {AppLanguage.vi: 'Nghỉ ca'},
    'Search resident management by name, unit, email, or assignment': {
      AppLanguage.vi: 'Tìm cư dân theo tên, căn hộ, email hoặc phân công'
    },
    'Search billing by resident, unit, title, category, or assignment': {
      AppLanguage.vi:
          'Tìm hóa đơn theo cư dân, căn hộ, tiêu đề, loại hoặc phân công'
    },
    'Search facilities by name, area, status, or assigned team': {
      AppLanguage.vi:
          'Tìm tiện ích theo tên, khu vực, trạng thái hoặc đội phụ trách'
    },
    'Search security by incident, zone, severity, or assigned team': {
      AppLanguage.vi:
          'Tìm an ninh theo sự cố, khu vực, mức độ hoặc đội phụ trách'
    },
    'Search apartment administration by unit, tower, type, or resident': {
      AppLanguage.vi: 'Tìm quản trị căn hộ theo mã căn, tòa, loại hoặc cư dân'
    },
    'Search by staff name, title, email, or phone': {
      AppLanguage.vi:
          'Tìm nhân viên theo tên, chức danh, email hoặc số điện thoại'
    },
    'Total Invoiced': {AppLanguage.vi: 'Tổng đã lập hóa đơn'},
    'Outstanding': {AppLanguage.vi: 'Còn phải thu'},
    'Attention': {AppLanguage.vi: 'Cần chú ý'},
    'Incidents': {AppLanguage.vi: 'Sự cố'},
    'Total Residents': {AppLanguage.vi: 'Tổng cư dân'},
    'Occupancy Rate': {AppLanguage.vi: 'Tỷ lệ lấp đầy'},
    'Pending Billing': {AppLanguage.vi: 'Hóa đơn chờ xử lý'},
    'Open Requests': {AppLanguage.vi: 'Yêu cầu đang mở'},
    'Add New Resident': {AppLanguage.vi: 'Thêm cư dân mới'},
    'Staff': {AppLanguage.vi: 'Nhân viên'},
    'Unable to load admin dashboard': {
      AppLanguage.vi: 'Không thể tải bảng điều khiển quản trị'
    },
    'Unable to load activity feed': {
      AppLanguage.vi: 'Không thể tải luồng hoạt động'
    },
    'Billing review required': {AppLanguage.vi: 'Cần rà soát hóa đơn'},
    'Security incident update': {AppLanguage.vi: 'Cập nhật sự cố an ninh'},
    'Resident onboarding queue': {AppLanguage.vi: 'Hàng đợi duyệt cư dân mới'},
    'Onboarding': {AppLanguage.vi: 'Tiếp nhận'},
    'Balance': {AppLanguage.vi: 'Số dư'},
    'Next Due': {AppLanguage.vi: 'Kỳ hạn tiếp theo'},
    'No unpaid bills': {AppLanguage.vi: 'Không có hóa đơn chưa thanh toán'},
    'Up to date': {AppLanguage.vi: 'Đã cập nhật'},
    'Resident data could not be loaded': {
      AppLanguage.vi: 'Không thể tải dữ liệu cư dân'
    },
    'Quick Actions': {AppLanguage.vi: 'Thao tác nhanh'},
    'Book': {AppLanguage.vi: 'Đặt'},
    'Pay Now': {AppLanguage.vi: 'Thanh toán ngay'},
    'Book Pool': {AppLanguage.vi: 'Đặt hồ bơi'},
    'Book Gym': {AppLanguage.vi: 'Đặt phòng gym'},
    'Help Desk': {AppLanguage.vi: 'Hỗ trợ'},
    'Select a time slot': {AppLanguage.vi: 'Chọn khung giờ'},
    'Confirm Booking': {AppLanguage.vi: 'Xác nhận đặt chỗ'},
    'Active Bookings': {AppLanguage.vi: 'Đặt chỗ đang hoạt động'},
    'Booking management': {AppLanguage.vi: 'Quản lý đặt chỗ'},
    'Use the resident dashboard quick actions to create a new pool or gym reservation. This page tracks all active slots and building updates.':
        {
      AppLanguage.vi:
          'Dùng thao tác nhanh ở trang cư dân để đặt hồ bơi hoặc phòng gym. Trang này theo dõi toàn bộ lượt đặt chỗ và cập nhật từ tòa nhà.',
    },
    'All Bookings': {AppLanguage.vi: 'Tất cả lượt đặt chỗ'},
    'No bookings yet': {AppLanguage.vi: 'Chưa có lượt đặt chỗ nào'},
    'Go to the resident dashboard and use Book Pool or Book Gym to create your first reservation.':
        {
      AppLanguage.vi:
          'Vào trang cư dân và dùng Đặt hồ bơi hoặc Đặt phòng gym để tạo lượt đặt đầu tiên.',
    },
    'No resident services available right now.': {
      AppLanguage.vi: 'Hiện chưa có dịch vụ cư dân nào.'
    },
    'No announcements available right now.': {
      AppLanguage.vi: 'Hiện chưa có thông báo nào.'
    },
    'Security & Support': {AppLanguage.vi: 'An ninh và hỗ trợ'},
    'Emergency SOS': {AppLanguage.vi: 'Khẩn cấp SOS'},
    'Alert on-site security immediately': {
      AppLanguage.vi: 'Báo ngay cho đội an ninh tại chỗ'
    },
    'ACTIVATE': {AppLanguage.vi: 'KÍCH HOẠT'},
    'Report Incident': {AppLanguage.vi: 'Báo cáo sự cố'},
    'Guard Desk': {AppLanguage.vi: 'Bàn trực an ninh'},
    'Call extension 100 or use the lobby intercom for immediate assistance.': {
      AppLanguage.vi:
          'Gọi số nội bộ 100 hoặc dùng intercom ở sảnh để được hỗ trợ ngay.',
    },
    'Call Desk': {AppLanguage.vi: 'Gọi bàn trực'},
    'Access History': {AppLanguage.vi: 'Lịch sử ra vào'},
    'Title': {AppLanguage.vi: 'Tiêu đề'},
    'Zone': {AppLanguage.vi: 'Khu vực'},
    'Description': {AppLanguage.vi: 'Mô tả'},
    'Severity': {AppLanguage.vi: 'Mức độ'},
    'Low': {AppLanguage.vi: 'Thấp'},
    'Medium': {AppLanguage.vi: 'Trung bình'},
    'High': {AppLanguage.vi: 'Cao'},
    'Critical': {AppLanguage.vi: 'Nghiêm trọng'},
    'Submit Report': {AppLanguage.vi: 'Gửi báo cáo'},
    'Billing & Payments': {AppLanguage.vi: 'Hóa đơn và thanh toán'},
    'Unable to load resident bills': {
      AppLanguage.vi: 'Không thể tải hóa đơn cư dân'
    },
    'Last Payment': {AppLanguage.vi: 'Thanh toán gần nhất'},
    'No payments yet': {AppLanguage.vi: 'Chưa có thanh toán'},
    'Waiting for first payment': {
      AppLanguage.vi: 'Đang chờ thanh toán đầu tiên'
    },
    'Statement': {AppLanguage.vi: 'Sao kê'},
    'Recent Bills': {AppLanguage.vi: 'Hóa đơn gần đây'},
    'Pay': {AppLanguage.vi: 'Thanh toán'},
    'Profile Details': {AppLanguage.vi: 'Thông tin hồ sơ'},
    'Change Password': {AppLanguage.vi: 'Đổi mật khẩu'},
    'Update your account password': {
      AppLanguage.vi: 'Cập nhật mật khẩu tài khoản'
    },
    'Payment Preferences': {AppLanguage.vi: 'Tùy chọn thanh toán'},
    'Manage auto-pay and saved methods': {
      AppLanguage.vi: 'Quản lý tự động thanh toán và phương thức đã lưu'
    },
    'Email and in-app alerts': {
      AppLanguage.vi: 'Cảnh báo qua email và trong ứng dụng'
    },
    'Toggle app appearance': {AppLanguage.vi: 'Chuyển đổi giao diện ứng dụng'},
    'Current Password': {AppLanguage.vi: 'Mật khẩu hiện tại'},
    'Change': {AppLanguage.vi: 'Đổi'},
    'Incident List': {AppLanguage.vi: 'Danh sách sự cố'},
    'Map View': {AppLanguage.vi: 'Xem bản đồ'},
    'Operations Center': {AppLanguage.vi: 'Trung tâm vận hành'},
    'Staff Dashboard': {AppLanguage.vi: 'Bảng điều khiển nhân viên'},
    'In Progress': {AppLanguage.vi: 'Đang xử lý'},
    'Done': {AppLanguage.vi: 'Hoàn thành'},
    'Today\'s Tasks': {AppLanguage.vi: 'Công việc hôm nay'},
    'Facility & Service': {AppLanguage.vi: 'Tiện ích và dịch vụ'},
    'Open Jobs': {AppLanguage.vi: 'Việc đang mở'},
    'Escalations': {AppLanguage.vi: 'Việc cần xử lý gấp'},
    'Health score:': {AppLanguage.vi: 'Điểm sức khỏe:'},
    'Log Note': {AppLanguage.vi: 'Ghi chú'},
    'Dispatch': {AppLanguage.vi: 'Điều phối'},
    'Mark operational': {AppLanguage.vi: 'Đánh dấu hoạt động bình thường'},
    'Add maintenance note': {AppLanguage.vi: 'Thêm ghi chú bảo trì'},
    'Save': {AppLanguage.vi: 'Lưu'},
    'Search security log': {AppLanguage.vi: 'Tìm nhật ký an ninh'},
    'Alert security team immediately': {
      AppLanguage.vi: 'Báo ngay cho đội an ninh'
    },
    'System Configuration': {AppLanguage.vi: 'Cấu hình hệ thống'},
    'Rules': {AppLanguage.vi: 'Quy định'},
    'Unit Types': {AppLanguage.vi: 'Loại căn hộ'},
    'Pricing': {AppLanguage.vi: 'Định giá'},
    'Validate Data Consistency': {
      AppLanguage.vi: 'Kiểm tra tính nhất quán dữ liệu'
    },
    'BUILDING RULES': {AppLanguage.vi: 'QUY ĐỊNH TÒA NHÀ'},
    'Late Fee Automation': {AppLanguage.vi: 'Tự động phí trễ hạn'},
    'Apply fees after the 5th of each month': {
      AppLanguage.vi: 'Áp dụng phí sau ngày 5 hằng tháng'
    },
    'Visitor Registration': {AppLanguage.vi: 'Đăng ký khách'},
    'Require digital ID for all guest entries': {
      AppLanguage.vi: 'Yêu cầu định danh số cho mọi lượt khách'
    },
    'Amenity Booking': {AppLanguage.vi: 'Đặt tiện ích'},
    'Enable digital scheduling for gym and pool': {
      AppLanguage.vi: 'Bật đặt lịch số cho phòng gym và hồ bơi'
    },
    'Unit Types & Tiers': {AppLanguage.vi: 'Loại căn hộ và hạng'},
    'Edit All': {AppLanguage.vi: 'Sửa tất cả'},
    'Pricing Insight': {AppLanguage.vi: 'Phân tích giá'},
    'Validation Result': {AppLanguage.vi: 'Kết quả kiểm tra'},
    'Configuration looks consistent.': {
      AppLanguage.vi: 'Cấu hình hiện nhất quán.'
    },
    'Edit Unit Tiers': {AppLanguage.vi: 'Sửa hạng căn hộ'},
    'Reset Method': {AppLanguage.vi: 'Phương thức đặt lại'},
    'Email Verification': {AppLanguage.vi: 'Xác minh email'},
    'FPT Identity': {AppLanguage.vi: 'Định danh FPT'},
    'Resident Support': {AppLanguage.vi: 'Hỗ trợ cư dân'},
    'Contact Management': {AppLanguage.vi: 'Liên hệ ban quản lý'},
    'Account Security': {AppLanguage.vi: 'Bảo mật tài khoản'},
    'Confirm Password': {AppLanguage.vi: 'Xác nhận mật khẩu'},
    'Filters': {AppLanguage.vi: 'Bộ lọc'},
    'Domain Filter': {AppLanguage.vi: 'Lọc tên miền'},
    'Recovery Channel': {AppLanguage.vi: 'Kênh khôi phục'},
    'Auto Detect': {AppLanguage.vi: 'Tự nhận diện'},
    'FPT Domain': {AppLanguage.vi: 'Tên miền FPT'},
    'Personal Domain': {AppLanguage.vi: 'Tên miền cá nhân'},
    'Email Delivery': {AppLanguage.vi: 'Gửi qua email'},
    'Direct Reset': {AppLanguage.vi: 'Đặt lại trực tiếp'},
    'Support Ticket': {AppLanguage.vi: 'Phiếu hỗ trợ'},
    'Reset Preview': {AppLanguage.vi: 'Xem trước đặt lại'},
    'Auto-updated': {AppLanguage.vi: 'Tự cập nhật'},
    'Account Email': {AppLanguage.vi: 'Email tài khoản'},
    'Access Level': {AppLanguage.vi: 'Mức truy cập'},
    'Verification': {AppLanguage.vi: 'Xác minh'},
    'Password Strength': {AppLanguage.vi: 'Độ mạnh mật khẩu'},
    'Weak': {AppLanguage.vi: 'Yếu'},
    'Strong': {AppLanguage.vi: 'Mạnh'},
    'General': {AppLanguage.vi: 'Chung'},
    'Support': {AppLanguage.vi: 'Hỗ trợ'},
    'Generate Secure Reset': {AppLanguage.vi: 'Tạo yêu cầu đặt lại an toàn'},
    'Enter a valid email address': {
      AppLanguage.vi: 'Nhập địa chỉ email hợp lệ'
    },
    'Password must be at least 6 characters': {
      AppLanguage.vi: 'Mật khẩu phải có ít nhất 6 ký tự'
    },
    'Passwords do not match': {AppLanguage.vi: 'Mật khẩu xác nhận không khớp'},
    'Password reset completed': {AppLanguage.vi: 'Đặt lại mật khẩu thành công'},
    'The app now loads backend data only. Check that the microservices are running and reachable.':
        {
      AppLanguage.vi:
          'Ứng dụng hiện chỉ tải dữ liệu từ backend. Hãy kiểm tra các microservice đang chạy và có thể truy cập.',
    },
    'Book Now': {AppLanguage.vi: 'Đặt ngay'},
    'Unavailable': {AppLanguage.vi: 'Tạm khóa'},
    'Tap a service card or use Book Now to reserve a slot.': {
      AppLanguage.vi:
          'Chạm vào thẻ dịch vụ hoặc bấm Đặt ngay để giữ khung giờ.',
    },
    'Tap this card to reserve this service.': {
      AppLanguage.vi: 'Chạm vào thẻ này để đặt dịch vụ.',
    },
    'This service is currently unavailable for booking.': {
      AppLanguage.vi: 'Dịch vụ này hiện chưa thể đặt.',
    },
    'Selected Date': {AppLanguage.vi: 'Ngày đã chọn'},
    'booked successfully': {AppLanguage.vi: 'đã được đặt thành công'},
    'Free booking': {AppLanguage.vi: 'Miễn phí'},
    'Booking fee': {AppLanguage.vi: 'Phí đặt chỗ'},
    'Confirm': {AppLanguage.vi: 'Xác nhận'},
    'Confirm this free service booking?': {
      AppLanguage.vi: 'Xác nhận đặt dịch vụ miễn phí này?',
    },
    'Confirm this booking and create an invoice for': {
      AppLanguage.vi: 'Xác nhận đặt và tạo hóa đơn cho',
    },
    'An invoice has been added to your bills.': {
      AppLanguage.vi: 'Một hóa đơn đã được thêm vào danh sách hóa đơn của bạn.',
    },
  };

  static String text(BuildContext context, String key) {
    final language = Provider.of<AppState>(context, listen: false).language;
    return _normalizeLocalized(_strings[key]?[language] ?? key, language);
  }

  static String rawText(BuildContext context, String input) {
    final language = Provider.of<AppState>(context, listen: false).language;
    return _normalizeLocalized(
        _rawStrings[input]?[language] ?? input, language);
  }

  static String _normalizeLocalized(String value, AppLanguage language) {
    if (language != AppLanguage.vi) {
      return value;
    }

    if (!_looksMojibake(value)) {
      return value;
    }

    try {
      return utf8.decode(latin1.encode(value));
    } catch (_) {
      return value;
    }
  }

  static bool _looksMojibake(String value) {
    const markers = ['Ã', 'Ä', 'Å', 'Æ', 'á»', 'áº', 'â€', 'Â'];
    return markers.any(value.contains);
  }
}

extension AppI18nExtension on BuildContext {
  String t(String key) => AppI18n.text(this, key);
  String tr(String raw) => AppI18n.rawText(this, raw);
}
