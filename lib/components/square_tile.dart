import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';

/// Botão de login social (ícone SVG + texto opcional), em estilo "contornado".
class SquareTile extends StatelessWidget {
  final String imagePath;
  final double height;
  final Function()? onTap;
  final String? label;

  const SquareTile({
    super.key,
    required this.imagePath,
    required this.height,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(imagePath, height: height),
            if (label != null) ...[
              const SizedBox(width: 12),
              Text(label!),
            ],
          ],
        ),
      ),
    );
  }
}
