import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../components/auth_layout.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../components/square_tile.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  final Function()? onTap;
  LoginScreen({super.key, required this.onTap});

  @override
  State<LoginScreen> createState() {
    return LoginScreenState();
  }
}

class LoginScreenState extends State<LoginScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _userService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      // AuthScreen já observa authStateChanges e abre o menu.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'invalid-credential' => 'Credenciais inválidas, tente novamente!',
        'invalid-email' => 'Informe um email válido!',
        'user-not-found' => 'Email não encontrado, efetue o registro!',
        'wrong-password' => 'Senha incorreta, tente novamente!',
        'user-disabled' => 'Esta conta está desativada.',
        _ => 'Não foi possível entrar: ${e.code}',
      };
      genericErrorMessage(message);
    } catch (e) {
      if (mounted) genericErrorMessage('Não foi possível entrar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGitHubSignIn() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _userService.signInWithGitHub();
    } on FirebaseAuthException catch (e) {
      if (mounted) genericErrorMessage('Não foi possível entrar com GitHub: ${e.code}');
    } catch (e) {
      if (mounted) genericErrorMessage('Não foi possível entrar com GitHub: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void genericErrorMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      formKey: _formKey,
      title: 'Bem-vindo de volta',
      subtitle: 'Entre para ver os gatinhos de hoje.',
      children: [
        MyTextField(
          controller: _emailController,
          hintText: 'Email',
          icon: const Icon(Icons.email_outlined),
          obscureText: false,
          capitalization: false,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        MyTextField(
          controller: _passwordController,
          hintText: 'Senha',
          icon: const Icon(Icons.lock_outline),
          obscureText: true,
          capitalization: false,
        ),
        const SizedBox(height: 22),
        MyButton(
          onPressed: _handleSignIn,
          formKey: _formKey,
          text: 'Entrar',
          isLoading: _isLoading,
        ),
        const SizedBox(height: 24),
        const AuthDivider(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SquareTile(
            onTap: _handleGitHubSignIn,
            imagePath: 'assets/icons/github.svg',
            height: 24,
            label: 'Continuar com GitHub',
          ),
        ),
      ],
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Novo por aqui?',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          TextButton(
            onPressed: widget.onTap,
            child: const Text('Registre-se'),
          ),
        ],
      ),
    );
  }
}
