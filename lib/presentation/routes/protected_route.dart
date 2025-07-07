/// Componentes de rutas protegidas para la aplicación ABSTI
///
/// Este archivo contiene widgets que manejan la protección de rutas
/// basada en el estado de autenticación del usuario.
///
/// Incluye rutas protegidas (requieren autenticación) y rutas de invitado
/// (requieren NO estar autenticado).
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';

/// Widget que protege rutas que requieren autenticación
///
/// Este widget verifica si el usuario está autenticado antes de mostrar
/// el contenido. Si no está autenticado, redirige al login.
///
/// Casos de uso:
/// - Páginas principales de la aplicación (home, perfil, historial)
/// - Funcionalidades que requieren usuario logueado
class ProtectedRoute extends StatelessWidget {
  /// Widget hijo que se muestra si el usuario está autenticado
  final Widget child;

  /// Widget opcional que se muestra mientras se verifica la autenticación
  final Widget? fallback;

  /// Constructor de la ruta protegida
  ///
  /// Parámetros:
  /// - [child]: Widget a mostrar si está autenticado
  /// - [fallback]: Widget opcional para mostrar durante la verificación
  const ProtectedRoute({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el estado de autenticación
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Si aún no se ha inicializado, mostrar loading
        if (!authProvider.isInitialized) {
          return _buildLoadingScreen();
        }

        // Si está autenticado, mostrar el contenido
        if (authProvider.isAuthenticated) {
          return child;
        } else {
          // Si no está autenticado, redirigir al login
          _redirectToLogin(context);

          // Mientras se redirige, mostrar loading o fallback
          return fallback ?? _buildUnauthorizedScreen();
        }
      },
    );
  }

  /// Redirigir al usuario a la página de login
  ///
  /// Parámetros:
  /// - [context]: Contexto de construcción del widget
  void _redirectToLogin(BuildContext context) {
    // Programar la redirección para el siguiente frame
    // Esto evita problemas de navegación durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    });
  }

  /// Construir pantalla de carga mientras se inicializa
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la aplicación
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(
                  AppStyles.borderRadiusLarge,
                ),
              ),
              child: const Center(
                child: Text(
                  'ABSTI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppStyles.paddingLarge),

            // Indicador de progreso
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),

            const SizedBox(height: AppStyles.paddingMedium),

            // Texto de carga
            Text(
              'Verificando autenticación...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppStyles.fontSizeMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir pantalla para usuario no autorizado
  Widget _buildUnauthorizedScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de no autorizado
            Icon(Icons.lock_outline, size: 64, color: AppColors.error),

            const SizedBox(height: AppStyles.paddingMedium),

            // Mensaje de no autorizado
            Text(
              'Acceso no autorizado',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppStyles.fontSizeXLarge,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppStyles.paddingSmall),

            Text(
              'Redirigiendo al login...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppStyles.fontSizeMedium,
              ),
            ),

            const SizedBox(height: AppStyles.paddingLarge),

            // Indicador de progreso
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para rutas que requieren NO estar autenticado
///
/// Este widget verifica que el usuario NO esté autenticado antes de mostrar
/// el contenido. Si ya está autenticado, redirige al home.
///
/// Casos de uso:
/// - Página de login
/// - Página de registro
/// - Páginas de recuperación de contraseña
class GuestRoute extends StatelessWidget {
  /// Widget hijo que se muestra si el usuario NO está autenticado
  final Widget child;

  /// Constructor de la ruta de invitado
  ///
  /// Parámetros:
  /// - [child]: Widget a mostrar si NO está autenticado
  const GuestRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios en el estado de autenticación
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Si aún no se ha inicializado, mostrar loading
        if (!authProvider.isInitialized) {
          return _buildLoadingScreen();
        }

        // Si NO está autenticado, mostrar el contenido
        if (!authProvider.isAuthenticated) {
          return child;
        } else {
          // Si ya está autenticado, redirigir al home
          _redirectToHome(context);

          // Mientras se redirige, mostrar loading
          return _buildAlreadyAuthenticatedScreen();
        }
      },
    );
  }

  /// Redirigir al usuario a la página principal
  ///
  /// Parámetros:
  /// - [context]: Contexto de construcción del widget
  void _redirectToHome(BuildContext context) {
    // Programar la redirección para el siguiente frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  /// Construir pantalla de carga durante inicialización
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la aplicación
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(
                  AppStyles.borderRadiusLarge,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'ABSTI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppStyles.paddingXLarge),

            // Indicador de progreso
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),

            const SizedBox(height: AppStyles.paddingMedium),

            // Texto de bienvenida
            Text(
              'Iniciando ${AppConfig.appName}...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppStyles.fontSizeLarge,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construir pantalla para usuario ya autenticado
  Widget _buildAlreadyAuthenticatedScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de usuario autenticado
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 40,
                color: AppColors.success,
              ),
            ),

            const SizedBox(height: AppStyles.paddingMedium),

            // Mensaje de ya autenticado
            Text(
              'Ya tienes sesión iniciada',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: AppStyles.fontSizeXLarge,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: AppStyles.paddingSmall),

            Text(
              'Redirigiendo a la aplicación...',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppStyles.fontSizeMedium,
              ),
            ),

            const SizedBox(height: AppStyles.paddingLarge),

            // Indicador de progreso
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget para manejar errores de autenticación
///
/// Muestra una pantalla de error con opciones para reintentar
class AuthErrorRoute extends StatelessWidget {
  /// Mensaje de error a mostrar
  final String error;

  /// Callback para reintentar la autenticación
  final VoidCallback? onRetry;

  const AuthErrorRoute({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(AppStyles.paddingLarge),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de error
              Icon(Icons.error_outline, size: 64, color: AppColors.error),

              const SizedBox(height: AppStyles.paddingMedium),

              // Título del error
              Text(
                'Error de autenticación',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: AppStyles.fontSizeXLarge,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppStyles.paddingSmall),

              // Mensaje de error
              Text(
                error,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppStyles.fontSizeMedium,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppStyles.paddingXLarge),

              // Botón de reintentar
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),

              const SizedBox(height: AppStyles.paddingMedium),

              // Botón para ir al login
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                child: const Text('Ir al Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
