import 'dart:convert';
import 'dart:io';

void send(HttpRequest req, int status, Object body) {
  print('${req.method} ${req.uri.path} -> ${status}');
  req.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body))
    ..close();
}

Future<void> handle(HttpRequest req) async {
  send(req, 200, {'message': 'Hello World!'});
}

void main() async {
  final server = await HttpServer.bind('localhost', 3000);
  print('Server running on http://${server.address.host}:${server.port}');
  await for (final req in server) {
    await handle(req);
  }
}
