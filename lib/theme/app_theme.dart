import 'package:flutter/material.dart';

/// Paleta do app: creme quente como fundo, terracota como cor de destaque e
/// dourado reservado para o gato favorito.
class AppColors {
  AppColors._();

  static const Color cream = Color(0xFFFAF6F1); // fundo das telas
  static const Color surface = Colors.white; // cards e molduras
  static const Color sand = Color(0xFFF1E9DF); // áreas neutras, fundo das fotos
  static const Color line = Color(0xFFE9DFD3); // bordas discretas
  static const Color ink = Color(0xFF2A2420); // texto principal
  static const Color muted = Color(0xFF6F655D); // texto secundário
  static const Color primary = Color(0xFFC2561B); // terracota (contraste 4.5:1 com branco)
  static const Color primarySoft = Color(0xFFFBE6D8); // fundo de chips e seleção
  static const Color onPrimarySoft = Color(0xFF7A3410);
  static const Color gold = Color(0xFFF2B01E); // favorito / foto de perfil
  static const Color danger = Color(0xFFD64545);
}

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x142A2420),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];
}

/// Decoração padrão dos campos de texto (arredondada, com borda discreta que
/// ganha a cor de destaque quando o campo está em foco).
InputDecoration appInputDecoration({
  String? hint,
  String? label,
  String? helper,
  Widget? prefix,
  Widget? suffix,
  Color fill = AppColors.surface,
  double radius = 18,
}) {
  OutlineInputBorder border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hint,
    labelText: label,
    helperText: helper,
    hintStyle: const TextStyle(color: AppColors.muted),
    helperStyle: const TextStyle(color: AppColors.muted),
    prefixIcon: prefix,
    suffixIcon: suffix,
    prefixIconColor: AppColors.muted,
    suffixIconColor: AppColors.muted,
    filled: true,
    fillColor: fill,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: border(AppColors.line),
    enabledBorder: border(AppColors.line),
    focusedBorder: border(AppColors.primary, 1.6),
    errorBorder: border(AppColors.danger),
    focusedErrorBorder: border(AppColors.danger, 1.6),
  );
}

ThemeData buildAppTheme() {
  const scheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.primarySoft,
    onPrimaryContainer: AppColors.onPrimarySoft,
    secondary: AppColors.onPrimarySoft,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.primarySoft,
    onSecondaryContainer: AppColors.onPrimarySoft,
    surface: AppColors.surface,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    onError: Colors.white,
    outline: AppColors.line,
    outlineVariant: AppColors.line,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    fontFamily: 'Roboto',
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.cream,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cream,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Roboto',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.ink,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.sand,
        disabledForegroundColor: AppColors.muted,
        elevation: 0,
        shadowColor: Colors.transparent,
        minimumSize: const Size(0, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.primarySoft,
      labelStyle: const TextStyle(
        color: AppColors.onPrimarySoft,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide.none,
      shape: const StadiumBorder(),
      deleteIconColor: AppColors.onPrimarySoft,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cream,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );
}
