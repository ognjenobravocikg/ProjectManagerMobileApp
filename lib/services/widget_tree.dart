import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class WidgetTree extends StatefulWidget {
  const WidgetTree({Key? key}) : super(key: key);

  @override
  State<WidgetTree> createState() => _WidgetTreeState();
}

class _WidgetTreeState extends State<WidgetTree> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // ✅ IMPORTANT: show the 3-tab main screen once logged in
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
