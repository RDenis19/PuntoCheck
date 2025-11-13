import 'dart:math';

class FirebaseAuthDatasource {
  Future<String> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 350));
    final record = _FakeAuthStore.records[email.toLowerCase()];
    if (record == null || record.password != password) {
      throw Exception('Credenciales inválidas');
    }
    _FakeAuthStore.currentUid = record.uid;
    return record.uid;
  }

  Future<String> signUp(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_FakeAuthStore.records.containsKey(email.toLowerCase())) {
      throw Exception('Ya existe una cuenta con este correo');
    }
    final uid = _FakeAuthStore.generateUid();
    _FakeAuthStore.records[email.toLowerCase()] = _AuthRecord(uid: uid, email: email, password: password);
    _FakeAuthStore.currentUid = uid;
    return uid;
  }

  Future<void> sendResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_FakeAuthStore.records.containsKey(email.toLowerCase())) {
      throw Exception('No encontramos una cuenta con ese correo');
    }
    // Aquí se llamaría a FirebaseAuth.sendPasswordResetEmail(email).
  }

  Future<void> updatePassword(String uid, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final entry = _FakeAuthStore.records.entries.firstWhere(
      (element) => element.value.uid == uid,
      orElse: () => throw Exception('No existe la sesión activa'),
    );
    entry.value.password = newPassword;
  }

  String? get currentUserId => _FakeAuthStore.currentUid;

  void resumeSession(String uid) {
    _FakeAuthStore.currentUid = uid;
  }

  String? findUidByEmail(String email) => _FakeAuthStore.records[email.toLowerCase()]?.uid;
}

class _AuthRecord {
  final String uid;
  final String email;
  String password;

  _AuthRecord({required this.uid, required this.email, required this.password});
}

class _FakeAuthStore {
  static final Random _random = Random();
  static final Map<String, _AuthRecord> records = <String, _AuthRecord>{};
  static String? currentUid;

  static String generateUid() {
    final buffer = StringBuffer('uid_');
    buffer.write(DateTime.now().millisecondsSinceEpoch);
    buffer.write('_');
    buffer.write(_random.nextInt(9999));
    return buffer.toString();
  }
}
