# 📝 Guía de Migración - Actualizar Vistas Existentes

## Problema

Las vistas existentes están importando archivos de providers que no existen:
- `auth_provider.dart`
- `attendance_provider.dart`
- `admin_provider.dart`
- `schedule_provider.dart`
- `organization_provider.dart`
- `biometric_provider.dart`

Y usando nombres de providers antiguos como:
- `currentUserProfileProvider`
- `adminDashboardStatsProvider`
- `activeShiftProvider` (sin importar de app_providers)
- etc.

## ✅ Solución

Reemplaza todos los imports de providers individuales con:

```dart
import 'package:puntocheck/providers/app_providers.dart';
```

## 🔄 Mapeo de Providers Antiguos → Nuevos

| Archivo Antiguo | Provider Antiguo | Nuevo Provider | En Archivo |
|---|---|---|---|
| `auth_provider.dart` | `currentUserProfileProvider` | `profileProvider` | `app_providers.dart` |
| | `authControllerProvider` | `authControllerProvider` | ✅ Igual |
| | `authStateProvider` | `authStateProvider` | ✅ Igual |
| | `currentUserProvider` | `currentUserProvider` | ✅ Igual |
| `attendance_provider.dart` | `activeShiftProvider` | `activeShiftProvider` | ✅ Igual |
| | `attendanceHistoryProvider` | `attendanceHistoryProvider` | ✅ Igual |
| | `todayStatsProvider` | `todayStatsProvider` | ✅ Igual |
| | `attendanceControllerProvider` | `attendanceControllerProvider` | ✅ Igual |
| `admin_provider.dart` | `adminDashboardStatsProvider` | ❌ NO EXISTE |
| | `orgEmployeesProvider` | ❌ NO EXISTE |
| `schedule_provider.dart` | `scheduleControllerProvider` | `scheduleControllerProvider` | ✅ Igual |
| | `myScheduleProvider` | `myScheduleProvider` | ✅ Igual |
| `organization_provider.dart` | `organizationControllerProvider` | `organizationControllerProvider` | ✅ Igual |
| | `currentOrganizationProvider` | `currentOrganizationProvider` | ✅ Igual |
| `biometric_provider.dart` | `biometricControllerProvider` | `biometricControllerProvider` | ✅ Igual |

## 🔧 Ejemplos de Actualización

### Antes:
```dart
import 'package:puntocheck/providers/auth_provider.dart';
import 'package:puntocheck/providers/attendance_provider.dart';
import 'package:puntocheck/providers/admin_provider.dart';

class MyView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentUserProfileProvider);
    final stats = ref.watch(adminDashboardStatsProvider);
    final activeShift = ref.watch(activeShiftProvider);
  }
}
```

### Después:
```dart
import 'package:puntocheck/providers/app_providers.dart';

class MyView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    // adminDashboardStatsProvider: CREAR NUEVO si lo necesitas
    final activeShift = ref.watch(activeShiftProvider);
  }
}
```

## 📝 Actualización por Vista

### 1. **admin_home_view.dart**
```dart
// QUITAR:
- import 'package:puntocheck/providers/auth_provider.dart';
- import 'package:puntocheck/providers/admin_provider.dart';

// AÑADIR:
+ import 'package:puntocheck/providers/app_providers.dart';

// CAMBIAR:
- final statsAsync = ref.watch(adminDashboardStatsProvider);
+ // Crear provider adminStatsProvider si lo necesitas
+ // Por ahora puedes usar directamente organizationControllerProvider

- final profileAsync = ref.watch(currentUserProfileProvider);
+ final profileAsync = ref.watch(profileProvider);

// CAMBIAR navegación:
- Navigator.pushNamed(context, AppRouter.adminNuevoEmpleado);
+ context.go('/admin/home/nuevo-empleado');
```

### 2. **employee_home_view.dart**
```dart
// QUITAR:
- import 'package:puntocheck/providers/auth_provider.dart';
- import 'package:puntocheck/providers/attendance_provider.dart';

// AÑADIR:
+ import 'package:puntocheck/providers/app_providers.dart';

// CAMBIAR:
- final profileAsync = ref.watch(currentUserProfileProvider);
+ final profileAsync = ref.watch(profileProvider);

- final activeShiftAsync = ref.watch(activeShiftProvider);
+ final activeShiftAsync = ref.watch(activeShiftProvider); // ✅ Ya está bien

// CAMBIAR navegación:
- Navigator.pushNamed(context, AppRouter.employeeRegistroAsistencia);
+ context.go('/employee/home/registro-asistencia');
```

### 3. **registro_asistencia_view.dart**
```dart
// QUITAR:
- import 'package:puntocheck/providers/attendance_provider.dart';

// AÑADIR:
+ import 'package:puntocheck/providers/app_providers.dart';

// TODO: ref.read(attendanceControllerProvider.notifier) ya está disponible
```

### 4. **login_view.dart**
```dart
// QUITAR:
- import 'package:puntocheck/providers/auth_provider.dart';
- import 'package:puntocheck/providers/biometric_provider.dart';

// AÑADIR:
+ import 'package:puntocheck/providers/app_providers.dart';

// TODO: authControllerProvider ya está disponible
// TODO: biometricControllerProvider ya está disponible
```

### 5. **settings_view.dart**
```dart
// CAMBIAR navegación:
- Navigator.pushNamed(context, AppRouter.employeePersonalInfo);
+ context.go('/employee/home/personal-info');

- AppRouter.login
+ context.go('/login');
```

### 6. **horario_admin_view.dart**
```dart
// QUITAR:
- import 'package:puntocheck/providers/schedule_provider.dart';
- import 'package:puntocheck/providers/auth_provider.dart';

// AÑADIR:
+ import 'package:puntocheck/providers/app_providers.dart';

// CAMBIAR:
- final profile = await ref.read(currentUserProfileProvider.future);
+ final profile = await ref.read(profileProvider.future);

- final scheduleController = ref.read(scheduleControllerProvider.notifier);
+ final scheduleController = ref.read(scheduleControllerProvider.notifier); // ✅ OK
```

### 7. **apariencia_app_view.dart**
```dart
// QUITAR:
- import 'package:puntocheck/providers/organization_provider.dart';
- import 'package:puntocheck/providers/auth_provider.dart';

// AÑADIR:
+ import 'package:puntocheck/providers/app_providers.dart';

// CAMBIAR:
- final profile = await ref.read(currentUserProfileProvider.future);
+ final profile = await ref.read(profileProvider.future);

- final controller = ref.read(organizationControllerProvider.notifier);
+ final controller = ref.read(organizationControllerProvider.notifier); // ✅ OK
```

### 8. **empleados_list_view.dart**
```dart
// QUITAR:
- import 'package:puntocheck/providers/admin_provider.dart';

// AÑADIR:
+ import 'package:puntocheck/providers/app_providers.dart';

// CAMBIAR:
- final employeesAsync = ref.watch(orgEmployeesProvider);
+ // Necesitas crear un empleadosProvider en app_providers.dart
+ // Por ahora, muestra un placeholder
```

### 9. **employee_home_cards.dart**
```dart
// QUITAR:
- import 'package:puntocheck/providers/attendance_provider.dart';

// AÑADIR:
+ import 'package:puntocheck/providers/app_providers.dart';

// CAMBIAR:
- final statsAsync = ref.watch(todayStatsProvider);
+ final statsAsync = ref.watch(todayStatsProvider); // ✅ Ya está disponible

- final historyAsync = ref.watch(attendanceHistoryProvider);
+ final historyAsync = ref.watch(attendanceHistoryProvider); // ✅ Ya está disponible
```

## 🚀 Pasos de Actualización (Automático)

Si quieres actualizar todas las vistas automáticamente, ejecuta estos comandos en tu terminal:

```bash
cd app/puntocheck

# Buscar y reemplazar en todas las vistas
find lib/presentation -name "*.dart" -exec sed -i \
  's|package:puntocheck/providers/auth_provider\.dart|package:puntocheck/providers/app_providers.dart|g' {} \;

find lib/presentation -name "*.dart" -exec sed -i \
  's|package:puntocheck/providers/attendance_provider\.dart|package:puntocheck/providers/app_providers.dart|g' {} \;

find lib/presentation -name "*.dart" -exec sed -i \
  's|package:puntocheck/providers/admin_provider\.dart|package:puntocheck/providers/app_providers.dart|g' {} \;

find lib/presentation -name "*.dart" -exec sed -i \
  's|package:puntocheck/providers/schedule_provider\.dart|package:puntocheck/providers/app_providers.dart|g' {} \;

find lib/presentation -name "*.dart" -exec sed -i \
  's|package:puntocheck/providers/organization_provider\.dart|package:puntocheck/providers/app_providers.dart|g' {} \;

find lib/presentation -name "*.dart" -exec sed -i \
  's|package:puntocheck/providers/biometric_provider\.dart|package:puntocheck/providers/app_providers.dart|g' {} \;

# Reemplazar currentUserProfileProvider por profileProvider
find lib/presentation -name "*.dart" -exec sed -i \
  's/currentUserProfileProvider/profileProvider/g' {} \;
```

## ⚠️ Providers Faltantes que Necesitas Crear

Algunos providers se usan en las vistas pero no existen en `app_providers.dart`. Aquí está cómo crearlos:

### `adminDashboardStatsProvider`
```dart
// En app_providers.dart
final adminDashboardStatsProvider = 
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final orgState = ref.watch(currentOrganizationProvider);
  
  return orgState.whenData((org) {
    if (org == null) return {};
    
    // Aquí harías llamadas a los servicios para obtener estadísticas
    return {
      'total_employees': 0,
      'active_today': 0,
      'late_today': 0,
      'absent_today': 0,
    };
  }).value ?? {};
});
```

### `orgEmployeesProvider`
```dart
// En app_providers.dart
final orgEmployeesProvider = 
    FutureProvider.autoDispose<List<Profile>>((ref) async {
  // Necesitarías crear un método en OrganizationService
  // que obtenga todos los empleados de la organización
  return []; // Por ahora retorna lista vacía
});
```

## ✅ Checklist de Actualización

- [ ] Reemplazar todos los imports de providers antiguos
- [ ] Cambiar `currentUserProfileProvider` → `profileProvider`
- [ ] Cambiar `AppRouter.*` → `context.go()` o `context.push()`
- [ ] Verificar que todos los providers usados existen en `app_providers.dart`
- [ ] Crear providers faltantes si es necesario
- [ ] Correr `flutter pub get`
- [ ] Correr `flutter analyze` para verificar errores
- [ ] Testear cada vista

## 📞 Necesitas Ayuda?

Si algunas vistas usan providers específicos que no existen:

1. Mira la documentación en `PROVIDERS_GUIDE.md`
2. Revisa `EXAMPLES_PROVIDERS.md` para ver patrones
3. Crea el provider necesario en `app_providers.dart`
4. Importa desde `app_providers.dart`

---

**Última actualización**: Noviembre 2025
