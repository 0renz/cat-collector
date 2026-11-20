import 'package:flutter/material.dart';

/// Botão principal dos formulários. Valida o formulário antes de chamar
/// [onPressed] e troca o texto por um indicador de progresso enquanto
/// [isLoading] for verdadeiro.
class MyButton extends StatelessWidget {
  final Function()? onPressed;
  final GlobalKey<FormState> formKey;
  final String text;
  final bool isLoading;

  const MyButton({
    super.key,
    required this.onPressed,
    required this.formKey,
    required this.text,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        height: 54,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            if (isLoading) return;
            if (formKey.currentState!.validate()) {
              onPressed?.call();
            }
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(text, key: ValueKey(text)),
          ),
        ),
      ),
    );
  }
}
