import 'dart:async';

void main() {
  final userChanges = StreamController<Map<String, String>?>.broadcast();

  userChanges.stream.listen((value) => print(value));
  userChanges.add(null);
  userChanges.add({'name': 'Bình', 'role': 'user'});
  userChanges.add({'name': 'Bình', 'role': 'admin'});
  userChanges.add(null);
}
