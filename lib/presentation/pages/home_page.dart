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
  List<int> _selectedLocations = [
    LocationTypes.REMOTE_DECLARED,
  ]; // Lista de ubicaciones seleccionadas
  final Map<int, String> _locations = LocationTypes.names;

  // Nuevas variables para el manejo de selección única vs múltiple
  String _selectionMode = 'single'; // 'single' o 'multiple'
  int? _selectedSingleLocation =
      LocationTypes.REMOTE_DECLARED; // Ubicación cuando está en modo único

  // Mapa para horarios de ubicaciones múltiples: {locationId: TimeOfDay}
  Map<int, TimeOfDay> _locationSchedule = {};

  // Horarios habituales del usuario
  TimeOfDay? _userStartTime;
  TimeOfDay? _userEndTime;

  // Horarios habituales ORIGINALES del backend (para validación)
  TimeOfDay? _originalStartTime;
  TimeOfDay? _originalEndTime;

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

  /// Maneja los cambios en el horario habitual de inicio
  void _onUserStartTimeChanged(TimeOfDay newTime) {
    if (!mounted) return;
    setState(() {
      _userStartTime = newTime;
    });
  }

  /// Maneja los cambios en el horario habitual de fin
  void _onUserEndTimeChanged(TimeOfDay newTime) {
    if (!mounted) return;
    setState(() {
      _userEndTime = newTime;
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

  /// Obtiene los horarios habituales del usuario desde sus datos
  Future<Map<String, TimeOfDay?>> _getUserHabitalSchedule() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final userData = await UserService.getCurrentUser(token);

        TimeOfDay? startTime;
        TimeOfDay? endTime;

        // Extraer checkin_start_time
        if (userData?['checkin_start_time'] != null &&
            userData!['checkin_start_time'].toString().isNotEmpty) {
          try {
            final timeStr = userData['checkin_start_time'].toString();
            final timeParts = timeStr.split(':');
            if (timeParts.length >= 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              startTime = TimeOfDay(hour: hour, minute: minute);
            }
          } catch (e) {
            // Error parseando checkin_start_time
          }
        }

        // Extraer checkout_end_time
        if (userData?['checkout_end_time'] != null &&
            userData!['checkout_end_time'].toString().isNotEmpty) {
          try {
            final timeStr = userData['checkout_end_time'].toString();
            final timeParts = timeStr.split(':');
            if (timeParts.length >= 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              endTime = TimeOfDay(hour: hour, minute: minute);
            }
          } catch (e) {
            // Error parseando checkout_end_time
          }
        }

        return {'startTime': startTime, 'endTime': endTime};
      }
    } catch (e) {
      // Error obteniendo horarios habituales del usuario
    }

    // Valores por defecto
    return {
      'startTime': const TimeOfDay(hour: 9, minute: 0),
      'endTime': const TimeOfDay(hour: 18, minute: 0),
    };
  }

  /// Carga y almacena los horarios habituales del usuario
  Future<void> _loadUserSchedule() async {
    final schedule = await _getUserHabitalSchedule();

    setState(() {
      _userStartTime = schedule['startTime'];
      _userEndTime = schedule['endTime'];

      // Cargar también los horarios originales para validación
      _originalStartTime = schedule['startTime'];
      _originalEndTime = schedule['endTime'];
    });

    // Horarios habituales establecidos
  }

  /// Convierte un TimeOfDay a formato UTC string para el backend
  String _timeOfDayToUTC(TimeOfDay time, {DateTime? date}) {
    final targetDate = date ?? DateTime.now();
    final localDateTime = DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      time.hour,
      time.minute,
    );

    final utcDateTime = localDateTime.toUtc();
    return utcDateTime.toIso8601String();
  }

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
      final catalogLocations = await CatalogService.getLocations(widget.token);

      if (mounted) {
        setState(() {
          _catalogLocations = catalogLocations;
        });
      }
    } catch (e) {
      // No mostrar error al usuario, las ubicaciones del catálogo son opcionales
      // pero seguir funcionando con las ubicaciones básicas
    }
  }

  /// Carga los datos del usuario para obtener el domicilio declarado
  Future<void> _loadUserData() async {
    try {
      final userData = await UserService.getCurrentUser(widget.token);

      if (userData != null && mounted) {
        // Obtener la dirección directamente del objeto location del usuario
        if (userData['location'] != null) {
          final location = userData['location'] as Map<String, dynamic>;
          final formattedAddress = UserService.formatDeclaredAddress(location);

          setState(() {
            _userDeclaredAddress = formattedAddress.isNotEmpty
                ? formattedAddress
                : null;
          });
        } else {
          setState(() {
            _userDeclaredAddress = null;
          });
        }

        // Cargar horarios habituales del usuario
        await _loadUserSchedule();
      }
    } catch (e) {
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
          final timeA =
              DateTime.tryParse(a['timestamp'] ?? '') ?? DateTime.now();
          final timeB =
              DateTime.tryParse(b['timestamp'] ?? '') ?? DateTime.now();
          return timeA.compareTo(timeB);
        });

        if (mounted) {
          setState(() {
            // Combinar ubicaciones planificadas con historial real
            _locationHistory = [...plannedLocations, ..._locationHistory];
          });
        }
      }
    } catch (e) {}
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
          final checkoutTime =
              checkIn['checkout_time'] ?? checkIn['check_out_time'];

          // Para jornadas completadas, obtener la ubicación real del historial
          String actualLocationDetail = checkIn['location_detail'];
          if (checkoutTime != null) {
            try {
              final locationHistory =
                  await CheckInService.getSessionLocationHistory(token);
              if (locationHistory.isNotEmpty) {
                // Buscar la ubicación más reciente (última del día)
                final lastLocation = locationHistory.last;
                actualLocationDetail =
                    lastLocation['location_detail'] ?? actualLocationDetail;
              }
            } catch (e) {
              // Continuar con la ubicación del check-in si hay error
            }
          }

          if (mounted) {
            setState(() {
              _todayCheckIn = checkIn;

              // Normalizar los nombres de los campos
              final checkoutTime =
                  checkIn['checkout_time'] ?? checkIn['check_out_time'];
              final checkoutStatus = checkIn['checkout_status'];

              // Si ya hay check-in pero no checkout, está trabajando
              if (checkoutTime == null) {
                _isWorking = true;
                _dayCompleted = false;

                // Intentar obtener la hora de inicio desde diferentes campos
                try {
                  String? timeString;

                  // Prioridad 1: check_in_time (campo normalizado)
                  if (checkIn['check_in_time'] != null &&
                      checkIn['check_in_time'].toString().isNotEmpty) {
                    timeString = checkIn['check_in_time'].toString();

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

                  if (_workStartTime == null) {
                    throw Exception('No se pudo obtener la hora de inicio');
                  }
                } catch (e) {
                  // Si no se puede parsear, usar la hora actual como fallback
                  _workStartTime = DateTime.now();
                }

                _selectedLocations = [
                  checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED,
                ];
                _selectedSingleLocation = _selectedLocations.first;
                _completedLocationDetail = actualLocationDetail;

                // Iniciar timer para mostrar duración actual
                _startWorkTimer();
              } else if (checkoutTime != null &&
                  checkoutStatus == 'completed') {
                // La jornada ya está completada hoy
                _selectedLocations = [
                  checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED,
                ];
                _selectedSingleLocation = _selectedLocations.first;
                _completedLocationDetail = actualLocationDetail;
                _isWorking = false;
                _dayCompleted = true;
                _workStartTime = null;
                // No resetear _workDuration aquí, _getTodayWorkTime() calculará el tiempo real
              } else if (checkoutTime != null) {
                // Hay checkout_time pero el status no es "completed" - podría ser que el checkout falló

                // Si hay checkout_time pero no status completed, asumir que está completado
                // (el backend podría no estar actualizando el status correctamente)
                _selectedLocations = [
                  checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED,
                ];
                _selectedSingleLocation = _selectedLocations.first;
                _completedLocationDetail = actualLocationDetail;
                _isWorking = false;
                _dayCompleted =
                    true; // Cambio: considerar completado si hay checkout_time
                _workStartTime = null;
                // No resetear _workDuration aquí, _getTodayWorkTime() calculará el tiempo real
              } else {
                // Caso por defecto - no debería llegar aquí
                _isWorking = false;
                _dayCompleted = false;
                _workStartTime = null;
                _workDuration = Duration.zero;
              }
            });
          }
        } else {
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
        // No hay token disponible
      }
    } catch (e) {
      // Error al cargar check-in de hoy
      _showErrorSnackBar('Error al cargar estado de trabajo');
    } finally {
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
        _workDuration = DateTime.now().toUtc().difference(
          _workStartTime!.toUtc(),
        );
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

          // Reconstruir _selectedLocations a partir del historial
          _reconstructSelectedLocationsFromHistory();
        }
      }
    } catch (e) {
      // Error al cargar historial de ubicaciones
      // No mostramos error al usuario ya que esta es información adicional
    }
  }

  /// Reconstruye _selectedLocations a partir del historial de ubicaciones
  void _reconstructSelectedLocationsFromHistory() {
    if (_locationHistory.isEmpty) return;

    final List<int> reconstructedLocationIds = [];
    final List<WorkLocation> reconstructedAdditionalLocations = [];

    // Crear un mapa para deduplicar por location_type
    final Map<int, Map<String, dynamic>> uniqueLocations = {};

    // Ordenar por start_time para procesar cronológicamente
    final sortedHistory = List<Map<String, dynamic>>.from(_locationHistory);
    sortedHistory.sort((a, b) {
      final timeA = DateTime.tryParse(a['start_time'] ?? '') ?? DateTime.now();
      final timeB = DateTime.tryParse(b['start_time'] ?? '') ?? DateTime.now();
      return timeA.compareTo(timeB);
    });

    // Deduplicar por location_type, manteniendo la entrada más reciente de cada tipo
    for (final entry in sortedHistory) {
      final locationType = entry['location_type'] as int;
      uniqueLocations[locationType] = entry;
    }

    // Convertir a lista ordenada cronológicamente
    final sortedUniqueEntries = uniqueLocations.values.toList();
    sortedUniqueEntries.sort((a, b) {
      final timeA = DateTime.tryParse(a['start_time'] ?? '') ?? DateTime.now();
      final timeB = DateTime.tryParse(b['start_time'] ?? '') ?? DateTime.now();
      return timeA.compareTo(timeB);
    });

    // Procesar cada ubicación única
    for (int i = 0; i < sortedUniqueEntries.length; i++) {
      final entry = sortedUniqueEntries[i];
      final locationType = entry['location_type'] as int;
      final locationDetail = entry['location_detail'] as String;
      final startTime = entry['start_time'] as String;
      final endTime = entry['end_time'] as String?;

      // Agregar a la lista de IDs seleccionados
      if (!reconstructedLocationIds.contains(locationType)) {
        reconstructedLocationIds.add(locationType);
      }

      // Convertir timestamps UTC a hora local para mostrar en la UI
      TimeOfDay? startTimeOfDay = _parseTimeFromISOString(
        startTime,
        convertToLocal: true,
      );
      TimeOfDay? endTimeOfDay;

      if (endTime != null) {
        endTimeOfDay = _parseTimeFromISOString(endTime, convertToLocal: true);
      }

      if (startTimeOfDay != null) {
        // Solo agregar a _additionalLocations si NO es la primera ubicación
        // La primera ubicación se maneja a través de _selectedSingleLocation
        if (i > 0) {
          final workLocation = WorkLocation(
            locationTypeId: locationType,
            locationDetail: locationDetail,
            startTime: startTimeOfDay,
            endTime: endTimeOfDay,
          );

          reconstructedAdditionalLocations.add(workLocation);
        } else {}
      }
    }

    // Actualizar las listas reconstruidas
    if (mounted) {
      setState(() {
        _selectedLocations = reconstructedLocationIds;
        _additionalLocations = reconstructedAdditionalLocations;

        // Establecer la ubicación principal como la primera
        if (reconstructedLocationIds.isNotEmpty) {
          _selectedSingleLocation = reconstructedLocationIds.first;
        }
      });
    }
  }

  /// Parsea una cadena ISO de tiempo y extrae solo la hora y minutos
  /// Si convertToLocal es true, convierte de UTC a hora local
  TimeOfDay? _parseTimeFromISOString(
    String isoString, {
    bool convertToLocal = false,
  }) {
    try {
      final dateTime = DateTime.parse(isoString);

      // Si se solicita conversión a hora local, convertir desde UTC
      final targetDateTime = convertToLocal ? dateTime.toLocal() : dateTime;

      return TimeOfDay(
        hour: targetDateTime.hour,
        minute: targetDateTime.minute,
      );
    } catch (e) {
      return null;
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
    } catch (e) {}
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
          final userName =
              '${userData['name'] ?? ''} ${userData['surname'] ?? ''}'.trim();

          // Programar recordatorios cada 15 minutos
          final notificationService = NotificationService();
          await notificationService.scheduleMissedCheckinReminders(
            checkinTime: checkinTime,
            userName: userName.isEmpty ? 'Usuario' : userName,
            maxReminders: 12, // 3 horas de recordatorios
          );
        }
      }
    } catch (e) {}
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
              final checkinDateTime = DateTime(
                now.year,
                now.month,
                now.day,
                hour,
                minute,
              );

              // Si ya pasó la hora de check-in y no está trabajando, programar recordatorios
              if (now.isAfter(checkinDateTime)) {
                await _scheduleMissedCheckinReminders();
              }
            }
          }
        }
      }
    } catch (e) {}
  }

  /// Construye el mensaje de ubicaciones para mostrar en el diálogo de confirmación
  String _buildLocationMessage({
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) {
    List<String> locationParts = [];

    // Agregar la ubicación principal con horario
    String primaryLocationName = _getLocationName(_selectedSingleLocation!);
    String mainTimeRange = '${startTime.format(context)} - ${endTime.format(context)}';
    locationParts.add('$primaryLocationName ($mainTimeRange)');

    // Agregar ubicaciones adicionales con horarios
    for (final additionalLocation in _additionalLocations) {
      String additionalLocationName = _getLocationName(
        additionalLocation.locationTypeId,
      );
      String timeRange = '${additionalLocation.startTime.format(context)}';
      if (additionalLocation.endTime != null) {
        timeRange += ' - ${additionalLocation.endTime!.format(context)}';
      }
      locationParts.add('$additionalLocationName ($timeRange)');
    }

    if (locationParts.length == 1) {
      return locationParts.first;
    } else {
      // Solo mostrar la lista de ubicaciones, sin prefijos
      return locationParts.map((part) => '• $part').join('\n');
    }
  }

  /// Obtiene el nombre de una ubicación por su ID
  String _getLocationName(int locationId) {
    // Verificar tipos de ubicación especiales primero (1-4)
    switch (locationId) {
      case LocationTypes.REMOTE_DECLARED:
        return 'Domicilio Declarado';
      case LocationTypes.REMOTE_ALTERNATIVE:
        return 'Domicilio Alternativo';
      case LocationTypes.CLIENT:
        return 'Cliente';
      case LocationTypes.OFFICE:
        return 'Oficina';
      case 101:
        return 'Oficina ABSTI';
      case 102:
        return 'Oficina de Swiss Medical Group';
      case 103:
        return 'Oficina Allianz';
      case 104:
        return 'Oficina Galicia';
    }

    // Si es un ID de la UI del catálogo (1001, 1002, 1003, 1004), convertirlo al ID real del catálogo
    int realCatalogId = locationId;
    if (locationId >= 1001 && locationId <= 1004) {
      realCatalogId = locationId - 1000; // 1001 -> 1, 1002 -> 2, etc.
    }

    // Buscar en el catálogo con el ID real

    try {
      final catalogLocation = _catalogLocations.firstWhere(
        (cat) => cat.id == realCatalogId,
      );
      return catalogLocation.name;
    } catch (e) {}

    // Si no se encuentra en el catálogo, verificar IDs de backend mapeados (101, 102, 103, 104)
    switch (locationId) {
      case 101:
        return 'Oficina ABSTI';
      case 102:
        return 'Oficina de Swiss Medical Group';
      case 103:
        return 'Oficina Galicia';
      case 104:
        return 'Oficina Allianz';
    }

    // Fallback final

    return 'Ubicación Desconocida ($locationId)';
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

    // Obtener los horarios habituales del usuario (ya cargados)
    final baseStartTime = _userStartTime ?? const TimeOfDay(hour: 9, minute: 0);
    final baseEndTime = _userEndTime ?? const TimeOfDay(hour: 18, minute: 0);

    // Aplicar lógica inteligente de horarios (igual que WorkStatusPanel._getEffectiveStartTime)
    final currentTime = TimeOfDay.now();
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final habitualStartMinutes = baseStartTime.hour * 60 + baseStartTime.minute;

    // Determinar horario de inicio efectivo
    final defaultStartTime = currentMinutes > habitualStartMinutes
        ? currentTime
        : baseStartTime;
    final defaultEndTime = baseEndTime; // El horario de fin se mantiene igual

    // Validar que el horario de fin sea posterior al de inicio
    final startMinutes = defaultStartTime.hour * 60 + defaultStartTime.minute;
    final endMinutes = defaultEndTime.hour * 60 + defaultEndTime.minute;

    if (endMinutes <= startMinutes) {
      _showErrorSnackBar(
        'La hora de fin debe ser posterior a la hora de inicio',
      );
      return;
    }

    // Horarios habituales originales para comparación
    final habitualStartTime =
        _originalStartTime ??
        _userStartTime ??
        const TimeOfDay(hour: 9, minute: 0);
    final habitualEndTime =
        _originalEndTime ??
        _userEndTime ??
        const TimeOfDay(hour: 18, minute: 0);

    // Construir mensaje para el diálogo de horarios
    String locationMessage = _buildLocationMessage(
      startTime: defaultStartTime,
      endTime: defaultEndTime,
    );

    // Mostrar diálogo de selección de horarios
    final selectedSchedule = await ScheduleSelectionDialog.show(
      context: context,
      defaultStartTime: defaultStartTime,
      defaultEndTime: defaultEndTime,
      habitualStartTime: habitualStartTime,
      habitualEndTime: habitualEndTime,
      locationName: locationMessage,
    );

    if (selectedSchedule != null) {
      final startTime = selectedSchedule['startTime']!;

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

          // Obtener la fecha y hora actuales
          final now = DateTime.now();

          // Usar el horario seleccionado por el usuario (convertido a UTC)
          final startTimeUtc = _timeOfDayToUTC(startTime, date: now);
          final time = CheckInService.toRFC3339(
            now,
          ); // Hora actual para el check-in

          // Debug del formato de fecha y hora

          // Determinar si llega tarde basado en el horario seleccionado
          final currentTime = TimeOfDay.fromDateTime(now);
          final startMinutes = startTime.hour * 60 + startTime.minute;
          final currentMinutes = currentTime.hour * 60 + currentTime.minute;
          final isLate = currentMinutes > startMinutes;

          // Crear los datos de ubicaciones para enviar al backend
          List<Map<String, dynamic>> locationsData = [];

          // 1. Agregar la ubicación principal seleccionada
          // Convertir el ID de UI al location_type que espera el backend
          final primaryLocationIdUI = _selectedSingleLocation!;
          final primaryLocationId = _convertUILocationIdToBackendType(
            primaryLocationIdUI,
          );
          String primaryLocationDetail;

          // Determinar el location_detail basado en el tipo de ubicación

          if (primaryLocationId == LocationTypes.REMOTE_DECLARED &&
              _userDeclaredAddress != null) {
            // Usar domicilio declarado del usuario
            primaryLocationDetail = _userDeclaredAddress!;
          } else if (primaryLocationId == LocationTypes.REMOTE_DECLARED &&
              _userDeclaredAddress == null) {
            // Fallback si no hay domicilio declarado
            primaryLocationDetail = 'Domicilio Declarado';
          } else if (primaryLocationId == LocationTypes.REMOTE_ALTERNATIVE &&
              _otherLocationDetail != null) {
            // Usar domicilio alternativo con campos adicionales
            primaryLocationDetail = _otherLocationDetail!;
            if (_otherLocationFloor != null &&
                _otherLocationFloor!.isNotEmpty) {
              primaryLocationDetail += ', Piso $_otherLocationFloor';
            }
            if (_otherLocationApartment != null &&
                _otherLocationApartment!.isNotEmpty) {
              primaryLocationDetail += ', Dpto $_otherLocationApartment';
            }
          } else if (primaryLocationId >= 101 && primaryLocationId <= 104) {
            // Es una ubicación de catálogo - buscar el catálogo con id = primaryLocationId - 100
            final catalogId = primaryLocationId - 100;
            final catalogLocation = _catalogLocations.firstWhere(
              (cat) => cat.id == catalogId,
              orElse: () => CatalogLocation(
                id: catalogId,
                name: 'Ubicación del catálogo',
                address: 'Desconocido',
                isActive: true,
              ),
            );
            primaryLocationDetail =
                catalogLocation.address ?? catalogLocation.name;
          } else if (_catalogLocations.any(
            (cat) => cat.id == primaryLocationId,
          )) {
            // Compatibilidad: si el id coincide directo
            final catalogLocation = _catalogLocations.firstWhere(
              (cat) => cat.id == primaryLocationId,
              orElse: () => CatalogLocation(
                id: primaryLocationId,
                name: 'Ubicación del catálogo',
                isActive: true,
              ),
            );
            primaryLocationDetail =
                catalogLocation.address ?? catalogLocation.name;
          } else {
            // Ubicaciones estándar
            primaryLocationDetail =
                _locations[primaryLocationId] ?? 'Desconocido';
          }

          // Agregar la ubicación principal

          // Calcular end_time para la ubicación principal
          String primaryEndTimeUtc;
          if (_additionalLocations.isNotEmpty) {
            // Si hay ubicaciones adicionales, el end_time es el start_time de la primera ubicación adicional
            final firstAdditionalLocation = _additionalLocations.first;
            final firstAdditionalStartTime = DateTime(
              now.year,
              now.month,
              now.day,
              firstAdditionalLocation.startTime.hour,
              firstAdditionalLocation.startTime.minute,
            ).toUtc();
            primaryEndTimeUtc = firstAdditionalStartTime.toIso8601String();
          } else {
            // Si no hay ubicaciones adicionales, usar el final del día laboral (18:00)
            final endOfWorkDay = DateTime(
              now.year,
              now.month,
              now.day,
              18, // 18:00 como final del día laboral por defecto
              0,
            ).toUtc();
            primaryEndTimeUtc = endOfWorkDay.toIso8601String();
          }

          locationsData.add({
            'location_type': primaryLocationId,
            'location_detail': primaryLocationDetail,
            'start_time': startTimeUtc, // Horario seleccionado en formato UTC
            'end_time': primaryEndTimeUtc, // End time requerido por el servidor
          });

          // 2. Agregar ubicaciones adicionales con sus horarios
          for (final additionalLocation in _additionalLocations) {
            locationsData.add(additionalLocation.toJson(baseDate: now));
          }

          // Los datos para el check-in en el nuevo formato
          final checkInData = {
            'time': time,
            'locations':
                locationsData, // Lista con location_type, location_detail y start_time
            'notes': '',
            'user_id': userId,
          };

          // Si llega tarde, agregar la razón
          if (isLate) {
            checkInData['late_reason'] = 'Llegada tardía'; // Razón por defecto
          }

          // Debug: Mostrar el payload completo

          // Debug: Mostrar todos los datos que se van a enviar

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
    if (_workStartTime == null || _isProcessing) return;

    final currentTime = DateTime.now();
    final sessionDuration = currentTime.difference(_workStartTime!);

    // Construir mensaje para el diálogo - mostrar solo la ubicación actual (última ubicación activa)
    String locationMessage;

    // Intentar obtener la ubicación actual desde el historial de ubicaciones
    if (_locationHistory.isNotEmpty) {
      // Buscar la última entrada que no tenga end_time (ubicación actual)
      Map<String, dynamic>? currentLocation;
      for (int i = _locationHistory.length - 1; i >= 0; i--) {
        final location = _locationHistory[i];
        if (location['end_time'] == null ||
            location['end_time'].toString().isEmpty) {
          currentLocation = location;
          break;
        }
      }

      if (currentLocation != null) {
        locationMessage =
            currentLocation['location_detail'] as String? ?? 'Ubicación actual';
      } else if (_locationHistory.isNotEmpty) {
        // Si todas tienen end_time, usar la última
        final lastLocation = _locationHistory.last;
        locationMessage =
            lastLocation['location_detail'] as String? ?? 'Última ubicación';
      } else {
        locationMessage = 'Ubicación no especificada';
      }
    } else {
      // Fallback: usar la ubicación principal seleccionada
      if (_selectedSingleLocation != null) {
        locationMessage = _getLocationName(_selectedSingleLocation!);
      } else if (_selectedLocations.isNotEmpty) {
        final selectedId = _selectedLocations.first;
        locationMessage = _locations[selectedId] ?? 'Ubicación desconocida';
      } else {
        locationMessage = 'Ubicación no especificada';
      }
    }

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
          // Obtener el check-in time para validar que el checkout sea posterior
          final checkInTime =
              _todayCheckIn!['time'] ?? _todayCheckIn!['check_in_time'];
          DateTime? checkInDateTime;
          if (checkInTime != null) {
            try {
              checkInDateTime = DateTime.parse(checkInTime);
            } catch (e) {}
          }

          // Asegurar que checkout time sea posterior a check-in time con margen de seguridad
          DateTime checkoutTime = currentTime;
          if (checkInDateTime != null) {
            // Asegurar que checkout sea al menos 30 segundos después del check-in
            final minCheckoutTime = checkInDateTime.add(Duration(seconds: 30));
            if (checkoutTime.isBefore(minCheckoutTime)) {
              checkoutTime = minCheckoutTime;
            }
          }

          // Debugging detallado de timestamps
          if (checkInDateTime != null) {
            // timeDifference removed as unused
          }

          // Body correcto para el endpoint /api/checkins/checkout - SOLO los campos que espera el backend
          final checkOutData = {
            'checkout_time': CheckInService.toRFC3339(
              checkoutTime,
            ), // Hora de checkout en formato RFC3339
            'status': 'completed', // Estado del checkout
          };

          await CheckInService.checkOut(token, checkOutData);

          if (mounted) {
            _workTimer?.cancel();
            _showSuccessSnackBar(
              'Jornada terminada exitosamente. Actualizando datos...',
            );

            // NO desactivar _isProcessing aquí - mantenerlo activo para mostrar loading
            // _isProcessing ya está en true desde el inicio de _stopWork

            // Hacer múltiples intentos de refresh para asegurar datos correctos
            for (int attempt = 1; attempt <= 3; attempt++) {
              await _refreshState();

              // Verificar si ya tenemos un location_detail válido
              if (_completedLocationDetail != null &&
                  _completedLocationDetail!.isNotEmpty &&
                  !_completedLocationDetail!.toLowerCase().contains(
                    'desconocida',
                  )) {
                break;
              } else {
                // Quitar delay para evitar problemas de timestamp
              }
            }

            // Si aún no tenemos un location_detail válido, forzar el uso del catálogo
            if (_completedLocationDetail == null ||
                _completedLocationDetail!.isEmpty ||
                _completedLocationDetail!.toLowerCase().contains(
                  'desconocida',
                )) {
              final currentLocationTypeId = _selectedSingleLocation != null
                  ? _convertUILocationIdToBackendType(_selectedSingleLocation!)
                  : null;

              if (currentLocationTypeId != null) {
                _completedLocationDetail = _getLocationName(
                  currentLocationTypeId,
                );
              }
            }

            // Forzar actualización de UI inmediata después de obtener los datos del backend
            if (mounted) {
              setState(() {
                _isProcessing = false; // Desactivar loading
                // Esto forzará un rebuild completo del widget con los datos actualizados
              });
            }
          }
        } else {}
      } catch (e) {
        // Si hay error, revertir estado y re-verificar desde el backend
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }

        // Re-cargar estado desde el backend para asegurar consistencia
        // Agregar delay para permitir que el backend procese el checkout

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
            if (!checkinTime.toString().endsWith('Z') &&
                !checkinTime.toString().contains('+')) {
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
              if (!checkoutTime.toString().endsWith('Z') &&
                  !checkoutTime.toString().contains('+')) {
                endTime = DateTime.parse(checkoutTime.toString() + 'Z');
              }
            } else {
              endTime = DateTime.parse(
                '${_todayCheckIn!['date']} $checkoutTime',
              );
            }

            // Calcular diferencia en UTC para evitar problemas de zona horaria
            final sessionDuration = endTime.toUtc().difference(
              startTime.toUtc(),
            );
            totalTime += sessionDuration;
          } else if (_isWorking && _workStartTime != null) {
            // Si está trabajando actualmente, agregar tiempo actual
            totalTime += _workDuration;
          }
        }
      } catch (e) {
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
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => LocationChangeDialog(
        catalogLocations:
            _catalogLocations, // Lista de ubicaciones del catálogo
        userDeclaredAddress:
            _userDeclaredAddress, // Dirección del domicilio declarado
        currentLocations:
            _selectedLocations, // Ubicaciones actualmente seleccionadas
        onLocationSelected:
            _changeLocationDuringWork, // Callback con WorkLocation
      ),
    );
  }

  /// Cambia la ubicación durante la jornada laboral
  Future<void> _changeLocationDuringWork(WorkLocation newLocation) async {
    // Validar que el usuario esté trabajando
    if (!_isWorking) {
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
        'start_time': userSelectedStartTime
            .toIso8601String(), // Usar el horario elegido por el usuario
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

      // Obtener el ID de la ubicación actual para actualizarla
      int? currentLocationId;
      if (_locationHistory.isNotEmpty) {
        // Buscar la ÚLTIMA ubicación actual (la que no tiene end_time)
        // Ordenar por timestamp/start_time en orden descendente y tomar la primera sin end_time
        final locationsWithoutEndTime = _locationHistory
            .where((location) => location['end_time'] == null)
            .toList();

        Map<String, dynamic>? currentLocation;
        if (locationsWithoutEndTime.isNotEmpty) {
          // Ordenar por start_time/timestamp en orden descendente (más reciente primero)
          locationsWithoutEndTime.sort((a, b) {
            final timestampA = a['start_time'] ?? a['timestamp'] ?? '';
            final timestampB = b['start_time'] ?? b['timestamp'] ?? '';
            return timestampB.toString().compareTo(timestampA.toString());
          });

          currentLocation = locationsWithoutEndTime.first; // La más reciente
        } else {
          // Si todas tienen end_time, usar la última del historial
          currentLocation = _locationHistory.last;
        }

        currentLocationId = currentLocation['id'] as int?;
      }

      if (currentLocationId == null) {
        if (mounted) {
          _showErrorSnackBar(
            'Error: No se pudo identificar la ubicación actual',
          );
          setState(() {
            _isProcessing = false;
          });
        }
        return;
      }

      // Llamar al servicio para cambiar ubicación durante trabajo
      final response = await CheckInService.changeLocationDuringWork(
        token,
        currentLocationId,
        locationData,
      );

      if (response != null && response['success'] == true) {
        // El detalle ya viene en newLocation.locationDetail
        final String newLocationDetail = newLocation.locationDetail;

        // Actualizar estado local
        if (mounted) {
          setState(() {
            // REEMPLAZAR TODAS las ubicaciones con la nueva ubicación
            _selectedLocations = [newLocation.locationTypeId];
            _selectedSingleLocation = newLocation.locationTypeId;
            _additionalLocations
                .clear(); // ¡IMPORTANTE! Limpiar ubicaciones adicionales

            if (newLocation.locationTypeId ==
                LocationTypes.REMOTE_ALTERNATIVE) {
              // Extraer componentes para almacenamiento local
              final addressParts = newLocation.locationDetail.split(', ');
              _otherLocationDetail = addressParts.isNotEmpty
                  ? addressParts[0]
                  : '';
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
            } else {
              _otherLocationDetail = '';
              _otherLocationFloor = '';
              _otherLocationApartment = '';
            }

            // Actualizar también el check-in local con la nueva ubicación
            if (_todayCheckIn != null) {
              _todayCheckIn!['location_type'] = newLocation.locationTypeId;
              _todayCheckIn!['location_detail'] = newLocationDetail;
            }

            // Actualizar el completed location detail para cuando termine la jornada
            _completedLocationDetail = newLocationDetail;
          });
        }

        // Mostrar mensaje de éxito
        if (mounted) {
          final message =
              response['message']?.toString() ??
              'Ubicación cambiada exitosamente';
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
        final errorMessage =
            response?['message'] ?? 'Error desconocido al cambiar ubicación';
        if (mounted) {
          _showErrorSnackBar(errorMessage);
        }
      }
    } catch (e) {
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

  /// Convierte el ID de la UI al location_type que espera el backend
  int _convertUILocationIdToBackendType(int uiId) {
    // Para domicilio declarado y alternativo (1, 2), usar directamente
    if (uiId == LocationTypes.REMOTE_DECLARED ||
        uiId == LocationTypes.REMOTE_ALTERNATIVE) {
      return uiId;
    }

    // Para ubicaciones de catálogo, pueden venir como 1001-1004 (UI format) o 1-4 (catalog ID directo)
    if (uiId >= 1001 && uiId <= 1004) {
      final catalogId = uiId - 1000; // Extraer el ID del catálogo (1, 2, 3, 4)
      return _mapCatalogIdToBackendType(catalogId);
    } else if (uiId >= 1 && uiId <= 4) {
      // ID de catálogo directo, mapearlo al backend
      return _mapCatalogIdToBackendType(uiId);
    }

    // Fallback: retornar el mismo ID si no coincide con ningún patrón
    return uiId;
  }

  /// Mapea el ID del catálogo al location_type que espera el backend
  int _mapCatalogIdToBackendType(int catalogId) {
    switch (catalogId) {
      case 1:
        return 101; // Oficina ABSTI
      case 2:
        return 102; // Swiss Medical
      case 3:
        return 103; // Allianz
      case 4:
        return 104; // Galicia
      default:
        return catalogId + 100; // Fallback genérico
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
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token != null) {
        final checkIn = await CheckInService.getTodayCheckIn(token);

        if (checkIn != null) {
          // Si la jornada está completada, obtener la ubicación real del historial
          String actualLocationDetail = checkIn['location_detail'];
          final checkoutTime =
              checkIn['checkout_time'] ?? checkIn['check_out_time'];
          final checkoutStatus = checkIn['checkout_status'];

          // Si la jornada está completada, intentar obtener la ubicación de finalización del historial
          if (checkoutTime != null && checkoutStatus == 'completed') {
            try {
              final locationHistory =
                  await CheckInService.getSessionLocationHistory(token);
              if (locationHistory.isNotEmpty) {
                // ⭐ GUARDAR EL HISTORIAL DE UBICACIONES PARA EL MAPA ⭐
                _locationHistory = locationHistory;

                // Ordenar el historial por timestamp para asegurar orden cronológico
                locationHistory.sort((a, b) {
                  try {
                    final timeA = DateTime.parse(
                      a['start_time'] ?? a['timestamp'] ?? '1970-01-01',
                    );
                    final timeB = DateTime.parse(
                      b['start_time'] ?? b['timestamp'] ?? '1970-01-01',
                    );
                    return timeA.compareTo(timeB);
                  } catch (e) {
                    return 0; // Si hay error, mantener orden actual
                  }
                });

                // Buscar la ubicación donde se finalizó (sin end_time = ubicación activa)
                Map<String, dynamic>? finalLocation;
                // Buscar la ubicación con el end_time más alto (la última cronológicamente)
                if (locationHistory.isNotEmpty) {
                  final ubicacionesConFin = locationHistory
                      .where(
                        (loc) =>
                            loc['end_time'] != null &&
                            loc['end_time'].toString().isNotEmpty,
                      )
                      .toList();
                  if (ubicacionesConFin.isNotEmpty) {
                    finalLocation = ubicacionesConFin.reduce((a, b) {
                      final aEnd = DateTime.parse(a['end_time']);
                      final bEnd = DateTime.parse(b['end_time']);
                      return aEnd.isAfter(bEnd) ? a : b;
                    });
                  } else {
                    // Si ninguna tiene end_time, usar la última del historial
                    finalLocation = locationHistory.last;
                  }
                }

                if (finalLocation != null) {
                  String backendLocationDetail =
                      finalLocation['location_detail'] ?? '';
                  final locationTypeId = finalLocation['location_type'] as int?;

                  // MAPEO DIRECTO Y SIMPLE para ubicaciones de catálogo
                  if (locationTypeId != null) {
                    String mappedLocationName = '';

                    // Mapeo directo usando switch - MÁS CONFIABLE
                    switch (locationTypeId) {
                      case 101:
                        mappedLocationName = 'Oficina ABSTI';
                        break;
                      case 102:
                        mappedLocationName = 'Oficina de Swiss Medical Group';
                        break;
                      case 103:
                        mappedLocationName = 'Oficina Allianz';
                        break;
                      case 104:
                        mappedLocationName = 'Oficina Galicia';
                        break;
                      case 1: // Domicilio Declarado
                        mappedLocationName = 'Domicilio Declarado';
                        break;
                      case 2: // Domicilio Alternativo
                        mappedLocationName = 'Domicilio Alternativo';
                        break;
                      default:
                        // Para otros tipos, usar el backend detail si está disponible
                        mappedLocationName = backendLocationDetail.isNotEmpty
                            ? backendLocationDetail
                            : 'Ubicación $locationTypeId';
                        break;
                    }

                    // Para ubicaciones de catálogo (101-104), SIEMPRE usar nuestro mapeo
                    if (locationTypeId >= 101 && locationTypeId <= 104) {
                      actualLocationDetail = mappedLocationName;
                    } else {
                      // Para otros tipos, usar el mapeo si está disponible, sino backend
                      actualLocationDetail = mappedLocationName.isNotEmpty
                          ? mappedLocationName
                          : actualLocationDetail;
                    }
                  } else {
                    actualLocationDetail = backendLocationDetail.isNotEmpty
                        ? backendLocationDetail
                        : actualLocationDetail;
                  }
                } else {}
              } else {
                // Asegurar que _locationHistory se vacíe si no hay datos
                _locationHistory = [];
              }
            } catch (e) {
              // Continuar con la ubicación del check-in si hay error
              _locationHistory = [];
            }
          } else if (checkoutTime != null) {
            // También cargar historial si hay checkout_time pero no status completed
            try {
              final locationHistory =
                  await CheckInService.getSessionLocationHistory(token);
              if (locationHistory.isNotEmpty) {
                _locationHistory = locationHistory;
              } else {
                _locationHistory = [];
              }
            } catch (e) {
              _locationHistory = [];
            }
          }

          if (mounted) {
            setState(() {
              _todayCheckIn = checkIn;

              // Aplicar la misma lógica que _loadTodayCheckIn pero sin pantalla de carga
              if (checkoutTime == null) {
                _selectedLocations = [
                  checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED,
                ];
                _selectedSingleLocation = _selectedLocations.first;
                _completedLocationDetail =
                    actualLocationDetail; // Usar ubicación del historial si está disponible
                _isWorking = true;
                _dayCompleted = false;
                // No resetear _workStartTime si ya está trabajando
              } else if (checkoutTime != null &&
                  checkoutStatus == 'completed') {
                _selectedLocations = [
                  checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED,
                ];
                _selectedSingleLocation = _selectedLocations.first;
                _completedLocationDetail =
                    actualLocationDetail; // Usar ubicación real del historial
                _isWorking = false;
                _dayCompleted = true;
                _workStartTime = null;
                _workDuration = Duration.zero;
                _workTimer?.cancel();
              } else if (checkoutTime != null) {
                // Si hay checkout_time, asumir que está completado independientemente del status
                _selectedLocations = [
                  checkIn['location_type'] ?? LocationTypes.REMOTE_DECLARED,
                ];
                _selectedSingleLocation = _selectedLocations.first;
                _completedLocationDetail =
                    actualLocationDetail; // Usar ubicación real del historial
                _isWorking = false;
                _dayCompleted = true;
                _workStartTime = null;
                _workDuration = Duration.zero;
                _workTimer?.cancel();
              } else {
                _isWorking = false;
                _dayCompleted = false;
                _workStartTime = null;
                _workDuration = Duration.zero;
              }
            });
          }
        }
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar pantalla de carga mientras se inicializa
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
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
                onOtherLocationApartmentChanged:
                    _onOtherLocationApartmentChanged,
                completedLocationDetail: _completedLocationDetail,
                locationHistory: _locationHistory,
                // Nuevos parámetros para la funcionalidad mejorada
                catalogLocations: _catalogLocations,
                userDeclaredAddress: _userDeclaredAddress,
                additionalLocations: _additionalLocations,
                onAddAdditionalLocation: _onAddAdditionalLocation,
                onRemoveAdditionalLocation: _onRemoveAdditionalLocation,
                onUpdateAdditionalLocation: _onUpdateAdditionalLocation,
                // Horarios habituales del usuario
                userStartTime: _userStartTime,
                userEndTime: _userEndTime,
                originalStartTime: _originalStartTime,
                originalEndTime: _originalEndTime,
                onStartTimeChanged: _onUserStartTimeChanged,
                onEndTimeChanged: _onUserEndTimeChanged,
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
      // TODO VA PARA SEGUNDA ET
      /* floatingActionButton: _isWorking && !_isProcessing && !_dayCompleted
          ? FloatingActionButton.extended(
              onPressed: _showLocationChangeDialog,
              backgroundColor: const Color(0xFFE67D21),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.location_on),
              label: const Text('Cambiar Ubicación'),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat, */
    );
  }
}
