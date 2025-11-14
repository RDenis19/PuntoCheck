import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:puntocheck/backend/data/models/user_model.dart';

class SupabaseUserDatasource {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> createUser(UserModel user) async {
    // Build payload from model but avoid inserting fields that are
    // already stored in the `auth.users` table (email, timestamps, etc.)
    final Map<String, dynamic> payload = Map<String, dynamic>.from(user.toMap());

    // Remove fields that duplicate auth.users columns to avoid redundancy
    // and potential conflicts with defaults / FK behaviour.
    payload.remove('email');
    payload.remove('created_at');
    payload.remove('updated_at');

    try {
      // Return the inserted row (if your table has triggers/defaults)
      await _client.from('profiles').insert(payload).select().maybeSingle();
    } catch (e) {
      // Re-throw with a clearer message for upstream handling/logging
      throw Exception('Error inserting profile into profiles: $e');
    }
  }

  Future<UserModel?> getUser(String uid) async {
    final data = await _client
      .from('profiles')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final data = await _client
      .from('profiles')
        .select()
        .ilike('email', email)
        .maybeSingle();

    if (data == null) return null;
    return UserModel.fromMap(Map<String, dynamic>.from(data));
  }

  Future<void> updateUser(UserModel user) async {
    await _client.from('profiles').update(user.toMap()).eq('id', user.id);
  }
}
