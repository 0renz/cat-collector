import 'package:flutter/material.dart';
import 'login.dart';
import 'register.dart';

class LoginOrRegisterScreen extends StatefulWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  State<LoginOrRegisterScreen> createState() {
    return LoginOrRegisterScreenState();
  }
}

class LoginOrRegisterScreenState extends State<LoginOrRegisterScreen> {
  // initially show login Page
  bool showLoginScreen = true;

  // toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginScreen = !showLoginScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Troca com transição suave entre as duas telas.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: showLoginScreen
          ? LoginScreen(key: const ValueKey('login'), onTap: togglePages)
          : RegisterScreen(key: const ValueKey('register'), onTap: togglePages),
    );
  }
}
