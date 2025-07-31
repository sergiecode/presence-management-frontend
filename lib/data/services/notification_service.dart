/// Servicio de gestión de notificaciones locales para la aplicación ABSTI
///
/// Este servicio maneja todas las operaciones relacionadas con notificaciones
/// locales, incluyendo configuración inicial, programación de recordatorios
/// de check-in, y gestión de permisos.
///
/// Utiliza flutter_local_notifications para mostrar notificaciones.
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'dart:io';
import 'package:flutter/material.dart';
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
  
  /// ID único para recordatorios cada 15 minutos
  static const int missedCheckinBaseId = 2000;

  /// Canal de notificaciones para check-in (Android)
  static const String checkinChannelId = 'checkin_reminders';
  static const String checkinChannelName = 'Recordatorios de Check-in';
  static const String checkinChannelDescription =
      'Notificaciones para recordar hacer check-in';
      
  /// Canal de notificaciones para check-ins perdidos (Android)
  static const String missedCheckinChannelId = 'missed_checkin_reminders';
  static const String missedCheckinChannelName = 'Recordatorios de Check-in Perdido';
  static const String missedCheckinChannelDescription =
      'Notificaciones cada 15 minutos cuando no se ha hecho check-in';

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
      print('NotificationService: INICIANDO - Inicializando servicio de notificaciones...');

      // Inicializar zonas horarias
      tz.initializeTimeZones();
      print('NotificationService: INICIANDO - Zonas horarias inicializadas');

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
      print('NotificationService: INICIANDO - Inicializando plugin...');
      final bool? result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      print('NotificationService: INICIANDO - Resultado inicialización plugin: $result');

      if (result == true) {
        // Crear canal de notificaciones para Android
        print('NotificationService: INICIANDO - Creando canales...');
        await _createNotificationChannel();
        
        // Solicitar permisos
        print('NotificationService: INICIANDO - Solicitando permisos...');
        final permissionsGranted = await _requestPermissions();
        print('NotificationService: INICIANDO - Permisos resultado: $permissionsGranted');
        
        _isInitialized = true;
        print('NotificationService: ÉXITO - Servicio inicializado exitosamente');
        return true;
      } else {
        print('NotificationService: ERROR - Error al inicializar plugin notificaciones, resultado: $result');
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
      // Canal para recordatorios normales de check-in
      const AndroidNotificationChannel checkinChannel = AndroidNotificationChannel(
        checkinChannelId,
        checkinChannelName,
        description: checkinChannelDescription,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      // Canal para recordatorios de check-in perdido
      const AndroidNotificationChannel missedCheckinChannel = AndroidNotificationChannel(
        missedCheckinChannelId,
        missedCheckinChannelName,
        description: missedCheckinChannelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
      );

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidPlugin?.createNotificationChannel(checkinChannel);
      await androidPlugin?.createNotificationChannel(missedCheckinChannel);

      print('NotificationService: Canales de notificaciones creados');
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

      // Permisos para Android
      if (Platform.isAndroid) {
        // Solicitar permiso de notificaciones (API 33+)
        final notificationStatus = await Permission.notification.request();
        print('NotificationService: Estado permiso notificaciones: $notificationStatus');
        
        // Solicitar permiso de alarmas exactas (API 31+)
        final scheduleExactAlarmStatus = await Permission.scheduleExactAlarm.request();
        print('NotificationService: Estado permiso alarmas exactas: $scheduleExactAlarmStatus');
        
        // Verificar si ambos permisos están concedidos
        final hasNotificationPermission = notificationStatus.isGranted;
        final hasExactAlarmPermission = scheduleExactAlarmStatus.isGranted;
        
        if (hasNotificationPermission && hasExactAlarmPermission) {
          print('NotificationService: Todos los permisos Android concedidos');
          return true;
        } else {
          print('NotificationService: Permisos Android incompletos - Notificaciones: $hasNotificationPermission, Alarmas exactas: $hasExactAlarmPermission');
          
          // Si no tiene permiso de alarmas exactas, informar al usuario
          if (!hasExactAlarmPermission) {
            print('NotificationService: IMPORTANTE - Sin permiso de alarmas exactas, las notificaciones programadas podrían no funcionar correctamente');
          }
          
          return hasNotificationPermission; // Al menos necesitamos notificaciones básicas
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

  /// Programar recordatorios cada 15 minutos después de la hora de check-in perdida
  ///
  /// Programa múltiples notificaciones cada 15 minutos después de que pase
  /// la hora de check-in sin que el usuario haya registrado entrada.
  ///
  /// Parámetros:
  /// - [checkinTime]: Hora de check-in en formato "HH:MM:SS" o "HH:MM"
  /// - [userName]: Nombre del usuario para personalizar el mensaje
  /// - [maxReminders]: Número máximo de recordatorios (por defecto 12 = 3 horas)
  ///
  /// Retorna:
  /// - [bool]: true si las notificaciones fueron programadas exitosamente
  Future<bool> scheduleMissedCheckinReminders({
    required String checkinTime,
    String userName = 'Usuario',
    int maxReminders = 12, // 12 recordatorios = 3 horas
  }) async {
    try {
      if (!_isInitialized) {
        print('NotificationService: Servicio no inicializado');
        return false;
      }

      // Cancelar recordatorios anteriores
      await cancelMissedCheckinReminders();

      // Parsear hora de check-in
      final timeParts = checkinTime.split(':');
      if (timeParts.length < 2) {
        print('NotificationService: Formato de hora inválido: $checkinTime');
        return false;
      }

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      // Crear fecha/hora de check-in de hoy
      final now = DateTime.now();
      var checkinDateTime = DateTime(now.year, now.month, now.day, hour, minute);

      // Si ya pasó la hora de hoy, programar para mañana
      if (checkinDateTime.isBefore(now)) {
        checkinDateTime = checkinDateTime.add(const Duration(days: 1));
      }

      // Programar recordatorios cada 15 minutos después del check-in
      for (int i = 1; i <= maxReminders; i++) {
        final reminderTime = checkinDateTime.add(Duration(minutes: 15 * i));
        
        // Solo programar si es en el futuro
        if (reminderTime.isAfter(now)) {
          await _scheduleMissedCheckinNotification(
            reminderTime,
            userName,
            checkinTime,
            i,
            missedCheckinBaseId + i,
          );
        }
      }

      print('NotificationService: $maxReminders recordatorios de check-in perdido programados');
      return true;
    } catch (e) {
      print('NotificationService: Error programando recordatorios de check-in perdido: $e');
      return false;
    }
  }

  /// Método interno para programar una notificación de check-in perdido
  Future<bool> _scheduleMissedCheckinNotification(
    DateTime notificationDateTime,
    String userName,
    String checkinTime,
    int reminderNumber,
    int notificationId,
  ) async {
    try {
      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
        notificationDateTime,
        tz.local,
      );

      // Crear mensaje más urgente después de cada recordatorio
      String title;
      String body;
      
      if (reminderNumber == 1) {
        title = '⏰ Check-in Pendiente';
        body = '¡Hola $userName! Se te pasó la hora de check-in ($checkinTime). ¡Registra tu entrada ahora!';
      } else if (reminderNumber <= 4) {
        title = '🔔 Recordatorio: Check-in Pendiente';
        body = '¡$userName! Aún no has registrado tu entrada de hoy. Tu horario era a las $checkinTime.';
      } else {
        title = '⚠️ URGENTE: Check-in Pendiente';
        body = '¡$userName! Es importante que registres tu entrada. ¿Olvidaste hacer check-in?';
      }

      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            missedCheckinChannelId,
            missedCheckinChannelName,
            channelDescription: missedCheckinChannelDescription,
            importance: Importance.max,
            priority: Priority.max,
            icon: '@mipmap/ic_launcher',
            playSound: true,
            enableVibration: true,
            enableLights: true,
            color: Colors.red, // Color rojo para urgencia
            colorized: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default',
            interruptionLevel: InterruptionLevel.critical, // Interrumpir incluso en modo silencio
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      print('NotificationService: Recordatorio #$reminderNumber programado para: $scheduledDate');
      return true;
    } catch (e) {
      print('NotificationService: Error programando recordatorio #$reminderNumber: $e');
      return false;
    }
  }

  /// Cancelar todos los recordatorios de check-in perdido
  ///
  /// Cancela todas las notificaciones de recordatorios cada 15 minutos.
  ///
  /// Retorna:
  /// - [bool]: true si la cancelación fue exitosa
  Future<bool> cancelMissedCheckinReminders() async {
    try {
      // Cancelar hasta 24 recordatorios posibles (6 horas máx)
      for (int i = 1; i <= 24; i++) {
        await _notifications.cancel(missedCheckinBaseId + i);
      }
      print('NotificationService: Recordatorios de check-in perdido cancelados');
      return true;
    } catch (e) {
      print('NotificationService: Error cancelando recordatorios de check-in perdido: $e');
      return false;
    }
  }

  /// Cancelar TODAS las notificaciones (check-in y recordatorios)
  ///
  /// Útil cuando el usuario hace check-in para detener todos los recordatorios.
  ///
  /// Retorna:
  /// - [bool]: true si la cancelación fue exitosa
  Future<bool> cancelAllReminders() async {
    try {
      await cancelCheckinReminder();
      await cancelMissedCheckinReminders();
      print('NotificationService: Todos los recordatorios cancelados');
      return true;
    } catch (e) {
      print('NotificationService: Error cancelando todos los recordatorios: $e');
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
    } else if (response.id != null && response.id! >= missedCheckinBaseId && response.id! < missedCheckinBaseId + 25) {
      print('NotificationService: Usuario tocó recordatorio de check-in perdido');
      // TODO: Navegar a la página de check-in y mostrar mensaje sobre check-in perdido
    }
  }

  /// Verificar si el servicio está inicializado
  bool get isInitialized => _isInitialized;
}
