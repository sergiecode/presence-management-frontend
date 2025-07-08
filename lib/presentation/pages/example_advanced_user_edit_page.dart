import 'package:flutter/material.dart';
import 'dart:io';
import '../molecules/molecules.dart';
import '../../core/constants/app_constants.dart';

/// **EJEMPLO: Uso del Formulario Avanzado de Usuario**
///
/// Esta página muestra cómo implementar el nuevo formulario de edición
/// de usuario con todas las características avanzadas.
class ExampleAdvancedUserEditPage extends StatefulWidget {
  const ExampleAdvancedUserEditPage({super.key});

  @override
  State<ExampleAdvancedUserEditPage> createState() =>
      _ExampleAdvancedUserEditPageState();
}

class _ExampleAdvancedUserEditPageState
    extends State<ExampleAdvancedUserEditPage> {
  bool _isLoading = false;
  String? _errorMessage;

  // Datos de ejemplo del usuario
  Map<String, dynamic> _sampleUserData = {
    'id': 12345,
    'name': 'María José',
    'surname': 'García López',
    'email': 'maria.garcia@absti.com',
    'phone': '+54 11 1234-5678',
    'picture':
        'https://ui-avatars.com/api/?name=Maria+Garcia&background=E67D21&color=fff',
    'role': 'manager',
    'timezone': 'America/Argentina/Buenos_Aires',
    'notification_offset_min': 15,
    'checkin_start_time': '09:00',
    'email_confirmed': true,
    'deactivated': false,
    'pending_approval': false,
  };

  /// Simula el guardado de datos del usuario
  Future<void> _handleSaveUser({
    required String name,
    required String surname,
    required String phone,
    required String timezone,
    required int notificationOffsetMin,
    required String checkinStartTime,
    required String checkoutEndTime,
    File? newProfileImage,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Simular delay de red
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Aquí iría la lógica real de guardado
      print('Guardando datos del usuario:');
      print('- Nombre: $name');
      print('- Apellido: $surname');
      print('- Teléfono: $phone');
      print('- Zona horaria: $timezone');
      print('- Recordatorio: $notificationOffsetMin minutos');
      print('- Hora check-in: $checkinStartTime');
      print('- Hora check-out: $checkoutEndTime');
      if (newProfileImage != null) {
        print('- Nueva imagen: ${newProfileImage.path}');
      }

      // Actualizar datos locales
      setState(() {
        _sampleUserData.addAll({
          'name': name,
          'surname': surname,
          'phone': phone,
          'timezone': timezone,
          'notification_offset_min': notificationOffsetMin,
          'checkin_start_time': checkinStartTime,
          'checkout_end_time': checkoutEndTime,
        });
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al guardar los datos: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Simula diferentes tipos de usuario
  void _toggleUserRole() {
    setState(() {
      final currentRole = _sampleUserData['role'];
      _sampleUserData['role'] = currentRole == 'admin' ? 'employee' : 'admin';
    });
  }

  /// Simula diferentes estados de cuenta
  void _toggleAccountStatus() {
    setState(() {
      _sampleUserData['email_confirmed'] =
          !(_sampleUserData['email_confirmed'] ?? false);
      _sampleUserData['pending_approval'] =
          !(_sampleUserData['pending_approval'] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _sampleUserData['role'] == 'admin';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
        title: const Text(
          'Formulario Avanzado - Demo',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Botón para alternar rol de usuario
          IconButton(
            icon: Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              color: AppColors.primary,
            ),
            onPressed: _toggleUserRole,
            tooltip: 'Cambiar rol (${isAdmin ? 'Admin' : 'Usuario'})',
          ),
          // Botón para alternar estado de cuenta
          IconButton(
            icon: const Icon(Icons.toggle_on, color: AppColors.primary),
            onPressed: _toggleAccountStatus,
            tooltip: 'Cambiar estado de cuenta',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header informativo
            Card(
              color: AppColors.primary.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Demo del Formulario Avanzado',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este es un ejemplo del nuevo formulario de edición de usuario. '
                      'Incluye campos editables, campos de solo lectura, edición de avatar, '
                      'y diferentes vistas según el rol del usuario.',
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            'Rol: ${isAdmin ? 'Administrador' : 'Usuario'}',
                          ),
                          backgroundColor: isAdmin
                              ? AppColors.warning
                              : AppColors.info,
                        ),
                        Chip(
                          label: Text(
                            'Email: ${_sampleUserData['email_confirmed'] ? 'Confirmado' : 'Sin confirmar'}',
                          ),
                          backgroundColor: _sampleUserData['email_confirmed']
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Formulario avanzado
            AdvancedUserEditForm(
              userData: _sampleUserData,
              onSave: _handleSaveUser,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              isAdmin: isAdmin,
            ),

            const SizedBox(height: 20),

            // Información adicional
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚡ Características Implementadas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const _FeatureItem(
                      icon: Icons.photo_camera,
                      title: 'Editor de Avatar',
                      description: 'Subida de fotos desde cámara o galería',
                    ),
                    const _FeatureItem(
                      icon: Icons.edit,
                      title: 'Campos Editables',
                      description:
                          'Nombre, apellido, teléfono, configuraciones',
                    ),
                    const _FeatureItem(
                      icon: Icons.visibility,
                      title: 'Campos de Solo Lectura',
                      description: 'Email, rol, ID, estados del sistema',
                    ),
                    const _FeatureItem(
                      icon: Icons.admin_panel_settings,
                      title: 'Vista de Administrador',
                      description: 'Campos adicionales para usuarios admin',
                    ),
                    const _FeatureItem(
                      icon: Icons.check_circle,
                      title: 'Validación Completa',
                      description: 'Validación de campos y formatos de imagen',
                    ),
                    const _FeatureItem(
                      icon: Icons.palette,
                      title: 'UI/UX Mejorada',
                      description: 'Interfaz intuitiva con estados visuales',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Datos actuales (para debugging)
            if (isAdmin) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔧 Datos Actuales (Debug)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          _sampleUserData.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget auxiliar para mostrar características
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
