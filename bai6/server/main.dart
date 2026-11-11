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

  if (route == 'POST /login') {
    final username = body['username'] as String;
    final password = body['password'] as String;
    final token = auth.login(username, password);
    if (token == null) {
      send(req, 401, {'message': 'Invalid username or password'});
      return;
    }
    send(req, 200, {'token': token});
    return;
  }

  if (route == 'POST /register') {
    final username = body['username'] as String;
    final password = body['password'] as String;
    final token = auth.register(username, password);
    if (token == null) {
      send(req, 409, {'message': 'Username already exists'});
      return;
    }
    send(req, 200, {'token': token});
    return;
  }

  final token = req.headers.value('authorization')?.replaceFirst('Bearer ', '');
  final name = owner[token];
  if (name == null) {
    send(req, 401, {'message': 'Unauthorized'});
    return;
  }
  if (route == 'GET /me') {
    send(req, 200, {'username': name, 'role': auth.findUser(name)![2]});
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
