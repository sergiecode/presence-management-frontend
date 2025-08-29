/// Modelos de datos para ubicaciones múltiples y catálogo
///
/// Este archivo contiene las clases que manejan la información
/// de ubicaciones, incluyendo ubicaciones del catálogo y 
/// ubicaciones múltiples con horarios.
///
/// Autor: Equipo ABSTI
/// Fecha: 2025
library;

import 'package:flutter/material.dart';

/// Modelo para una ubicación de trabajo con horarios
class WorkLocation {
  final int locationTypeId;
  final String locationDetail;
  final TimeOfDay startTime;
  final TimeOfDay? endTime;

  WorkLocation({
    required this.locationTypeId,
    required this.locationDetail,
    required this.startTime,
    this.endTime,
  });

  /// Convierte la ubicación a formato JSON para la API
  /// Si se proporciona [baseDate], convierte los horarios a UTC
  Map<String, dynamic> toJson({DateTime? baseDate}) {
    return {
      'location_type': locationTypeId,
      'location_detail': locationDetail,
      'start_time': baseDate != null 
          ? _formatTimeToUtc(startTime, baseDate)
          : _formatTimeOfDay(startTime),
      if (endTime != null) 'end_time': baseDate != null
          ? _formatTimeToUtc(endTime!, baseDate) 
          : _formatTimeOfDay(endTime!),
    };
  }

  /// Formatea TimeOfDay al formato HH:mm que espera la API (DEPRECATED - usar toJson con baseDate)
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Convierte TimeOfDay a formato ISO 8601 UTC usando una fecha base
  String _formatTimeToUtc(TimeOfDay time, DateTime baseDate) {
    // Crear un DateTime con la fecha base y la hora especificada en zona local
    final localDateTime = DateTime(
      baseDate.year,
      baseDate.month, 
      baseDate.day,
      time.hour,
      time.minute,
    );
    
    // Convertir a UTC y formatear como ISO 8601 UTC
    final utcDateTime = localDateTime.toUtc();
    return utcDateTime.toIso8601String();
  }

  /// Crea una copia de la ubicación con nuevos valores
  WorkLocation copyWith({
    int? locationTypeId,
    String? locationDetail,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) {
    return WorkLocation(
      locationTypeId: locationTypeId ?? this.locationTypeId,
      locationDetail: locationDetail ?? this.locationDetail,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  String toString() {
    return 'WorkLocation(type: $locationTypeId, detail: $locationDetail, start: ${_formatTimeOfDay(startTime)}, end: ${endTime != null ? _formatTimeOfDay(endTime!) : 'null'})';
  }
}

/// Modelo para ubicaciones adicionales que se pueden agregar durante el día
class AdditionalLocation extends WorkLocation {
  final String? notes; // Notas adicionales para esta ubicación

  AdditionalLocation({
    required super.locationTypeId,
    required super.locationDetail,
    required super.startTime,
    super.endTime,
    this.notes,
  });

  @override
  Map<String, dynamic> toJson({DateTime? baseDate}) {
    final json = super.toJson(baseDate: baseDate);
    if (notes != null && notes!.isNotEmpty) {
      json['notes'] = notes;
    }
    return json;
  }

  /// Crea una copia de la ubicación adicional con nuevos valores
  @override
  AdditionalLocation copyWith({
    int? locationTypeId,
    String? locationDetail,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? notes,
  }) {
    return AdditionalLocation(
      locationTypeId: locationTypeId ?? this.locationTypeId,
      locationDetail: locationDetail ?? this.locationDetail,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
    );
  }
}

/// Modelo para manejar ubicaciones de catálogos con sus diferentes fuentes
class LocationOption {
  final int id;
  final String name;
  final String? description;
  final LocationSource source;
  final String? address;
  final int? catalogId; // ID original del catálogo (para mapear al backend)

  LocationOption({
    required this.id,
    required this.name,
    this.description,
    required this.source,
    this.address,
    this.catalogId,
  });

  /// Convierte a formato para mostrar en dropdowns
  String get displayName {
    switch (source) {
      case LocationSource.catalog:
        return name;
      case LocationSource.declaredAddress:
        return 'Domicilio Declarado';
      case LocationSource.alternativeAddress:
        return 'Domicilio Alternativo';
    }
  }

  /// Obtiene el detalle de ubicación apropiado
  String getLocationDetail({String? userDeclaredAddress, String? alternativeAddress}) {
    switch (source) {
      case LocationSource.catalog:
        return name;
      case LocationSource.declaredAddress:
        return userDeclaredAddress ?? 'Domicilio Declarado';
      case LocationSource.alternativeAddress:
        return alternativeAddress ?? '';
    }
  }

  @override
  String toString() {
    return 'LocationOption(id: $id, name: $name, source: $source)';
  }
}

/// Fuente de una ubicación
enum LocationSource {
  catalog,           // Ubicación desde catálogo (oficinas, clientes)
  declaredAddress,   // Domicilio declarado del usuario  
  alternativeAddress // Domicilio alternativo especificado
}
