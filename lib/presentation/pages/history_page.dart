import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importaciones de la nueva estructura
import '../../data/services/checkin_service.dart';
import '../../data/providers/auth_provider.dart';
import '../organisms/organisms.dart';
import '../atoms/atoms.dart';

/// **Página de Historial**
///
/// Página que muestra el historial completo de registros de entrada y salida
/// del usuario. Permite filtrar por diferentes períodos de tiempo y muestra
/// estadísticas agregadas del tiempo trabajado.
///
/// Utiliza el diseño atómico:
/// - Átomo: AppLogo para el logo en la barra de navegación
/// - Organismo: HistoryList para manejar toda la lógica del historial
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  /// Filtro actualmente seleccionado para los registros
  String selectedFilter = 'Todos';

  /// Opciones disponibles para filtrar el historial
  final List<String> filterOptions = [
    'Todos',
    'Última semana',
    'Último mes',
    'Este año',
  ];

  /// Lista de registros de entrada/salida del usuario
  List<Map<String, dynamic>> checkInHistory = [];

  /// Indica si se están cargando los datos
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCheckInHistory();
  }

  /// Carga el historial de registros desde el servidor
  Future<void> _loadCheckInHistory() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final data = await CheckInService.getCheckIns(token);
        setState(() {
          checkInHistory = data;
        });
      }
    } catch (e) {
      _showErrorSnackBar(
        'Error al cargar historial: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Muestra un mensaje de error al usuario
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Maneja el cambio de filtro
  void _onFilterChanged(String newFilter) {
    setState(() {
      selectedFilter = newFilter;
    });
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
      // title: const AppLogo.navbar(),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.3),
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
            'Cargando historial...',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Construye el contenido principal de la página
  Widget _buildContent() {
    return HistoryList(
      checkInHistory: checkInHistory,
      selectedFilter: selectedFilter,
      filterOptions: filterOptions,
      onFilterChanged: _onFilterChanged,
      onRefresh: _loadCheckInHistory,
    );
  }
}
