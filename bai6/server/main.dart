import 'dart:convert';
import 'dart:io';

import 'auth.dart';

void send(HttpRequest req, int status, Object body) {
  print('${req.method} ${req.uri.path} -> ${status}');
  req.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}

Future<void> handle(HttpRequest req) async {
  final route = '${req.method} ${req.uri.path}';
  final body = req.method == 'POST'
      ? jsonDecode(await utf8.decoder.bind(req).join())
      : {};

  if (route == 'POST /refresh') {
    final refreshToken = body['refreshToken'] as String;
    if (!refreshOwner.containsKey(refreshToken)) {
      send(req, 401, {'message': 'Invalid refresh token'});
      return;
    }
    send(req, 200, {'token': auth.newToken(refreshOwner[refreshToken]!)});
    return;
  }

  if (route == 'POST /login') {
    final username = body['username'] as String;
    final password = body['password'] as String;
    final List<String>? tokens = auth.login(username, password);
    if (tokens == null) {
      send(req, 401, {'message': 'Invalid username or password'});
      return;
    }
    send(req, 200, {'token': tokens[0], 'refreshToken': tokens[1]});
    return;
  }

  if (route == 'POST /register') {
    final username = body['username'] as String;
    final password = body['password'] as String;
    final List<String>? tokens = auth.register(username, password);
    if (tokens == null) {
      send(req, 409, {'message': 'Username already exists'});
      return;
    }
    send(req, 200, {'token': tokens[0], 'refreshToken': tokens[1]});
    return;
  }

  final token = req.headers.value('authorization')?.replaceFirst('Bearer ', '');
  final name = owner[token];

  if (name == null) {
    send(req, 401, {'message': 'Unauthorized'});
    return;
  }
  if (auth.isExpired(token!)) {
    send(req, 401, {'message': 'Token expired'});
    return;
  }

  final role = auth.findUser(name)![2];

  if (route == 'GET /me') {
    send(req, 200, {'username': name, 'role': role});
    return;
  }

  if (route == 'GET /users') {
    if (role != 'admin') {
      send(req, 403, {'message': 'Forbidden'});
      return;
    }
    send(req, 200, {'users': auth.getAllUsers()});
    return;
  }
  send(req, 404, {'message': 'Not found'});
}

void main() async {
  final server = await HttpServer.bind('localhost', 3000);
  print('Server running on http://${server.address.host}:${server.port}');
  await for (final req in server) {
    await handle(req);
  }
}
