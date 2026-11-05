void main() {
  final oldDoc = {'displayName': 'Alice', 'role': 'user', 'isActive': true};
  final allowed = {'displayName', 'phoneNumber', 'photoUrl', 'updatedAt'};

  print('doc: $oldDoc');
  print('được phép đổi: $allowed');
}
