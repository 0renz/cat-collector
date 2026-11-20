import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/fade_in.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'biblioteca_gatos.dart';
import 'gatos.dart';

class MenuOptions extends StatefulWidget {
  const MenuOptions({super.key});

  @override
  State<MenuOptions> createState() => _MenuOptionsState();
}

class _MenuOptionsState extends State<MenuOptions> {
  int pageIndex = 0;
  String userName = 'Usuário';

  // Gato favorito = foto de perfil. Atualiza ao vivo quando o usuário marca
  // ou desmarca um favorito na biblioteca.
  String? favoriteCatId;
  StreamSubscription<String?>? _favoriteSubscription;

  final List<String> paginas = [
    'Encontrar gatos',
    'Biblioteca de gatos',
  ];

  String titulo = 'Encontrar gatos';

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      userName = displayName;
    }
    if (currentUser != null) {
      _favoriteSubscription = UserService().favoriteCatIdStream().listen(
        (id) {
          if (mounted) setState(() => favoriteCatId = id);
        },
        onError: (Object e) => debugPrint('Erro ao ler o gato favorito: $e'),
      );
      UserService().getUser().then((user) {
        if (user != null && mounted) {
          setState(() {
            userName = user.displayName.trim().isEmpty
                ? 'Usuário'
                : user.displayName;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  void setPaginaAtual(int index) {
    setState(() {
      pageIndex = index;
      titulo = paginas[index];
    });
  }

  void selecionarPagina(int index) {
    // Apenas troca a página: a tela de gatos é recriada ao voltar para ela
    // (veja o body) e por isso busca um gato novo no initState.
    if (index != pageIndex) setPaginaAtual(index);
    Navigator.pop(context);
  }

  Future<void> sairDoAplicativo() async {
    Navigator.pop(context);
    try {
      await FirebaseAuth.instance.signOut();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao sair: $e')),
        );
      }
    }
  }

  /// Foto de perfil: o gato favorito, em um círculo com anel de destaque.
  Widget _buildAvatar() {
    const size = 72.0;
    const fallback = Icon(Icons.person, size: 38, color: AppColors.primary);
    final id = favoriteCatId;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
        border: Border.all(
          color: id == null ? AppColors.line : AppColors.gold,
          width: 3,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: ClipOval(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          layoutBuilder: expandedSwitcherLayout,
          child: id == null
              ? const ColoredBox(
                  key: ValueKey('sem-foto'),
                  color: AppColors.primarySoft,
                  child: Center(child: fallback),
                )
              : Image.network(
                  UserService.catImageUrl(id),
                  key: ValueKey(id),
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const ColoredBox(
                      color: AppColors.primarySoft,
                      child: Center(child: fallback),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const ColoredBox(
                      color: AppColors.primarySoft,
                      child: Center(child: fallback),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    final email = FirebaseAuth.instance.currentUser?.email;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 28,
        24,
        24,
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (email != null && email.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(titulo, key: ValueKey(titulo)),
        ),
      ),

      drawer: Drawer(
        width: 300,
        child: Column(
          children: [
            _buildDrawerHeader(),
            const Divider(indent: 24, endIndent: 24),
            const SizedBox(height: 12),

            // Opções
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildMenuItem(
                    index: 0,
                    icon: Icons.pets_outlined,
                    label: 'Encontrar gatos',
                    onTap: () => selecionarPagina(0),
                  ),
                  _buildMenuItem(
                    index: 1,
                    icon: Icons.collections_bookmark_outlined,
                    label: 'Biblioteca de gatos',
                    onTap: () => selecionarPagina(1),
                  ),
                  const SizedBox(height: 8),
                  const Divider(indent: 8, endIndent: 8),
                  const SizedBox(height: 8),
                  _buildMenuItem(
                    index: -1,
                    icon: Icons.logout_outlined,
                    label: 'Sair',
                    onTap: sairDoAplicativo,
                  ),
                ],
              ),
            ),

            // Rodapé
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: const [
                    Icon(Icons.pets, size: 16, color: AppColors.muted),
                    SizedBox(width: 8),
                    Text(
                      'Criado por Lorenzo',
                      style: TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Só uma tela fica na árvore por vez, com transição suave entre elas.
      // A tela de gatos é recriada ao voltar e sorteia um gato novo.
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        layoutBuilder: expandedSwitcherLayout,
        child: pageIndex == 0
            ? const GatosScreen(key: ValueKey('gatos'))
            : const BibliotecaGatosScreen(key: ValueKey('biblioteca')),
      ),
    );
  }

  Widget _buildMenuItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final bool selecionado = pageIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selecionado ? AppColors.primarySoft : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selecionado ? AppColors.primary : AppColors.muted,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selecionado
                          ? AppColors.onPrimarySoft
                          : AppColors.ink,
                      fontSize: 16,
                      fontWeight:
                          selecionado ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
