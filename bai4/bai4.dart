import 'dart:math';

void main() {
  final account = {'An': '123456', 'Binh': '123456'};
  final owner = <String, String>{};
  final role = {'An': 'admin', 'Binh': 'user'};

  String? login(String name, String password) {
    if (account[name] == password) {
      final r = Random.secure();
      final token = r.nextInt(1 << 32).toRadixString(16);
      owner[token] = name;
      return token;
    }
    return null;
  }

  int adminPage(String? token) {
    switch (role[owner[token]]) {
      case 'admin':
        return 200;
      case null:
        return 401;
      default:
        return 403;
    }
  }

  final anToken = login('An', '123456');
  final binhToken = login('Binh', '123456');
  print('An: ${adminPage(anToken)}');
  print('Binh: ${adminPage(binhToken)}');
  print('Lạ: ${adminPage('abc')}');
}
