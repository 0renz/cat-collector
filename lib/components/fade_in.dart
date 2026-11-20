import 'package:flutter/material.dart';

/// Aparece suavemente (fade + leve subida) uma única vez, quando entra na
/// árvore de widgets.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final double offsetY;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.offsetY = 16,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      child: child,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, offsetY * (1 - value)),
            child: child,
          ),
        );
      },
    );
  }
}

/// Layout para AnimatedSwitcher que mantém o conteúdo ocupando todo o espaço
/// (o padrão do Flutter afrouxa as restrições e encolhe telas e fotos).
Widget expandedSwitcherLayout(
  Widget? currentChild,
  List<Widget> previousChildren,
) {
  return Stack(
    fit: StackFit.expand,
    children: [
      ...previousChildren,
      if (currentChild != null) currentChild,
    ],
  );
}

/// Estado vazio padrão: ícone de patinha, título e mensagem.
class EmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: FadeSlideIn(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFBE6D8),
                ),
                child: const Icon(
                  Icons.pets,
                  size: 44,
                  color: Color(0xFFC2561B),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6F655D), height: 1.4),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 12),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
