/// Servicio de gestión de notificaciones locales para la aplicación Tareas
///
/// Este servicio maneja todas las operaciones relacionadas con notificaciones
/// locales, incluyendo configuración inicial, programación de recordatorios
/// de check-in, y gestión de permisos.
///
/// Utiliza flutter_local_notifications para mostrar notificaciones.
///
/// Autor: Equipo Gold
/// Fecha: 2025
library;

import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

/// Servicio que maneja todas las operaciones de notificaciones locales
class NotificationService {
  /// Instancia singleton del servicio
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Plugin de notificaciones locales
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// ID único para notificaciones de check-in
  static const int checkinNotificationId = 1000;

  /// Canal de notificaciones para check-in (Android)
  static const String checkinChannelId = 'checkin_reminders';
  static const String checkinChannelName = 'Recordatorios de Check-in';
  static const String checkinChannelDescription =
      'Notificaciones para recordar hacer check-in';

  /// Indica si el servicio está inicializado
  bool _isInitialized = false;

  /// Inicializar el servicio de notificaciones
  ///
  /// Este método debe llamarse al inicio de la aplicación para configurar
  /// las notificaciones locales y solicitar permisos necesarios.
  ///
  /// Retorna:
  /// - [bool]: true si la inicialización fue exitosa, false en caso contrario
  Future<bool> initialize() async {
    try {
      // NotificationService: Inicializando servicio de notificaciones...

      // Inicializar zonas horarias
      tz.initializeTimeZones();

      // Configuración para Android
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración para iOS
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Configuración para Linux
      const LinuxInitializationSettings linuxSettings =
          LinuxInitializationSettings(defaultActionName: 'Open notification');

      // Configuración general
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        linux: linuxSettings,
      );

      // Inicializar el plugin
      final bool? result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (result == true) {
        // Crear canal de notificaciones para Android
        await _createNotificationChannel();
        
        // Solicitar permisos
        await _requestPermissions();
        
        _isInitialized = true;
        // NotificationService: Servicio inicializado exitosamente
        return true;
      } else {
        // NotificationService: Error al inicializar notificaciones
        return false;
      }
    } catch (e) {
      print('NotificationService: Error durante inicialización: $e');
      return false;
    }
  }

  /// Crear canal de notificaciones para Android
  Future<void> _createNotificationChannel() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        checkinChannelId,
        checkinChannelName,
        description: checkinChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      print('NotificationService: Canal de notificaciones creado');
    }
  }

  /// Solicitar permisos de notificaciones
  Future<bool> _requestPermissions() async {
    try {
      // Permisos para iOS
      if (Platform.isIOS) {
        final bool? result = await _notifications
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
        
        if (result == true) {
          print('NotificationService: Permisos iOS concedidos');
          return true;
        }
      }

      // Permisos para Android (API 33+)
      if (Platform.isAndroid) {
        final status = await Permission.notification.request();
        if (status.isGranted) {
          print('NotificationService: Permisos Android concedidos');
          return true;
        } else {
          print('NotificationService: Permisos Android denegados');
          return false;
        }
      }

      return true; // Para otras plataformas
    } catch (e) {
      print('NotificationService: Error solicitando permisos: $e');
      return false;
    }
  }

  /// Programar notificación de recordatorio de check-in
  ///
  /// Programa una notificación diaria basada en la hora de check-in del usuario
  /// y el offset de recordatorio configurado.
  ///
  /// Parámetros:
  /// - [checkinTime]: Hora de check-in en formato "HH:MM:SS" o "HH:MM"
  /// - [notificationOffsetMin]: Minutos antes del check-in para mostrar recordatorio
  /// - [userName]: Nombre del usuario para personalizar el mensaje
  ///
  /// Retorna:
  /// - [bool]: true si la notificación fue programada exitosamente
  Future<bool> scheduleCheckinReminder({
    required String checkinTime,
    required int notificationOffsetMin,
    String userName = 'Usuario',
  }) async {
    try {
      if (!_isInitialized) {
        print('NotificationService: Servicio no inicializado');
        return false;
      }

      // Cancelar notificación anterior
      await cancelCheckinReminder();

      // Parsear hora de check-in
      final timeParts = checkinTime.split(':');
      if (timeParts.length < 2) {
        print('NotificationService: Formato de hora inválido: $checkinTime');
        return false;
      }

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Crear fecha/hora objetivo (hoy a la hora de check-in)
      final now = DateTime.now();
      var targetDateTime = DateTime(now.year, now.month, now.day, hour, minute);

      // Si ya pasó la hora de hoy, programar para mañana
      if (targetDateTime.isBefore(now)) {
        targetDateTime = targetDateTime.add(const Duration(days: 1));
      }

      // Restar el offset de recordatorio
      final notificationDateTime = targetDateTime.subtract(
        Duration(minutes: notificationOffsetMin),
      );

      // Verificar que la notificación no sea en el pasado
      if (notificationDateTime.isBefore(now)) {
        // Programar para mañana
        final tomorrowTarget = targetDateTime.add(const Duration(days: 1));
        final tomorrowNotification = tomorrowTarget.subtract(
          Duration(minutes: notificationOffsetMin),
        );
        return await _scheduleNotification(
          tomorrowNotification,
          userName,
          checkinTime,
          notificationOffsetMin,
        );
      }

      return await _scheduleNotification(
        notificationDateTime,
        userName,
        checkinTime,
        notificationOffsetMin,
      );
    } catch (e) {
      print('NotificationService: Error programando recordatorio: $e');
      return false;
    }
  }

  /// Método interno para programar la notificación
  Future<bool> _scheduleNotification(
    DateTime notificationDateTime,
    String userName,
    String checkinTime,
    int offsetMinutes,
  ) async {
    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        notificationDateTime,
        tz.local,
      );

      print('NotificationService: Programando notificación para: $scheduledDate');

      await _notifications.zonedSchedule(
        checkinNotificationId,
        '🕒 Recordatorio de Check-in',
        offsetMinutes > 0
            ? '¡Hola $userName! Tu check-in es en $offsetMinutes minutos ($checkinTime). ¡No olvides registrar tu entrada!'
            : '¡Hola $userName! Es hora de hacer check-in ($checkinTime). ¡Registra tu entrada ahora!',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            checkinChannelId,
            checkinChannelName,
            channelDescription: checkinChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Repetir diariamente
      );

      print('NotificationService: Notificación programada exitosamente');
      return true;
    } catch (e) {
      print('NotificationService: Error en _scheduleNotification: $e');
      return false;
    }
  }

  /// Cancelar recordatorio de check-in
  ///
  /// Cancela cualquier notificación de recordatorio de check-in programada.
  ///
  /// Retorna:
  /// - [bool]: true si la cancelación fue exitosa
  Future<bool> cancelCheckinReminder() async {
    try {
      await _notifications.cancel(checkinNotificationId);
      print('NotificationService: Recordatorio de check-in cancelado');
      return true;
    } catch (e) {
      print('NotificationService: Error cancelando recordatorio: $e');
      return false;
    }
  }

  /// Mostrar notificación inmediata de prueba
  ///
  /// Útil para probar que las notificaciones funcionan correctamente.
  ///
  /// Parámetros:
  /// - [userName]: Nombre del usuario para personalizar el mensaje
  Future<bool> showTestNotification({String userName = 'Usuario'}) async {
    try {
      if (!_isInitialized) {
        print('NotificationService: Servicio no inicializado');
        return false;
      }

      await _notifications.show(
        999, // ID temporal para pruebas
        '🧪 Notificación de Prueba',
        '¡Hola $userName! Las notificaciones están funcionando correctamente.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            checkinChannelId,
            checkinChannelName,
            channelDescription: checkinChannelDescription,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
          ),
        ),
      );

      print('NotificationService: Notificación de prueba enviada');
      return true;
    } catch (e) {
      print('NotificationService: Error enviando notificación de prueba: $e');
      return false;
    }
  }

  /// Obtener notificaciones pendientes
  ///
  /// Retorna información sobre notificaciones programadas.
  ///
  /// Retorna:
  /// - [List<PendingNotificationRequest>]: Lista de notificaciones pendientes
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      print('NotificationService: Error obteniendo notificaciones pendientes: $e');
      return [];
    }
  }

  /// Verificar si hay permisos de notificaciones
  ///
  /// Retorna:
  /// - [bool]: true si los permisos están concedidos
  Future<bool> hasPermissions() async {
    try {
      if (Platform.isAndroid) {
        return await Permission.notification.isGranted;
      } else if (Platform.isIOS) {
        // Para iOS, asumimos que los permisos están concedidos si el servicio se inicializó
        return _isInitialized;
      }
      return true; // Para otras plataformas
    } catch (e) {
      print('NotificationService: Error verificando permisos: $e');
      return false;
    }
  }

  /// Callback cuando se toca una notificación
  static void _onNotificationTapped(NotificationResponse response) {
    print('NotificationService: Notificación tocada - ID: ${response.id}');
    
    // Aquí se puede agregar lógica para abrir la app en una pantalla específica
    // Por ejemplo, ir directamente a la página de check-in
    
    if (response.id == checkinNotificationId) {
      print('NotificationService: Usuario tocó recordatorio de check-in');
      // TODO: Navegar a la página de check-in si la app no está abierta
    }
  }

  /// Verificar si el servicio está inicializado
  bool get isInitialized => _isInitialized;
}
