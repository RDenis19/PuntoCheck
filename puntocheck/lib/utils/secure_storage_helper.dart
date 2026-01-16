import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureLocalStorage extends LocalStorage {
  final FlutterSecureStorage _storage;

  SecureLocalStorage()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences:
              true,
        ),
        iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
      );

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final result = await _storage.containsKey(key: supabasePersistSessionKey);
    return result;
  }

  @override
  Future<String?> accessToken() async {
    return await _storage.read(key: supabasePersistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    return await _storage.write(
      key: supabasePersistSessionKey,
      value: persistSessionString,
    );
  }

  @override
  Future<void> removePersistedSession() async {
    return await _storage.delete(key: supabasePersistSessionKey);
  }
}
