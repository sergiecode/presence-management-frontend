/// Configuración del tema de la aplicación ABSTI
///
/// Este archivo define todos los estilos visuales de la aplicación,
/// incluyendo colores, tipografías, botones, campos de texto, etc.
/// Utiliza las constantes definidas en app_constants.dart
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Clase que contiene la configuración completa del tema de la aplicación
class AppTheme {
  /// Tema principal de la aplicación con colores corporativos de ABSTI
  static ThemeData get lightTheme {
    return ThemeData(
      // Configuración del esquema de colores usando Material 3
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),

      // Color de fondo principal de las pantallas
      scaffoldBackgroundColor: AppColors.background,

      // Configuración de la barra de aplicación (AppBar)
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: AppStyles.elevationLow,
        shadowColor: Colors.grey,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: AppStyles.fontSizeXLarge,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Configuración de botones elevados (ElevatedButton)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: AppStyles.elevationLow,
          shadowColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.paddingLarge,
            vertical: AppStyles.paddingMedium,
          ),
          textStyle: const TextStyle(
            fontSize: AppStyles.fontSizeLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Configuración de botones de texto (TextButton)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontSize: AppStyles.fontSizeMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Configuración de campos de entrada de texto
      inputDecorationTheme: InputDecorationTheme(
        // Bordes cuando el campo no está enfocado
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        // Borde cuando el campo está enfocado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        // Borde cuando hay error
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        // Configuración de relleno y colores
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingMedium,
          vertical: AppStyles.paddingMedium,
        ),
        // Estilos de texto para etiquetas
        labelStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: AppStyles.fontSizeMedium,
        ),
        floatingLabelStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: AppStyles.fontSizeMedium,
        ),
      ),

      // Configuración de tarjetas (Card)
      cardTheme: CardThemeData(
        elevation: AppStyles.elevationLow,
        shadowColor: Colors.grey.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
        ),
        color: AppColors.surface,
      ),

      // Configuración de mensajes emergentes (SnackBar)
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusSmall),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Configuración de diálogos
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusLarge),
        ),
        elevation: AppStyles.elevationHigh,
      ),

      // Configuración del indicador de progreso circular
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      // Configuración de iconos
      iconTheme: const IconThemeData(color: AppColors.textSecondary, size: 24),

      // Configuración de divisores
      dividerTheme: DividerThemeData(
        color: Colors.grey.withValues(alpha: 0.2),
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Tema oscuro (para futuras implementaciones)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
    );
  }
}

/// Extensiones útiles para trabajar con colores y estilos
extension ColorExtensions on Color {
  /// Convierte un color a su equivalente con opacidad reducida
  Color withOpacityPercentage(double percentage) {
    return withValues(alpha: percentage / 100);
  }
}

/// Clase con estilos de texto predefinidos para la aplicación
class AppTextStyles {
  /// Estilo para títulos principales
  static const TextStyle heading1 = TextStyle(
    fontSize: AppStyles.fontSizeTitle,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  /// Estilo para subtítulos
  static const TextStyle heading2 = TextStyle(
    fontSize: AppStyles.fontSizeXLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  /// Estilo para texto normal
  static const TextStyle body1 = TextStyle(
    fontSize: AppStyles.fontSizeLarge,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  /// Estilo para texto secundario
  static const TextStyle body2 = TextStyle(
    fontSize: AppStyles.fontSizeMedium,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  /// Estilo para texto pequeño
  static const TextStyle caption = TextStyle(
    fontSize: AppStyles.fontSizeSmall,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
  );

  /// Estilo para botones
  static const TextStyle button = TextStyle(
    fontSize: AppStyles.fontSizeLarge,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  /// Estilo para enlaces
  static const TextStyle link = TextStyle(
    fontSize: AppStyles.fontSizeMedium,
    fontWeight: FontWeight.w500,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );

  /// Estilo para texto de error
  static const TextStyle error = TextStyle(
    fontSize: AppStyles.fontSizeMedium,
    fontWeight: FontWeight.normal,
    color: AppColors.error,
  );

  /// Estilo para texto de éxito
  static const TextStyle success = TextStyle(
    fontSize: AppStyles.fontSizeMedium,
    fontWeight: FontWeight.normal,
    color: AppColors.success,
  );
}
