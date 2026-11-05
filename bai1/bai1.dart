void main() {
  final oldDoc = {'displayName': 'Alice', 'role': 'user', 'isActive': true};
  final allowed = {'displayName', 'phoneNumber', 'photoUrl', 'updatedAt'};
  final attempts = {
    'sửa tên': {'displayName': 'Alice Mới'},
    'giấu role trong lần sửa tên': {'displayName': 'Alice 2', 'role': 'admin'},
    'gửi lại isActive y như cũ': {'isActive': true},
  };

  print('doc: $oldDoc');
  print('được phép đổi: $allowed');

  for (final entry in attempts.entries) {
    final newDoc = {...oldDoc, ...entry.value};
    print(entry.key);
    print('newDoc: $newDoc');
  }
}
