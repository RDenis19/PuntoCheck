# ✅ Checklist de Implementación Supabase

## Verificación de Archivos

- [x] `lib/main.dart` — Inicializa Supabase con `SupabaseBootstrap`
- [x] `lib/app.dart` — Configura `MultiProvider` con providers
- [x] `lib/core/utils/supabase_bootstrap.dart` — Lee variables de entorno
- [x] `lib/backend/config/provider_setup.dart` — Define inyección de dependencias
- [x] `lib/backend/data/datasources/supabase_auth_datasource.dart` — Maneja auth
- [x] `lib/backend/data/datasources/supabase_user_datasource.dart` — Maneja profiles
- [x] `lib/backend/data/datasources/supabase_storage_datasource.dart` — Maneja storage
- [x] `lib/backend/data/repositories/auth_repository.dart` — Conecta datasources
- [x] `lib/backend/data/models/user_model.dart` — Mapea datos + role
- [x] `lib/backend/domain/entities/app_user.dart` — Entidad base + role
- [x] `lib/frontend/controllers/auth_controller.dart` — Lógica de negocio + navegación
- [x] `lib/frontend/vistas/auth/login_view.dart` — Usa `Consumer<AuthController>`
- [x] `lib/frontend/vistas/auth/register_view.dart` — Usa `Consumer<AuthController>`
- [x] `lib/frontend/vistas/auth/forgot_password_view.dart` — Usa `Consumer<AuthController>`

## Dependencias

- [x] `supabase_flutter: ^2.10.3` — SDK oficial de Supabase
- [x] `provider` — Ya estaba; actualizado
- [x] `local_auth` — Para biometría (ya estaba)
- [x] `shared_preferences` — Para persistencia (instalado con Supabase)

## Configuración Supabase (Pendiente - Hacer en Consola)

Antes de ejecutar la app:

- [ ] Crear proyecto en [supabase.com](https://supabase.com)
- [ ] Copiar URL (ej: `https://xxxxx.supabase.co`)
- [ ] Copiar ANON_KEY
- [ ] Crear tabla `profiles`
- [ ] Crear bucket `avatars` (opcional si subes fotos)
- [ ] Configurar RLS si lo requieres (opcional para desarrollo)

## Ejecución

Para ejecutar con credenciales:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_ID.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

O si prefieres configurar en VS Code `.vscode/launch.json` con los defines.

## Flujos Funcionales

### Login ✅
1. Usuario ingresa email + password en `login_view.dart`
2. Vista llama `authController.login(...)` del Provider
3. Controller → Repository → Datasource → Supabase Auth
4. Si OK: busca perfil en tabla `profiles`
5. Navega según `role` (employee/admin/superadmin)

### Registro ✅
1. Usuario completa formulario en `register_view.dart`
2. Vista llama `authController.register(...)`
3. Controller → Repository:
   - Crea usuario en Auth
   - Sube foto (si existe)
   - Inserta perfil en `profiles`
4. Si OK: navega según rol

### Reset Password ✅
1. Usuario ingresa email en `forgot_password_view.dart`
2. Vista llama `authController.sendResetEmail(email)`
3. Supabase envía email con link de recuperación
4. Usuario abre link (fuera de la app) y resetea contraseña

## Testing Manual

1. **Login con usuario existente**
   - Email: `test@example.com`
   - Password: `Test123!`
   - Resultado esperado: navega a home según rol

2. **Registro de nuevo usuario**
   - Completa todos los campos
   - Verifica que se crea en `auth.users` y `profiles`
   - Debe navegar automáticamente a home

3. **Reset de contraseña**
   - Ingresa email válido
   - Revisa inbox por email de Supabase
   - Abre link y establece nueva contraseña

4. **Logout (si lo implementas)**
   - Llama `await authController.logout()`
   - Debe limpiar datos y navegar a login

## Códigos de Estado / Errores Esperados

- `"Credenciales inválidas"` → Email o password incorrecto
- `"No se encontró una cuenta con ese correo"` → Email no existe en Auth
- `"Ya existe una cuenta con este correo"` → Email duplicado
- `"Usuario sin perfil en Firestore"` (legacy message) → Fila en `profiles` no existe
- `"Debes iniciar sesión primero"` → No hay usuario autenticado

## Validaciones del Cliente

- Email: Formato `^[^@]+@[^@]+\.[^@]+`
- Contraseña: No vacía (mínimo requerido)
- Confirmación de contraseña: Debe coincidir
- Teléfono: No vacío
- Nombre completo: No vacío

## Seguridad (Notas)

- Las credenciales Supabase (URL + ANON_KEY) se pasan vía `--dart-define` (variables de entorno en compile-time)
- No se hardcodean en el código
- Para producción: usa RLS en la tabla `profiles`
- No persistas contraseñas localmente (usa tokens de sesión)
- La clase `SecureStorageService` está en memoria; cambia a `flutter_secure_storage` para persistencia real

## Siguientes Pasos Opcionales

- [ ] Implementar `flutter_secure_storage` real en `SecureStorageService`
- [ ] Agregar 2FA
- [ ] Agregar social login (Google, GitHub)
- [ ] Implementar refresh de sesión automático
- [ ] Agregar logging/analytics
- [ ] Crear interceptor de errores global

---

**Estado**: ✅ Backend Supabase v2 completamente generado e integrado
**Último update**: Noviembre 13, 2025
