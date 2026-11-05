void main() {
  final orders = <String, String>{};

  void create(String user, String intent) {
    final id = '${user}_${intent}';
    orders[id] = 'pending';
    print('${id}: tạo mới');
  }

  create('An', 'a1');
  orders['An_a1'] = 'paid';
  create('An', 'a1');
  create('An', 'a2');

  print('Đơn hàng: $orders');
}
