import 'dart:convert';

import 'package:http/http.dart' as http;

Uri _url(String path) => Uri.parse('http://localhost:3000$path');

class Auth {
  String? token;

  Future<http.Response> get(String path) async {
    return http.get(
      _url(path),
      headers: token != null ? {'Authorization': 'Bearer $token'} : {},
    );
  }

  Future<String> signIn(String path, String username, String password) async {
    final res = await http.post(
      _url(path),
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode != 200) return '${res.statusCode} ${res.body}';
    token = jsonDecode(res.body)['token'] as String;
    final resGet = await get('/me');
    return '${resGet.statusCode} ${resGet.body}';
  }
}

final auth = Auth();
