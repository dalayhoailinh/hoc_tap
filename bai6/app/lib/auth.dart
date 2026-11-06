import 'dart:convert';

import 'package:http/http.dart' as http;

Uri _url(String path) => Uri.parse('http://localhost:3000$path');

class Auth {
  Future<String> signIn(String path, String username, String password) async {
    final res = await http.post(
      _url(path),
      body: jsonEncode({'username': username, 'password': password}),
    );
    return '${res.statusCode} ${res.body}';
  }
}

final auth = Auth();
