import 'package:supabase_flutter/supabase_flutter.dart';

// Acceso rápido al cliente para evitar escribir Supabase.instance.client en todos lados
final supabase = Supabase.instance.client;