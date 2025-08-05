import 'package:flutter/material.dart';
import 'dart:io';
import '../atoms/atoms.dart';
import './user_avatar_editor.dart';
import '../../core/constants/app_constants.dart';

/// **MOLÉCULA: Formulario Completo de Edición de Usuario**
///
/// Componente que maneja el formulario completo de edición de información
/// del usuario, incluyendo campos editables y de solo lectura.
///
/// **Características:**
/// - Edición de foto de perfil
/// - Campos editables: nombre, apellido, teléfono, timezone, etc.
/// - Campos de solo lectura: email, rol, estado, etc.
/// - Validación integral
/// - Estados de carga y error
/// - Interfaz adaptativa según permisos
class AdvancedUserEditForm extends StatefulWidget {
  /// Datos actuales del usuario
  final Map<String, dynamic>? userData;

  /// Función que se ejecuta al guardar los cambios
  final Future<void> Function({
    required String name,
    required String surname,
    required String phone,
    required String timezone,
    required int notificationOffsetMin,
    required String checkinStartTime,
    File? newProfileImage,
  })
  onSave;

  /// Si el formulario está en estado de carga
  final bool isLoading;

  /// Mensaje de error a mostrar (null si no hay error)
  final String? errorMessage;

  /// Si el usuario actual es administrador (puede ver más campos)
  final bool isAdmin;

  const AdvancedUserEditForm({
    super.key,
    this.userData,
    required this.onSave,
    this.isLoading = false,
    this.errorMessage,
    this.isAdmin = false,
  });

  @override
  State<AdvancedUserEditForm> createState() => _AdvancedUserEditFormState();
}

class _AdvancedUserEditFormState extends State<AdvancedUserEditForm> {
  /// Clave global para el formulario (para validación)
  final _formKey = GlobalKey<FormState>();

  /// Controladores para campos editables
  final _phoneController = TextEditingController();
  final _timezoneController = TextEditingController();
  final _checkinStartTimeController = TextEditingController();

  /// Variables para campos con selección
  int _notificationOffsetMin = 0;
  File? _selectedProfileImage;
  bool _isUploadingImage = false;

  /// Lista de zonas horarias comunes
  final List<String> _commonTimezones = [
    'America/Argentina/Buenos_Aires',
    'America/Santiago',
    'America/Sao_Paulo',
    'America/Lima',
    'America/Bogota',
    'America/Mexico_City',
    'America/New_York',
    'Europe/Madrid',
    'Europe/London',
    'UTC',
  ];

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  @override
  void didUpdateWidget(AdvancedUserEditForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      _populateFields();
    }
  }

  /// Puebla los campos con los datos actuales del usuario
  void _populateFields() {
    if (widget.userData != null) {
      _phoneController.text = widget.userData!['phone'] ?? '';
      _timezoneController.text = widget.userData!['timezone'] ?? 'UTC';
      _checkinStartTimeController.text =
          widget.userData!['checkin_start_time'] ?? '09:00';
      _notificationOffsetMin = widget.userData!['notification_offset_min'] ?? 0;
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _timezoneController.dispose();
    _checkinStartTimeController.dispose();
    super.dispose();
  }

  /// Maneja el submit del formulario
  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Solo enviamos los campos editables, nombre y apellido se obtienen del userData actual
      widget.onSave(
        name:
            widget.userData!['name'] ??
            '', // Campo readonly, pero requerido por la interfaz
        surname:
            widget.userData!['surname'] ??
            '', // Campo readonly, pero requerido por la interfaz
        phone: _phoneController.text.trim(),
        timezone: _timezoneController.text.trim(),
        notificationOffsetMin: _notificationOffsetMin,
        checkinStartTime: _checkinStartTimeController.text.trim(),
        newProfileImage: _selectedProfileImage,
      );
    }
  }

  /// Maneja la selección de nueva imagen de perfil
  void _handleImageSelected(File imageFile) {
    setState(() {
      _selectedProfileImage = imageFile;
      _isUploadingImage = true;
    });

    // Simular upload (en una implementación real, aquí subirías la imagen)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    });
  }

  /// Selecciona hora de check-in
  Future<void> _selectCheckinTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _checkinStartTimeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  /// Construye un campo de información de solo lectura
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
    Widget? statusWidget,
  }) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: valueColor ?? Colors.black87,
                          ),
                        ),
                      ),
                      if (statusWidget != null) statusWidget,
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye un widget de estado
  Widget _buildStatusChip(String status, bool value) {
    final color = value ? AppColors.success : AppColors.error;
    final text = value ? 'Activo' : 'Inactivo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// Validaciones
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ErrorMessages.requiredField;
    }
    if (value.trim().length < 8) {
      return 'El teléfono debe tener al menos 8 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final userData = widget.userData;
    if (userData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección: Foto de perfil y datos básicos
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información Personal',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Avatar editor centrado
                    Center(
                      child: UserAvatarEditor(
                        currentPhotoUrl: userData['picture'],
                        userInitials: _getInitials(),
                        onImageSelected: _handleImageSelected,
                        isUploading: _isUploadingImage,
                        enabled: !widget.isLoading,
                        size: 120,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campos de solo lectura
                    _buildReadOnlyField(
                      label: 'Nombre',
                      value: widget.userData!['name'] ?? 'No especificado',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 16),

                    _buildReadOnlyField(
                      label: 'Apellido',
                      value: widget.userData!['surname'] ?? 'No especificado',
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 16),

                    // Campos editables
                    CustomTextField(
                      controller: _phoneController,
                      labelText: 'Teléfono *',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhone,
                      enabled: !widget.isLoading,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sección: Información de cuenta (solo lectura)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de Cuenta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildReadOnlyField(
                      label: 'Email',
                      value: userData['email'] ?? 'No especificado',
                      icon: Icons.email,
                      statusWidget: _buildStatusChip(
                        'Confirmado',
                        userData['email_confirmed'] ?? false,
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildReadOnlyField(
                      label: 'Rol',
                      value:
                          AppConfig.userRoleLabels[userData['role']] ??
                          userData['role'] ??
                          'No especificado',
                      icon:
                          AppConfig.userRoleIcons[userData['role']] ??
                          Icons.person,
                    ),

                    const SizedBox(height: 12),

                    _buildReadOnlyField(
                      label: 'ID de Usuario',
                      value: userData['id']?.toString() ?? 'N/A',
                      icon: Icons.tag,
                    ),

                    if (widget.isAdmin) ...[
                      const SizedBox(height: 12),
                      _buildReadOnlyField(
                        label: 'Estado de Cuenta',
                        value: userData['deactivated'] == true
                            ? 'Desactivada'
                            : 'Activa',
                        icon: Icons.account_circle,
                        valueColor: userData['deactivated'] == true
                            ? AppColors.error
                            : AppColors.success,
                      ),

                      const SizedBox(height: 12),
                      _buildReadOnlyField(
                        label: 'Aprobación Pendiente',
                        value: userData['pending_approval'] == true
                            ? 'Sí'
                            : 'No',
                        icon: Icons.pending,
                        valueColor: userData['pending_approval'] == true
                            ? AppColors.warning
                            : AppColors.success,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Mensaje de error
            if (widget.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: StatusMessage(
                  message: widget.errorMessage!,
                  type: MessageType.error,
                ),
              ),

            // Botón de guardar
            CustomButton(
              text: 'Guardar Cambios',
              onPressed: widget.isLoading ? null : _handleSubmit,
              isLoading: widget.isLoading,
              type: ButtonType.primary,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }

  /// Obtiene las iniciales del usuario
  String _getInitials() {
    final name = widget.userData?['name'] ?? '';
    final surname = widget.userData?['surname'] ?? '';

    String initials = '';
    if (name.isNotEmpty) initials += name[0].toUpperCase();
    if (surname.isNotEmpty && initials.length < 2) {
      initials += surname[0].toUpperCase();
    }

    return initials.isEmpty ? 'U' : initials;
  }
}
