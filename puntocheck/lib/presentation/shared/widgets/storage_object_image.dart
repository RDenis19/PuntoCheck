import 'package:flutter/material.dart';
import 'package:puntocheck/services/storage_service.dart';

class StorageObjectImage extends StatelessWidget {
  const StorageObjectImage({
    super.key,
    required this.bucketId,
    required this.pathOrUrl,
    this.fit = BoxFit.cover,
    this.signedUrlExpiresInSeconds = 60 * 10,
  });

  final String bucketId;
  final String pathOrUrl;
  final BoxFit fit;
  final int signedUrlExpiresInSeconds;

  bool _isHttpUrl(String value) {
    final v = value.trim().toLowerCase();
    return v.startsWith('http://') || v.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final raw = pathOrUrl.trim();
    if (raw.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sin evidencia'),
        ),
      );
    }

    if (_isHttpUrl(raw)) {
      return Image.network(
        raw,
        fit: fit,
        errorBuilder: (_, __, ___) => const Center(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('No se pudo cargar la evidencia'),
          ),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
      );
    }

    return FutureBuilder<String>(
      future: StorageService.instance.getSignedUrl(
        bucketId,
        raw,
        expiresIn: signedUrlExpiresInSeconds,
      ),
      builder: (context, snap) {
        final url = snap.data?.trim() ?? '';
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (url.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No se pudo cargar la evidencia'),
            ),
          );
        }
        return Image.network(
          url,
          fit: fit,
          errorBuilder: (_, __, ___) => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No se pudo cargar la evidencia'),
            ),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        );
      },
    );
  }
}

