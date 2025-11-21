# 🚀 Configuración de Providers y Rutas - Guía Rápida

## ✅ Lo que se ha configurado

### 1. **Providers (Riverpod)** - `lib/providers/app_providers.dart`
Archivo centralizado con todos los providers de la aplicación:

- ✅ **Servicios** (inyección de dependencias)
- ✅ **Autenticación** (signIn, signUp, signOut, resetPassword)
- ✅ **Perfil de Usuario** (cargar, actualizar, subir avatar)
- ✅ **Organización** (datos de la empresa)
- ✅ **Asistencia** (check-in, check-out, historial)
- ✅ **Notificaciones** (stream en tiempo real)
- ✅ **Horarios** (gestión de horarios)
- ✅ **Biometría** (autenticación biométrica)

### 2. **Rutas (Go Router)** - `lib/routes/app_router.dart`
Sistema de navegación completamente integrado con Riverpod:

- ✅ **Protección automática** de rutas por autenticación
- ✅ **Protección por rol** (Empleado, Admin, SuperAdmin)
- ✅ **Redirects inteligentes** basados en estado
- ✅ **Rutas dinámicas** con parámetros
- ✅ **Debug logging** habilitado

### 3. **Aplicación Principal** - `lib/app.dart`
Integración completa de Riverpod y Go Router:

- ✅ `ProviderScope` envuelve la app
- ✅ `MaterialApp.router` usa GoRouter
- ✅ Tema configurable

---

## 🎯 Primeros Pasos

### 1. Verificar que todo funciona
```bash
cd app/puntocheck
flutter clean
flutter pub get
flutter run
```

### 2. Los archivos principales están listos:
```
lib/
├── providers/
│   └── app_providers.dart       ✅ COMPLETO
├── routes/
│   └── app_router.dart          ✅ COMPLETO
├── app.dart                     ✅ ACTUALIZADO
├── main.dart                    ✅ OK
└── ...
```

---

## 📚 Documentación

Se han creado dos archivos de documentación:

### `PROVIDERS_GUIDE.md` 📖
Guía completa y detallada de:
- Todos los providers disponibles
- Cómo usarlos desde las vistas
- Patrones de código
- Flujos completos
- Solución de problemas

### `EXAMPLES_PROVIDERS.md` 💡
Ejemplos prácticos de código para:
- Formulario de login
- Perfil de usuario con avatar
- Check-in/Check-out con ubicación
- Lista de notificaciones
- Lista de empleados
- Y más...

---

## 🔄 Flujo de Trabajo Típico

### 1️⃣ Usuario entra a la app
```
main.dart 
  ↓
PuntoCheckApp (Consumer)
  ↓
MaterialApp.router + GoRouter
  ↓
Splash View (SplashView)
```

### 2️⃣ Autenticación
```
LoginView
  ↓
authControllerProvider.signIn()
  ↓
authStateProvider observa cambio
  ↓
Router redirige automáticamente
```

### 3️⃣ Carga de Perfil
```
authState = Logueado
  ↓
profileProvider carga Profile
  ↓
Router verifica rol
  ↓
Redirige a dashboard (employee/admin/superadmin)
```

### 4️⃣ Pantalla Principal
```
ConsumerWidget (accede a ref)
  ↓
ref.watch(profileProvider)
  ↓
ref.watch(activeShiftProvider)
  ↓
ref.watch(notificationsStreamProvider)
  ↓
UI reactiva a cambios
```

---

## 🛠️ Usar Providers desde una Vista

### Patrón básico en cualquier Vista:

```dart
class MiVista extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Observar datos (Reactividad)
    final miDato = ref.watch(miProviderProvider);

    // 2. Usar controller para acciones
    final controller = ref.read(miControllerProvider.notifier);

    return Scaffold(
      body: miDato.when(
        data: (dato) => Text('Dato: $dato'),
        loading: () => const CircularProgressIndicator(),
        error: (err, st) => Text('Error: $err'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await controller.hacerAlgo();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
      ),
    );
  }
}
```

---

## 🚀 Caso de Uso: Crear Nuevo Provider

Si necesitas un nuevo provider (ej: lista de empleados):

### 1. En `app_providers.dart`:
```dart
// Primero, crea el service si no existe
final empleadoServiceProvider = 
    Provider<EmpleadoService>((ref) => EmpleadoService());

// Luego, el provider para obtener datos
final empleadosProvider = FutureProvider.autoDispose<List<Empleado>>((ref) async {
  return ref.watch(empleadoServiceProvider).getEmpleados();
});

// Si necesitas acciones, crea un controller
class EmpleadoController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() => null;

  Future<void> crearEmpleado(Empleado empleado) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(empleadoServiceProvider).crear(empleado);
      ref.invalidate(empleadosProvider); // Refrescar lista
    });
  }
}
final empleadoControllerProvider = 
    AsyncNotifierProvider<EmpleadoController, void>(EmpleadoController.new);
```

### 2. En tu Vista:
```dart
class EmpleadosView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final empleados = ref.watch(empleadosProvider);
    
    return empleados.when(
      data: (items) => ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, i) => ListTile(title: Text(items[i].nombre)),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (err, _) => Text('Error: $err'),
    );
  }
}
```

---

## 🛡️ Seguridad de Rutas

El router **automáticamente**:

✅ Bloquea acceso a rutas privadas sin autenticación
✅ Protege rutas administrativas por rol
✅ Redirige según permisos

**Ejemplo de flujo protegido:**
```
Usuario NO autenticado intenta ir a /admin/home
  ↓
Router detecta: authState.session == null
  ↓
Redirige a /login
  ↓
Usuario inicia sesión
  ↓
Router detecta: profile.isOrgAdmin == true
  ↓
Permite acceso a /admin/home
```

---

## 📱 Navegación desde la UI

### Navegar simple:
```dart
context.go('/employee/home');
```

### Navegar y volver:
```dart
context.push('/employee/home/registro-asistencia');
```

### Con parámetros:
```dart
context.go('/admin/home/empleado-detalle/$empleadoId');
```

### Con nombres (type-safe):
```dart
context.goNamed('registroAsistencia');
```

---

## ⚠️ Checklist Pre-Producción

Antes de desplegar:

- [ ] Todos los servicios están inicializados correctamente
- [ ] Variables de entorno (SUPABASE_URL, SUPABASE_ANON_KEY) están configuradas
- [ ] RLS (Row Level Security) en Supabase está habilitado
- [ ] Autenticación biométrica configurada si es necesario
- [ ] Permisos de ubicación configurados (android/ios)
- [ ] Permisos de cámara configurados
- [ ] Permisos de almacenamiento configurados
- [ ] Error handling completo en todas las acciones
- [ ] Logs de debug deshabilitados en producción
- [ ] Testing de flujos de autenticación completado

---

## 🐛 Solución de Problemas Comunes

### "ProviderScope no encontrado"
**Solución**: Asegúrate que `main.dart` envuelve la app con `ProviderScope`

### "ref no está disponible aquí"
**Solución**: Usa `ConsumerWidget` en lugar de `StatelessWidget`

### "Ruta no encontrada"
**Solución**: Verifica que el `path` en `GoRoute` coincide con lo que usas en `context.go()`

### "Usuario se desconecta constantemente"
**Solución**: Verifica que `authStateProvider` está observando correctamente y que RLS está bien configurado

---

## 📞 Soporte

Para documentación completa:
- Mira `PROVIDERS_GUIDE.md` para referencia detallada
- Mira `EXAMPLES_PROVIDERS.md` para ejemplos de código
- Lee los comentarios en `app_providers.dart` y `app_router.dart`

---

## 🎉 ¡Listo para empezar!

1. ✅ Providers configurados
2. ✅ Rutas protegidas
3. ✅ Autenticación integrada
4. ✅ Documentación completa

**Ahora puedes:**
- Crear vistas que usen los providers
- Navegar entre pantallas
- Acceder a servicios desde la UI
- Manejar autenticación automáticamente

¡Buena suerte! 🚀

