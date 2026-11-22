void main() {
  int sold = 5;
  var anOrder = {'status': 'confirmed', 'quantity': 2};

  void update(Map<String, Object> patch) {
    final before = anOrder;
    anOrder = {...anOrder, ...patch};
    for (final key in patch.keys) {
      print('$key: ${before[key]} -> ${anOrder[key]}');
    }
  }

  update({'status': 'cancelled'});
  print('đã bán: $sold');
}
