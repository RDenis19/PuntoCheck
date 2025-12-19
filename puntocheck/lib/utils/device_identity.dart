import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class DeviceIdentity {
  const DeviceIdentity({
    required this.id,
    required this.model,
    required this.platform,
  });

  /// ID estable generado por la app (por instalacion).
  final String id;
  final String model;
  final String platform;
}

const _deviceIdKey = 'puntocheck_device_id';
const _storage = FlutterSecureStorage();

Future<String?> readAppDeviceId() async {
  try {
    final existing = await _storage.read(key: _deviceIdKey);
    final trimmed = existing?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  } catch (_) {
    return null;
  }
}

bool isValidAppDeviceId(String id) {
  final v = id.trim();
  if (v.length < 3 || v.length > 80) return false;
  return RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*[A-Za-z0-9]$').hasMatch(v);
}

Future<void> setAppDeviceId(String id) async {
  final trimmed = id.trim();
  if (!isValidAppDeviceId(trimmed)) {
    throw Exception('Device ID invalido');
  }
  await _storage.write(key: _deviceIdKey, value: trimmed);
}

/// Borra el ID actual y genera uno nuevo (UUID v4). Retorna el nuevo ID.
Future<String> resetAppDeviceId() async {
  try {
    await _storage.delete(key: _deviceIdKey);
  } catch (_) {
    // ignore
  }
  final generated = _uuidV4();
  try {
    await _storage.write(key: _deviceIdKey, value: generated);
  } catch (_) {
    // ignore
  }
  return generated;
}

Future<DeviceIdentity> getDeviceIdentity() async {
  final appDeviceId = await _getOrCreateAppDeviceId();

  if (kIsWeb) {
    return DeviceIdentity(id: appDeviceId, model: 'web', platform: 'web');
  }

  final deviceInfo = DeviceInfoPlugin();

  try {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = await deviceInfo.androidInfo;
        return DeviceIdentity(
          id: appDeviceId,
          model: '${android.brand} ${android.model}',
          platform: 'android',
        );
      case TargetPlatform.iOS:
        final ios = await deviceInfo.iosInfo;
        return DeviceIdentity(
          id: appDeviceId,
          model: ios.name,
          platform: 'ios',
        );
      case TargetPlatform.macOS:
        final mac = await deviceInfo.macOsInfo;
        return DeviceIdentity(
          id: appDeviceId,
          model: mac.model,
          platform: 'macos',
        );
      case TargetPlatform.windows:
        final win = await deviceInfo.windowsInfo;
        return DeviceIdentity(
          id: appDeviceId,
          model: win.computerName,
          platform: 'windows',
        );
      case TargetPlatform.linux:
        final linux = await deviceInfo.linuxInfo;
        return DeviceIdentity(
          id: appDeviceId,
          model: linux.name,
          platform: 'linux',
        );
      case TargetPlatform.fuchsia:
        return DeviceIdentity(
          id: appDeviceId,
          model: 'fuchsia',
          platform: 'fuchsia',
        );
    }
  } catch (_) {
    // fallback below
  }

  return DeviceIdentity(id: appDeviceId, model: 'unknown', platform: 'unknown');
}

Future<String> _getOrCreateAppDeviceId() async {
  final existing = await readAppDeviceId();
  if (existing != null) return existing;

  final generated = _uuidV4();
  try {
    await _storage.write(key: _deviceIdKey, value: generated);
  } catch (_) {
    // ignore: if we can't persist, at least return a value for this session
  }
  return generated;
}

String _uuidV4() {
  final rng = Random.secure();
  final bytes = Uint8List(16);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = rng.nextInt(256);
  }

  // Set version to 4 (0100)
  bytes[6] = (bytes[6] & 0x0F) | 0x40;
  // Set variant to RFC 4122 (10xx)
  bytes[8] = (bytes[8] & 0x3F) | 0x80;

  String b(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
  return '${b(0)}${b(1)}${b(2)}${b(3)}-'
      '${b(4)}${b(5)}-'
      '${b(6)}${b(7)}-'
      '${b(8)}${b(9)}-'
      '${b(10)}${b(11)}${b(12)}${b(13)}${b(14)}${b(15)}';
}
