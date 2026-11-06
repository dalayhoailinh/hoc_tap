import 'dart:math';

void main() {
  final account = {'An': '123456', 'Binh': '123456'};
  final owner = <String, String>{};
  final role = {'An': 'admin', 'Binh': 'user'};
  var now = DateTime(2026, 11, 6, 9, 0);
  final expiry = <String, DateTime>{};

  String? login(String name, String password) {
    if (account[name] == password) {
      final r = Random.secure();
      final token = r.nextInt(1 << 32).toRadixString(16);
      owner[token] = name;
      expiry[token] = now.add(const Duration(minutes: 30));
      return token;
    }
    return null;
  }

  int adminPage(String? token) {
    if (!owner.containsKey(token) || !expiry[token]!.isAfter(now)) return 401;
    return (role[owner[token]] == 'admin') ? 200 : 403;
  }

  print('An gõ sai: ${login('An', '1234567')}');
  final anToken = login('An', '123456');
  final binhToken = login('Binh', '123456');
  print(
    'An: ${adminPage(anToken)}, '
    'Binh: ${adminPage(binhToken)}, '
    'Lạ: ${adminPage('abc')}',
  );
  now = now.add(const Duration(minutes: 31));
  print('${now.hour}:${now.minute}, An: ${adminPage(anToken)}');
}
