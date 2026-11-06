import 'dart:math';

void main() {
  final account = {'An': '123456', 'Binh': '123456'};
  final owner = <String, String>{};

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
    return owner.containsKey(token) ? 200 : 401;
  }

  final anToken = login('An', '123456');
  print('An: ${adminPage(anToken)}');
  print('Lạ: ${adminPage('abc')}');
}
