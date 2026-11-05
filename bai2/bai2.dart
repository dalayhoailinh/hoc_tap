void main() {
  var stock = 1;
  var version = 0;
  final buyers = <String>[];

  final anSaw = stock;
  final binhSaw = stock;
  final anVersion = version;
  final binhVersion = version;
  if (anSaw > 0 && anVersion == version) {
    stock = anSaw - 1;
    version++;
    buyers.add('An');
  } else {
    print('An: bị chen, đọc lại');
  }
  if (binhSaw > 0 && binhVersion == version) {
    stock = binhSaw - 1;
    version++;
    buyers.add('Bình');
  } else {
    print('Bình: bị chen, đọc lại');
    final binhSawAgain = stock;
    final binhVersionAgain = version;
    if (binhSawAgain > 0 && binhVersionAgain == version) {
      stock = binhSawAgain - 1;
      version++;
      buyers.add('Bình');
    } else {
      print('Bình: hết vé');
    }
  }

  print('Đã bán: $buyers, còn $stock vé');
}
