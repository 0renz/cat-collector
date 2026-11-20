import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../components/confirm_dialog.dart';
import '../components/tag_sheets.dart';
import '../components/fade_in.dart';
import '../theme/app_theme.dart';
import '../models/saved_cat.dart';
import '../services/user_service.dart';

class BibliotecaGatosScreen extends StatefulWidget {
  const BibliotecaGatosScreen({super.key});

  @override
  State<BibliotecaGatosScreen> createState() => _BibliotecaGatosScreenState();
}

class _BibliotecaGatosScreenState extends State<BibliotecaGatosScreen> {
  final UserService _userService = UserService();

  // O stream é criado uma vez só (antes era recriado a cada rebuild).
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _stream =
      _userService.savedCatsStream();

  // Tags escolhidas no filtro. Vazio = todos os gatos aparecem.
  final Set<String> _selectedTags = {};

  // Gato favorito (= foto de perfil), atualizado ao vivo pelo Firestore.
  String? _favoriteCatId;
  StreamSubscription<String?>? _favoriteSubscription;

  @override
  void initState() {
    super.initState();
    _favoriteSubscription = _userService.favoriteCatIdStream().listen(
      (id) {
        if (mounted) setState(() => _favoriteCatId = id);
      },
      onError: (Object e) => debugPrint('Erro ao ler o gato favorito: $e'),
    );
  }

  @override
  void dispose() {
    _favoriteSubscription?.cancel();
    super.dispose();
  }

  Future<void> _toggleFavorite(SavedCat cat) async {
    final wasFavorite = cat.id == _favoriteCatId;
    try {
      if (wasFavorite) {
        await _userService.clearFavoriteCat();
        _showMessage('Gato favorito removido. A foto de perfil voltou ao padrão.');
      } else {
        await _userService.setFavoriteCat(cat.id);
        _showMessage('Este gato agora é sua foto de perfil!');
      }
    } catch (e) {
      _showMessage('Não foi possível atualizar o gato favorito: $e');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _openFilter(Map<String, int> counts) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => TagFilterSheet(
        counts: counts,
        initialSelected: {..._selectedTags},
        onChanged: (tags) => setState(() {
          _selectedTags
            ..clear()
            ..addAll(tags);
        }),
      ),
    );
  }

  Future<void> _editTags(SavedCat cat) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => EditTagsSheet(cat: cat, userService: _userService),
    );
  }

  Future<void> _deleteCat(SavedCat cat) async {
    final isFavorite = cat.id == _favoriteCatId;
    final confirmado = await confirmarAcao(
      context,
      titulo: 'Excluir gato',
      mensagem: isFavorite
          ? 'Tem certeza de que deseja excluir este gato da biblioteca? '
              'Ele é seu gato favorito, então sua foto de perfil também será removida.'
          : 'Tem certeza de que deseja excluir este gato da biblioteca?',
    );
    if (!confirmado) return;

    try {
      await _userService.deleteCat(cat.id);
      _showMessage('Gato excluído da biblioteca.');
    } catch (e) {
      _showMessage('Não foi possível excluir o gato: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Não foi possível carregar a biblioteca: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final cats = (snapshot.data?.docs ?? [])
            .map(SavedCat.fromDoc)
            .whereType<SavedCat>()
            .toList();
        if (cats.isEmpty) {
          return const EmptyState(
            title: 'Sua biblioteca está vazia',
            message:
                'Guarde gatinhos na tela "Encontrar gatos" e eles aparecem aqui.',
          );
        }

        // Tags presentes no banco agora, com a quantidade de gatos de cada.
        // Recalculado a cada atualização do stream, então editar ou excluir
        // gatos atualiza o filtro automaticamente.
        final counts = <String, int>{};
        for (final cat in cats) {
          for (final tag in cat.tags) {
            counts[tag] = (counts[tag] ?? 0) + 1;
          }
        }

        // Tags selecionadas que já não existem em nenhum gato saem do filtro.
        final selected = _selectedTags.where(counts.containsKey).toSet();
        if (selected.length != _selectedTags.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _selectedTags.retainAll(counts.keys.toSet()));
            }
          });
        }

        // Só aparecem gatos que têm todas as tags selecionadas.
        final visible = selected.isEmpty
            ? cats
            : cats.where((c) => selected.every(c.tags.contains)).toList();

        return Column(
          children: [
            if (counts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: _TagFilterField(
                  selected: selected,
                  onTap: () => _openFilter(counts),
                  onRemove: (tag) => setState(() => _selectedTags.remove(tag)),
                  onClear: () => setState(_selectedTags.clear),
                ),
              ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                layoutBuilder: expandedSwitcherLayout,
                child: visible.isEmpty
                    ? EmptyState(
                        key: const ValueKey('sem-resultado'),
                        title: 'Nenhum gato com essas tags',
                        message:
                            'Nenhum gato guardado tem todas as tags selecionadas.',
                        actionLabel: 'Limpar filtro',
                        onAction: () => setState(_selectedTags.clear),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('grade'),
                        child: _buildGrid(visible),
                      ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGrid(List<SavedCat> cats) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.62,
      ),
      itemCount: cats.length,
      itemBuilder: (context, index) {
        final cat = cats[index];
        return FadeSlideIn(
          key: ValueKey(cat.id),
          offsetY: 12,
          duration: const Duration(milliseconds: 350),
          child: _buildCard(cat),
        );
      },
    );
  }

  Widget _buildCard(SavedCat cat) {
    final isFavorite = cat.id == _favoriteCatId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.soft,
        // Borda dourada destaca o gato que é a foto de perfil.
        border: Border.all(
          color: isFavorite ? AppColors.gold : Colors.transparent,
          width: 2.5,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const ColoredBox(color: AppColors.sand),
                    // contain: mostra o gato inteiro, sem cortar as bordas.
                    Image.network(
                      cat.imageUrl,
                      fit: BoxFit.contain,
                      frameBuilder: (context, child, frame, wasSync) {
                        if (wasSync) return child;
                        return AnimatedOpacity(
                          opacity: frame == null ? 0 : 1,
                          duration: const Duration(milliseconds: 350),
                          child: child,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Text(
                            'Imagem indisponível',
                            style: TextStyle(color: AppColors.muted),
                          ),
                        );
                      },
                    ),
                    // Selo dourado: este gato é a foto de perfil.
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedScale(
                        scale: isFavorite ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutBack,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _CatTagsRow(tags: cat.tags),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: isFavorite
                    ? 'Remover dos favoritos (foto de perfil)'
                    : 'Definir como gato favorito (foto de perfil)',
                visualDensity: VisualDensity.compact,
                onPressed: () => _toggleFavorite(cat),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    key: ValueKey(isFavorite),
                  ),
                ),
                color: isFavorite ? AppColors.gold : AppColors.muted,
              ),
              IconButton(
                tooltip: 'Editar tags',
                visualDensity: VisualDensity.compact,
                onPressed: () => _editTags(cat),
                icon: const Icon(Icons.edit_outlined),
                color: AppColors.muted,
              ),
              IconButton(
                tooltip: 'Excluir gato',
                visualDensity: VisualDensity.compact,
                onPressed: () => _deleteCat(cat),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

/// Faixa de tags de um gato, com rolagem horizontal quando não cabem todas.
class _CatTagsRow extends StatelessWidget {
  final List<String> tags;

  const _CatTagsRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: tags.isEmpty
          ? const Center(
              child: Text(
                'Sem tags',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            )
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: tags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 4),
              itemBuilder: (context, index) {
                return Center(
                  child: Chip(
                    label: Text(tags[index], style: const TextStyle(fontSize: 11)),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                  ),
                );
              },
            ),
    );
  }
}

/// Campo do filtro: mostra as tags escolhidas (ou "Todas as tags") e abre a
/// janela de seleção ao ser tocado.
class _TagFilterField extends StatelessWidget {
  final Set<String> selected;
  final VoidCallback onTap;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  const _TagFilterField({
    required this.selected,
    required this.onTap,
    required this.onRemove,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = selected.toList()..sort();

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: false,
        decoration: appInputDecoration(
          radius: 28,
          prefix: const Icon(Icons.filter_list),
          suffix: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: selected.isEmpty
                ? const Icon(Icons.arrow_drop_down, key: ValueKey('abrir'))
                : IconButton(
                    key: const ValueKey('limpar'),
                    tooltip: 'Limpar filtro',
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                  ),
          ),
        ),
        child: selected.isEmpty
            ? const Text(
                'Filtrar por tags',
                style: TextStyle(color: AppColors.muted),
              )
            : Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  for (final tag in sorted)
                    InputChip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      onPressed: onTap,
                      onDeleted: () => onRemove(tag),
                    ),
                ],
              ),
      ),
    );
  }
}
