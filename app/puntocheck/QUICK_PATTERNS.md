# 🎯 Patrones Rápidos - Copia y Pega

Esta guía tiene fragmentos listos para copiar y pegar en tus vistas.

---

## 1️⃣ Lectura de Datos (ConsumerWidget)

### Template básico
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';

class MiVista extends ConsumerWidget {
  const MiVista({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(miProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Vista')),
      body: datos.when(
        data: (data) => _buildContent(context, data),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, dynamic data) {
    return Center(child: Text('Datos: $data'));
  }
}
```

---

## 2️⃣ Lectura de Perfil (Ejemplo Real)

```dart
class ProfileCard extends ConsumerWidget {
  const ProfileCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    return profileState.when(
      data: (profile) {
        if (profile == null) {
          return const Card(child: Text('No hay perfil'));
        }
        return Card(
          child: ListTile(
            leading: profile.avatarUrl != null
                ? CircleAvatar(backgroundImage: NetworkImage(profile.avatarUrl!))
                : const CircleAvatar(child: Icon(Icons.person)),
            title: Text(profile.fullName ?? 'Sin nombre'),
            subtitle: Text(profile.jobTitle),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
```

---

## 3️⃣ Acciones (Controllers)

### Template para acciones
```dart
class ActionButton extends ConsumerWidget {
  final String label;
  final Future<void> Function(WidgetRef ref) onPressed;

  const ActionButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(miControllerProvider);

    return ElevatedButton(
      onPressed: state.isLoading
          ? null
          : () async {
              try {
                await onPressed(ref);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
      child: state.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

// Usar:
ActionButton(
  label: 'Hacer algo',
  onPressed: (ref) async {
    final controller = ref.read(miControllerProvider.notifier);
    await controller.hacerAlgo();
  },
)
```

---

## 4️⃣ Sign In (Login)

```dart
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  late final emailController = TextEditingController();
  late final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: authState.isLoading
                ? const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('Iniciar Sesión'),
                  ),
          ),
          if (authState.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Error: ${authState.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final authController = ref.read(authControllerProvider.notifier);

    try {
      await authController.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      // El router automáticamente redirige
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
```

---

## 5️⃣ Lista Reactiva (Stream)

```dart
class NotificationsList extends ConsumerWidget {
  const NotificationsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Badge(label: Text('$unreadCount')),
              ),
            ),
        ],
      ),
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(child: Text('Sin notificaciones'));
          }
          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return ListTile(
                title: Text(notif.title),
                subtitle: Text(notif.message),
                trailing: notif.isRead
                    ? null
                    : GestureDetector(
                        onTap: () => _marcarComoLeida(ref, notif.id),
                        child: const Icon(Icons.done, color: Colors.blue),
                      ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _marcarComoLeida(WidgetRef ref, String notifId) {
    final controller = ref.read(notificationControllerProvider.notifier);
    controller.markAsRead(notifId);
  }
}
```

---

## 6️⃣ Check-In Con Ubicación

```dart
class CheckInButton extends ConsumerWidget {
  const CheckInButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceState = ref.watch(attendanceControllerProvider);
    final profileState = ref.watch(profileProvider);

    return ElevatedButton.icon(
      onPressed: attendanceState.isLoading
          ? null
          : () => _handleCheckIn(context, ref, profileState),
      icon: const Icon(Icons.login),
      label: const Text('Hacer Check-In'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _handleCheckIn(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Profile?> profileState,
  ) async {
    // 1. Obtener ubicación
    final position = await Geolocator.getCurrentPosition();

    // 2. Obtener foto
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) return;

    // 3. Obtener perfil
    final profile = profileState.value;
    if (profile == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil no disponible')),
        );
      }
      return;
    }

    // 4. Hacer check-in
    try {
      final controller = ref.read(attendanceControllerProvider.notifier);
      await controller.checkIn(
        location: GeoLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        photoFile: File(photo.path),
        orgId: profile.organizationId!,
        address: 'Ubicación automática',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Check-in registrado!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
```

---

## 7️⃣ Cierre de Sesión

```dart
class LogoutButton extends ConsumerWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _handleLogout(context, ref),
      icon: const Icon(Icons.logout),
      label: const Text('Cerrar Sesión'),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final authController = ref.read(authControllerProvider.notifier);

    try {
      await authController.signOut();
      // El router automáticamente redirige a /login
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
```

---

## 8️⃣ Actualizar Perfil

```dart
class EditProfileForm extends ConsumerStatefulWidget {
  final Profile profile;

  const EditProfileForm({required this.profile, super.key});

  @override
  ConsumerState<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<EditProfileForm> {
  late final nameController = TextEditingController(
    text: widget.profile.fullName,
  );
  late final phoneController = TextEditingController(
    text: widget.profile.phone,
  );

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: phoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: profileState.isLoading
                ? const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : ElevatedButton(
                    onPressed: _handleSave,
                    child: const Text('Guardar'),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    final controller = ref.read(profileProvider.notifier);
    final updatedProfile = widget.profile.copyWith(
      fullName: nameController.text,
      phone: phoneController.text,
    );

    try {
      await controller.updateProfile(updatedProfile);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
```

---

## 9️⃣ Navegar

```dart
// Navegar simple
context.go('/employee/home');

// Navegar y poder volver
context.push('/employee/home/registro-asistencia');

// Con parámetros
context.go('/admin/home/empleado-detalle/$empleadoId');

// Con nombres (recomendado)
context.goNamed('registroAsistencia');
context.goNamed('empleadoDetalle', pathParameters: {'id': empleadoId});

// Reemplazar ruta (para login)
context.go('/employee/home');
```

---

## 🔟 Refrescar Datos

```dart
// Después de una acción, refrescar un provider
ref.invalidate(miProvider);

// O refrescar múltiples
ref.invalidate(profileProvider);
ref.invalidate(activeShiftProvider);
ref.invalidate(attendanceHistoryProvider);

// Si necesitas esperar que se recargue:
await ref.refresh(miProvider.future);
```

---

## 🎁 Bonus: ConsumerStatefulWidget

Si necesitas un StatefulWidget con providers:

```dart
class MyPage extends ConsumerStatefulWidget {
  const MyPage({super.key});

  @override
  ConsumerState<MyPage> createState() => _MyPageState();
}

class _MyPageState extends ConsumerState<MyPage> {
  @override
  void initState() {
    super.initState();
    // Aquí puedes usar ref.read() pero NO ref.watch()
    _initializeData();
  }

  void _initializeData() {
    // Usa read, no watch
    final data = ref.read(miProvider);
  }

  @override
  Widget build(BuildContext context) {
    // Aquí puedes usar ref.watch()
    final datos = ref.watch(miProvider);
    
    return Scaffold(
      body: datos.when(
        data: (d) => Text('$d'),
        loading: () => const CircularProgressIndicator(),
        error: (e, _) => Text('Error: $e'),
      ),
    );
  }
}
```

---

## 📝 Notas Finales

1. **Siempre verifica `context.mounted`** antes de usar `context` en callbacks async
2. **Usa `.when()`** para manejar states
3. **Lee providers**, no veas controladores (en callbacks):
   ```dart
   final controller = ref.read(controllerProvider.notifier); // ✅ OK
   final data = ref.watch(dataProvider); // ✅ OK en build
   ```
4. **Invalida después de cambios** para que la UI se actualice
5. **Maneja errores** mostrando SnackBars o diálogos

¡Ahora estás listo para empezar! 🚀

