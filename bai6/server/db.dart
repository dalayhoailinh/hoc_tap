import 'dart:io';

final db = _open();

File _open() {
  final file = File('users.txt');
  if (!file.existsSync()) {
    file.writeAsStringSync('An,123,admin\n');
  }
  return file;
}
