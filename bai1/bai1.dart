void main() {
  final oldDoc = {'displayName': 'Alice', 'role': 'user', 'isActive': true};
  final allowed = {'displayName', 'phoneNumber', 'photoUrl', 'updatedAt'};
  final attempts = {
    'sửa tên': {'displayName': 'Alice Mới'},
    'giấu role trong lần sửa tên': {'displayName': 'Alice 2', 'role': 'admin'},
    'gửi lại isActive y như cũ': {'isActive': true},
  };

  for (final entry in attempts.entries) {
    final newDoc = {...oldDoc, ...entry.value};
    final changed = newDoc.keys
        .where((key) => newDoc[key] != oldDoc[key])
        .toSet();
    final ok = allowed.containsAll(changed);

    print('${entry.key}: đổi $changed -> ${ok ? 'cho qua' : 'chặn'}');
  }
}
