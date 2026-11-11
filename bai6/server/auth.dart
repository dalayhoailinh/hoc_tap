import 'dart:io';
import 'dart:math';

import 'db.dart';

final owner = <String, String>{};

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

  String? login(String username, String password) {
    final user = findUser(username);
    if (user != null && user[1] == password) {
      final r = Random.secure();
      final token = r.nextInt(1 << 32).toRadixString(16);
      owner[token] = username;
      return token;
    }
    return null;
  }

  String? register(String username, String password) {
    final user = findUser(username);
    if (user != null) return null;
    db.writeAsStringSync('$username,$password,user\n', mode: FileMode.append);
    return login(username, password);
  }
}

final auth = Auth(db);
