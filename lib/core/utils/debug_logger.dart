/// **UTILIDAD: Debug Logger**
///
/// Sistema de logging centralizado para debugging de la aplicación ABSTI.
/// Permite registrar eventos importantes, errores y información de estado
/// que se puede ver tanto en consola como en la UI durante testing.
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'package:flutter/material.dart';

/// Logger centralizado para debugging de la aplicación
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  /// Lista de logs recientes (últimos 100)
  final List<DebugLogEntry> _logs = [];
  
  /// Listeners para notificar cambios en los logs
  final List<Function()> _listeners = [];
  
  /// Nivel de logging actual
  LogLevel _currentLevel = LogLevel.info;
  
  /// Habilitar/deshabilitar logging
  bool _enabled = true;

  // --- GETTERS ---
  
  /// Obtener todos los logs
  List<DebugLogEntry> get logs => List.unmodifiable(_logs);
  
  /// Obtener logs filtrados por nivel
  List<DebugLogEntry> getLogsByLevel(LogLevel level) {
    return _logs.where((log) => log.level.index >= level.index).toList();
  }
  
  /// Obtener logs de error y warning
  List<DebugLogEntry> get errorAndWarningLogs {
    return _logs.where((log) => 
      log.level == LogLevel.error || log.level == LogLevel.warning
    ).toList();
  }
  
  /// Verificar si está habilitado
  bool get isEnabled => _enabled;
  
  /// Obtener nivel actual
  LogLevel get currentLevel => _currentLevel;

  // --- MÉTODOS PÚBLICOS ---

  /// Agregar un listener para cambios en los logs
  void addListener(Function() listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  /// Remover un listener
  void removeListener(Function() listener) {
    _listeners.remove(listener);
  }

  /// Habilitar logging
  void enable() {
    _enabled = true;
    _log(LogLevel.info, '🔧 Debug logging habilitado');
  }

  /// Deshabilitar logging
  void disable() {
    _enabled = false;
    _log(LogLevel.info, '🔧 Debug logging deshabilitado');
  }

  /// Establecer nivel de logging
  void setLevel(LogLevel level) {
    _currentLevel = level;
    _log(LogLevel.info, '🔧 Nivel de logging establecido a: $level');
  }

  /// Limpiar todos los logs
  void clear() {
    _logs.clear();
    _notifyListeners();
    _log(LogLevel.info, '🧹 Todos los logs han sido limpiados');
  }

  /// Obtener logs como texto para copiar
  String getLogsAsText() {
    return _logs.map((log) => log.toString()).join('\n');
  }

  // --- MÉTODOS DE LOGGING ---

  /// Log de debug (más detallado)
  void debug(String message, {String? tag, Object? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log de información general
  void info(String message, {String? tag, Object? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log de advertencia
  void warning(String message, {String? tag, Object? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Log de error
  void error(String message, {String? tag, Object? data, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, data: data, error: error, stackTrace: stackTrace);
  }

  /// Log de error crítico (siempre se muestra)
  void critical(String message, {String? tag, Object? data, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.critical, message, tag: tag, data: data, error: error, stackTrace: stackTrace);
  }

  // --- MÉTODOS PRIVADOS ---

  /// Método interno para agregar logs
  void _log(LogLevel level, String message, {
    String? tag,
    Object? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_enabled || level.index < _currentLevel.index) {
      return;
    }

    final entry = DebugLogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      data: data,
      error: error,
      stackTrace: stackTrace,
    );

    _logs.add(entry);
    
    // Mantener solo los últimos 100 logs
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }

    // Imprimir en consola
    _printToConsole(entry);
    
    // Notificar listeners
    _notifyListeners();
  }

  /// Imprimir log en consola
  void _printToConsole(DebugLogEntry entry) {
    final timestamp = entry.timestamp.toString().substring(11, 19);
    final levelIcon = _getLevelIcon(entry.level);
    final tag = entry.tag != null ? ' [${entry.tag}]' : '';
    
    print('$levelIcon [$timestamp]$tag ${entry.message}');
    
    if (entry.data != null) {
      print('   📊 Data: ${entry.data}');
    }
    
    if (entry.error != null) {
      print('   ❌ Error: ${entry.error}');
    }
    
    if (entry.stackTrace != null) {
      print('   📍 Stack Trace: ${entry.stackTrace}');
    }
  }

  /// Obtener icono para el nivel de log
  String _getLevelIcon(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }

  /// Notificar a todos los listeners
  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener();
      } catch (e) {
        // Evitar que un listener roto rompa el logging
        print('Error en listener de DebugLogger: $e');
      }
    }
  }
}

/// Entrada individual de log
class DebugLogEntry {
  final DateTime timestamp;
  final LogLevel level;
  final String message;
  final String? tag;
  final Object? data;
  final Object? error;
  final StackTrace? stackTrace;

  DebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.data,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final timestamp = this.timestamp.toString().substring(11, 19);
    final levelIcon = _getLevelIcon();
    final tag = this.tag != null ? ' [${this.tag}]' : '';
    
    String result = '$levelIcon [$timestamp]$tag $message';
    
    if (data != null) {
      result += '\n   📊 Data: $data';
    }
    
    if (error != null) {
      result += '\n   ❌ Error: $error';
    }
    
    return result;
  }

  String _getLevelIcon() {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
      case LogLevel.critical:
        return '🚨';
    }
  }
}

/// Niveles de logging
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3),
  critical(4);

  const LogLevel(this.value);
  final int value;
}

/// Extensiones útiles para logging
extension DebugLoggerExtension on Object {
  /// Log de debug con tag automático
  void debugLog(String message, {Object? data}) {
    DebugLogger().debug(message, tag: runtimeType.toString(), data: data);
  }

  /// Log de info con tag automático
  void infoLog(String message, {Object? data}) {
    DebugLogger().info(message, tag: runtimeType.toString(), data: data);
  }

  /// Log de warning con tag automático
  void warningLog(String message, {Object? data}) {
    DebugLogger().warning(message, tag: runtimeType.toString(), data: data);
  }

  /// Log de error con tag automático
  void errorLog(String message, {Object? data, Object? error, StackTrace? stackTrace}) {
    DebugLogger().error(message, tag: runtimeType.toString(), data: data, error: error, stackTrace: stackTrace);
  }
}
