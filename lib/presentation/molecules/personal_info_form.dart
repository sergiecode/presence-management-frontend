import 'package:flutter/material.dart';
import '../atoms/atoms.dart';

/// **MOLÉCULA: Formulario de Información Personal**
///
/// Componente que maneja el formulario de edición de información
/// personal del usuario.
///
/// **Características:**
/// - Campos para nombre, apellido, email y teléfono
/// - Validación integrada
/// - Estados de carga y error
/// - Interfaz consistente con el diseño de la app
class PersonalInfoForm extends StatefulWidget {
  /// Datos actuales del usuario
  final Map<String, dynamic>? userData;

  /// Función que se ejecuta al guardar los cambios
  final Future<void> Function({
    required String name,
    required String surname,
    required String email,
    required String phone,
  })
  onSave;

  /// Si el formulario está en estado de carga
  final bool isLoading;

  /// Mensaje de error a mostrar (null si no hay error)
  final String? errorMessage;

  const PersonalInfoForm({
    super.key,
    this.userData,
    required this.onSave,
    this.isLoading = false,
    this.errorMessage,
  });

  @override
  State<PersonalInfoForm> createState() => _PersonalInfoFormState();
}

class _PersonalInfoFormState extends State<PersonalInfoForm> {
  /// Clave global para el formulario (para validación)
  final _formKey = GlobalKey<FormState>();

  /// Controladores para todos los campos del formulario
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  @override
  void didUpdateWidget(PersonalInfoForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userData != oldWidget.userData) {
      _populateFields();
    }
  }

  /// Puebla los campos con los datos actuales del usuario
  void _populateFields() {
    if (widget.userData != null) {
      _nameController.text = widget.userData!['name'] ?? '';
      _surnameController.text = widget.userData!['surname'] ?? '';
      _emailController.text = widget.userData!['email'] ?? '';
      _phoneController.text = widget.userData!['phone'] ?? '';
    }
  }

  @override
  void dispose() {
    // Limpiar todos los controladores al destruir el widget
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Maneja el submit del formulario
  void _handleSubmit() {
    // Validar el formulario
    if (_formKey.currentState?.validate() ?? false) {
      // Si todo está bien, ejecutar la función de guardado
      widget.onSave(
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
    }
  }

  /// Validador para el campo de nombre
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El nombre es requerido';
    }
    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    return null;
  }

  /// Validador para el campo de apellido
  String? _validateSurname(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El apellido es requerido';
    }
    if (value.trim().length < 2) {
      return 'El apellido debe tener al menos 2 caracteres';
    }
    return null;
  }

  /// Validador para el campo de email
  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El email es requerido';
    }
    // Regex para validar formato de email
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    return null;
  }

  /// Validador para el campo de teléfono
  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El teléfono es requerido';
    }
    if (value.trim().length < 8) {
      return 'El teléfono debe tener al menos 8 caracteres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título de la sección
              const Text(
                'Información Personal',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE67D21),
                ),
              ),
              const SizedBox(height: 20),

              // Campo de nombre
              CustomTextField(
                controller: _nameController,
                labelText: 'Nombre *',
                prefixIcon: Icons.person,
                validator: _validateName,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: 16),

              // Campo de apellido
              CustomTextField(
                controller: _surnameController,
                labelText: 'Apellido *',
                prefixIcon: Icons.person_outline,
                validator: _validateSurname,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: 16),

              // Campo de email
              CustomTextField(
                controller: _emailController,
                labelText: 'Email *',
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: 16),

              // Campo de teléfono
              CustomTextField(
                controller: _phoneController,
                labelText: 'Teléfono *',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                enabled: !widget.isLoading,
              ),
              const SizedBox(height: 20),

              // Mensaje de error (si existe)
              if (widget.errorMessage != null)
                StatusMessage(
                  message: widget.errorMessage!,
                  type: MessageType.error,
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
      ),
    );
  }
}
