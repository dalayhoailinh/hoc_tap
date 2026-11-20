void main() {
  final anBooking = {
    'userId': 'an',
    'status': 'confirmed',
    'startAt': DateTime(2030, 12, 24, 19, 0, 0),
  };
  final before = DateTime(2030, 12, 24, 18, 0, 0);
  final after = DateTime(2030, 12, 24, 20, 0, 0);

  bool canCancel(Map<String, Object> booking, String uid, DateTime now) =>
      (uid == booking['userId'] as String &&
      now.isBefore(booking['startAt'] as DateTime) &&
      booking['status'] as String == 'confirmed');

  print('An hủy lúc 18:00: ${canCancel(anBooking, 'an', before)}');
  print(
    'Bình hủy lúc 18:00 đơn của An: ${canCancel(anBooking, 'binh', before)}',
  );
  print('An hủy lúc 20:00: ${canCancel(anBooking, 'an', after)}');
}
