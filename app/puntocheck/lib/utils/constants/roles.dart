/// Constantes de roles de usuario en la aplicación.
abstract final class AppRoles {
  static const String employee = 'employee';
  static const String admin = 'admin';
  static const String superadmin = 'superadmin';
}

/// Datos de usuario mock para autenticación en frontend.
/// TODO(backend): Reemplazar por autenticación real con un servicio de Auth (Firebase Auth, OAuth, etc.)
/// Motivo: Actualmente solo se validan credenciales en memoria en el cliente.
const Map<String, Map<String, dynamic>> kMockUsers = {
  'empleado@demo.com': {
    'password': '123456',
    'role': AppRoles.employee,
  },
  'admin@demo.com': {
    'password': '123456',
    'role': AppRoles.admin,
  },
  'super@demo.com': {
    'password': '123456',
    'role': AppRoles.superadmin,
  },
};
