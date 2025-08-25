import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';

// Importaciones de la nueva estructura
import '../../data/services/checkin_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/catalog_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/models/work_location.dart';
import '../../core/constants/location_types.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';
import '../organisms/organisms.dart';

// Importaciones de páginas refactorizadas
import 'pages.dart';

/// **PÁGINA: Página Principal (Home)**
///
/// Página principal de la aplicación donde los usuarios pueden:
/// - Ver su estado de trabajo actual
/// - Iniciar y terminar jornadas laborales
/// - Navegar a otras secciones de la app
/// - Ver resumen de tiempo trabajado
///
/// **Funcionalidades principales:**
/// - Control de tiempo de trabajo en tiempo real
/// - Gestión de check-in/check-out
/// - Selección de ubicación de trabajo
/// - Navegación a perfil, historial y solicitudes
/// - Logout seguro
///
/// **Componentes utilizados:**
/// - AppLogo (átomo)
/// - WorkStatusPanel (organismo)
/// - NavigationMenu (organismo)
/// - WorkConfirmationDialog (molécula)
class HomePage extends StatefulWidget {
  /// Token de autenticación del usuario
  final String token;

  const HomePage({super.key, required this.token});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  // Estados del trabajo
  bool _isWorking = false;
  DateTime? _workStartTime;
  Duration _workDuration = Duration.zero;
  Timer? _workTimer;

  // Configuración de ubicación usando constantes del backend
  List<int> _selectedLocations = [LocationTypes.REMOTE_DECLARED]; // Lista de ubicaciones seleccionadas
  final Map<int, String> _locations = LocationTypes.names;
  
  // Nuevas variables para el manejo de selección única vs múltiple
  String _selectionMode = 'single'; // 'single' o 'multiple'
  int? _selectedSingleLocation = LocationTypes.REMOTE_DECLARED; // Ubicación cuando está en modo único
  
  // Mapa para horarios de ubicaciones múltiples: {locationId: TimeOfDay}
  Map<int, TimeOfDay> _locationSchedule = {};

  // Campos adicionales para "Domicilio Alternativo"
  String? _otherLocationDetail;
  String? _otherLocationFloor;
  String? _otherLocationApartment;

  // Nuevos campos para la funcionalidad mejorada
  /// Ubicaciones del catálogo (oficinas, clientes, etc.)
  List<CatalogLocation> _catalogLocations = [];
  
  /// Dirección del domicilio declarado del usuario
  String? _userDeclaredAddress;
  
  /// Lista de ubicaciones adicionales agregadas durante el día
  List<WorkLocation> _additionalLocations = [];
  
  // /// Datos del usuario actual
  // Map<String, dynamic>? _userData;

  // Campo para almacenar el location_detail cuando la jornada está completada
  String? _completedLocationDetail;

  // Historial de ubicaciones durante la jornada
  List<Map<String, dynamic>> _locationHistory = [];

  void _onLocationChanged(List<int> newLocations) {
    if (!mounted) return;
    setState(() {
      _selectedLocations = newLocations;
      
      // Si no incluye "Domicilio Alternativo", limpiar sus campos
      if (!newLocations.contains(LocationTypes.REMOTE_ALTERNATIVE)) {
        _otherLocationDetail = null;
        _otherLocationFloor = null;
        _otherLocationApartment = null;
      }
    });
  }

  void _onSelectionModeChanged(String newMode) {
    if (!mounted) return;
    setState(() {
      _selectionMode = newMode;
      
      if (newMode == 'single') {
        // Si cambia a modo único, usar la primera ubicación seleccionada como única
        if (_selectedLocations.isNotEmpty) {
          _selectedSingleLocation = _selectedLocations.first;
          _selectedLocations = [_selectedSingleLocation!];
        } else {
          _selectedSingleLocation = LocationTypes.REMOTE_DECLARED;
          _selectedLocations = [_selectedSingleLocation!];
        }
      } else {
        // Si cambia a modo múltiple, mantener la selección actual
        if (_selectedSingleLocation != null) {
          _selectedLocations = [_selectedSingleLocation!];
        }
      }
    });
  }

  void _onSingleLocationChanged(int locationId) {
    if (!mounted) return;
    setState(() {
      _selectedSingleLocation = locationId;
      _selectedLocations = [locationId];
      
      // Si no es "Domicilio Alternativo", limpiar sus campos
      if (locationId != LocationTypes.REMOTE_ALTERNATIVE) {
        _otherLocationDetail = null;
        _otherLocationFloor = null;
        _otherLocationApartment = null;
      }
    });
  }

  void _onScheduleChanged(Map<int, TimeOfDay> newSchedule) {
    if (!mounted) return;
    setState(() {
      _locationSchedule = newSchedule;
    });
  }

  void _onOtherLocationChanged(String value) {
    if (!mounted) return;
    setState(() {
      _otherLocationDetail = value;
    });
  }

  void _onOtherLocationFloorChanged(String value) {
    if (!mounted) return;
    setState(() {
      _otherLocationFloor = value;
    });
  }

  void _onOtherLocationApartmentChanged(String value) {
    if (!mounted) return;
    setState(() {
      _otherLocationApartment = value;
    });
  }

  // Funciones para manejar ubicaciones adicionales
  void _onAddAdditionalLocation(WorkLocation location) {
    if (!mounted) return;
    setState(() {
      _additionalLocations.add(location);
    });
  }

  void _onRemoveAdditionalLocation(int index) {
    if (!mounted) return;
    if (index >= 0 && index < _additionalLocations.length) {
      setState(() {
        _additionalLocations.removeAt(index);
      });
    }
  }

  void _onUpdateAdditionalLocation(int index, WorkLocation location) {
    if (!mounted) return;
    if (index >= 0 && index < _additionalLocations.length) {
      setState(() {
        _additionalLocations[index] = location;
      });
    }
  }

  /// Carga las ubicaciones del catálogo
  Future<void> _loadCatalogLocations() async {
    try {
      print('HomePage: Iniciando carga de ubicaciones del catálogo...');
      final catalogLocations = await CatalogService.getLocations(widget.token);
      
      if (mounted) {
        setState(() {
          _catalogLocations = catalogLocations;
        });
        print('HomePage: ✅ ${catalogLocations.length} ubicaciones del catálogo cargadas exitosamente:');
        for (final location in catalogLocations) {
          print('  - ID: ${location.id}, Nombre: ${location.name}, Activa: ${location.isActive}');
        }
      }
    } catch (e) {
      print('HomePage: ❌ Error cargando ubicaciones del catálogo: $e');
      // No mostrar error al usuario, las ubicaciones del catálogo son opcionales
      // pero seguir funcionando con las ubicaciones básicas
    }
  }

  /// Carga los datos del usuario para obtener el domicilio declarado
  Future<void> _loadUserData() async {
    try {
      print('HomePage: Iniciando carga de datos del usuario...');
      final userData = await UserService.getCurrentUser(widget.token);
      
      if (userData != null && mounted) {
        setState(() {
          // _userData = userData; // Comentado - no se usa actualmente
        });
        print('HomePage: ✅ Datos del usuario cargados exitosamente');
        
        // Cargar dirección declarada por separado usando el nuevo endpoint
        print('HomePage: 🔍 Cargando domicilio declarado...');
        try {
          final declaredAddressData = await UserService.getUserDeclaredAddress(widget.token);
          print('HomePage: 📍 Datos raw del domicilio: $declaredAddressData');
          if (declaredAddressData != null && mounted) {
            final formattedAddress = UserService.formatDeclaredAddress(declaredAddressData);
            print('HomePage: 📍 Dirección formateada: "$formattedAddress"');
            setState(() {
              _userDeclaredAddress = formattedAddress.isNotEmpty ? formattedAddress : null;
            });
            print('HomePage: ✅ Domicilio declarado establecido: ${_userDeclaredAddress ?? "No configurado"}');
          } else {
            print('HomePage: ❌ No se pudo obtener datos del domicilio declarado');
          }
        } catch (e) {
          print('HomePage: ⚠️ Error cargando domicilio declarado: $e');
          // No bloquear la UI, el domicilio declarado es opcional
        }
      }
    } catch (e) {
      print('HomePage: ❌ Error cargando datos del usuario: $e');
      // No bloquear la UI, el domicilio declarado es opcional
    }
  }

  // Datos de la sesión
  Map<String, dynamic>? _todayCheckIn;
  final List<Map<String, dynamic>> _workHistory = [];

  // Estados de la UI
  bool _isLoading = true;
  bool _isProcessing = false;
  bool _dayCompleted = false;
  
  // Servicios
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTodayCheckIn();
    _initializeNotificationService();
    // Cargar catálogos y datos del usuario en paralelo
    _loadCatalogLocations();
    _loadUserData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _workTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Cuando la app regresa al foreground, actualizar el estado
    if (state == AppLifecycleState.resumed) {
      // App resumed - Actualizando estado...
      _refreshState();
    }
  }

    /// Carga las ubicaciones planificadas del checkin actual
  Future<void> _loadPlannedLocations() async {
    if (_todayCheckIn == null) return;
    
    try {
      // Extraer ubicaciones del checkin actual
      final locations = _todayCheckIn!['locations'];
      if (locations != null && locations is List) {
        List<Map<String, dynamic>> plannedLocations = [];
        
        for (var location in locations) {
          if (location is Map<String, dynamic>) {
            final startTime = location['start_time'];
            final locationDetail = location['location_detail'] ?? '';
            final locationType = location['location_type'] ?? 1;
            
            // Crear entrada de historial para la ubicación planificada
            plannedLocations.add({
              'location_type': locationType,
              'location_detail': locationDetail,
              'timestamp': startTime ?? _todayCheckIn!['time'],
              'description': '$locationDetail (Planificado)',
              'is_planned': true, // Marcador para distinguir de cambios reales
            });
          }
        }
        
        // Ordenar por timestamp
        plannedLocations.sort((a, b) {
          final timeA = DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
          final timeB = DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
          return timeA.compareTo(timeB);
        });
        
        if (mounted) {
          setState(() {
            // Combinar ubicaciones planificadas con historial real
            _locationHistory = [...plannedLocations, ..._locationHistory];
          });
        }
      }
    } catch (e) {
      print('Error cargando ubicaciones planificadas: $e');
    }
  }

  /// Carga el historial de ubicaciones del día actual si existe
  Future<void> _loadTodayCheckIn() async {
    // _loadTodayCheckIn: Iniciando carga...
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      // _loadTodayCheckIn: Token disponible: ${token != null}

      if (token != null) {
        final checkIn = await CheckInService.getTodayCheckIn(token);
        // _loadTodayCheckIn: Resultado del servicio: $checkIn

        if (checkIn != null) {
          // DIAGNÓSTICO COMPLETO DEL CHECK-IN
          print('=== 🔍 DIAGNÓSTICO DEL CHECK-IN ===');
          print('📅 ID: ${checkIn['id']}');
          print('📅 Fecha: ${checkIn['date']}');
          print('⏰ check_in_time: ${checkIn['check_in_time']}');
          print('⏰ time: ${checkIn['time']}');
          print('🚪 checkout_time: ${checkIn['checkout_time']}');
          print('🚪 check_out_time: ${checkIn['check_out_time']}');
          print('📊 checkout_status: ${checkIn['checkout_status']}');
          print('🏠 location_type: ${checkIn['location_type']}');
          print('📍 location_detail: ${checkIn['location_detail']}');
          print('🗂️ locations: ${checkIn['locations']}');
          print('⏱️ created_at: ${checkIn['created_at']}');
          print('⏱️ updated_at: ${checkIn['updated_at']}');
          print('=== FIN DIAGNÓSTICO ===');
          
          print('_loadTodayCheckIn: checkIn encontrado: $checkIn');
          print(
            '_loadTodayCheckIn: checkout_time: ${checkIn['checkout_time']}',
          );
          print(
            '_loadTodayCheckIn: check_out_time: ${checkIn['check_out_time']}',
          );
          print(
            '_loadTodayCheckIn: checkout_status: ${checkIn['checkout_status']}',
          );

          final checkoutTime = checkIn['checkout_time'] ?? checkIn['check_out_time'];

          // Para jornadas completadas, obtener la ubicación real del historial
          String actualLocationDetail = checkIn['location_detail'];
          if (checkoutTime != null) {
            print('_loadTodayCheckIn: Jornada completada - obteniendo ubicación real del historial...');
            try {
              final locationHistory = await CheckInService.getSessionLocationHistory(token);
              if (locationHistory.isNotEmpty) {
                // Buscar la ubicación más reciente (última del día)
                final lastLocation = locationHistory.last;
                actualLocationDetail = lastLocation['location_detail'] ?? actualLocationDetail;
                print('_loadTodayCheckIn: Ubicación de fin de jornada desde historial: $actualLocationDetail');
              }
            } catch (e) {
              print('_loadTodayCheckIn: Error obteniendo historial para ubicación final: $e');
              // Continuar con la ubicación del check-in si hay error
            }
          }

          setState(() {
            _todayCheckIn = checkIn;

            // Normalizar los nombres de los campos
            final checkoutTime =
                checkIn['checkout_time'] ?? checkIn['check_out_time'];
            final checkoutStatus = checkIn['checkout_status'];

            // Si ya hay check-in pero no checkout, está trabajando
            if (checkoutTime == null) {
              print(
                '_loadTodayCheckIn: Condición 1 - Usuario está trabajando (sin checkout_time)',
              );
              _isWorking = true;
              _dayCompleted = false;

              // Intentar obtener la hora de inicio desde diferentes campos
              try {
                String? timeString;

                // Prioridad 1: check_in_time (campo normalizado)
                if (checkIn['check_in_time'] != null &&
                    checkIn['check_in_time'].toString().isNotEmpty) {
                  timeString = checkIn['check_in_time'].toString();
                  print('_loadTodayCheckIn: Usando check_in_time: $timeString');

                  // Si es un timestamp ISO completo, parsear directamente
                  if (timeString.contains('T')) {
                    _workStartTime = DateTime.parse(timeString);
                  } else {
                    // Si es solo hora, combinar con fecha
                    _workStartTime = DateTime.parse(
                      '${checkIn['date']} $timeString',
                    );
                  }
                }
                // Prioridad 2: time (campo original del backend)
                else if (checkIn['time'] != null &&
                    checkIn['time'].toString().isNotEmpty) {
                  timeString = checkIn['time'].toString();
                  print('_loadTodayCheckIn: Usando time: $timeString');

                  // Si es un timestamp ISO completo, parsear directamente
                  if (timeString.contains('T')) {
                    _workStartTime = DateTime.parse(timeString);
                  } else {
                    // Si es solo hora, combinar con fecha
                    _workStartTime = DateTime.parse(
                      '${checkIn['date']} $timeString',
                    );
                  }
                }

                if (_workStartTime != null) {
                  print(
                    '_loadTodayCheckIn: _workStartTime parseado exitosamente: $_workStartTime',
                  );
                } else {
                  throw Exception('No se pudo obtener la hora de inicio');
                }
              } catch (e) {
                print('_loadTodayCheckIn: Error parseando fecha/hora: $e');
                print(
                  '_loadTodayCheckIn: checkIn[check_in_time]: ${checkIn['check_in_time']}',
                );
                print('_loadTodayCheckIn: checkIn[time]: ${checkIn['time']}');
                print('_loadTodayCheckIn: checkIn[date]: ${checkIn['date']}');
                // Si no se puede parsear, usar la hora actual como fallback
                _workStartTime = DateTime.now();
                print(
                  '_loadTodayCheckIn: Usando hora actual como fallback: $_workStartTime',
                );
              }

              _selectedLocations = [checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED];
              _selectedSingleLocation = _selectedLocations.first;
              _completedLocationDetail = actualLocationDetail;

              // Iniciar timer para mostrar duración actual
              _startWorkTimer();
            } else if (checkoutTime != null && checkoutStatus == 'completed') {
              // La jornada ya está completada hoy
              print(
                '_loadTodayCheckIn: Condición 2 - Jornada completada (checkout_time + status completed)',
              );
              print(
                '_loadTodayCheckIn: checkoutTime: $checkoutTime, checkoutStatus: $checkoutStatus',
              );
              _selectedLocations = [checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED];
              _selectedSingleLocation = _selectedLocations.first;
              _completedLocationDetail = actualLocationDetail;
              _isWorking = false;
              _dayCompleted = true;
              _workStartTime = null;
              // No resetear _workDuration aquí, _getTodayWorkTime() calculará el tiempo real
            } else if (checkoutTime != null) {
              // Hay checkout_time pero el status no es "completed" - podría ser que el checkout falló
              print(
                '_loadTodayCheckIn: Condición 3 - Checkout incompleto (checkout_time pero status no completed)',
              );
              print('_loadTodayCheckIn: checkoutTime: $checkoutTime');
              print('_loadTodayCheckIn: checkoutStatus: $checkoutStatus');

              // Si hay checkout_time pero no status completed, asumir que está completado
              // (el backend podría no estar actualizando el status correctamente)
              _selectedLocations = [checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED];
              _selectedSingleLocation = _selectedLocations.first;
              _completedLocationDetail = actualLocationDetail;
              _isWorking = false;
              _dayCompleted =
                  true; // Cambio: considerar completado si hay checkout_time
              _workStartTime = null;
              // No resetear _workDuration aquí, _getTodayWorkTime() calculará el tiempo real
            } else {
              // Caso por defecto - no debería llegar aquí
              print('_loadTodayCheckIn: Condición 4 - Caso inesperado');
              _isWorking = false;
              _dayCompleted = false;
              _workStartTime = null;
              _workDuration = Duration.zero;
            }
          });
        } else {
          print('_loadTodayCheckIn: No hay check-in para hoy');
          // Reset completo del estado cuando no hay check-in
          setState(() {
            _dayCompleted = false;
            _isWorking = false;
            _workStartTime = null;
            _workDuration = Duration.zero;
            _todayCheckIn = null;
            _completedLocationDetail = null;
            _selectedLocations = [];
            _selectedSingleLocation = null;
          });
        }
      } else {
        print('_loadTodayCheckIn: No hay token disponible');
      }
    } catch (e) {
      print('Error al cargar check-in de hoy: $e');
      _showErrorSnackBar('Error al cargar estado de trabajo');
    } finally {
      print(
        '_loadTodayCheckIn: Finalizando - _isWorking: $_isWorking, _workStartTime: $_workStartTime, _dayCompleted: $_dayCompleted',
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Cargar historial de ubicaciones si hay una sesión activa o completada
      if (_isWorking || _dayCompleted) {
        _loadLocationHistory();
        // También cargar las ubicaciones planificadas del checkin actual
        _loadPlannedLocations();
      }
      
      // Verificar si necesita programar recordatorios de check-in perdido
      await _checkAndScheduleMissedCheckinReminders();
    }
  }

  /// Inicia el timer para actualizar la duración del trabajo
  void _startWorkTimer() {
    _workTimer?.cancel();
    _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _workStartTime == null) {
        timer.cancel();
        return;
      }
      setState(() {
        // Usar UTC para evitar problemas de zona horaria con el servidor
        _workDuration = DateTime.now().toUtc().difference(_workStartTime!.toUtc());
      });
    });
  }

  /// Carga el historial de ubicaciones de la sesión actual
  Future<void> _loadLocationHistory() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final history = await CheckInService.getSessionLocationHistory(token);
        if (mounted) {
          setState(() {
            _locationHistory = history;
          });
        }
      }
    } catch (e) {
      print('Error al cargar historial de ubicaciones: $e');
      // No mostramos error al usuario ya que esta es información adicional
    }
  }

  /// Cancela todas las notificaciones de check-in (normales y recordatorios)
  Future<void> _cancelAllNotifications() async {
    try {
      final notificationService = NotificationService();
      
      // Cancelar notificación previa al check-in
      await notificationService.cancelCheckinReminder();
      
      // Cancelar recordatorios cada 15 minutos
      await notificationService.cancelMissedCheckinReminders();
      
      print('HomePage: Todas las notificaciones canceladas');
    } catch (e) {
      print('HomePage: Error cancelando notificaciones: $e');
    }
  }

  /// Programa recordatorios cada 15 minutos después de la hora de check-in perdida
  Future<void> _scheduleMissedCheckinReminders() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        // Obtener datos del usuario para conseguir la hora de check-in
        final userData = await UserService.getCurrentUser(token);
        if (userData != null && userData['checkin_start_time'] != null) {
          final checkinTime = userData['checkin_start_time'].toString();
          final userName = '${userData['name'] ?? ''} ${userData['surname'] ?? ''}'.trim();

          // Programar recordatorios cada 15 minutos
          final notificationService = NotificationService();
          await notificationService.scheduleMissedCheckinReminders(
            checkinTime: checkinTime,
            userName: userName.isEmpty ? 'Usuario' : userName,
            maxReminders: 12, // 3 horas de recordatorios
          );

          print('HomePage: Recordatorios de check-in perdido programados');
        }
      }
    } catch (e) {
      print('HomePage: Error programando recordatorios de check-in perdido: $e');
    }
  }

  /// Verifica si debe programar recordatorios de check-in perdido
  Future<void> _initializeNotificationService() async {
    await _notificationService.initialize();
    // Configurar las notificaciones después de cargar los datos del usuario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndScheduleMissedCheckinReminders();
    });
  }

  Future<void> _checkAndScheduleMissedCheckinReminders() async {
    try {
      if (!_isWorking && !_dayCompleted) {
        // Solo si no está trabajando y no completó el día
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        if (token != null) {
          final userData = await UserService.getCurrentUser(token);
          if (userData != null && userData['checkin_start_time'] != null) {
            final checkinTime = userData['checkin_start_time'].toString();
            
            // Parsear la hora de check-in
            final timeParts = checkinTime.split(':');
            if (timeParts.length >= 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              
              // Crear fecha/hora de check-in de hoy
              final now = DateTime.now();
              final checkinDateTime = DateTime(now.year, now.month, now.day, hour, minute);
              
              // Si ya pasó la hora de check-in y no está trabajando, programar recordatorios
              if (now.isAfter(checkinDateTime)) {
                print('HomePage: Hora de check-in pasada sin registrar entrada - programando recordatorios');
                await _scheduleMissedCheckinReminders();
              }
            }
          }
        }
      }
    } catch (e) {
      print('HomePage: Error verificando recordatorios de check-in perdido: $e');
    }
  }

  /// Construye el mensaje de ubicaciones para mostrar en el diálogo de confirmación
  String _buildLocationMessage() {
    List<String> locationParts = [];

    // Agregar la ubicación principal
    String primaryLocationName = _getLocationName(_selectedSingleLocation!);
    locationParts.add(primaryLocationName);

    // Agregar ubicaciones adicionales con horarios
    for (final additionalLocation in _additionalLocations) {
      String additionalLocationName = _getLocationName(additionalLocation.locationTypeId);
      String timeRange = '${additionalLocation.startTime.format(context)}';
      if (additionalLocation.endTime != null) {
        timeRange += ' - ${additionalLocation.endTime!.format(context)}';
      }
      locationParts.add('$additionalLocationName ($timeRange)');
    }

    if (locationParts.length == 1) {
      return locationParts.first;
    } else {
      // Usar presente si ya está trabajando, futuro si va a empezar
      final prefix = _isWorking ? 'Trabajando en' : 'Trabajarás en';
      return '$prefix:\n${locationParts.map((part) => '• $part').join('\n')}';
    }
  }

  /// Obtiene el nombre de una ubicación por su ID
  String _getLocationName(int locationId) {
    if (locationId == LocationTypes.REMOTE_DECLARED) {
      return 'Domicilio Declarado';
    } else if (locationId == LocationTypes.REMOTE_ALTERNATIVE) {
      return 'Domicilio Alternativo';
    } else {
      // Buscar en el catálogo
      try {
        final catalogLocation = _catalogLocations.firstWhere(
          (cat) => cat.id == locationId,
        );
        return catalogLocation.name;
      } catch (e) {
        return 'Ubicación $locationId';
      }
    }
  }

  /// Inicia la jornada laboral
  Future<void> _startWork() async {
    if (_isProcessing) return;

    // Validar que hay una ubicación principal seleccionada
    if (_selectedSingleLocation == null) {
      _showErrorSnackBar('Selecciona una ubicación para trabajar');
      return;
    }

    // Verificar si el día ya está completado
    if (_dayCompleted) {
      _showErrorSnackBar('Ya completaste tu jornada laboral de hoy');
      return;
    }

    // Construir mensaje para el diálogo de confirmación
    String locationMessage = _buildLocationMessage();

    // Mostrar diálogo de confirmación
    final confirm = await WorkConfirmationDialog.showStartWorkDialog(
      context: context,
      locationName: locationMessage,
    );

    if (confirm == true) {
      if (mounted) {
        setState(() {
          _isProcessing = true;
        });
      }

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        if (token != null) {
          // Obtener los datos del usuario actual para conseguir user_id
          final userData = await UserService.getCurrentUser(token);
          if (userData == null || userData['id'] == null) {
            throw Exception('No se pudo obtener información del usuario');
          }

          final userId = userData['id'];

          // Obtener la fecha y hora actuales en el formato requerido RFC3339 (UTC)
          final now = DateTime.now();
          final nowUtc = now.toUtc();
          final date =
              '${nowUtc.year}-${nowUtc.month.toString().padLeft(2, '0')}-${nowUtc.day.toString().padLeft(2, '0')}';
          final time = CheckInService.toRFC3339(now);

          // Debug del formato de fecha y hora
          print('HomePageDebug: DateTime original: $now');
          print('HomePageDebug: DateTime UTC: $nowUtc');
          print('HomePageDebug: Date formateado: $date');
          print('HomePageDebug: Time RFC3339: $time');

          // Determinar si llega tarde basado en la hora de inicio del usuario
          TimeOfDay startTime = const TimeOfDay(hour: 9, minute: 0); // Hora por defecto
          
          // Si el usuario tiene una hora de inicio personalizada, usarla
          if (userData['checkin_start_time'] != null && 
              userData['checkin_start_time'].toString().isNotEmpty) {
            try {
              // Formato esperado: "HH:MM:SS" o "HH:MM"
              final timeStr = userData['checkin_start_time'].toString();
              final timeParts = timeStr.split(':');
              if (timeParts.length >= 2) {
                final hour = int.parse(timeParts[0]);
                final minute = int.parse(timeParts[1]);
                startTime = TimeOfDay(hour: hour, minute: minute);
              }
            } catch (e) {
              print('Error parseando hora de inicio del usuario: $e');
              // Usar hora por defecto si hay error
            }
          }
          
          final currentTime = TimeOfDay.fromDateTime(now);
          
          // Convertir TimeOfDay a minutos para comparar fácilmente
          final startMinutes = startTime.hour * 60 + startTime.minute;
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;
          final isLate = currentMinutes > startMinutes;

           // Crear los datos de ubicaciones para enviar al backend
          List<Map<String, dynamic>> locationsData = [];
          
          // 1. Agregar la ubicación principal seleccionada
          final primaryLocationId = _selectedSingleLocation!;
          String primaryLocationDetail;
          
          // Determinar el location_detail basado en el tipo de ubicación
          print('HomePageDebug: Determinando location_detail para locationId: $primaryLocationId');
          print('HomePageDebug: LocationTypes.REMOTE_DECLARED = ${LocationTypes.REMOTE_DECLARED}');
          print('HomePageDebug: _userDeclaredAddress = "${_userDeclaredAddress}"');
          
          if (primaryLocationId == LocationTypes.REMOTE_DECLARED && _userDeclaredAddress != null) {
            // Usar domicilio declarado del usuario
            primaryLocationDetail = _userDeclaredAddress!;
            print('HomePageDebug: ✅ Usando domicilio declarado: "$primaryLocationDetail"');
          } else if (primaryLocationId == LocationTypes.REMOTE_DECLARED && _userDeclaredAddress == null) {
            // Fallback si no hay domicilio declarado
            primaryLocationDetail = 'Domicilio Declarado';
            print('HomePageDebug: ⚠️ FALLBACK: _userDeclaredAddress es null, usando placeholder: "$primaryLocationDetail"');
          } else if (primaryLocationId == LocationTypes.REMOTE_ALTERNATIVE && _otherLocationDetail != null) {
            // Usar domicilio alternativo con campos adicionales
            primaryLocationDetail = _otherLocationDetail!;
            if (_otherLocationFloor != null && _otherLocationFloor!.isNotEmpty) {
              primaryLocationDetail += ', Piso $_otherLocationFloor';
            }
            if (_otherLocationApartment != null && _otherLocationApartment!.isNotEmpty) {
              primaryLocationDetail += ', Dpto $_otherLocationApartment';
            }
          } else if (primaryLocationId >= 1000) {
            // Es una ubicación del catálogo (IDs altos)
            final catalogLocation = _catalogLocations.firstWhere(
              (cat) => cat.id == primaryLocationId,
              orElse: () => CatalogLocation(id: primaryLocationId, name: 'Ubicación del catálogo', isActive: true),
            );
            primaryLocationDetail = catalogLocation.name;
          } else {
            // Ubicaciones estándar
            primaryLocationDetail = _locations[primaryLocationId] ?? 'Desconocido';
          }
          
          // Agregar la ubicación principal
          print('HomePageDebug: 📍 Agregando ubicación principal:');
          print('HomePageDebug:    location_type = $primaryLocationId');
          print('HomePageDebug:    location_detail = "$primaryLocationDetail"');
          print('HomePageDebug:    start_time = "$time"');
          
          locationsData.add({
            'location_type': primaryLocationId,
            'location_detail': primaryLocationDetail,
            'start_time': time, // Siempre empieza ahora
          });
          
          // 2. Agregar ubicaciones adicionales con sus horarios
          for (final additionalLocation in _additionalLocations) {
            locationsData.add(additionalLocation.toJson());
          }

          // Los datos para el check-in en el nuevo formato
          final checkInData = {
            'time': time,
            'locations': locationsData, // Lista con location_type, location_detail y start_time
            'notes': '',
            'user_id': userId,
          };

          // Si llega tarde, agregar la razón
          if (isLate) {
            checkInData['late_reason'] = 'Llegada tardía'; // Razón por defecto
          }

          // Debug: Mostrar todos los datos que se van a enviar
          print('HomePageDebug: === DATOS ENVIADOS AL SERVICIO ===');
          print('HomePageDebug: Usuario ID: $userId');
          print('HomePageDebug: Fecha actual: $now');
          print('HomePageDebug: Hora de inicio esperada: ${startTime.hour}:${startTime.minute}');
          print('HomePageDebug: Hora actual: ${currentTime.hour}:${currentTime.minute}');
          print('HomePageDebug: ¿Llega tarde?: $isLate');
          print('HomePageDebug: date = "$date"');
          print('HomePageDebug: time = "$time"');
          print('HomePageDebug: Datos completos: $checkInData');
          print('HomePageDebug: === FIN DATOS ===');

          final result = await CheckInService.checkIn(token, checkInData);

          if (mounted) {
            setState(() {
              _isWorking = true;
              _workStartTime = DateTime.now();
              _workDuration = Duration.zero;
              _todayCheckIn = result;
              // Para jornada finalizada, usar el location_detail del último elemento del array locations
              _completedLocationDetail = locationsData.isNotEmpty 
                ? locationsData.last['location_detail'] as String?
                : null;
              
              // Ya no necesitamos actualizar _selectedLocations ya que usamos el nuevo sistema
              // _selectedLocations = locationsToUse;
            });
          }

          _startWorkTimer();
          
          // Cancelar todos los recordatorios ya que se hizo check-in
          await _cancelAllNotifications();
          
          _showSuccessSnackBar('Jornada iniciada exitosamente');
        }
      } catch (e) {
        _showErrorSnackBar(
          'Error al iniciar jornada: ${e.toString().replaceAll('Exception: ', '')}',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  /// Termina la jornada laboral
  Future<void> _stopWork() async {
    print('🔄 _stopWork iniciado');
    print('🔄 _stopWork - _workStartTime: $_workStartTime');
    print('🔄 _stopWork - _isProcessing: $_isProcessing');
    print('🔄 _stopWork - _selectedLocations: $_selectedLocations');
    print('🔄 _stopWork - _locations: $_locations');
    
    if (_workStartTime == null || _isProcessing) return;

    final currentTime = DateTime.now();
    final sessionDuration = currentTime.difference(_workStartTime!);

    // Construir mensaje para el diálogo según cantidad de ubicaciones
    String locationMessage;
    if (_selectedLocations.length == 1) {
      final selectedId = _selectedLocations.first;
      print('🔄 _stopWork - selectedId: $selectedId');
      print('🔄 _stopWork - _locations[selectedId]: ${_locations[selectedId]}');
      locationMessage = _locations[_selectedLocations.first] ?? 'Ubicación desconocida';
    } else {
      locationMessage = 'ubicaciones múltiples: ${_selectedLocations.map((id) => _locations[id] ?? 'Ubicación $id').join(', ')}';
    }
    
    print('🔄 _stopWork - locationMessage: $locationMessage');

    // Mostrar diálogo de confirmación
    final confirm = await WorkConfirmationDialog.showStopWorkDialog(
      context: context,
      sessionDuration: sessionDuration,
      locationName: locationMessage,
    );

    if (confirm == true) {
      if (mounted) {
        setState(() {
          _isProcessing = true;
        });
      }

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.token;

        if (token != null && _todayCheckIn != null) {
          // Calcular si hay overtime (más de 8 horas trabajadas)
          final standardWorkHours = 8;
          final workedHours = sessionDuration.inHours;
          final hasOvertime = workedHours > standardWorkHours;

          // Body correcto para el endpoint /api/checkins/checkout
          final checkOutData = {
            'overtime': hasOvertime,
            'status': 'completed', // Status por defecto
          };

          print(
            'CheckOut: Llamando a CheckInService.checkOut con datos: $checkOutData',
          );

          await CheckInService.checkOut(token, checkOutData);

          if (mounted) {
            // Construir el location_detail actual donde se termina la jornada
            String currentLocationDetail;
            if (_selectedLocations.length == 1) {
              final locationId = _selectedLocations.first;
              if (locationId == LocationTypes.REMOTE_ALTERNATIVE && 
                  _otherLocationDetail != null && _otherLocationDetail!.isNotEmpty) {
                // Para domicilio alternativo, construir dirección completa
                currentLocationDetail = _otherLocationDetail!;
                if (_otherLocationFloor != null && _otherLocationFloor!.isNotEmpty) {
                  currentLocationDetail += ', Piso $_otherLocationFloor';
                }
                if (_otherLocationApartment != null && _otherLocationApartment!.isNotEmpty) {
                  currentLocationDetail += ', Dpto $_otherLocationApartment';
                }
              } else {
                // Para otras ubicaciones, buscar primero en ubicaciones estáticas, luego en catálogo
                String? locationName = _locations[locationId];
                if (locationName == null) {
                  // Buscar en catálogo
                  try {
                    final catalogLocation = _catalogLocations.firstWhere((cat) => cat.id == locationId);
                    locationName = catalogLocation.name;
                  } catch (e) {
                    locationName = 'Ubicación $locationId';
                  }
                }
                currentLocationDetail = locationName;
              }
            } else {
              // Para múltiples ubicaciones (esto puede pasar si iniciaste con múltiples ubicaciones)
              currentLocationDetail = _selectedLocations.map((id) {
                String? locationName = _locations[id];
                if (locationName == null) {
                  // Buscar en catálogo
                  try {
                    final catalogLocation = _catalogLocations.firstWhere((cat) => cat.id == id);
                    return catalogLocation.name;
                  } catch (e) {
                    return 'Ubicación $id';
                  }
                }
                return locationName;
              }).join(', ');
            }
            
            print('_stopWork: Terminando jornada en ubicación actual: $currentLocationDetail');

            setState(() {
              _isWorking = false;
              _dayCompleted = true; // Marcar día como completado
              _workStartTime = null;
              // No resetear _workDuration aquí, _getTodayWorkTime() calculará el tiempo real

              // Actualizar _completedLocationDetail con la ubicación actual donde se termina
              _completedLocationDetail = currentLocationDetail;

              // Actualizar el check-in con la hora de salida
              _todayCheckIn = {
                ..._todayCheckIn!,
                'checkout_time': CheckInService.toRFC3339(currentTime),
                'checkout_status':
                    'completed', // Asegurar que el status esté completado
                'location_detail': currentLocationDetail, // Actualizar también en el check-in
              };
            });
          }

          _workTimer?.cancel();
          _showSuccessSnackBar('Jornada terminada exitosamente');

          // NO hacer refresh automático para evitar pisar la ubicación actual
          // El usuario ya está viendo la ubicación correcta donde terminó
          // Future.delayed(const Duration(seconds: 1), () {
          //   if (mounted) {
          //     _refreshState();
          //   }
          // });
        } else {
          print('_stopWork: ERROR - Token o _todayCheckIn es null');
        }
      } catch (e) {
        print('_stopWork: ERROR: $e');

        // Si hay error, revertir estado y re-verificar desde el backend
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }

        // Re-cargar estado desde el backend para asegurar consistencia
        await _refreshState();

        _showErrorSnackBar(
          'Error al terminar jornada: ${e.toString().replaceAll('Exception: ', '')}',
        );
        return; // Salir temprano para evitar el finally
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  /// Calcula el tiempo total trabajado en el día
  Duration _getTodayWorkTime() {
    final today = DateTime.now();
    Duration totalTime = Duration.zero;

    // Agregar tiempo de sesiones anteriores
    for (var session in _workHistory) {
      final sessionDate = session['date'] as DateTime;
      if (sessionDate.year == today.year &&
          sessionDate.month == today.month &&
          sessionDate.day == today.day) {
        totalTime += session['duration'] as Duration;
      }
    }

    // Si hay un check-in del día actual, calcular tiempo trabajado
    if (_todayCheckIn != null) {
      try {
        // Normalizar nombres de campos
        final checkoutTime =
            _todayCheckIn!['checkout_time'] ?? _todayCheckIn!['check_out_time'];
        final checkinTime =
            _todayCheckIn!['check_in_time'] ?? _todayCheckIn!['time'];

        if (checkinTime != null) {
          // Parsear hora de inicio - asumir que viene en UTC del servidor
          DateTime startTime;
          if (checkinTime.toString().contains('T')) {
            startTime = DateTime.parse(checkinTime.toString());
            // Si no tiene información de zona, asumimos UTC
            if (!checkinTime.toString().endsWith('Z') && !checkinTime.toString().contains('+')) {
              startTime = DateTime.parse(checkinTime.toString() + 'Z');
            }
          } else {
            startTime = DateTime.parse(
              '${_todayCheckIn!['date']} $checkinTime',
            );
          }

          if (checkoutTime != null) {
            // Si hay checkout, calcular tiempo total de la jornada completada
            DateTime endTime;
            if (checkoutTime.toString().contains('T')) {
              endTime = DateTime.parse(checkoutTime.toString());
              // Si no tiene información de zona, asumimos UTC
              if (!checkoutTime.toString().endsWith('Z') && !checkoutTime.toString().contains('+')) {
                endTime = DateTime.parse(checkoutTime.toString() + 'Z');
              }
            } else {
              endTime = DateTime.parse(
                '${_todayCheckIn!['date']} $checkoutTime',
              );
            }

            // Calcular diferencia en UTC para evitar problemas de zona horaria
            final sessionDuration = endTime.toUtc().difference(startTime.toUtc());
            totalTime += sessionDuration;
            print(
              '_getTodayWorkTime: Jornada completada - ${sessionDuration.inHours}h ${sessionDuration.inMinutes.remainder(60)}m',
            );
          } else if (_isWorking && _workStartTime != null) {
            // Si está trabajando actualmente, agregar tiempo actual
            totalTime += _workDuration;
            print(
              '_getTodayWorkTime: Trabajando actualmente - ${_workDuration.inHours}h ${_workDuration.inMinutes.remainder(60)}m',
            );
          }
        }
      } catch (e) {
        print('_getTodayWorkTime: Error calculando tiempo: $e');
        // Fallback: si está trabajando, usar tiempo actual
        if (_isWorking) {
          totalTime += _workDuration;
        }
      }
    }

    return totalTime;
  }

  /// Muestra el menú de navegación
  void _showMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return NavigationMenu(
          onProfile: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilePage()),
            ).then((_) {
              // Actualizar estado cuando regresa de ProfilePage
              print('Regresando de ProfilePage - Refrescando estado...');
              _refreshState();
            });
          },
          onHistory: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HistoryPage()),
            ).then((_) {
              // Actualizar estado cuando regresa de HistoryPage
              print('Regresando de HistoryPage - Refrescando estado...');
              _refreshState();
            });
          },
          onRequests: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RequestsPage()),
            ).then((_) {
              // Actualizar estado cuando regresa de RequestsPage
              print('Regresando de RequestsPage - Refrescando estado...');
              _refreshState();
            });
          },
          onLogout: () {
            Navigator.pop(context);
            _handleLogout();
          },
        );
      },
    );
  }

  /// Muestra el diálogo de cambio de ubicación durante la jornada laboral
  void _showLocationChangeDialog() {
    print('Mostrando diálogo de cambio de ubicación');
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => LocationChangeDialog(
        catalogLocations: _catalogLocations, // Lista de ubicaciones del catálogo
        userDeclaredAddress: _userDeclaredAddress, // Dirección del domicilio declarado
        currentLocations: _selectedLocations, // Ubicaciones actualmente seleccionadas
        onLocationSelected: _changeLocationDuringWork, // Callback con WorkLocation
      ),
    );
  }

  /// Cambia la ubicación durante la jornada laboral
  Future<void> _changeLocationDuringWork(WorkLocation newLocation) async {
    print('🔄 Cambiando ubicación durante trabajo a: ${newLocation.locationTypeId}');
    print('   - Detalle: ${newLocation.locationDetail}');
    print('   - Hora inicio: ${newLocation.startTime.format(context)}');
    print('   - Hora fin: ${newLocation.endTime?.format(context) ?? 'Sin límite'}');
    print('   - ¿Usuario trabajando?: $_isWorking');
    print('   - ¿Procesando?: $_isProcessing');

    // Validar que el usuario esté trabajando
    if (!_isWorking) {
      print('❌ Error: Usuario no está trabajando actualmente');
      if (mounted) {
        _showErrorSnackBar('Debes estar trabajando para cambiar de ubicación');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
      });
    }

    try {
      // Obtener token
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null) {
        throw Exception('Token no disponible');
      }

      // Preparar datos de la nueva ubicación
      final today = DateTime.now();
      final userSelectedStartTime = DateTime(
        today.year,
        today.month,
        today.day,
        newLocation.startTime.hour,
        newLocation.startTime.minute,
      );
      
      // Si hay endTime, también prepararlo
      DateTime? userSelectedEndTime;
      if (newLocation.endTime != null) {
        userSelectedEndTime = DateTime(
          today.year,
          today.month,
          today.day,
          newLocation.endTime!.hour,
          newLocation.endTime!.minute,
        );
      }
      
      final Map<String, dynamic> locationData = {
        'location_type': newLocation.locationTypeId,
        'location_detail': newLocation.locationDetail,
        'start_time': userSelectedStartTime.toIso8601String(), // Usar el horario elegido por el usuario
      };
      
      // Agregar end_time solo si está presente
      if (userSelectedEndTime != null) {
        locationData['end_time'] = userSelectedEndTime.toIso8601String();
      }

      // Agregar detalles adicionales si es necesario
      if (newLocation.locationTypeId == LocationTypes.REMOTE_ALTERNATIVE) {
        // Extraer componentes de dirección del locationDetail
        final addressParts = newLocation.locationDetail.split(', ');
        if (addressParts.isNotEmpty) {
          locationData['address'] = addressParts[0];
        }
        
        // Buscar piso y apartamento en los detalles
        for (final part in addressParts) {
          if (part.startsWith('Piso ')) {
            locationData['floor'] = part.substring(5);
          } else if (part.startsWith('Dpto ')) {
            locationData['apartment'] = part.substring(5);
          }
        }
      }

      print('📍 Datos de ubicación a enviar: $locationData');
      print('📍 start_time: ${locationData['start_time']}');
      print('📍 end_time: ${locationData['end_time'] ?? 'No especificado'}');

      // Llamar al servicio para cambiar ubicación durante trabajo
      final response = await CheckInService.changeLocationDuringWork(token, locationData);

      print('📝 Respuesta del servicio: $response');

      if (response != null && response['success'] == true) {
        print('✅ Ubicación cambiada exitosamente');
        print('📊 DEBUGGING - Respuesta completa del servidor: $response');
        
        // El detalle ya viene en newLocation.locationDetail
        final String newLocationDetail = newLocation.locationDetail;
        print('📍 Nueva ubicación: $newLocationDetail');
        print('📍 DEBUGGING - newLocation completo: ${newLocation.toString()}');
        
        // Actualizar estado local
        if (mounted) {
          setState(() {
            print('📍 Actualizando estado local con:');
            print('   - newLocationTypeId: ${newLocation.locationTypeId}');
            print('   - newLocationDetail: $newLocationDetail');
            print('   - ANTES - _selectedLocations: $_selectedLocations');
            print('   - ANTES - _selectedSingleLocation: $_selectedSingleLocation');
            print('   - ANTES - _additionalLocations: ${_additionalLocations.map((l) => l.locationTypeId).toList()}');
            
            // REEMPLAZAR TODAS las ubicaciones con la nueva ubicación
            _selectedLocations = [newLocation.locationTypeId];
            _selectedSingleLocation = newLocation.locationTypeId;
            _additionalLocations.clear(); // ¡IMPORTANTE! Limpiar ubicaciones adicionales
            
            if (newLocation.locationTypeId == LocationTypes.REMOTE_ALTERNATIVE) {
              // Extraer componentes para almacenamiento local
              final addressParts = newLocation.locationDetail.split(', ');
              _otherLocationDetail = addressParts.isNotEmpty ? addressParts[0] : '';
              _otherLocationFloor = '';
              _otherLocationApartment = '';
              
              // Buscar piso y apartamento
              for (final part in addressParts) {
                if (part.startsWith('Piso ')) {
                  _otherLocationFloor = part.substring(5);
                } else if (part.startsWith('Dpto ')) {
                  _otherLocationApartment = part.substring(5);
                }
              }
              
              print('📍 Estado local de domicilio alternativo actualizado:');
              print('   - _otherLocationDetail: $_otherLocationDetail');
              print('   - _otherLocationFloor: $_otherLocationFloor');
              print('   - _otherLocationApartment: $_otherLocationApartment');
            } else {
              _otherLocationDetail = '';
              _otherLocationFloor = '';
              _otherLocationApartment = '';
            }
            
            // Actualizar también el check-in local con la nueva ubicación
            if (_todayCheckIn != null) {
              _todayCheckIn!['location_type'] = newLocation.locationTypeId;
              _todayCheckIn!['location_detail'] = newLocationDetail;
              print('📍 Check-in local actualizado: location_type=${newLocation.locationTypeId}, location_detail=$newLocationDetail');
            }
            
            // Actualizar el completed location detail para cuando termine la jornada
            _completedLocationDetail = newLocationDetail;
            print('📍 _completedLocationDetail actualizado: $_completedLocationDetail');
            
            print('   - DESPUÉS - _selectedLocations: $_selectedLocations');
            print('   - DESPUÉS - _selectedSingleLocation: $_selectedSingleLocation');
            print('   - DESPUÉS - _additionalLocations: ${_additionalLocations.map((l) => l.locationTypeId).toList()}');
            print('   - DESPUÉS - _otherLocationDetail: $_otherLocationDetail');
            print('   - DESPUÉS - _completedLocationDetail: $_completedLocationDetail');
          });
        }

        // Mostrar mensaje de éxito
        if (mounted) {
          final message = response['message']?.toString() ?? 'Ubicación cambiada exitosamente';
          _showSuccessSnackBar(message);
        }

        // Refrescar historial de ubicaciones (pero NO el estado principal para evitar pisar la dirección)
        await _loadLocationHistory();
        
        // TEMPORALMENTE COMENTADO: Esto podría estar sobrescribiendo el cambio con datos viejos
        // await _loadTodayCheckIn();
        
        // Cerrar el diálogo si sigue abierto
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        
        // Si necesitamos refrescar el estado, hacerlo con un pequeño delay para dar tiempo al backend
        // Future.delayed(const Duration(seconds: 2), () async {
        //   await _refreshState();
        // });
      } else {
        final errorMessage = response?['message'] ?? 'Error desconocido al cambiar ubicación';
        print('❌ Error al cambiar ubicación: $errorMessage');
        if (mounted) {
          _showErrorSnackBar(errorMessage);
        }
      }
    } catch (e) {
      print('❌ Excepción al cambiar ubicación: $e');
      if (mounted) {
        _showErrorSnackBar('Error al cambiar ubicación: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Maneja el logout del usuario
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  /// Muestra un SnackBar de éxito
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color.fromARGB(255, 89, 167, 92),
      ),
    );
  }

  /// Muestra un SnackBar de error
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Re-verifica el estado actual desde el backend (sin pantalla de carga)
  Future<void> _refreshState() async {
    print('_refreshState: Verificando estado desde backend...');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final checkIn = await CheckInService.getTodayCheckIn(token);
        print('_refreshState: Resultado del servicio: $checkIn');

        if (checkIn != null) {
          print('_refreshState: checkout_time: ${checkIn['checkout_time']}');
          print('_refreshState: check_out_time: ${checkIn['check_out_time']}');
          print(
            '_refreshState: checkout_status: ${checkIn['checkout_status']}',
          );
          print(
            '_refreshState: Estado actual antes del cambio - _isWorking: $_isWorking, _dayCompleted: $_dayCompleted',
          );

          // Si la jornada está completada, obtener la ubicación real del historial
          String actualLocationDetail = checkIn['location_detail'];
          final checkoutTime = checkIn['checkout_time'] ?? checkIn['check_out_time'];
          final checkoutStatus = checkIn['checkout_status'];
          
          // Si la jornada está completada, intentar obtener la ubicación de finalización del historial
          if (checkoutTime != null && checkoutStatus == 'completed') {
            print('_refreshState: Jornada completada - obteniendo ubicación real del historial...');
            try {
              final locationHistory = await CheckInService.getSessionLocationHistory(token);
              if (locationHistory.isNotEmpty) {
                // Buscar la ubicación más reciente (última del día)
                final lastLocation = locationHistory.last;
                actualLocationDetail = lastLocation['location_detail'] ?? actualLocationDetail;
                print('_refreshState: Ubicación de fin de jornada desde historial: $actualLocationDetail');
              }
            } catch (e) {
              print('_refreshState: Error obteniendo historial para ubicación final: $e');
              // Continuar con la ubicación del check-in si hay error
            }
          }

          if (mounted) {
            setState(() {
              _todayCheckIn = checkIn;

              // Aplicar la misma lógica que _loadTodayCheckIn pero sin pantalla de carga
              if (checkoutTime == null) {
                print(
                  '_refreshState: Usuario sigue trabajando (sin checkout_time)',
                );
                _selectedLocations = [checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED];
                _selectedSingleLocation = _selectedLocations.first;
                _completedLocationDetail = actualLocationDetail; // Usar ubicación del historial si está disponible
                _isWorking = true;
                _dayCompleted = false;
                // No resetear _workStartTime si ya está trabajando
              } else if (checkoutTime != null && checkoutStatus == 'completed') {
                print(
                  '_refreshState: Jornada completada (checkout_time + status completed)',
                );
                print(
                  '_refreshState: checkoutTime: $checkoutTime, checkoutStatus: $checkoutStatus',
                );
                print(
                  '_refreshState: Ubicación final determinada: $actualLocationDetail',
                );
                _selectedLocations = [checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED];
                _selectedSingleLocation = _selectedLocations.first;
                _completedLocationDetail = actualLocationDetail; // Usar ubicación real del historial
                _isWorking = false;
                _dayCompleted = true;
                _workStartTime = null;
                _workDuration = Duration.zero;
                _workTimer?.cancel();
              } else if (checkoutTime != null) {
                print(
                  '_refreshState: Checkout con tiempo pero status no completed',
                );
                print('_refreshState: checkoutTime: $checkoutTime');
                print('_refreshState: checkoutStatus: $checkoutStatus');
                // Si hay checkout_time, asumir que está completado independientemente del status
                _selectedLocations = [checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED];
                _selectedSingleLocation = _selectedLocations.first;
                _completedLocationDetail = actualLocationDetail; // Usar ubicación real del historial
                _isWorking = false;
                _dayCompleted = true;
                _workStartTime = null;
                _workDuration = Duration.zero;
                _workTimer?.cancel();
              } else {
                print('_refreshState: Caso inesperado');
                _isWorking = false;
                _dayCompleted = false;
                _workStartTime = null;
                _workDuration = Duration.zero;
              }
            });
          }

          print(
            '_refreshState: Estado final - _isWorking: $_isWorking, _dayCompleted: $_dayCompleted',
          );
        }
      }
    } catch (e) {
      print('_refreshState: Error al verificar estado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar pantalla de carga mientras se inicializa
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        centerTitle: true,
          title: const AppLogo(
            width: 35,
            height: 35,
            imagePath: 'assets/images/logo-navbar.png',
            showSubtitle: false,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFFE67D21)),
              onPressed: _showMenu,
            ),
          ],
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFFE67D21)),
              SizedBox(height: 16),
              Text(
                'Cargando estado de asistencia...',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // Pantalla principal
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        centerTitle: true,
        title: const AppLogo.navbar(),
        actions: [
          // Indicador de conexión
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_done, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  'Conectado',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFE67D21)),
            onPressed: _showMenu,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Pull to refresh - Refrescando estado...
          await _refreshState();
        },
        color: const Color(0xFFE67D21),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Panel principal de estado de trabajo
              WorkStatusPanel(
                isWorking: _isWorking,
                workStartTime: _workStartTime,
                workDuration: _workDuration,
                totalDayTime: _getTodayWorkTime(),
                selectedLocations: _selectedLocations,
                locations: _locations,
                isProcessing: _isProcessing,
                dayCompleted: _dayCompleted,
                onStartWork: _startWork,
                onStopWork: _stopWork,
                onLocationChanged: _onLocationChanged,
                selectionMode: _selectionMode,
                onSelectionModeChanged: _onSelectionModeChanged,
                onSingleLocationChanged: _onSingleLocationChanged,
                selectedSingleLocation: _selectedSingleLocation,
                locationSchedule: _locationSchedule,
                onScheduleChanged: _onScheduleChanged,
                otherLocationDetail: _otherLocationDetail,
                onOtherLocationChanged: _onOtherLocationChanged,
                otherLocationFloor: _otherLocationFloor,
                otherLocationApartment: _otherLocationApartment,
                onOtherLocationFloorChanged: _onOtherLocationFloorChanged,
                onOtherLocationApartmentChanged: _onOtherLocationApartmentChanged,
                completedLocationDetail: _completedLocationDetail,
                locationHistory: _locationHistory,
                // Nuevos parámetros para la funcionalidad mejorada
                catalogLocations: _catalogLocations,
                userDeclaredAddress: _userDeclaredAddress,
                additionalLocations: _additionalLocations,
                onAddAdditionalLocation: _onAddAdditionalLocation,
                onRemoveAdditionalLocation: _onRemoveAdditionalLocation,
                onUpdateAdditionalLocation: _onUpdateAdditionalLocation,
              ),

              // Aquí se podrían agregar más organismos como:
              // - Resumen de productividad
              // - Notificaciones recientes
              // - Accesos rápidos
              // etc.
            ],
          ),
        ),
      ),
      // Floating Action Button para cambiar ubicación durante trabajo
      // Solo se muestra cuando está trabajando, no está procesando Y la jornada no está completada
      floatingActionButton: _isWorking && !_isProcessing && !_dayCompleted
          ? FloatingActionButton.extended(
              onPressed: _showLocationChangeDialog,
              backgroundColor: const Color(0xFFE67D21),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.location_on),
              label: const Text('Cambiar Ubicación'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
