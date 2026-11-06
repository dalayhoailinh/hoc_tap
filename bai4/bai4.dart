void main() {
  final account = {'An': '123456', 'Binh': '123456'};

  bool login(String name, String password) {
    return account[name] == password;
  }

  print('An gõ sai: ${login('An', '1234567')}');
  print('An gõ đúng: ${login('An', '123456')}');
}
