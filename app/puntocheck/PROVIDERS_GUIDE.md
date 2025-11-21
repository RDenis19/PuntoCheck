# Guía de Providers y Rutas - PuntoCheck

## 📋 Descripción General

Este documento describe la arquitectura de **Riverpod Providers** y **Go Router** para PuntoCheck. Los providers actúan como intermediarios entre la interfaz de usuario (UI) y los servicios, proporcionando una forma limpia y reactividad para acceder a los datos.

---

## 🏗️ Arquitectura de Capas

```
┌─────────────────────────────────────┐
│        PRESENTATION (UI)            │
│   (Widgets y Vistas en Flutter)    │
└────────────┬──────────────────────┘
             │
┌────────────▼──────────────────────┐
│      PROVIDERS (RIVERPOD)          │
│  (Controladores de Estado)        │
│  - Controllers (AsyncNotifier)    │
│  - Future/Stream Providers        │
└────────────┬──────────────────────┘
             │
┌────────────▼──────────────────────┐
│      SERVICES (Lógica)            │
│  - AuthService                    │
│  - AttendanceService              │
│  - NotificationService            │
│  - etc...                          │
└────────────┬──────────────────────┘
             │
┌────────────▼──────────────────────┐
│   SUPABASE (Backend)              │
│   - Autenticación                 │
│   - Base de Datos                 │
│   - Storage                       │
└─────────────────────────────────────┘
```

---

## 🔐 Autenticación (Auth)

### Providers Disponibles

#### `authStateProvider` (StreamProvider)
- **Tipo**: `Stream<AuthState>`
- **Descripción**: Stream del estado de autenticación desde Supabase
- **Uso**: Observar cambios de sesión en tiempo real
- **Ejemplo**:
  ```dart
  final authState = ref.watch(authStateProvider);
  
  if (authState.isLoading) {
    return const LoadingWidget();
  }
  
  if (authState.hasError) {
    return const ErrorWidget();
  }
  
  final isLoggedIn = authState.value?.session != null;
  ```

#### `currentUserProvider` (Provider)
- **Tipo**: `User?`
- **Descripción**: Usuario actual desde Supabase Auth
- **Uso**: Acceder a los datos del usuario autenticado
- **Ejemplo**:
  ```dart
  final user = ref.watch(currentUserProvider);
  if (user != null) {
    print('Email: ${user.email}');
    print('ID: ${user.id}');
  }
  ```

#### `authControllerProvider` (AsyncNotifierProvider)
- **Tipo**: `AsyncNotifier<void>`
- **Métodos**:
  - `signIn(String email, String password)` - Inicia sesión
  - `signUp(...)` - Registra nuevo usuario
  - `signOut()` - Cierra sesión
  - `resetPassword(String email)` - Inicia recuperación de contraseña
- **Uso**: Ejecutar acciones de autenticación desde la UI
- **Ejemplo**:
  ```dart
  // En un formulario de login
  final authController = ref.read(authControllerProvider.notifier);
  
  try {
    await authController.signIn(email, password);
    // El router automáticamente redirigirá al usuario logueado
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
  ```

---

## 👤 Perfil de Usuario (Profile)

### Providers Disponibles

#### `profileProvider` (AsyncNotifierProvider)
- **Tipo**: `AsyncNotifier<Profile?>`
- **Descripción**: Carga y mantiene el perfil del usuario actual
- **Métodos**:
  - `refresh()` - Refresca el perfil desde la BD
  - `updateProfile(Profile)` - Actualiza datos del perfil
  - `uploadAvatar(File)` - Sube un avatar y actualiza el perfil
- **Uso**: Acceder y actualizar información del perfil
- **Ejemplo**:
  ```dart
  // Leer el perfil
  final profileState = ref.watch(profileProvider);
  
  profileState.when(
    data: (profile) {
      if (profile == null) return const Text('Sin perfil');
      
      return Column(
        children: [
          if (profile.avatarUrl != null)
            Image.network(profile.avatarUrl!),
          Text('Nombre: ${profile.fullName}'),
          Text('Código: ${profile.employeeCode}'),
          Text('Rol: ${profile.jobTitle}'),
        ],
      );
    },
    loading: () => const CircularProgressIndicator(),
    error: (err, st) => Text('Error: $err'),
  );
  ```

#### Actualizar Perfil
```dart
final profileController = ref.read(profileProvider.notifier);

final updatedProfile = profile.copyWith(
  fullName: 'Nuevo Nombre',
  phone: '+34123456789',
);

await profileController.updateProfile(updatedProfile);
```

#### Subir Avatar
```dart
final profileController = ref.read(profileProvider.notifier);

// Seleccionar imagen con image_picker
final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);

if (pickedFile != null) {
  await profileController.uploadAvatar(File(pickedFile.path));
}
```

---

## 🏢 Organización (Organization)

### Providers Disponibles

#### `currentOrganizationProvider` (FutureProvider)
- **Tipo**: `Future<Organization?>`
- **Descripción**: Obtiene la organización del usuario actual
- **Uso**: Acceder a datos de la empresa
- **Ejemplo**:
  ```dart
  final orgState = ref.watch(currentOrganizationProvider);
  
  orgState.whenData((org) {
    if (org != null) {
      print('Empresa: ${org.name}');
      print('Sector: ${org.industry}');
    }
  });
  ```

#### `allOrganizationsProvider` (FutureProvider)
- **Tipo**: `Future<List<Organization>>`
- **Uso**: Solo para SUPERADMIN - listar todas las organizaciones
- **Ejemplo**:
  ```dart
  final orgsState = ref.watch(allOrganizationsProvider);
  
  orgsState.whenData((orgs) {
    return ListView.builder(
      itemCount: orgs.length,
      itemBuilder: (_, i) => ListTile(
        title: Text(orgs[i].name),
      ),
    );
  });
  ```

#### `organizationControllerProvider`
- **Métodos**:
  - `updateOrgConfig(String orgId, Map<String, dynamic>)` - Actualiza configuración
- **Uso**: Ejecutar acciones administrativas
- **Ejemplo**:
  ```dart
  final orgController = ref.read(organizationControllerProvider.notifier);
  
  await orgController.updateOrgConfig(orgId, {
    'name': 'Nuevo nombre',
    'timezone': 'Europe/Madrid',
  });
  ```

---

## ✅ Asistencia (Attendance)

### Providers Disponibles

#### `activeShiftProvider` (FutureProvider)
- **Tipo**: `Future<WorkShift?>`
- **Descripción**: Obtiene el turno activo del día (si existe)
- **Uso**: Saber si el usuario ya ha hecho check-in
- **Ejemplo**:
  ```dart
  final activeShift = ref.watch(activeShiftProvider);
  
  activeShift.whenData((shift) {
    if (shift != null) {
      return Text('Entrada: ${shift.checkInTime}');
    } else {
      return const Text('No has hecho check-in hoy');
    }
  });
  ```

#### `attendanceHistoryProvider` (FutureProvider)
- **Tipo**: `Future<List<WorkShift>>`
- **Descripción**: Historial de asistencia del usuario
- **Uso**: Mostrar lista de asistencias pasadas
- **Ejemplo**:
  ```dart
  final history = ref.watch(attendanceHistoryProvider);
  
  history.whenData((shifts) {
    return ListView.builder(
      itemCount: shifts.length,
      itemBuilder: (_, i) {
        final shift = shifts[i];
        return ListTile(
          title: Text('${shift.date}'),
          subtitle: Text('Entrada: ${shift.checkInTime} - Salida: ${shift.checkOutTime}'),
        );
      },
    );
  });
  ```

#### `todayStatsProvider` (FutureProvider)
- **Tipo**: `Future<Map<String, dynamic>>`
- **Descripción**: Estadísticas de hoy (horas trabajadas, etc.)
- **Uso**: Mostrar resumen del día

#### `attendanceControllerProvider` (AsyncNotifierProvider)
- **Métodos**:
  - `checkIn({required GeoLocation location, required File photoFile, required String orgId, String? address})` - Registra entrada
  - `checkOut({required String shiftId, required GeoLocation location, required String orgId, File? photoFile, String? address})` - Registra salida
- **Uso**: Registrar check-in/check-out
- **Ejemplo**:
  ```dart
  final attendanceController = ref.read(attendanceControllerProvider.notifier);
  final profile = ref.watch(profileProvider).value;
  
  if (profile != null) {
    // Obtener ubicación
    final location = await LocationHelper.getCurrentLocation();
    
    // Obtener foto
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    
    if (photo != null) {
      await attendanceController.checkIn(
        location: location,
        photoFile: File(photo.path),
        orgId: profile.organizationId!,
        address: 'Oficina Principal',
      );
    }
  }
  ```

---

## 🔔 Notificaciones (Notifications)

### Providers Disponibles

#### `notificationsStreamProvider` (StreamProvider)
- **Tipo**: `Stream<List<AppNotification>>`
- **Descripción**: Stream en tiempo real de notificaciones
- **Uso**: Mostrar lista de notificaciones actual
- **Ejemplo**:
  ```dart
  final notifications = ref.watch(notificationsStreamProvider);
  
  notifications.when(
    data: (notifs) => ListView.builder(
      itemCount: notifs.length,
      itemBuilder: (_, i) => NotificationCard(notification: notifs[i]),
    ),
    loading: () => const CircularProgressIndicator(),
    error: (err, _) => Text('Error: $err'),
  );
  ```

#### `unreadNotificationsCountProvider` (Provider)
- **Tipo**: `int`
- **Descripción**: Cantidad de notificaciones no leídas
- **Uso**: Mostrar badge con contador
- **Ejemplo**:
  ```dart
  final unreadCount = ref.watch(unreadNotificationsCountProvider);
  
  return Badge(
    label: Text('$unreadCount'),
    child: Icon(Icons.notifications),
  );
  ```

#### `notificationControllerProvider`
- **Métodos**:
  - `markAsRead(String id)` - Marca una notificación como leída
  - `markAllAsRead()` - Marca todas como leídas
- **Ejemplo**:
  ```dart
  final notifController = ref.read(notificationControllerProvider.notifier);
  
  await notifController.markAsRead(notificationId);
  ```

---

## 📅 Horarios (Schedules)

### Providers Disponibles

#### `myScheduleProvider` (FutureProvider)
- **Tipo**: `Future<List<WorkSchedule>>`
- **Descripción**: Obtiene el horario semanal del usuario
- **Uso**: Mostrar horario de trabajo
- **Ejemplo**:
  ```dart
  final schedule = ref.watch(myScheduleProvider);
  
  schedule.whenData((schedules) {
    final monday = schedules.firstWhere((s) => s.dayOfWeek == 1);
    print('Lunes: ${monday.startTime} - ${monday.endTime}');
  });
  ```

#### `scheduleControllerProvider`
- **Métodos**:
  - `createSchedule(WorkSchedule)` - Crea un nuevo horario (Admin)
- **Uso**: Administradores creando horarios

---

## 🔒 Rutas Protegidas (Go Router)

El sistema de routing está completamente integrado con Riverpod. Las rutas se protegen automáticamente basándose en el estado de autenticación y el rol del usuario.

### Estructura de Rutas

```
/                                    # Splash (Público)
├── /login                           # Login (Público)
├── /register                        # Registro (Público)
└── /forgot/*                        # Recuperación contraseña (Público)

/employee/home                       # Dashboard Empleado (Protegido)
├── /registro-asistencia            # Check-in/Check-out
├── /horario-trabajo                # Ver horario
├── /historial                      # Historial de asistencia
├── /avisos                         # Notificaciones
├── /settings                       # Configuración
└── /personal-info                  # Información personal

/admin/home                         # Dashboard Admin (Protegido - Admin)
├── /nuevo-empleado                # Crear empleado
├── /empleados                      # Listar empleados
├── /empleado-detalle/:id          # Detalle de empleado
├── /horario                        # Gestionar horarios
├── /anuncios                       # Listar anuncios
├── /anuncios/nuevo                # Crear anuncio
└── /apariencia-app                # Configuración visual

/superadmin/home                    # Dashboard SuperAdmin (Protegido - SuperAdmin)
├── /organizaciones                 # Listar organizaciones
├── /organizacion-detalle           # Detalle de organización
└── /config-global                  # Configuración global
```

### Lógica de Redirección

El router automáticamente:

1. **Redirige a Login** si intentas acceder a rutas protegidas sin autenticación
2. **Redirige al Dashboard** si intentas acceder a login/splash ya estando logueado
3. **Protege por Rol**:
   - Empleados NO pueden acceder a `/admin/*` ni `/superadmin/*`
   - Admins pueden acceder a `/admin/*` y `/employee/*`
   - SuperAdmins pueden acceder a todas las rutas

### Navegación desde la UI

#### Navegar a una Ruta
```dart
context.go('/employee/home');
context.push('/employee/home/registro-asistencia');
```

#### Con Parámetros
```dart
context.go('/admin/home/empleado-detalle/$employeeId');
```

#### Con Nombres de Rutas (Type-Safe)
```dart
context.goNamed('registroAsistencia');
context.goNamed('empleadoDetalle', pathParameters: {'id': employeeId});
```

---

## 🎯 Patrones de Uso en Vistas

### Patrón: Carga de Datos
```dart
class MyView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataState = ref.watch(someProvider);
    
    return dataState.when(
      data: (data) => MyWidget(data: data),
      loading: () => const CircularProgressIndicator(),
      error: (error, stackTrace) => ErrorWidget(error: error),
    );
  }
}
```

### Patrón: Acciones con Controller
```dart
class MyActionWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        final controller = ref.read(someControllerProvider.notifier);
        
        try {
          await controller.doSomething();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Éxito!')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        }
      },
      child: const Text('Hacer algo'),
    );
  }
}
```

### Patrón: Invalidar Datos (Refrescar)
```dart
// Después de actualizar algo, refrescar los datos
ref.invalidate(someProvider);

// O refrescar de forma más granular
ref.invalidate(attendanceHistoryProvider);
ref.invalidate(activeShiftProvider);
```

---

## 📱 Servicios Disponibles

Todos estos servicios se inyectan automáticamente via Riverpod:

- **AuthService**: Autenticación con Supabase
- **AttendanceService**: Gestión de asistencia
- **OrganizationService**: Datos de la organización
- **StorageService**: Subida de archivos
- **NotificationService**: Gestión de notificaciones
- **ScheduleService**: Gestión de horarios
- **BiometricService**: Autenticación biométrica

---

## 🔄 Flujo Completo: Login → Dashboard

```
1. Usuario entra a la app
   └─> Router ve authState.isLoading
   └─> Muestra Splash

2. Supabase termina de cargar el estado
   └─> Si NO está logueado: Redirige a /login
   └─> Si está logueado: Carga el perfil

3. Perfil se carga
   └─> Router ve el rol del usuario
   └─> Redirige al dashboard correspondiente
   
4. Si es Admin:
   └─> Redirige a /admin/home
   └─> UI muestra AdminShellView
   └─> Providers cargan datos de la organización

5. Si es Empleado:
   └─> Redirige a /employee/home
   └─> UI muestra EmployeeHomeView
   └─> Providers cargan asistencia y notificaciones
```

---

## ⚠️ Errores Comunes

### Error 1: "Esperaba watching un provider, pero no está disponible"
**Solución**: Asegúrate de que el provider está importado correctamente y que lo estás using dentro de un `ConsumerWidget`.

### Error 2: "El usuario está null cuando lo necesito"
**Solución**: Siempre verifica que `currentUserProvider` no sea null antes de usarlo:
```dart
final user = ref.watch(currentUserProvider);
if (user == null) return const LoginView();
```

### Error 3: "Las rutas no se actualizan después de cambios"
**Solución**: Invalida los providers relacionados después de cambios:
```dart
await controller.updateData();
ref.invalidate(myDataProvider);
```

---

## 🚀 Tips de Rendimiento

1. **Usa `autoDispose`** para providers que consumen recursos:
   ```dart
   final provider = FutureProvider.autoDispose<Data>(...);
   ```

2. **Invalida selectivamente**, no todo:
   ```dart
   // Bueno: Solo invalida lo que cambió
   ref.invalidate(activeShiftProvider);
   
   // Malo: Invalida todo
   ref.invalidateAll();
   ```

3. **Usa `select`** para escuchar solo partes específicas:
   ```dart
   // Solo notifica cambios si unreadCount cambia
   final count = ref.watch(
     notificationsStreamProvider.select(
       (notifications) => notifications.whenData(
         (notifs) => notifs.where((n) => !n.isRead).length
       )
     )
   );
   ```

---

## 📚 Referencias

- [Riverpod Documentation](https://riverpod.dev)
- [Go Router Documentation](https://pub.dev/packages/go_router)
- [Supabase Flutter Documentation](https://supabase.com/docs/reference/flutter/overview)

---

**Última actualización**: Noviembre 2025
**Mantenido por**: Equipo PuntoCheck
