import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SafeImagePickerResult {
  const SafeImagePickerResult({
    this.file,
    this.permissionDenied = false,
    this.permanentlyDenied = false,
    this.errorMessage,
  });

  final File? file;
  final bool permissionDenied;
  final bool permanentlyDenied;
  final String? errorMessage;

  bool get hasFile => file != null;
}

/// Wrapper para centralizar permisos y recuperacion de imagenes perdidas.
class SafeImagePicker {
  SafeImagePicker({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  Future<SafeImagePickerResult> pickImage({
    required ImageSource source,
    double maxWidth = 1200,
    double? maxHeight,
    int imageQuality = 90,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final status = await _requestPermission(source);
    if (!status.isGranted && !status.isLimited) {
      return SafeImagePickerResult(
        permissionDenied: true,
        permanentlyDenied: status.isPermanentlyDenied,
      );
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: preferredCameraDevice,
      );
      if (picked != null) {
        final persisted = await _persistXFile(picked);
        return SafeImagePickerResult(file: persisted);
      }
    } catch (e, st) {
      debugPrint('Image pick failed: $e\n$st');
      return SafeImagePickerResult(errorMessage: e.toString());
    }

    return const SafeImagePickerResult();
  }

  Future<File?> recoverLostImage() async {
    if (!Platform.isAndroid) return null;

    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;

      final XFile? lostFile = response.file ??
          ((response.files?.isNotEmpty ?? false) ? response.files!.first : null);
      if (lostFile != null) {
        return _persistXFile(lostFile);
      }
      if (response.exception != null) {
        debugPrint('retrieveLostData error: ${response.exception}');
      }
    } catch (e, st) {
      debugPrint('retrieveLostData failed: $e\n$st');
    }
    return null;
  }

  Future<File> _persistXFile(XFile source) async {
    final bytes = await source.readAsBytes();
    if (bytes.isEmpty) {
      throw Exception('La imagen capturada está vacía.');
    }

    final tmpDir = await getTemporaryDirectory();
    final ext = _safeExtension(source.name) ?? _safeExtension(source.path) ?? 'jpg';
    final fileName = 'picked_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final outFile = File('${tmpDir.path}/$fileName');
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile;
  }

  String? _safeExtension(String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    final dot = v.lastIndexOf('.');
    if (dot == -1 || dot == v.length - 1) return null;
    final ext = v.substring(dot + 1).toLowerCase();
    if (ext.length > 5) return null;
    if (!RegExp(r'^[a-z0-9]+$').hasMatch(ext)) return null;
    return ext;
  }

  Future<PermissionStatus> _requestPermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      return Permission.camera.request();
    }

    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          return Permission.photos.request();
        }
      } catch (e, st) {
        debugPrint('Device info lookup failed: $e\n$st');
      }
      return Permission.storage.request();
    }

    return Permission.photos.request();
  }
}
