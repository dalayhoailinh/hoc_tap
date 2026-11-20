void main() {
  final anBooking = {
    'userId': 'an',
    'status': 'confirmed',
    'startAt': DateTime(2030, 12, 24, 19, 0, 0),
  };

  bool canCancel(Map<String, Object> booking, String uid) =>
      (uid == booking['userId'] as String &&
      DateTime.now().isBefore(booking['startAt'] as DateTime) &&
      booking['status'] as String == 'confirmed');

  print('An hủy: ${canCancel(anBooking, 'an')}');
  print('Bình hủy đơn của An: ${canCancel(anBooking, 'binh')}');
}
