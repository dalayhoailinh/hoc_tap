void main() {
  final anBooking = {
    'userId': 'an',
    'status': 'confirmed',
    'startAt': DateTime(2030, 12, 24, 19, 0, 0),
  };
  final anPending = {
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

  var passed = 0;
  void check(String name, String? actual, String? expected) {
    if (actual == expected) passed++;
    print(
      actual == expected
          ? 'OK   $name'
          : 'SAI  $name: ra $actual, mong $expected',
    );
  }

  check('An hủy lúc 18:00', canCancel(anBooking, 'an', before), null);
  check(
    'Bình hủy đơn của An',
    canCancel(anBooking, 'binh', before),
    'not-owner',
  );
  check(
    'An hủy lúc 20:00 đêm diễn',
    canCancel(anBooking, 'an', after),
    'event-started',
  );
  check(
    'An hủy đơn chưa trả tiền',
    canCancel(anPending, 'an', before),
    'not-cancellable',
  );
  check(
    'An hủy đơn không có',
    canCancel(null, 'an', before),
    'booking-not-found',
  );
  print('$passed/5 ca đúng');
}
