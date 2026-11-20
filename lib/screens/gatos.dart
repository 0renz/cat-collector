import 'dart:convert';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/tag_service.dart';
import '../services/user_service.dart';
import '../components/fade_in.dart';
import '../theme/app_theme.dart';

class GatosScreen extends StatefulWidget {
  const GatosScreen({super.key});

  @override
  State<GatosScreen> createState() => GatosScreenState();
}

class GatosScreenState extends State<GatosScreen> {
  static const String _apiUrl = 'https://cataas.com/cat';

  final TextEditingController _wishController = TextEditingController();
  final CatTagService _tagService = CatTagService();

  // ID do gato exibido. A imagem é carregada por /cat/{id}, então o gato da
  // tela é sempre o mesmo que será guardado na biblioteca.
  String? _catId;

  // Tags realmente usadas na busca do gato atual (em inglês).
  List<String> _activeTags = [];

  // Aviso para o usuário (ex.: nenhuma tag encontrada, Gemini indisponível).
  String? _statusMessage;

  // Último pedido interpretado: evita chamar o Gemini de novo (e gastar cota)
  // quando o usuário só quer "outro gato" com o mesmo texto.
  String _interpretedWish = '';
  List<String> _interpretedTags = [];

  bool _isLoading = true;
  bool _hasError = false;
  bool _isSaving = false;
  bool _isSaved = false;

  // Identifica a requisição mais recente para descartar respostas atrasadas.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    // Esta tela é recriada toda vez que o usuário volta para ela,
    // então um gato novo é sorteado a cada entrada.
    loadAnotherCat();
  }

  @override
  void dispose() {
    _wishController.dispose();
    super.dispose();
  }

  Future<void> loadAnotherCat() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final requestId = ++_requestId;
    setState(() {
      _isLoading = true;
      _hasError = false;
      _isSaved = false;
      _catId = null;
      _statusMessage = null;
    });

    try {
      final wish = _wishController.text.trim();
      String? warning;
      var tags = <String>[];

      // 1) Interpretar o pedido com o Gemini (se houver texto).
      if (wish.isNotEmpty) {
        if (wish == _interpretedWish) {
          tags = _interpretedTags;
        } else {
          try {
            tags = await _tagService.extractTags(wish);
            if (!mounted || requestId != _requestId) return;
            _interpretedWish = wish;
            _interpretedTags = tags;
          } catch (e) {
            if (!mounted || requestId != _requestId) return;
            debugPrint('Erro ao interpretar o pedido: $e');
            warning = 'Não foi possível interpretar o pedido ($e). '
                'Mostrando um gato aleatório.';
          }
        }
        if (tags.isEmpty && warning == null) {
          warning = 'Não encontrei uma tag que combine com esse pedido. '
              'Mostrando um gato aleatório.';
        }
      }

      // 2) Buscar o gato na Cataas, com fallback progressivo.
      final result = await _fetchCat(tags);
      if (!mounted || requestId != _requestId) return;
      if (result == null) {
        throw StateError('Não foi possível obter um gato da API.');
      }

      if (tags.isNotEmpty && result.tags.length < tags.length) {
        final used = result.tags.isEmpty
            ? 'um gato aleatório'
            : 'gatos com "${result.tags.join(', ')}"';
        warning = 'Não há gatos com todas as tags "${tags.join(', ')}". '
            'Mostrando $used.';
      }

      setState(() {
        _catId = result.id;
        _activeTags = result.tags;
        _statusMessage = warning;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erro ao buscar gato: $e');
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  /// Tenta todas as tags; se não houver gato, só a primeira; se ainda assim
  /// não houver, um gato aleatório. Devolve o id e as tags que funcionaram.
  Future<({String id, List<String> tags})?> _fetchCat(List<String> tags) async {
    final attempts = <List<String>>[
      if (tags.isNotEmpty) tags,
      if (tags.length > 1) [tags.first],
      <String>[],
    ];

    for (final attempt in attempts) {
      final id = await _requestCatId(attempt);
      if (id != null) return (id: id, tags: attempt);
    }
    return null;
  }

  Future<String?> _requestCatId(List<String> tags) async {
    try {
      // Tags com espaço viram %20 (ex.: "big eyes" -> big%20eyes).
      final path = tags.isEmpty
          ? _apiUrl
          : '$_apiUrl/${tags.map(Uri.encodeComponent).join(',')}';
      // json=true devolve os metadados (incluindo o id) em vez da imagem;
      // "t" evita cache devolvendo sempre o mesmo gato.
      final stamp = DateTime.now().microsecondsSinceEpoch;
      final response = await http
          .get(Uri.parse('$path?json=true&t=$stamp'))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final id = data is Map ? (data['id'] ?? data['_id']) : null;
      return id is String && id.isNotEmpty ? id : null;
    } catch (e) {
      debugPrint('Falha ao buscar gato (tags: $tags): $e');
      return null;
    }
  }

  String _describeError(Object e) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return 'sem permissão no Firestore (verifique as regras de segurança)';
        case 'unauthenticated':
          return 'usuário não autenticado';
        case 'unavailable':
          return 'sem conexão com o Firestore';
        default:
          return '${e.code}: ${e.message ?? ''}';
      }
    }
    return '$e';
  }

  Future<void> _saveCat() async {
    final catId = _catId;
    if (catId == null || _isSaving || _isSaved) return;

    final requestId = _requestId;
    // As tags que realmente trouxeram este gato vão junto com ele.
    final tags = List<String>.from(_activeTags);
    setState(() => _isSaving = true);
    try {
      await UserService().saveCat(catId, tags: tags);
      if (!mounted) return;
      // Só marca como salvo se o usuário ainda estiver olhando para o mesmo gato.
      if (requestId == _requestId) setState(() => _isSaved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gato guardado na biblioteca!')),
      );
    } catch (e) {
      debugPrint('Erro ao guardar o gato: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível guardar o gato: ${_describeError(e)}'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildWishField() {
    return TextField(
      controller: _wishController,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => loadAnotherCat(),
      decoration: appInputDecoration(
        hint: 'Ex.: gatos pretos deitados',
        helper: CatTagService.isConfigured
            ? null
            : 'Gemini não configurado: o texto será ignorado.',
        radius: 28,
        prefix: const Icon(Icons.auto_awesome, color: AppColors.primary),
        suffix: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _wishController,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Limpar',
              icon: const Icon(Icons.close),
              onPressed: _wishController.clear,
            );
          },
        ),
      ),
    );
  }

  /// Tags em uso e avisos, com animação de altura quando aparecem/somem.
  Widget _buildStatus() {
    final message = _statusMessage;
    final Widget content;

    if (_activeTags.isEmpty && message == null) {
      content = const SizedBox.shrink(key: ValueKey('sem-status'));
    } else {
      content = Padding(
        key: const ValueKey('com-status'),
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_activeTags.isNotEmpty)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.sell_outlined, size: 16, color: AppColors.muted),
                  for (final tag in _activeTags)
                    Chip(
                      label: Text(tag),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            if (message != null)
              Padding(
                padding: EdgeInsets.only(top: _activeTags.isNotEmpty ? 8 : 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: content,
        ),
      ),
    );
  }

  Widget _buildRetry() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.sentiment_dissatisfied_outlined,
            size: 40,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          const Text(
            'Não foi possível carregar o gato.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: loadAnotherCat,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final catId = _catId;
    if (_hasError || catId == null) {
      return _buildRetry();
    }
    // contain: o gato inteiro sempre aparece dentro da moldura, sem cortes.
    return SizedBox.expand(
      child: Image.network(
        UserService.catImageUrl(catId),
        key: ValueKey(catId),
        fit: BoxFit.contain,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded) return child;
          return AnimatedOpacity(
            opacity: frame == null ? 0 : 1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: child,
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) => _buildRetry(),
      ),
    );
  }

  /// Botão quadrado de "guardar": o ícone troca com animação de escala e
  /// vira um indicador de progresso enquanto grava.
  Widget _buildSaveButton({
    required bool canSave,
    required String label,
  }) {
    final Widget icon;
    if (_isSaving) {
      icon = const SizedBox(
        key: ValueKey('salvando'),
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    } else {
      icon = Icon(
        _isSaved ? Icons.bookmark_added : Icons.bookmark_add_outlined,
        key: ValueKey(_isSaved),
      );
    }

    return Tooltip(
      message: label,
      child: SizedBox(
        width: 56,
        height: 56,
        child: ElevatedButton(
          onPressed: canSave ? _saveCat : null,
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size(56, 56),
            backgroundColor: AppColors.primarySoft,
            foregroundColor: AppColors.primary,
            // Depois de guardar, o botão continua colorido (com o "check").
            disabledBackgroundColor:
                _isSaved ? AppColors.primarySoft : AppColors.sand,
            disabledForegroundColor:
                _isSaved ? AppColors.primary : AppColors.muted,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: icon,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _catId != null && !_isSaving && !_isSaved;
    final saveLabel = _isSaving
        ? 'Guardando...'
        : _isSaved
            ? 'Gato guardado'
            : 'Guardar gato';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWishField(),
          _buildStatus(),
          const SizedBox(height: 16),
          // Moldura de "foto": o gato troca com um fade suave.
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(30),
                boxShadow: AppShadows.soft,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: ColoredBox(
                  color: AppColors.sand,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    layoutBuilder: expandedSwitcherLayout,
                    child: KeyedSubtree(
                      key: ValueKey(
                        _isLoading ? 'carregando' : (_catId ?? 'erro'),
                      ),
                      child: _buildImage(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSaveButton(canSave: canSave, label: saveLabel),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : loadAnotherCat,
                  // Cada novo gato gira o ícone uma volta completa.
                  icon: AnimatedRotation(
                    turns: _requestId.toDouble(),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    child: const Icon(Icons.refresh),
                  ),
                  label: const Text('Outro gato'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 56),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
