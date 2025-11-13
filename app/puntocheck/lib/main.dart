import 'package:flutter/material.dart';
import 'package:puntocheck/app.dart';

/// Entrada principal de la aplicacion.
/// 
/// NOTA: Esta es una implementacion MOCK de autenticacion solo para frontend.
/// TODO(backend): Reemplazar la lógica de main para:
/// - Inicializar Firebase (si se usa)
/// - Configurar autenticación real con backend
/// - Implementar persistencia de sesión (shared_preferences, secure_storage, etc.)
/// - Añadir manejo de errores y logging
/// 
/// Por ahora, simplemente iniciamos la app con rutas basadas en credenciales mock.
void main() {
  runApp(const PuntoCheckApp());
}

