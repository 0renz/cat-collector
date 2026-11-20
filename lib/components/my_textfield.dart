import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MyTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget icon;
  final bool obscureText;
  final bool capitalization;
  final TextInputType? keyboardType;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.obscureText,
    required this.capitalization,
    this.keyboardType,
  });

  @override
  State<MyTextField> createState() {
    return MyTextFieldState();
  }
}

class MyTextFieldState extends State<MyTextField> {
  // Campos de senha ganham um botão para mostrar/ocultar o texto.
  late bool _hidden = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextFormField(
        controller: widget.controller,
        obscureText: _hidden,
        keyboardType: widget.keyboardType,
        textCapitalization: widget.capitalization
            ? TextCapitalization.words
            : TextCapitalization.none,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Preenchimento obrigatório!';
          }
          return null;
        },
        decoration: appInputDecoration(
          hint: widget.hintText,
          prefix: widget.icon,
          suffix: widget.obscureText
              ? IconButton(
                  tooltip: _hidden ? 'Mostrar senha' : 'Ocultar senha',
                  icon: Icon(
                    _hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () => setState(() => _hidden = !_hidden),
                )
              : null,
        ),
      ),
    );
  }
}
