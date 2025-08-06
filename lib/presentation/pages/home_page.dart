import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';

// Importaciones de la nueva estructura
import '../../data/services/checkin_service.dart';
import '../../data/services/user_service.dart';
import '../../data/services/notification_service.dart';
import '../../data/providers/auth_provider.dart';
import '../../core/constants/location_types.dart';
import '../atoms/atoms.dart';
import '../molecules/molecules.dart';
import '../molecules/location_change_dialog.dart';
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

  // Campos adicionales para "Domicilio Alternativo"
  String? _otherLocationDetail;
  String? _otherLocationFloor;
  String? _otherLocationApartment;

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

  /// Carga el check-in del día actual si existe
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
              _completedLocationDetail = checkIn['location_detail'];

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
              _completedLocationDetail = checkIn['location_detail'];
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
              _completedLocationDetail = checkIn['location_detail'];
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
          // Reset estado cuando no hay check-in
          _dayCompleted = false;
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
        _workDuration = DateTime.now().difference(_workStartTime!);
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

  /// Inicia la jornada laboral
  Future<void> _startWork() async {
    if (_isProcessing) return;

    // Verificar que al menos una ubicación esté seleccionada
    if (_selectedLocations.isEmpty) {
      _showErrorSnackBar('Selecciona al menos una ubicación para trabajar');
      return;
    }

    // Verificar si el día ya está completado
    if (_dayCompleted) {
      _showErrorSnackBar('Ya completaste tu jornada laboral de hoy');
      return;
    }

    // Construir mensaje para el diálogo según cantidad de ubicaciones
    String locationMessage;
    if (_selectedLocations.length == 1) {
      locationMessage = _locations[_selectedLocations.first]!;
    } else {
      locationMessage = 'ubicaciones múltiples: ${_selectedLocations.map((id) => _locations[id]).join(', ')}';
    }

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

           // Crear los datos de ubicaciones para enviar al backend (TODAS las ubicaciones seleccionadas)
          final locationsData = _selectedLocations.map((locationId) {
            String locationDetail = _locations[locationId] ?? 'Desconocido';
            
            // Si es "Domicilio Alternativo", construir la dirección completa
            if (locationId == LocationTypes.REMOTE_ALTERNATIVE && _otherLocationDetail != null) {
              locationDetail = _otherLocationDetail!;
              
              // Agregar piso si está disponible
              if (_otherLocationFloor != null && _otherLocationFloor!.isNotEmpty) {
                locationDetail += ', Piso $_otherLocationFloor';
              }
              
              // Agregar departamento si está disponible
              if (_otherLocationApartment != null && _otherLocationApartment!.isNotEmpty) {
                locationDetail += ', Dpto $_otherLocationApartment';
              }
            }
            
            return {
              'location_type': locationId,
              'location_detail': locationDetail,
            };
          }).toList();

          // Los datos para el check-in
          final checkInData = {
            'date': date,
            'time': time,
            'locations': locationsData, // Enviar la lista de ubicaciones
            'gps_lat': 0.0,
            'gps_long': 0.0,
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
              // Actualizar el completed location detail con todas las ubicaciones
              _completedLocationDetail = _selectedLocations.length == 1 
                ? locationsData.first['location_detail'] as String?
                : locationsData.map((loc) => loc['location_detail'] as String).join(', ');
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

    // Construir mensaje para el diálogo según cantidad de ubicaciones
    String locationMessage;
    if (_selectedLocations.length == 1) {
      locationMessage = _locations[_selectedLocations.first]!;
    } else {
      locationMessage = 'ubicaciones múltiples: ${_selectedLocations.map((id) => _locations[id]).join(', ')}';
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
                currentLocationDetail = _otherLocationDetail!;
                if (_otherLocationFloor != null && _otherLocationFloor!.isNotEmpty) {
                  currentLocationDetail += ', Piso $_otherLocationFloor';
                }
                if (_otherLocationApartment != null && _otherLocationApartment!.isNotEmpty) {
                  currentLocationDetail += ', Dpto $_otherLocationApartment';
                }
              } else {
                currentLocationDetail = _locations[locationId] ?? 'Ubicación desconocida';
              }
            } else {
              currentLocationDetail = _selectedLocations.map((id) => _locations[id]).join(', ');
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
          // Parsear hora de inicio
          DateTime startTime;
          if (checkinTime.toString().contains('T')) {
            startTime = DateTime.parse(checkinTime.toString());
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
            } else {
              endTime = DateTime.parse(
                '${_todayCheckIn!['date']} $checkoutTime',
              );
            }

            final sessionDuration = endTime.difference(startTime);
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

/*   /// Cambia la ubicación seleccionada
  void _onLocationChanged(int newLocation) {
    setState(() {
      _selectedLocation = newLocation;
    });
  } */

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
      builder: (context) => LocationChangeDialog(
        currentLocations: _selectedLocations, // Pasar toda la lista de ubicaciones
        locations: _locations,
        onLocationChanged: _changeLocationDuringWork,
      ),
    );
  }

  /// Cambia la ubicación durante la jornada laboral
  Future<void> _changeLocationDuringWork(
    int newLocation, {
    String? address,
    String? floor,
    String? apartment,
  }) async {
    print('🔄 Cambiando ubicación durante trabajo a: $newLocation');
    print('   - Dirección: $address');
    print('   - Piso: $floor');
    print('   - Depto: $apartment');
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
      final Map<String, dynamic> locationData = {
        'location_type': newLocation,
      };

      // Agregar detalles adicionales si es necesario
      if (newLocation == LocationTypes.REMOTE_ALTERNATIVE) {
        if (address != null && address.isNotEmpty) {
          locationData['address'] = address;
        }
        if (floor != null && floor.isNotEmpty) {
          locationData['floor'] = floor;
        }
        if (apartment != null && apartment.isNotEmpty) {
          locationData['apartment'] = apartment;
        }
      }

      print('📍 Datos de ubicación a enviar: $locationData');

      // Llamar al servicio para cambiar ubicación durante trabajo
      final response = await CheckInService.changeLocationDuringWork(token, locationData);

      print('📝 Respuesta del servicio: $response');

      if (response != null && response['success'] == true) {
        print('✅ Ubicación cambiada exitosamente');
        
        // Construir el location_detail correcto
        String newLocationDetail;
        if (newLocation == LocationTypes.REMOTE_ALTERNATIVE && address != null && address.isNotEmpty) {
          newLocationDetail = address;
          if (floor != null && floor.isNotEmpty) {
            newLocationDetail += ', Piso $floor';
          }
          if (apartment != null && apartment.isNotEmpty) {
            newLocationDetail += ', Dpto $apartment';
          }
          print('📍 Nueva ubicación construida para domicilio alternativo: $newLocationDetail');
        } else {
          newLocationDetail = _locations[newLocation] ?? '';
          print('📍 Nueva ubicación para tipo estándar: $newLocationDetail');
        }
        
        // Actualizar estado local
        if (mounted) {
          setState(() {
            print('📍 Actualizando estado local con:');
            print('   - newLocation: $newLocation');
            print('   - newLocationDetail: $newLocationDetail');
            print('   - address: $address');
            print('   - floor: $floor');
            print('   - apartment: $apartment');
            
            _selectedLocations = [newLocation];
            if (newLocation == LocationTypes.REMOTE_ALTERNATIVE) {
              _otherLocationDetail = address ?? '';
              _otherLocationFloor = floor ?? '';
              _otherLocationApartment = apartment ?? '';
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
              _todayCheckIn!['location_type'] = newLocation;
              _todayCheckIn!['location_detail'] = newLocationDetail;
              print('📍 Check-in local actualizado: location_type=$newLocation, location_detail=$newLocationDetail');
            }
            
            // Actualizar el completed location detail para cuando termine la jornada
            _completedLocationDetail = newLocationDetail;
            print('📍 _completedLocationDetail actualizado: $_completedLocationDetail');
          });
        }

        // Mostrar mensaje de éxito
        if (mounted) {
          final message = response['message']?.toString() ?? 'Ubicación cambiada exitosamente';
          _showSuccessSnackBar(message);
        }

        // Refrescar historial de ubicaciones (pero NO el estado principal para evitar pisar la dirección)
        await _loadLocationHistory();
        
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
                otherLocationDetail: _otherLocationDetail,
                onOtherLocationChanged: _onOtherLocationChanged,
                otherLocationFloor: _otherLocationFloor,
                otherLocationApartment: _otherLocationApartment,
                onOtherLocationFloorChanged: _onOtherLocationFloorChanged,
                onOtherLocationApartmentChanged: _onOtherLocationApartmentChanged,
                completedLocationDetail: _completedLocationDetail,
                locationHistory: _locationHistory,
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
