import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LogoutButton extends StatelessWidget {
  const LogoutButton({Key? key}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout, color: Colors.deepPurple),
      tooltip: "Log out",
      onPressed: () => _logout(context),
    );
  }
}
