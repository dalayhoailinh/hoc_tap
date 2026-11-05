void main() {
  var stock = 1;
  var version = 0;

  final buyers = <String>[];
  final anSaw = stock;
  final binhSaw = stock;
  final anVersion = version;
  final binhVersion = version;

  void write(String who, int saw, int ver) {
    if (ver != version) {
      print('$who: Bị chen, đọc lại');
      write(who, stock, version);
      return;
    }
    if (saw <= 0) {
      print('$who: Hết vé');
      return;
    }
    stock = saw - 1;
    version++;
    buyers.add(who);
  }

  write('An', anSaw, anVersion);
  write('Bình', binhSaw, binhVersion);

  print('Đã bán: $buyers, còn $stock vé');
}
