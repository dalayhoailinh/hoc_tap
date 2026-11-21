void main() {
  final db = {'đơn': 0, 'đã bán': 0, 'đơn của An': 0};

  void book(int quantity, {bool crash = false}) {
    final draft = <String, int>{};
    draft['đơn'] = db['đơn']! + 1;
    if (crash) throw 'mất điện';
    draft['đã bán'] = db['đã bán']! + quantity;
    draft['đơn của An'] = db['đơn của An']! + 1;
    db.addAll(draft);
  }

  book(2);
  print('lần 1: xong');

  try {
    book(2, crash: true);
    print('lần 2: xong');
  } catch (e) {
    print('lần 2: hỏng giữa chừng ($e)');
  }

  print(db);
}
