import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../components/auth_layout.dart';
import '../components/my_button.dart';
import '../components/my_textfield.dart';
import '../components/square_tile.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  final Function()? onTap;
  RegisterScreen({super.key, required this.onTap});

  @override
  State<RegisterScreen> createState() {
    return RegisterScreenState();
  }
}

class RegisterScreenState extends State<RegisterScreen> {
  final UserService _userService = UserService();
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  Future<void> _handleSignUp() async {
    if (_isLoading) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      genericErrorMessage('As senhas não correspondem!');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _userService.signUp(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      // AuthScreen já observa authStateChanges e abre o menu.
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = switch (e.code) {
        'weak-password' => 'A senha é muito fraca, tente novamente!',
        'invalid-email' => 'Informe um email válido!',
        'email-already-in-use' => 'Email já cadastrado, efetue o login!',
        _ => 'Não foi possível registrar: ${e.code}',
      };
      genericErrorMessage(message);
    } catch (e) {
      if (mounted) genericErrorMessage('Não foi possível registrar: $e');
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      formKey: _formKey,
      title: 'Crie sua conta',
      subtitle: 'Preencha seus dados para montar a sua biblioteca de gatos.',
      children: [
        MyTextField(
          controller: _nameController,
          hintText: 'Nome completo',
          icon: const Icon(Icons.person_outline),
          obscureText: false,
          capitalization: true,
        ),
        const SizedBox(height: 14),
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
        const SizedBox(height: 14),
        MyTextField(
          controller: _confirmPasswordController,
          hintText: 'Confirmar senha',
          icon: const Icon(Icons.shield_outlined),
          obscureText: true,
          capitalization: false,
        ),
        const SizedBox(height: 22),
        MyButton(
          onPressed: _handleSignUp,
          formKey: _formKey,
          text: 'Registrar',
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
            'Já possui uma conta?',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          TextButton(
            onPressed: widget.onTap,
            child: const Text('Faça login'),
          ),
        ],
      ),
    );
  }
}
