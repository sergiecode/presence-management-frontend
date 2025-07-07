import 'package:flutter/material.dart';

/// **ORGANISMO: Menú de Navegación**
///
/// Componente que muestra un menú deslizante con opciones de navegación
/// y acciones del usuario.
///
/// **Características:**
/// - Navegación a diferentes secciones de la app
/// - Información del usuario
/// - Opción de logout
/// - Diseño consistente y accesible
class NavigationMenu extends StatelessWidget {
  /// Función que se ejecuta al navegar al perfil
  final VoidCallback onProfile;

  /// Función que se ejecuta al navegar al historial
  final VoidCallback onHistory;

  /// Función que se ejecuta al navegar a solicitudes
  final VoidCallback onRequests;

  /// Función que se ejecuta al hacer logout
  final VoidCallback onLogout;

  const NavigationMenu({
    super.key,
    required this.onProfile,
    required this.onHistory,
    required this.onRequests,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador visual del modal
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Título del menú
          const Text(
            'Menú',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE67D21),
            ),
          ),
          const SizedBox(height: 20),

          // Opciones del menú
          _buildMenuItem(
            icon: Icons.person,
            title: 'Mi Perfil',
            subtitle: 'Ver y editar información personal',
            onTap: onProfile,
          ),

          _buildMenuItem(
            icon: Icons.history,
            title: 'Historial',
            subtitle: 'Ver registro de asistencias',
            onTap: onHistory,
          ),

          _buildMenuItem(
            icon: Icons.request_page,
            title: 'Solicitudes',
            subtitle: 'Gestionar permisos y ausencias',
            onTap: onRequests,
          ),

          const Divider(height: 30),

          // Opción de logout
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Cerrar Sesión',
            subtitle: 'Salir de la aplicación',
            onTap: onLogout,
            isDestructive: true,
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// Construye un elemento del menú
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red : const Color(0xFFE67D21);

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red.shade700 : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
}
