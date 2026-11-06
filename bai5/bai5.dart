import 'dart:async';

void main() {
  final userChanges = StreamController<Map<String, String>?>.broadcast();

  userChanges.stream.listen(
    (value) => print(
      value == null
          ? '-> Màn đăng nhập'
          : value['role'] == 'admin'
          ? '-> Màn admin (${value['name']})'
          : '-> Trang chủ (${value['name']})',
    ),
  );
  userChanges.add(null);
  userChanges.add({'name': 'Bình', 'role': 'user'});
  userChanges.add({'name': 'Bình', 'role': 'admin'});
  userChanges.add(null);
}
