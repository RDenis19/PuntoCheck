class FirebaseStorageDatasource {
  Future<String?> uploadProfilePhoto(String uid, {String? localPath}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (localPath == null) {
      return null;
    }
    // Aquí se llamaría a FirebaseStorage para subir el archivo real.
    return 'https://picsum.photos/seed/${uid.hashCode}/300/300';
  }
}
