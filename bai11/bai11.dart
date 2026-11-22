void main() {
  final bookings = <String, Map<String, Object>>{};

  bool rules(String uid, Map<String, Object> doc) =>
      uid == doc['userId'] &&
      (doc['status'] == 'pending' || doc['status'] == 'confirmed');

  void clientWrite(String uid, String id, Map<String, Object> doc) {
    final approve = rules(uid, doc);
    if (approve) bookings[id] = doc;
    print('$uid ghi $id qua cửa app: ${approve ? 'cho qua' : 'bị chặn'}');
  }

  clientWrite('an', 'don1', {
    'userId': 'an',
    'status': 'pending',
    'totalAmount': 200000,
  });
  clientWrite('ke_xau', 'don2', {
    'userId': 'an',
    'status': 'pending',
    'totalAmount': 200000,
  });
  print(bookings);
}
