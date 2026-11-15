import 'package:app/auth.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key, required this.user});
  final User user;

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  var _users = '';

  Future<void> _loadUsers() async {
    final res = await auth.get('/users');
    if (mounted) setState(() => _users = '${res.statusCode} ${res.body}');
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          TextButton(onPressed: auth.reload, child: const Text('Tải lại')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('${user.username} · ${user.role} · token ${auth.token}'),
            Text(_users),
            TextButton(onPressed: auth.signOut, child: const Text('Đăng xuất')),
          ],
        ),
      ),
    );
  }
}
