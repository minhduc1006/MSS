import 'dart:developer';

class NotificationService {
  // private constructor
  NotificationService._();

  static final instance = NotificationService._();

  Future<void> sendBookingConfirmation({
    required String residentName,
    required String itemName,
    required String bookingDetails,
  }) async {
    // TODO: implement actual notification sending logic
    log('Sending booking confirmation to $residentName for $itemName');
    log('Booking details: $bookingDetails');
    await Future.delayed(const Duration(seconds: 1));
  }
}
