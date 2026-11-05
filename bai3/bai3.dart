void main() {
  final orders = <String, String>{};

  void create() {
    final id = 'don${orders.length + 1}';
    orders[id] = 'pending';
    print('${id}: tạo mới');
  }

  create();
  create();

  print('Đơn hàng: $orders');
}
