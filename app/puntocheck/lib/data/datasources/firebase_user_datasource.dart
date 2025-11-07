import 'package:puntocheck/data/models/user_model.dart';

class FirebaseUserDatasource {
  Future<void> createUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _FakeFirestore.users[user.id] = user.toMap();
  }

  Future<UserModel?> getUser(String uid) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final doc = _FakeFirestore.users[uid];
    if (doc == null) {
      return null;
    }
    return UserModel.fromMap(doc);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 150));
    try {
      final map = _FakeFirestore.users.values.firstWhere(
        (element) => (element['email'] as String).toLowerCase() == email.toLowerCase(),
      );
      return UserModel.fromMap(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUser(UserModel user) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!_FakeFirestore.users.containsKey(user.id)) {
      throw Exception('Usuario no encontrado');
    }
    _FakeFirestore.users[user.id] = user.toMap();
  }
}

class _FakeFirestore {
  static final Map<String, Map<String, dynamic>> users = <String, Map<String, dynamic>>{};
}
