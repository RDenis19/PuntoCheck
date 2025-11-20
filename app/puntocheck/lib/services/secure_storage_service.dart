/// Simula `flutter_secure_storage` en memoria para esta demo.
class SecureStorageService {
  static const String keyBiometricEnabled = 'biometric_enabled';
  static const String keyRememberedEmail = 'remembered_email';
  static const String keySessionToken = 'session_token';
  static const String keyBiometricSessionToken = 'biometric_session_token';

  final Map<String, String> _inMemoryStore = <String, String>{};

  Future<void> write(String key, String value) async {
    _inMemoryStore[key] = value;
  }

  Future<String?> read(String key) async => _inMemoryStore[key];

  Future<void> delete(String key) async {
    _inMemoryStore.remove(key);
  }

  Future<void> deleteKeys(Iterable<String> keys) async {
    for (final key in keys) {
      _inMemoryStore.remove(key);
    }
  }

  Future<void> writeFlag(String key, bool value) => write(key, value.toString());

  Future<bool> readFlag(String key) async => (_inMemoryStore[key]?.toLowerCase() == 'true');
}
