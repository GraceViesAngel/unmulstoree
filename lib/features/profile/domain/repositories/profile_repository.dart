import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pab/features/profile/data/models/profile_model.dart';

class ProfileRepository {
  final _supabase = Supabase.instance.client;

  /// Unggah foto profil ke bucket `avatars` (path: `{userId}/avatar.jpg`).
  /// Mengembalikan URL publik untuk disimpan di `avatar_url`.
  Future<String> uploadUserAvatar({
    required String userId,
    required Uint8List bytes,
    required bool isPng,
  }) async {
    final ext = isPng ? 'png' : 'jpg';
    final contentType = isPng ? 'image/png' : 'image/jpeg';
    final path = '$userId/avatar.$ext';
    await _supabase.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _supabase.storage.from('avatars').getPublicUrl(path);
  }

  Future<ProfileModel?> getCurrentProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      return ProfileModel.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateProfile(ProfileModel profile) async {
    try {
      final existing = await getCurrentProfile();
      if (existing == null) {
        await _supabase.from('profiles').insert({
          'id': profile.id,
          'full_name': profile.fullName,
          'phone_number': profile.phoneNumber,
          'city': profile.city,
          'street': profile.street,
          'avatar_url': profile.avatarUrl,
        });
      } else {
        await _supabase
            .from('profiles')
            .update({
              'full_name': profile.fullName,
              'phone_number': profile.phoneNumber,
              'city': profile.city,
              'street': profile.street,
              'avatar_url': profile.avatarUrl,
            })
            .eq('id', profile.id);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }
  
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }
}
