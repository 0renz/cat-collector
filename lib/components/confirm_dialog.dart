import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Janela de confirmação para ações destrutivas. Devolve true só se o
/// usuário confirmar; fechar a janela ou tocar em "Cancelar" devolve false.
Future<bool> confirmarAcao(
  BuildContext context, {
  required String titulo,
  required String mensagem,
  String confirmarTexto = 'Excluir',
}) async {
  final confirmado = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          titulo,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        content: Text(
          mensagem,
          style: const TextStyle(color: AppColors.muted, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.muted),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmarTexto),
          ),
        ],
      );
    },
  );
  return confirmado ?? false;
}
