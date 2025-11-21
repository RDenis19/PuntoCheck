# Ejemplos Prácticos de Uso de Providers

## 🎯 Casos de Uso Comunes

### 1. Formulario de Login

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';

class LoginView extends ConsumerWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar Sesión')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            // Botón de login con estado de carga
            authState.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      final authController = 
                          ref.read(authControllerProvider.notifier);
                      
                      try {
                        await authController.signIn(
                          emailController.text.trim(),
                          passwordController.text.trim(),
                        );
                        // El router automáticamente redirige
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('¡Sesión iniciada!'),
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
                    },
                    child: const Text('Iniciar Sesión'),
                  ),
            // Mostrar errores si existen
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
      ),
    );
  }
}
```

---

### 2. Perfil de Usuario con Avatar

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:puntocheck/providers/app_providers.dart';

class PersonalInfoView extends ConsumerWidget {
  const PersonalInfoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Información Personal')),
      body: profileState.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No hay perfil disponible'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Avatar con opción de cambiar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: profile.avatarUrl != null
                          ? NetworkImage(profile.avatarUrl!)
                          : const AssetImage('assets/default_avatar.png')
                              as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _cambiarAvatar(context, ref, profile),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Información del usuario
              _buildInfoTile('Nombre', profile.fullName ?? 'No asignado'),
              _buildInfoTile('Email', profile.email ?? 'No asignado'),
              _buildInfoTile('Teléfono', profile.phone ?? 'No asignado'),
              _buildInfoTile(
                'Código Empleado',
                profile.employeeCode ?? 'No asignado',
              ),
              _buildInfoTile('Puesto', profile.jobTitle),
              const SizedBox(height: 24),
              // Botón de cerrar sesión
              ElevatedButton.icon(
                onPressed: () => _cerrarSesion(context, ref),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar Sesión'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _cambiarAvatar(
    BuildContext context,
    WidgetRef ref,
    Profile profile,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && context.mounted) {
      final profileController = ref.read(profileProvider.notifier);

      try {
        await profileController.uploadAvatar(File(image.path));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Avatar actualizado')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al actualizar avatar: $e')),
          );
        }
      }
    }
  }

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final authController = ref.read(authControllerProvider.notifier);

    try {
      await authController.signOut();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión cerrada')),
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

### 3. Check-In/Check-Out con Ubicación y Foto

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:puntocheck/providers/app_providers.dart';
import 'package:puntocheck/models/geo_location.dart';

class RegistroAsistenciaView extends ConsumerWidget {
  const RegistroAsistenciaView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeShift = ref.watch(activeShiftProvider);
    final profile = ref.watch(profileProvider);
    final attendanceState = ref.watch(attendanceControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Registro de Asistencia')),
      body: Center(
        child: activeShift.when(
          data: (shift) {
            // Si hay un turno activo, mostrar botón de check-out
            if (shift != null) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, size: 80, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Já has hecho check-in!',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entrada: ${shift.checkInTime}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  attendanceState.isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          onPressed: () =>
                              _hacerCheckOut(context, ref, shift, profile),
                          icon: const Icon(Icons.exit_to_app),
                          label: const Text('Registrar Salida'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                ],
              );
            }

            // Si no hay turno, mostrar botón de check-in
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.login, size: 80, color: Colors.blue),
                const SizedBox(height: 16),
                const Text(
                  'Registrar Entrada',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 32),
                attendanceState.isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: () =>
                            _hacerCheckIn(context, ref, profile),
                        icon: const Icon(Icons.fingerprint),
                        label: const Text('Hacer Check-In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, st) => Text('Error: $error'),
        ),
      ),
    );
  }

  Future<void> _hacerCheckIn(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Profile?> profileState,
  ) async {
    // Obtener ubicación
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error obteniendo ubicación: $e')),
        );
      }
      return;
    }

    // Obtener foto
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);
    if (photo == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Debes tomar una foto')),
        );
      }
      return;
    }

    // Hacer check-in
    if (!context.mounted) return;

    final profile = profileState.value;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil no disponible')),
      );
      return;
    }

    try {
      final attendanceController = 
          ref.read(attendanceControllerProvider.notifier);
      
      await attendanceController.checkIn(
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
            content: Text('¡Check-in registrado exitosamente!'),
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

  Future<void> _hacerCheckOut(
    BuildContext context,
    WidgetRef ref,
    WorkShift shift,
    AsyncValue<Profile?> profileState,
  ) async {
    // Obtener ubicación
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error obteniendo ubicación: $e')),
        );
      }
      return;
    }

    // Foto es opcional para check-out
    final photo = await ImagePicker().pickImage(source: ImageSource.camera);

    if (!context.mounted) return;

    final profile = profileState.value;
    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil no disponible')),
      );
      return;
    }

    try {
      final attendanceController = 
          ref.read(attendanceControllerProvider.notifier);
      
      await attendanceController.checkOut(
        shiftId: shift.id,
        location: GeoLocation(
          latitude: position.latitude,
          longitude: position.longitude,
        ),
        orgId: profile.organizationId!,
        photoFile: photo != null ? File(photo.path) : null,
        address: 'Ubicación automática',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Check-out registrado exitosamente!'),
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

### 4. Listar Notificaciones con Badge

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:puntocheck/providers/app_providers.dart';

class AvisosView extends ConsumerWidget {
  const AvisosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsStreamProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Avisos'),
        actions: [
          if (unreadCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Botón para marcar todas como leídas
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: GestureDetector(
                onTap: () => _marcarTodasComoLeidas(ref),
                child: const Text(
                  'Marcar todas',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: notificationsState.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Text('No hay avisos'),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(context, ref, notification);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildNotificationCard(
    BuildContext context,
    WidgetRef ref,
    AppNotification notification,
  ) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              notification.isRead ? Colors.grey : Colors.blue,
          child: Icon(
            _getIconForType(notification.type),
            color: Colors.white,
          ),
        ),
        title: Text(notification.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 4),
            Text(
              _formatTime(notification.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? GestureDetector(
                onTap: () => _marcarComoLeida(ref, notification.id),
                child: const Icon(Icons.done, color: Colors.blue),
              )
            : null,
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'attendance':
        return Icons.check_circle;
      case 'announcement':
        return Icons.notifications;
      case 'schedule':
        return Icons.calendar_today;
      default:
        return Icons.info;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} minutos';
    } else if (diff.inHours < 24) {
      return 'Hace ${diff.inHours} horas';
    } else {
      return 'Hace ${diff.inDays} días';
    }
  }

  void _marcarComoLeida(WidgetRef ref, String notificationId) {
    final controller = ref.read(notificationControllerProvider.notifier);
    controller.markAsRead(notificationId);
  }

  void _marcarTodasComoLeidas(WidgetRef ref) {
    final controller = ref.read(notificationControllerProvider.notifier);
    controller.markAllAsRead();
  }
}
```

---

### 5. Listar Empleados (Admin)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Nota: Este es un ejemplo conceptual
// Necesitarías crear un provider para listar empleados de la organización

class EmpleadosListView extends ConsumerWidget {
  const EmpleadosListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Crear employeesProvider en app_providers.dart
    // final employeesState = ref.watch(employeesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Empleados'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/admin/home/nuevo-empleado'),
          ),
        ],
      ),
      body: const Center(
        child: Text('Lista de empleados'),
      ),
    );
  }
}
```

---

## 📝 Notas Importantes

1. **Siempre usa `if (context.mounted)`** antes de usar `context` en callbacks asíncronos
2. **Invalida los providers correctos** después de cambios para refrescar la UI
3. **Maneja errores apropiadamente** mostrándolos en SnackBars o diálogos
4. **Usa `.when()`** para manejar los estados loading, data y error
5. **Prefiere lectura sobre watching** cuando no necesites reactividad:
   ```dart
   // Usa watch para reactividad
   final data = ref.watch(provider);
   
   // Usa read para valores únicos (en callbacks)
   final controller = ref.read(controllerProvider.notifier);
   ```

