import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
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
    int imageQuality = 90,
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
        imageQuality: imageQuality,
      );
      if (picked != null) {
        return SafeImagePickerResult(file: File(picked.path));
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
        return File(lostFile.path);
      }
      if (response.exception != null) {
        debugPrint('retrieveLostData error: ${response.exception}');
      }
    } catch (e, st) {
      debugPrint('retrieveLostData failed: $e\n$st');
    }
    return null;
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
