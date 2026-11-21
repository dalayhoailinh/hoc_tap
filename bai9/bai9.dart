void main() {
  final db = {'đơn': 0, 'đã bán': 0, 'đơn của An': 0};

  void book(int quantity) {
    db['đơn'] = db['đơn']! + 1;
    db['đã bán'] = db['đã bán']! + quantity;
    db['đơn của An'] = db['đơn của An']! + 1;
  }

  book(2);
  print('Lần 1: xong');
  print(db);
}
