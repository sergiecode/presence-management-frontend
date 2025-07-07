import 'package:flutter/material.dart';

/// **ÁTOMO: Logo de la aplicación ABSTI**
///
/// Este componente representa el logo de la aplicación que se puede usar
/// en diferentes tamaños y contextos (navbar, página de login, etc).
///
/// **Características:**
/// - Maneja errores de carga de imagen mostrando un fallback personalizado
/// - Configurable en tamaño (width, height)
/// - Estilo visual consistente con la marca ABSTI
/// - Gradiente corporativo como respaldo
/// - Constructores nombrados para casos de uso específicos
class AppLogo extends StatelessWidget {
  /// Ancho del logo (por defecto 120)
  final double width;

  /// Alto del logo (por defecto 120)
  final double height;

  /// Ruta de la imagen del logo
  final String imagePath;

  /// Si debe mostrar el texto "Asistencia" debajo del logo
  final bool showSubtitle;

  /// Constructor general
  const AppLogo({
    super.key,
    this.width = 120,
    this.height = 120,
    this.imagePath = 'assets/images/logo-app.png',
    this.showSubtitle = true,
  });

  /// Constructor para navbar (tamaño optimizado para barras de navegación)
  const AppLogo.navbar({
    super.key,
    this.width = 120,
    this.height = 120,
    this.imagePath = 'assets/images/logo-navbar.png',
    this.showSubtitle = false,
  });

  /// Constructor para pantallas de login (tamaño grande)
  const AppLogo.login({
    super.key,
    this.width = 150,
    this.height = 150,
    this.imagePath = 'assets/images/logo-app.png',
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imagePath,
      width: width,
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback personalizado cuando la imagen no se puede cargar
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            // Gradiente corporativo ABSTI
            gradient: const LinearGradient(
              colors: [Color(0xFFE67D21), Color(0xFFD16815)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE67D21).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Texto principal del logo (tamaño proporcional)
                Text(
                  'ABSTI',
                  style: TextStyle(
                    fontSize: _getFontSize(),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: _getLetterSpacing(),
                  ),
                ),
                // Subtítulo opcional
                if (showSubtitle)
                  Text(
                    'Asistencia',
                    style: TextStyle(
                      fontSize: _getSubtitleFontSize(),
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Calcula el tamaño de fuente principal basado en el tamaño del logo
  double _getFontSize() {
    if (width <= 50) return 12; // Para navbar
    if (width <= 100) return 18; // Para tamaños medianos
    return 24; // Para tamaños grandes
  }

  /// Calcula el espaciado entre letras basado en el tamaño
  double _getLetterSpacing() {
    if (width <= 50) return 1; // Para navbar
    return 2; // Para tamaños más grandes
  }

  /// Calcula el tamaño de fuente del subtítulo
  double _getSubtitleFontSize() {
    if (width <= 50) return 6; // Para navbar
    if (width <= 100) return 8; // Para tamaños medianos
    return 10; // Para tamaños grandes
  }
}
