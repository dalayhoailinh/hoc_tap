void main() {
  final bookings = <String, Map<String, Object>>{};
  const price = 100000;

  bool rules(String uid, Map<String, Object> doc) => false;

  void clientWrite(String uid, String id, Map<String, Object> doc) {
    final approve = rules(uid, doc);
    if (approve) bookings[id] = doc;
    print('$uid ghi $id qua cửa app: ${approve ? 'cho qua' : 'bị chặn'}');
  }

  void createBooking(String uid, String id, int quantity) {
    final doc = {
      'userId': uid,
      'status': 'pending',
      'totalAmount': price * quantity,
    };
    bookings[id] = doc;
    print('$uid gọi server tạo $id: xong');
  }

  createBooking('an', 'don1', 2);
  clientWrite('ke_xau', 'don2', {
    'userId': 'ke_xau',
    'status': 'confirmed',
    'totalAmount': 0,
  });
  print(bookings);
}
