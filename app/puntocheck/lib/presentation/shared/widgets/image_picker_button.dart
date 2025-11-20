import 'dart:io';
import 'package:flutter/material.dart';
import 'package:puntocheck/utils/camera_helper.dart';
import 'package:puntocheck/utils/theme/app_colors.dart';

class ImagePickerButton extends StatelessWidget {
  final File? imageFile;
  final Function(File?) onImageSelected;
  final String label;

  const ImagePickerButton({
    super.key,
    this.imageFile,
    required this.onImageSelected,
    this.label = 'Tomar Foto',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () async {
            // Directamente abrir la cámara, sin diálogo de selección
            final File? image = await CameraHelper.pickImageFromCamera();
            if (image != null) {
              onImageSelected(image);
            }
          },
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              image: imageFile != null
                  ? DecorationImage(
                      image: FileImage(imageFile!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: imageFile == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (imageFile != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => onImageSelected(null),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            label: const Text(
              'Eliminar foto',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ],
    );
  }
}
