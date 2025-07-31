import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';

// Importaciones de la nueva estructura
import '../../data/services/absence_service.dart';
import '../../data/providers/auth_provider.dart';
import '../organisms/organisms.dart';
import '../molecules/molecules.dart';
import '../atoms/atoms.dart';

/// **Página de Ausencias**
///
/// Página que permite al usuario gestionar sus ausencias, incluyendo
/// la visualización del historial y la creación de nuevas ausencias.
///
/// Utiliza el diseño atómico:
/// - Moléculas: NewAbsenceDialog para crear ausencias
/// - Organismo: AbsenceManagementPanel para gestionar toda la funcionalidad
class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  /// Lista de ausencias del usuario
  List<Map<String, dynamic>> absences = [];

  /// Indica si se están cargando los datos
  bool _isLoading = true;

  /// Indica si se está creando una nueva ausencia
  bool _isCreating = false;

  /// Tipos de ausencia disponibles con sus propiedades visuales
  final List<Map<String, dynamic>> _absenceTypes = [
    {
      'type': 'absence',
      'label': 'Ausencia',
      'icon': Icons.event_busy,
      'color': Colors.orange,
    },
    {
      'type': 'medical',
      'label': 'Permiso Médico',
      'icon': Icons.medical_services,
      'color': Colors.red,
    },
    {
      'type': 'vacation',
      'label': 'Vacaciones',
      'icon': Icons.beach_access,
      'color': Colors.blue,
    },
    {
      'type': 'personal',
      'label': 'Permiso Personal',
      'icon': Icons.person,
      'color': Colors.green,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAbsences();
  }

  /// Carga las ausencias del usuario desde el servidor
  Future<void> _loadAbsences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final data = await AbsenceService.getAbsences(token);
        setState(() {
          absences = data;
        });
      }
    } catch (e) {
      _showErrorSnackBar(
        'Error al cargar ausencias: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Muestra el diálogo para crear una nueva ausencia
  void _showNewAbsenceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NewAbsenceDialog(
          absenceTypes: _absenceTypes,
          onAbsenceCreated: _onAbsenceCreated,
        );
      },
    );
  }

  /// Maneja la creación de una nueva ausencia
  Future<void> _onAbsenceCreated(
    Map<String, dynamic> absenceData,
    File? documentFile,
  ) async {
    setState(() {
      _isCreating = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        // Crear la ausencia
        final createdAbsence = await AbsenceService.createAbsence(
          token,
          absenceData,
        );

        // Si hay documento, subirlo
        if (documentFile != null && createdAbsence['id'] != null) {
          await AbsenceService.uploadDocument(
            token,
            createdAbsence['id'],
            documentFile.path,
          );
        }

        _showSuccessSnackBar('Ausencia registrada exitosamente');
        await _loadAbsences(); // Recargar la lista
      }
    } catch (e) {
      _showErrorSnackBar(
        'Error al crear ausencia: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      setState(() {
        _isCreating = false;
      });
    }
  }

  /// Muestra un mensaje de error al usuario
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Muestra un mensaje de éxito al usuario
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 89, 167, 92),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  /// Construye la barra de navegación superior
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      centerTitle: true,
      title: const AppLogo.navbar(),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFFe67d21)),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  /// Construye el estado de carga
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFe67d21)),
          SizedBox(height: 16),
          Text(
            'Cargando ausencias...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Construye el contenido principal de la página
  Widget _buildContent() {
    return AbsenceManagementPanel(
      absences: absences,
      absenceTypes: _absenceTypes,
      isCreating: _isCreating,
      onNewAbsence: _showNewAbsenceDialog,
      onRefresh: _loadAbsences,
    );
  }
}
