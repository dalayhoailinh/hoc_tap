import 'dart:async';

void main() {
  final userChanges = StreamController<Map<String, String>?>.broadcast();

  userChanges.stream.listen(
    (value) => print(
      value == null
          ? '-> Màn đăng nhập'
          : value['role'] == 'admin'
          ? '-> Trang quản trị (${value['name']})'
          : '-> Trang chủ (${value['name']})',
    ),
  );
  userChanges.stream
      .map((user) => user?['name'])
      .distinct()
      .listen((name) => print('   ai đăng nhập: $name'));
  userChanges.add(null);
  userChanges.add({'name': 'Bình', 'role': 'user'});
  userChanges.add({'name': 'Bình', 'role': 'admin'});
  userChanges.add(null);
}
