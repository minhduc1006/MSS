class AppMedia {
  static const loginHero = 'https://images.unsplash.com/photo-1758448721205-8465cebc26af?auto=format&fit=crop&w=1600&q=80';
  static const apartmentExterior = 'https://images.unsplash.com/photo-1759086341057-5f7912848c5c?auto=format&fit=crop&w=1600&q=80';
  static const pool = 'https://images.unsplash.com/photo-1636417366133-149380dffa45?auto=format&fit=crop&w=1600&q=80';
  static const gym = 'https://images.unsplash.com/photo-1630703178161-1e2f9beddbf8?auto=format&fit=crop&w=1600&q=80';
  static const security = 'https://images.pexels.com/photos/18934462/pexels-photo-18934462.jpeg?auto=compress&cs=tinysrgb&w=1600';

  static String bookingImage(String title) {
    final value = title.toLowerCase();
    if (value.contains('gym')) return gym;
    if (value.contains('pool')) return pool;
    return apartmentExterior;
  }

  static String facilityImage(String name) {
    final value = name.toLowerCase();
    if (value.contains('gym')) return gym;
    if (value.contains('pool')) return pool;
    if (value.contains('security')) return security;
    return apartmentExterior;
  }

  static String announcementImage(String category) {
    final value = category.toLowerCase();
    if (value.contains('security')) return security;
    return loginHero;
  }
}
