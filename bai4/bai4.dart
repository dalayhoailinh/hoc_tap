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

  print('An gõ sai: ${login('An', '1234567')}');
  print('An gõ đúng: ${login('An', '123456')}');
  print(owner);
}
