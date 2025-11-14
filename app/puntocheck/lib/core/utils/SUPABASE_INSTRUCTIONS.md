Pasos para integrar Supabase en este proyecto

1) Añadir credenciales
   - Obtén `SUPABASE_URL` y `SUPABASE_ANON_KEY` desde la consola de Supabase.

2) Inicializar Supabase
   - Llama a `SupabaseBootstrap.initialize(url, anonKey)` antes de usar los datasources, típicamente en `main()`.

   Ejemplo:

```dart
import 'package:flutter/material.dart';
import 'core/utils/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize(
    supabaseUrl: 'https://tusupabaseurl.supabase.co',
    supabaseAnonKey: 'tu-anon-key',
  );
  runApp(const PuntoCheckApp());
}
```

3) Usar los datasources
   - He añadido plantillas en `lib/backend/data/datasources/`:
     - `supabase_auth_datasource.dart`
     - `supabase_user_datasource.dart`
     - `supabase_storage_datasource.dart`

   - Para usar Supabase en lugar del mock, actualiza las importaciones en
     `lib/backend/data/repositories/auth_repository.dart` y reemplaza
     las instancias por las del datasource de Supabase.

4) Notas
   - Algunos métodos son plantillas y pueden requerir ajustes según tu
     esquema de la tabla `users` y configuración de storage.
   - Si ves errores al añadir paquetes en Windows, activa "Developer Mode"
     en la configuración de Windows (permite crear symlinks necesarios
     por algunos plugins Flutter).
