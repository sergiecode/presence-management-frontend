import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// Importaciones de la nueva estructura
import '../../data/services/user_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/providers/auth_provider.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';

/// **PÁGINA: Perfil de Usuario**
///
/// Página donde los usuarios pueden ver y editar su información personal,
/// así como configurar sus preferencias de la aplicación.
///
/// **Funcionalidades:**
/// - Edición de información personal (nombre, apellido, email, teléfono)
/// - Configuración de notificaciones y recordatorios
/// - Configuración de ubicación
/// - Información de cuenta y zona horaria
/// - Logout seguro
///
/// **Componentes utilizados:**
/// - AppLogo (átomo)
/// - PersonalInfoForm (molécula)
/// - UserSettingsPanel (molécula)
/// - CustomButton (átomo)
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Estados de la página
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Carga los datos del usuario desde la API
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final userData = await UserService.getCurrentUser(token);

        if (userData != null && mounted) {
          setState(() {
            _userData = userData;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al cargar datos del usuario';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Guarda los cambios de información personal (solo campos editables)
  Future<void> _saveAdvancedUserInfo({
    required String name,
    required String surname,
    required String phone,
    required String timezone,
    required int notificationOffsetMin,
    required String checkinStartTime,
    File? newProfileImage,
  }) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        // Primero subir la imagen si hay una nueva
        String? newImageUrl;
        if (newProfileImage != null) {
          newImageUrl = await UserService.uploadUserAvatar(
            token,
            _userData?['id'] ?? 0,
            newProfileImage,
          );
        }

        // Preparar datos de actualización (solo campos editables)
        final profileData = <String, dynamic>{
          'phone': phone,
          'timezone': timezone,
          'notification_offset_min': notificationOffsetMin,
          'checkin_start_time': checkinStartTime,
        };

        // Agregar URL de imagen si se subió exitosamente
        if (newImageUrl != null) {
          profileData['picture'] = newImageUrl;
        }

        // Usar el nuevo método updateProfile
        final result = await UserService.updateProfile(token, profileData);

        if (result != null && mounted) {
          // Recargar datos para mostrar los cambios
          await _loadUserData();

          // Programar notificaciones con la nueva configuración
          await _scheduleNotifications(
            checkinStartTime: checkinStartTime,
            notificationOffsetMin: notificationOffsetMin,
            userName:
                '${_userData?['name'] ?? ''} ${_userData?['surname'] ?? ''}',
          );

          _showSuccessSnackBar('Perfil actualizado correctamente');
        } else {
          setState(() {
            _errorMessage = 'Error al actualizar el perfil';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión. Intenta nuevamente.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Programa notificaciones de recordatorio de check-in
  Future<void> _scheduleNotifications({
    required String checkinStartTime,
    required int notificationOffsetMin,
    required String userName,
  }) async {
    try {
      // Solo programar si las notificaciones están habilitadas (offset > 0)
      if (notificationOffsetMin > 0) {
        final notificationService = NotificationService();

        // Verificar permisos
        final hasPermissions = await notificationService.hasPermissions();
        if (!hasPermissions) {
          print('ProfilePage: Sin permisos de notificaciones');
          return;
        }

        // Programar recordatorio diario
        final success = await notificationService.scheduleCheckinReminder(
          checkinTime: checkinStartTime,
          notificationOffsetMin: notificationOffsetMin,
          userName: userName,
        );

        if (success) {
          print('ProfilePage: Notificaciones programadas exitosamente');
        } else {
          print('ProfilePage: Error programando notificaciones');
        }
      } else {
        // Si el offset es 0, cancelar notificaciones
        await NotificationService().cancelCheckinReminder();
        print('ProfilePage: Notificaciones canceladas (offset = 0)');
      }
    } catch (e) {
      print('ProfilePage: Error al programar notificaciones: $e');
    }
  }

  /// Maneja el logout del usuario
  Future<void> _handleLogout() async {
    // Mostrar diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Cerrar Sesión',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  /// Muestra un SnackBar de éxito
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color.fromARGB(255, 89, 167, 92),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        centerTitle: true,
        title: const AppLogo.navbar(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE67D21)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFFE67D21)),
                  SizedBox(height: 16),
                  Text(
                    'Cargando perfil...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Formulario avanzado de información personal
                  AdvancedUserEditForm(
                    userData: _userData,
                    onSave: _saveAdvancedUserInfo,
                    isLoading: _isSaving,
                    errorMessage: _errorMessage,
                    isAdmin: _userData?['role'] == 'admin',
                  ),

                  const SizedBox(height: 20),

                  // Botón de logout
                  CustomButton(
                    text: 'Cerrar Sesión',
                    onPressed: _handleLogout,
                    type: ButtonType.secondary,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
    );
  }
}
