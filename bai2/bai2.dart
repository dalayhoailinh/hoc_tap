void main() {
  var stock = 1;
  final buyers = <String>[];

  final anSaw = stock;
  if (anSaw > 0) {
    stock = anSaw - 1;
    buyers.add('An');
  }

  print('Đã bán: $buyers, còn $stock vé');
}
