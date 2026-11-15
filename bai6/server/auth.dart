import 'dart:io';
import 'dart:math';

import 'db.dart';

final owner = <String, String>{};
final expiry = <String, DateTime>{};
final refreshOwner = <String, String>{};

class Auth {
  final File db;

  const Auth(this.db);

  List<String>? findUser(String username) {
    final lines = db.readAsLinesSync();
    for (final line in lines) {
      final parts = line.split(',');
      if (parts[0] == username) return parts;
    }
    return null;
  }

  bool isExpired(String token) {
    final exp = expiry[token];
    if (exp == null) return true;
    return !exp.isAfter(DateTime.now());
  }

  String newToken(String username) {
    final r = Random.secure();
    final token = r.nextInt(1 << 32).toRadixString(16);
    owner[token] = username;
    expiry[token] = DateTime.now().add(const Duration(seconds: 10));
    return token;
  }

  List<String>? login(String username, String password) {
    final user = findUser(username);
    if (user != null && user[1] == password) {
      final r = Random.secure();
      final token = newToken(username);
      final refreshToken = r.nextInt(1 << 32).toRadixString(16);
      refreshOwner[refreshToken] = username;
      return [token, refreshToken];
    }
    return null;
  }

  List<String>? register(String username, String password) {
    final user = findUser(username);
    if (user != null) return null;
    db.writeAsStringSync('$username,$password,user\n', mode: FileMode.append);
    return login(username, password);
  }

  List<Map<String, String>> getAllUsers() {
    final lines = db.readAsLinesSync();
    return lines.map((line) {
      final parts = line.split(',');
      return {'username': parts[0], 'role': parts[2]};
    }).toList();
  }
}

final auth = Auth(db);
