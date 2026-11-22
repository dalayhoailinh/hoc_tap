void main() {
  int sold = 5;
  var anOrder = {'status': 'confirmed', 'quantity': 2};

  void onStatusChanged(Map<String, Object> before, Map<String, Object> after) {
    if (before['status'] != after['status'] && after['status'] == 'cancelled') {
      sold = sold - (before['quantity'] as int);
      print('trigger: trả ${before['quantity']} vé');
    }
  }

  void update(Map<String, Object> patch) {
    final before = anOrder;
    anOrder = {...anOrder, ...patch};
    for (final key in patch.keys) {
      print('$key: ${before[key]} -> ${anOrder[key]}');
    }
    onStatusChanged(before, anOrder);
    onStatusChanged(before, anOrder);
  }

  void cancel() {
    sold = sold - (anOrder['quantity'] as int);
    update({'status': 'cancelled', 'releasedAt': 1});
  }

  cancel();
  print('đã bán: $sold');
}
