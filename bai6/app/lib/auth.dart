import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

Uri _url(String path) => Uri.parse('http://localhost:3000$path');

class User {
  final String username;
  final String role;

  const User(this.username, this.role);
}

class Auth {
  String? token;
  final _userChanges = StreamController<User?>.broadcast();
  Stream<User?> get changes => _userChanges.stream;

  Future<http.Response> get(String path) async {
    return http.get(
      _url(path),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
  }

  Future<String?> signIn(String path, String username, String password) async {
    final res = await http.post(
      _url(path),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) return jsonDecode(res.body)['message'] as String;
    token = jsonDecode(res.body)['token'] as String;
    await reload();
    return null;
  }

  Future<void> reload() async {
    final res = await get('/me');
    if (res.statusCode != 200) {
      _userChanges.add(null);
      return;
    }
    _userChanges.add(
      User(
        jsonDecode(res.body)['username'] as String,
        jsonDecode(res.body)['role'] as String,
      ),
    );
  }

  Future<void> signOut() async {
    token = null;
    _userChanges.add(null);
  }
}

final auth = Auth();
