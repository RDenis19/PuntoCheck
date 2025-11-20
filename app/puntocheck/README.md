# PuntoCheck – Frontend

## 📁 Estructura de carpetas

```
lib
│  ├─ app.dart
│  ├─ backend
│  │  ├─ config/provider_setup.dart
│  │  ├─ data
│  │  │  ├─ datasources/(supabase_auth|supabase_storage|supabase_user)_datasource.dart
│  │  │  ├─ models/user_model.dart
│  │  │  └─ repositories/auth_repository.dart
│  │  └─ domain
│  │     ├─ entities/app_user.dart
│  │     └─ services/(biometric|profile|secure_storage)_service.dart
│  ├─ core
│  │  ├─ constants/(roles|strings).dart
│  │  ├─ theme/(app_colors|app_theme).dart
│  │  └─ utils/(result|supabase_bootstrap|SUPABASE_INSTRUCTIONS|validators)
│  ├─ frontend
│  │  ├─ routes/(app_router|app_router_mock).dart
│  │  ├─ features
│  │  │  ├─ auth/
│  │  │  │  ├─ controllers/auth_controller.dart
│  │  │  │  ├─ views/(login|register|forgot_password_*|reset_password_*).dart
│  │  │  │  └─ widgets/(auth_buttons|auth_text_field).dart
│  │  │  ├─ employee/
│  │  │  │  ├─ views/(employee_home|registro_asistencia|horario_trabajo|
│  │  │  │  │          historial|avisos|settings|personal_info)_view.dart
│  │  │  │  └─ widgets/(employee_home_cards|registro_widgets).dart
│  │  │  ├─ admin/
│  │  │  │  ├─ views/(admin_shell|admin_home|nuevo_empleado|empleados_list|
│  │  │  │  │          empleado_detalle|horario_admin|anuncios_admin|
│  │  │  │  │          nuevo_anuncio|apariencia_app)_view.dart
│  │  │  │  └─ widgets/(admin_dashboard_header|admin_module_tile|
│  │  │  │             admin_quick_action_button|announcement_type_chip|
│  │  │  │             employee_list_item|employee_stats_cards|
│  │  │  │             schedule_calendar).dart
│  │  │  ├─ superadmin/
│  │  │  │  ├─ views/(super_admin_shell|super_admin_home|organizaciones_list|
│  │  │  │  │          organizacion_detalle|config_global)_view.dart
│  │  │  │  ├─ widgets/(sa_kpi_card|sa_organization_card|sa_section_title).dart
│  │  │  │  └─ mock/organizations_mock.dart
│  │  │  ├─ splash/views/splash_view.dart
│  │  │  └─ shared/widgets/(primary_button|outlined_dark_button|
│  │  │                           text_field_icon|circle_logo_asset|
│  │  │                           history_item_card|notice_card).dart
│  └─ main.dart
```

## 🔁 Flujo funcional (detallado)

Esta sección resume cómo se utilizan las vistas para cada rol, de modo que backend y base de datos entiendan qué endpoints necesita cada pantalla. Todos los lugares con integración pendiente tienen comentarios `// TODO(backend)` en el código.

### 1. Autenticación (`features/auth`)
1. `login_view.dart`
   - Captura email/password y llama a `AuthController.login`.
   - Botones temporales para saltar a Admin/SuperAdmin (debug).
2. `register_view.dart`
   - Formulario completo de alta con validaciones.
3. Recuperación:
   - `forgot_password_view.dart` (elige método).
   - `forgot_password_email_view.dart` (envía código).
   - `forgot_password_code_view.dart` (valida OTP).
   - `reset_password_view.dart` → `reset_password_success_view.dart`.

### 2. Módulo Empleado (`features/employee`)
1. `employee_home_view.dart`
   - Header degradado, tarjetas de ubicación y estadísticas (`employee_home_cards.dart`).
   - Botón circular “Registrar entrada” → `registro_asistencia_view.dart`.
   - BottomNav: Home / Mapa mock / Historial / Avisos / Ajustes.
2. `registro_asistencia_view.dart`
   - `RegistroCircleAction` + `RegistroLocationCard` (GPS mock) + botón `PrimaryButton`.
3. `horario_trabajo_view.dart`
   - Calendario diario (`TodayScheduleCard`, `WeekSummaryCard` en `registro_widgets`).
4. `historial_view.dart`
   - Uso de `HistoryItemCard` + filtros.
5. `avisos_view.dart`
   - Lista de `NoticeCard` con modal (`showModalBottomSheet`).
6. `settings_view.dart`
   - Igual que Ajustes Admin: cuenta/preferencias/soporte + botón “Cerrar sesión”.
7. `personal_info_view.dart`
   - Edición en modales + cambio de contraseña.

### 3. Módulo Admin (`features/admin`)
1. `admin_shell_view.dart`
   - Tab Navigator (BottomNav) con 4 pestañas:
     - Inicio → `admin_home_view.dart`
     - Horario → `horario_admin_view.dart`
     - Editar App → `apariencia_app_view.dart`
     - Configuración → `SettingsView(embedded: true)`
2. `admin_home_view.dart`
   - Header degradado + KPI (`AdminDashboardHeader`).
   - Sección “Acciones rápidas” con `AdminQuickActionButton` (nuevo empleado, empleados, ubicación, reportes, anuncios).
3. `horario_admin_view.dart`
   - Calendario multi-selección (`schedule_calendar.dart`) + campos de horas.
4. `apariencia_app_view.dart`
   - Branding por organización (logo, nombre, color).
5. Otras vistas reutilizadas desde el shell:
   - `nuevo_empleado_view.dart`, `empleados_list_view.dart`, `empleado_detalle_view.dart`,
     `anuncios_admin_view.dart`, `nuevo_anuncio_view.dart`.

### 4. Módulo Super Admin (`features/superadmin`)
1. `super_admin_shell_view.dart`
   - Tabs: Inicio / Organizaciones / Config. Global.
2. `super_admin_home_view.dart`
   - Header degradado, KPIs calculados desde `mock/organizations_mock.dart`, listado de SaOrganizationCard.
3. `organizaciones_list_view.dart`
   - Buscador + filtros (Todos, Activas, Suspendidas, Prueba) + lista con `SaOrganizationCard`.
   - `onTap` → `organizacion_detalle_view.dart` (detalle completo + acciones de impersonación/cambio de estado).
4. `config_global_view.dart`
   - Cards para textos legales, valores por defecto, feature flags, botón “Guardar” y “Cerrar sesión”.

### 5. Splash
- `features/splash/views/splash_view.dart` coordina inicio (mock).

### 6. Widgets compartidos
- `features/shared/widgets` contiene todos los componentes reutilizables (botones, inputs, cards). Importar desde aquí evita duplicación.

## ✅ Notas para backend

- `mock/organizations_mock.dart` es la única fuente de datos quemada. Sustituirla por endpoints reales cuando estén listos.
- Los puntos `// TODO(backend)` ya explican qué se espera (ej. GPS, reportes, impersonación, feature flags).
- Las rutas principales están en `frontend/routes/app_router.dart`; cada rol navega primero a su `ShellView` correspondiente.

```