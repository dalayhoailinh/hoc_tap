void main() {
  var stock = 1;
  final version = 0;
  final buyers = <String>[];

  final anSaw = stock;
  final binhSaw = stock;
  if (anSaw > 0 && version == 0) {
    stock = anSaw - 1;
    buyers.add('An');
  }
  if (binhSaw > 0 && version == 0) {
    stock = binhSaw - 1;
    buyers.add('Binh');
  }

  print('Đã bán: $buyers, còn $stock vé');
}
