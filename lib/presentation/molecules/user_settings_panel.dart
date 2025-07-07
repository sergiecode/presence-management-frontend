import 'package:flutter/material.dart';
import '../../data/services/notification_service.dart';

/// **MOLÉCULA: Panel de Configuración de Usuario**
///
/// Componente que maneja las configuraciones y preferencias del usuario.
///
/// **Características:**
/// - Configuración de notificaciones
/// - Configuración de hora de check-in
/// - Zona horaria
/// - Interfaz intuitiva con switches y selectors
class UserSettingsPanel extends StatelessWidget {
  /// Si las notificaciones están habilitadas
  final bool notificationsEnabled;

  /// Offset en minutos para notificaciones
  final int notificationOffsetMin;

  /// Zona horaria del usuario
  final String timezone;

  /// Hora de check-in configurada
  final String checkinTime;

  /// Función que se ejecuta al cambiar configuración de notificaciones
  final Function(bool) onNotificationsChanged;

  /// Función que se ejecuta al cambiar offset de notificaciones
  final Function(int) onNotificationOffsetChanged;

  /// Si está en estado de carga
  final bool isLoading;

  const UserSettingsPanel({
    super.key,
    required this.notificationsEnabled,
    required this.notificationOffsetMin,
    required this.timezone,
    required this.checkinTime,
    required this.onNotificationsChanged,
    required this.onNotificationOffsetChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección
            const Text(
              'Configuración',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE67D21),
              ),
            ),
            const SizedBox(height: 20),

            // Configuración de notificaciones
            _buildSettingItem(
              icon: Icons.notifications,
              title: 'Notificaciones',
              subtitle: 'Recibir recordatorios de check-in',
              child: Switch(
                value: notificationsEnabled,
                onChanged: isLoading ? null : onNotificationsChanged,
                activeColor: const Color(0xFFE67D21),
              ),
            ),

            const Divider(height: 30),

            // Configuración de offset de notificaciones
            _buildSettingItem(
              icon: Icons.schedule,
              title: 'Recordatorio',
              subtitle:
                  'Minutos antes del check-in: $notificationOffsetMin min',
              child: DropdownButton<int>(
                value: notificationOffsetMin,
                items: [0, 5, 10, 15, 30, 60].map((int value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value min'),
                  );
                }).toList(),
                onChanged: isLoading
                    ? null
                    : (int? newValue) {
                        if (newValue != null) {
                          onNotificationOffsetChanged(newValue);
                        }
                      },
              ),
            ),

            const Divider(height: 30),

            // Botón de prueba de notificaciones
            _buildTestNotificationButton(),

            const Divider(height: 30),

            // Información de zona horaria (solo lectura)
            _buildInfoItem(
              icon: Icons.public,
              title: 'Zona Horaria',
              value: timezone,
            ),

            const SizedBox(height: 16),

            // Información de hora de check-in (solo lectura)
            _buildInfoItem(
              icon: Icons.access_time,
              title: 'Hora de Check-in',
              value: checkinTime,
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un elemento de configuración con switch o dropdown
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE67D21)),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }

  /// Crea el botón de prueba de notificaciones
  Widget _buildTestNotificationButton() {
    return Center(
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : _testNotification,
        icon: const Icon(Icons.notifications_active),
        label: const Text('Probar Notificación'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE67D21),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
    );
  }

  /// Envía una notificación de prueba
  Future<void> _testNotification() async {
    try {
      final notificationService = NotificationService();
      
      // Verificar permisos
      final hasPermissions = await notificationService.hasPermissions();
      if (!hasPermissions) {
        // Aquí podrías mostrar un diálogo pidiendo permisos
        print('UserSettingsPanel: Sin permisos de notificaciones');
        return;
      }

      // Enviar notificación de prueba
      await notificationService.showTestNotification(userName: 'Usuario');
    } catch (e) {
      print('UserSettingsPanel: Error enviando notificación de prueba: $e');
    }
  }

  /// Construye un elemento de información (solo lectura)
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
