class AppMedia {
  static const loginHero = 'https://lh3.googleusercontent.com/aida-public/AB6AXuAbnnPngkff7-HTTW2Z9S-4lSnQa2AzSBvURVLA2GEzheb9tMWO3xwtfriHrZE2Mq9w6W4RkMoz9gXdZ5CAJTGHJdcQejfFjrbejqUfxnQt9w2VZO4OP9P6kHEP48DzxaqIvNfr9ZBjLNIfFfEUsp_8EBQzhF5TTrqTU_75qbayXJ4tCCwyALiiRgVGoUa1vAKLwPQMt2o_JZfWdawr8GsF-cpP8ZKmLEI_Eu40JzKIEdxlArCbfep1r4C4vTfKg768K9NpVKa8GYM';
  static const apartmentExterior = 'https://images.unsplash.com/photo-1759086341057-5f7912848c5c?auto=format&fit=crop&w=1600&q=80';
  static const pool = 'https://lh3.googleusercontent.com/aida-public/AB6AXuDEmBSGYpJCr13NDJHQHoFOwYRx3Zr7lYPnkRiEi-66Hq2VI8JvL89rz6Kq6nvFWnSi4ZVIaEulveA_IEciJZMipWq76SRs0zaRXpKGtjvpRwogDcn6989zXR4LiBMaIpKs-6Rk4lO6XyC_XyFFs_phYguM17pmV4azbqaaCPoUT0TP7zuuHzBnEND8A33U429yImjxI7_b98C56XvdG9OItUPgJsOrZB0T1VOrgxU33EkEbeCWmP2PPjXJymohr2XUX09PC7-GSCw';
  static const gym = 'https://lh3.googleusercontent.com/aida-public/AB6AXuDS_Q2CLKkeaGZz9c0bwu4Q_z6T0bjEuuMu-PBG-3DCT56bAE9B9eXVVWylTS5uO5dT39zd-Ox13DA7Kiee22g_iC6gd3v70_jWxEqD9zx4eOXIgEULJxeiU2tXgRficGJaqsVpCkN3hocy2p3uPrzZl9LQjRWuKEuik9UOc6NK_WB9-qvXsim5VoejgNkHR4R_SR1CI45m-d_MvL9qCTGMWBh-rLqoTRUspzpiNn3Jpk-eT4xh37p6odVe0FyIR8YgMvFbqeB9a34';
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
