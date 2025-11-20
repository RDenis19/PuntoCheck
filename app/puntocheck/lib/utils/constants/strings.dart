/// Constantes de strings utilizadas en la aplicación.
abstract final class AppStrings {
  // General
  static const String appName = 'PuntoCheck';
  static const String welcome = 'Bienvenido';

  // Auth - Login
  static const String loginTitle = 'Iniciar Sesión';
  static const String email = 'Correo Electrónico';
  static const String password = 'Contraseña';
  static const String loginButton = 'Iniciar Sesión';
  static const String registerLink = '¿No tienes cuenta? Crear cuenta';
  static const String forgotPasswordLink = '¿Olvidaste tu contraseña?';

  // Auth - Register
  static const String registerTitle = 'Crear Cuenta';
  static const String fullName = 'Nombre Completo';
  static const String phone = 'Teléfono';
  static const String confirmPassword = 'Confirmar Contraseña';
  static const String registerButton = 'Crear Cuenta';
  static const String backToLogin = 'Volver a Iniciar Sesión';

  // Auth - Forgot Password
  static const String forgotPasswordTitle = '¿Olvidaste tu Contraseña?';
  static const String recoveryEmail = 'Correo para recuperación';
  static const String sendCodeButton = 'Enviar Código';
  static const String resetPasswordButton = 'Recuperar Contraseña';

  // Validation errors
  static const String emptyEmail = 'Por favor ingresa tu correo';
  static const String invalidEmail = 'Correo inválido';
  static const String emptyPassword = 'Por favor ingresa tu contraseña';
  static const String emptyFullName = 'Por favor ingresa tu nombre completo';
  static const String emptyPhone = 'Por favor ingresa tu teléfono';
  static const String emptyConfirmPassword = 'Por favor confirma tu contraseña';
  static const String passwordMismatch = 'Las contraseñas no coinciden';
  static const String userNotFound = 'Usuario no encontrado';
  static const String invalidPassword = 'Contraseña incorrecta';

  // Success messages
  static const String registrationSuccess = 'Cuenta creada exitosamente';
  static const String resetCodeSent = 'Codigo de recuperacion enviado a tu correo';
  static const String passwordResetSuccess = 'Contraseña actualizada correctamente';

  // Home screens
  static const String employeeHome = 'Hola Empleado';
  static const String adminHome = 'Hola Admin';
  static const String superAdminHome = 'Hola Super Admin';

  // Buttons
  static const String logout = 'Cerrar Sesión';
}
