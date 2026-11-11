import 'package:app/admin_page.dart';
import 'package:app/auth.dart';
import 'package:app/home_page.dart';
import 'package:app/login_page.dart';
import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: SessionGate()));

class SessionGate extends StatelessWidget {
  const SessionGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: auth.changes,
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) return const LoginPage();
        if (user.role == 'admin') return AdminPage(user: user);
        return HomePage(user: user);
      },
    );
  }
}
