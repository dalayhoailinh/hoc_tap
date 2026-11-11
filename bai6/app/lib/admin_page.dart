import 'package:app/auth.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trang chủ')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${user.username} · ${user.role} · token ${auth.token}'),
            TextButton(onPressed: auth.signOut, child: const Text('Đăng xuất')),
          ],
        ),
      ),
    );
  }
}
