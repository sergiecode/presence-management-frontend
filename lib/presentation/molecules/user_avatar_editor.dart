import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_constants.dart';

/// **MOLÉCULA: Editor de Avatar de Usuario**
///
/// Componente que permite ver y editar la foto de perfil del usuario.
///
/// **Características:**
/// - Muestra la foto actual del usuario
/// - Permite seleccionar nueva foto desde galería o cámara
/// - Validación de tamaño y formato de imagen
/// - Avatar por defecto con iniciales si no hay foto
/// - Estados de carga durante upload
class UserAvatarEditor extends StatefulWidget {
  /// URL de la foto actual del usuario
  final String? currentPhotoUrl;

  /// Iniciales del usuario para mostrar como fallback
  final String userInitials;

  /// Función que se ejecuta al seleccionar nueva imagen
  final Function(File imageFile)? onImageSelected;

  /// Si está en proceso de subida de imagen
  final bool isUploading;

  /// Si el widget está habilitado para edición
  final bool enabled;

  /// Tamaño del avatar
  final double size;

  const UserAvatarEditor({
    super.key,
    this.currentPhotoUrl,
    required this.userInitials,
    this.onImageSelected,
    this.isUploading = false,
    this.enabled = true,
    this.size = 120.0,
  });

  @override
  State<UserAvatarEditor> createState() => _UserAvatarEditorState();
}

class _UserAvatarEditorState extends State<UserAvatarEditor> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  /// Muestra el selector de fuente de imagen
  Future<void> _showImageSourceDialog() async {
    if (!widget.enabled) return;

    final result = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Cambiar foto de perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primary,
                ),
                title: const Text('Seleccionar de galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (widget.currentPhotoUrl != null || _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Quitar foto'),
                  onTap: () => Navigator.pop(context, null),
                ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );

    if (result != null) {
      await _pickImage(result);
    } else if (result == null && widget.currentPhotoUrl != null) {
      // Usuario quiere quitar la foto
      setState(() {
        _selectedImage = null;
      });
      // Aquí se podría llamar una función para eliminar la foto del servidor
    }
  }

  /// Selecciona una imagen de la fuente especificada
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);

        // Validar tamaño del archivo
        final int fileSizeBytes = await imageFile.length();
        if (fileSizeBytes > AppConfig.maxImageSizeBytes) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('La imagen es demasiado grande. Máximo 5MB.'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        // Validar extensión
        final String extension = image.path.split('.').last.toLowerCase();
        if (!AppConfig.allowedImageExtensions.contains(extension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Formato de imagen no válido. Use JPG, PNG o GIF.',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedImage = imageFile;
        });

        // Notificar al widget padre
        if (widget.onImageSelected != null) {
          widget.onImageSelected!(imageFile);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al seleccionar imagen'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Construye el widget de imagen
  Widget _buildImageWidget() {
    if (_selectedImage != null) {
      // Mostrar imagen seleccionada
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Image.file(
          _selectedImage!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
        ),
      );
    } else if (widget.currentPhotoUrl != null &&
        widget.currentPhotoUrl!.isNotEmpty) {
      // Mostrar imagen actual del servidor
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.size / 2),
        child: Image.network(
          widget.currentPhotoUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFallbackAvatar();
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(widget.size / 2),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Mostrar avatar con iniciales
      return _buildFallbackAvatar();
    }
  }

  /// Construye el avatar de fallback con iniciales
  Widget _buildFallbackAvatar() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(widget.size / 2),
      ),
      child: Center(
        child: Text(
          widget.userInitials,
          style: TextStyle(
            color: Colors.white,
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: widget.enabled ? _showImageSourceDialog : null,
          child: Stack(
            children: [
              // Imagen principal
              _buildImageWidget(),

              // Indicador de loading
              if (widget.isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(widget.size / 2),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),

              // Icono de edición
              if (widget.enabled && !widget.isUploading)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
        ),

        if (widget.enabled) const SizedBox(height: 8),

        if (widget.enabled)
          Text(
            'Tocar para cambiar',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
      ],
    );
  }
}
