void main() {
  final bookings = <String, Map<String, Object>>{};

  void clientWrite(String uid, String id, Map<String, Object> doc) {
    bookings[id] = doc;

    print('$uid ghi $id qua cửa app: cho qua');
  }

  clientWrite('an', 'don1', {
    'userId': 'an',
    'status': 'pending',
    'totalAmount': 200000,
  });
  print(bookings);
}
