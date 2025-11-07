class Validators {
  static String? requiredField(String? value, {String message = "Campo obligatorio"}) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  }

  static String? email(String? value) {
    if (requiredField(value) != null) {
      return "Ingresa tu correo";
    }
    final emailRegex = RegExp(r"^[\\w\\.-]+@[\\w\\.-]+\\.[a-zA-Z]{2,}");
    if (!emailRegex.hasMatch(value!.trim())) {
      return "Correo inválido";
    }
    return null;
  }

  static String? password(String? value) {
    if (requiredField(value) != null) {
      return "Ingresa tu contraseña";
    }
    if (value!.length < 8) {
      return "Mínimo 8 caracteres";
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    final result = password(value);
    if (result != null) {
      return result;
    }
    if (value!.trim() != original.trim()) {
      return "Las contraseñas no coinciden";
    }
    return null;
  }

  static String? phone(String? value) {
    if (requiredField(value) != null) {
      return "Ingresa tu número";
    }
    final cleaned = value!.replaceAll(' ', '');
    final ecuPattern = RegExp(r'^\+593\d{7,9}$');
    final localPattern = RegExp(r'^\d{10}$');
    if (!ecuPattern.hasMatch(cleaned) && !localPattern.hasMatch(cleaned)) {
      return "Formato +593 xxx o 10 dígitos";
    }
    return null;
  }
}
