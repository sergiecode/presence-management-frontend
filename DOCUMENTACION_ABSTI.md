# 📱 ABSTI - Sistema de Asistencia Laboral

## 🏢 **Información General**

**ABSTI** es una aplicación móvil desarrollada en Flutter para la gestión y control de asistencia laboral. Permite a los empleados registrar su entrada y salida del trabajo (check-in/check-out), gestionar solicitudes de ausencias, y proporciona a los administradores herramientas para supervisar y gestionar la asistencia del personal.

### **Características Principales**

- ✅ **Sistema de Check-in/Check-out** (sin geolocalización GPS)
- ✅ **Gestión de ausencias y permisos**
- ✅ **Notificaciones automáticas de recordatorio**
- ✅ **Historial completo de asistencia**
- ✅ **Autenticación segura con tokens**
- ✅ **Configuración personalizable por usuario**

---

## 🔧 **Arquitectura y Tecnologías**

### **Framework y Dependencias Principales**

```yaml
dependencies:
  flutter: ^3.24.5
  provider: ^6.1.2 # Gestión de estado
  http: ^1.2.2 # Comunicación HTTP
  shared_preferences: ^2.3.2 # Almacenamiento local
  flutter_local_notifications: ^17.2.3 # Notificaciones locales
  timezone: ^0.9.4 # Manejo de zonas horarias
  permission_handler: ^11.3.1 # Permisos del sistema
  image_picker: ^1.1.2 # Selección de imágenes
```

### **Estructura del Proyecto**

```
lib/
├── main.dart                       # Punto de entrada
├── core/                          # Configuraciones centrales
│   ├── constants/                 # Constantes de la app
│   └── themes/                    # Temas y estilos
├── data/                          # Capa de datos
│   ├── providers/                 # Proveedores de estado
│   └── services/                  # Servicios de comunicación
├── presentation/                  # Capa de presentación
│   ├── atoms/                     # Componentes básicos
│   ├── molecules/                 # Componentes medianos
│   ├── organisms/                 # Componentes complejos
│   ├── pages/                     # Pantallas principales
│   └── routes/                    # Rutas y navegación
└── assets/                        # Recursos estáticos
```

---

## 🔑 **Funcionalidades Principales**

### **1. Autenticación y Seguridad**

- **Login seguro** con email y contraseña
- **Registro de nuevos usuarios** con validación
- **Tokens JWT** para autenticación persistente
- **Rutas protegidas** que requieren autenticación
- **Logout automático** al expirar token

### **2. Sistema de Check-in/Check-out**

#### **Check-in (Entrada)**

- Registro de hora de entrada con timestamp preciso
- Selección de ubicación de trabajo (Oficina, Domicilio, Cliente, Otro)
- Detección automática de llegadas tardías
- Validación contra horario configurado del usuario
- Envío de datos: `user_id`, `date`, `time`, `location_type`, `late_reason`
- **Nota**: Actualmente usa coordenadas GPS fijas (0.0, 0.0) para compatibilidad con backend

#### **Check-out (Salida)**

- Registro de hora de salida
- Cálculo automático de horas trabajadas
- Detección de horas extra (overtime)
- Finalización de jornada laboral
- Actualización de estado a "completed"

#### **Estados de Trabajo**

- **No trabajando**: Sin check-in activo
- **Trabajando**: Check-in realizado, sin check-out
- **Día completado**: Check-in y check-out realizados

### **3. Gestión de Ausencias**

#### **Tipos de Ausencias Soportadas**

- **Vacaciones**: Días de descanso programados
- **Enfermedad**: Ausencias por motivos médicos
- **Personal**: Asuntos personales
- **Familiar**: Emergencias o asuntos familiares
- **Capacitación**: Formación y desarrollo profesional
- **Otro**: Motivos diversos

#### **Flujo de Solicitudes**

1. **Creación**: El empleado crea una solicitud
2. **Revisión**: Supervisor revisa la solicitud
3. **Aprobación/Rechazo**: Decisión final con comentarios
4. **Notificación**: El empleado recibe la respuesta

### **4. Sistema de Notificaciones**

#### **Recordatorios de Check-in**

- ✅ **Notificaciones programadas** diariamente
- ✅ **Configuración personalizable** (0, 5, 10, 15, 30, 60 minutos antes)
- ✅ **Mensajes personalizados** con nombre del usuario
- ✅ **Gestión automática** de permisos (Android/iOS)

#### **Ejemplo de Notificación**

```
🕒 Recordatorio de Check-in
¡Hola Juan Pérez! Tu check-in es en 15 minutos (09:00).
¡No olvides registrar tu entrada!
```

#### **Configuración Técnica**

- **Android**: Canal de notificaciones de alta prioridad
- **iOS**: Alertas, sonidos y badges habilitados
- **Repetición**: Diaria a la hora configurada
- **Cancelación**: Automática si se desactivan

### **5. Historial y Reportes**

#### **Vista del Empleado**

- Historial completo de check-ins y check-outs
- Filtros por fecha y estado
- Estadísticas básicas de asistencia
- Resumen de horas trabajadas
- Estado de solicitudes de ausencia

**Nota**: La vista de supervisor/administrador no está implementada actualmente.

### **6. Configuración de Usuario**

#### **Perfil Personal**

- Información básica (nombre, apellido, teléfono)
- Foto de perfil con selección desde galería/cámara
- Zona horaria personalizada
- Configuración de recordatorios

#### **Configuración Laboral**

- Hora de inicio de jornada personalizada
- Configuración de notificaciones
- Preferencias de ubicación de trabajo

---

## 🏗️ **Detalles Técnicos**

### **Gestión de Estado**

**Provider Pattern** para manejo centralizado:

- `AuthProvider`: Autenticación y estado de usuario
- Estado local con `setState()` para UI específica
- Persistencia con `SharedPreferences`

### **Comunicación con Backend**

#### **Servicios Principales**

- `AuthService`: Login, registro, renovación de tokens
- `CheckInService`: Gestión de check-in/check-out
- `UserService`: Datos de usuario y configuración
- `AbsenceService`: Gestión de solicitudes de ausencia
- `NotificationService`: Notificaciones locales

#### **Endpoints Principales**

```
POST /api/auth/login           # Autenticación
POST /api/auth/register        # Registro
POST /api/checkins            # Check-in
POST /api/checkins/checkout   # Check-out
GET  /api/checkins/today      # Check-in del día
GET  /api/users/me            # Datos del usuario
PUT  /api/users/me            # Actualizar perfil
```

### **Manejo de Errores**

- **Validación en tiempo real** en formularios
- **Mensajes de error claros** para el usuario
- **Fallbacks** para conexión perdida
- **Logs detallados** para debugging
- **Recuperación automática** de estados inconsistentes

---

## 🔐 **Seguridad**

### **Autenticación**

- Tokens JWT con expiración automática
- Renovación automática de tokens
- Logout seguro con limpieza de datos locales
- Validación de tokens en cada request

### **Datos Sensibles**

- Almacenamiento seguro de tokens
- No persistencia de contraseñas
- Validación de entrada de datos
- Sanitización de datos enviados al backend

---

### **Compatibilidad**

### **Plataformas Soportadas**

- ✅ **Android** (API 21+)
- ✅ **iOS** (iOS 11.0+)
- ⚠️ **Web** (funcionalidad básica, sin notificaciones)

### **Permisos Requeridos**

#### **Android**

- `android.permission.INTERNET` - Conexión a internet
- `android.permission.POST_NOTIFICATIONS` - Notificaciones (API 33+)
- `android.permission.CAMERA` - Cámara para fotos de perfil
- `android.permission.READ_EXTERNAL_STORAGE` - Acceso a galería

**Nota**: Los permisos de ubicación GPS no están implementados actualmente.

#### **iOS**

- NSCameraUsageDescription - Uso de cámara
- NSPhotoLibraryUsageDescription - Acceso a galería
- Permisos de notificaciones gestionados automáticamente

---

## 🚀 **Instalación y Configuración**

### **Requisitos Previos**

```bash
flutter --version  # Flutter 3.24.5 o superior
dart --version     # Dart 3.5.4 o superior
```

### **Instalación**

```bash
# Clonar proyecto
git clone [repository-url]
cd assistance_app

# Instalar dependencias
flutter pub get

# Generar archivos
flutter packages pub run build_runner build

# Ejecutar en dispositivo
flutter run
```

### **Configuración de Backend**

Actualizar la URL del backend en:

```dart
// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'https://your-api-domain.com';
}
```

---

## 🧪 **Testing y Debugging**

### **Funciones de Debug**

- **Logs detallados** en toda la aplicación
- **Estados de debug** visibles en consola
- **Información de conexión** en tiempo real
- **Validación de datos** en check-in/check-out

**Nota**: La página de pruebas de notificaciones fue eliminada tras completar las pruebas.

### **Testing Manual**

1. **Test de Login**: Verificar autenticación
2. **Test de Check-in**: Probar registro de entrada
3. **Test de Notificaciones**: Verificar recordatorios
4. **Test de Ausencias**: Crear y gestionar solicitudes
5. **Test de Conectividad**: Probar comportamiento sin internet

**Nota**: Los tests automatizados no están completamente implementados.

---

## 📈 **Estado del Proyecto**

### **✅ Funcionalidades Completadas**

- [x] Sistema de autenticación completo
- [x] Check-in/check-out robusto con validaciones
- [x] Sistema de notificaciones locales funcional
- [x] Gestión completa de ausencias
- [x] Historial y reportes básicos
- [x] Configuración de usuario avanzada
- [x] UI/UX mejorada y consistente

### **❌ Funcionalidades NO Implementadas (mencionadas anteriormente)**

- [ ] Panel de administración para supervisores
- [ ] Geolocalización GPS real
- [ ] Reportes con gráficos y estadísticas avanzadas
- [ ] Editor avanzado de imágenes
- [ ] Modo offline
- [ ] Integración con calendarios externos

### **⚠️ Limitaciones Actuales**

- **GPS**: La app usa coordenadas fijas (0.0, 0.0) por compatibilidad con backend
- **Roles**: Aunque se manejan roles de usuario (admin, employee, supervisor), no hay interfaces diferenciadas
- **Web**: Soporte limitado, sin notificaciones locales
- **Tests**: Tests automatizados mínimos, principalmente testing manual
- **Offline**: Requiere conexión a internet para todas las operaciones

### **🔄 Mejoras Implementadas Recientemente**

- [x] Corrección de errores en check-in (campos user_id y late_reason)
- [x] Eliminación de configuración de ubicación GPS no funcional
- [x] Sistema completo de notificaciones locales
- [x] Limpieza de código y reducción de warnings
- [x] Documentación consolidada y actualizada

### **🎯 Próximas Mejoras Sugeridas**

- [ ] Implementación real de GPS para ubicación automática
- [ ] Panel de administración para supervisores y managers
- [ ] Modo offline con sincronización diferida
- [ ] Reportes avanzados con gráficos y estadísticas
- [ ] Integración con calendarios externos
- [ ] Notificaciones push desde backend
- [ ] Editor avanzado de imágenes de perfil

---

## 👥 **Equipo de Desarrollo**

**Desarrollado por**: Equipo ABSTI  
**Año**: 2025  
**Tecnología Principal**: Flutter/Dart  
**Arquitectura**: Clean Architecture con Provider

---

## 📞 **Soporte**

Para soporte técnico o reportar bugs:

- Revisar logs de la aplicación
- Utilizar la página de pruebas integrada
- Verificar conectividad y permisos
- Contactar al equipo de desarrollo

---

**Versión de Documentación**: 1.1  
**Última Actualización**: Enero 2025  
**Estado**: Documentación sincronizada con código real implementado
