void main() {
  final anBooking1 = {
    'userId': 'an',
    'status': 'confirmed',
    'startAt': DateTime(2030, 12, 24, 19, 0, 0),
  };
  final anBooking2 = {
    'userId': 'an',
    'status': 'pending',
    'startAt': DateTime(2030, 12, 24, 19, 0, 0),
  };
  final before = DateTime(2030, 12, 24, 18, 0, 0);
  final after = DateTime(2030, 12, 24, 20, 0, 0);

  String? canCancel(Map<String, Object>? booking, String uid, DateTime now) {
    if (booking == null) return 'booking-not-found';
    if (uid != booking['userId'] as String) return 'not-owner';
    if (booking['status'] as String != 'confirmed') return 'not-cancellable';
    if (!now.isBefore(booking['startAt'] as DateTime)) return 'event-started';
    return null;
  }

  print('An hủy đơn 1 lúc 18:00: ${canCancel(anBooking1, 'an', before)}');
  print(
    'Bình hủy lúc 18:00 đơn của An: ${canCancel(anBooking1, 'binh', before)}',
  );
  print('An hủy lúc 20:00: ${canCancel(anBooking1, 'an', after)}');
  print('An hủy đơn 2 lúc 18:00: ${canCancel(anBooking2, 'an', before)}');
  print('An hủy đơn không có: ${canCancel(null, 'an', before)}');
}
