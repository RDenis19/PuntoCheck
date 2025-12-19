import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Captura una imagen directamente desde la cámara
  static Future<File?> pickImageFromCamera() async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      try {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1024,
          maxHeight: 1024,
          preferredCameraDevice: CameraDevice.rear,
        );
        
        if (photo != null) {
          return File(photo.path);
        }
      } catch (e) {
        debugPrint('Error al capturar foto: $e');
      }
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    return null;
  }
}
