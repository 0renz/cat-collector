import "package:firebase_auth/firebase_auth.dart";
import 'package:flutter/material.dart';
import 'menu.dart';
import 'login_or_register.dart';

class AuthScreen extends StatefulWidget{
  AuthScreen({super.key});
  @override
  State<AuthScreen> createState(){
    return AuthScreenState();
  }
}

class AuthScreenState extends State<AuthScreen>{
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context,  snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Não foi possível verificar a sessão: ${snapshot.error}'),
            );
          }
          // Entrar e sair do app acontecem com uma transição suave.
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: snapshot.hasData
                ? const MenuOptions(key: ValueKey('menu'))
                : const LoginOrRegisterScreen(key: ValueKey('auth')),
          );
        },
      ),
    );
  }
}
