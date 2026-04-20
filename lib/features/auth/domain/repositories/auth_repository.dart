import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<bool> checkEmailExists(String email) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: 'dummy_check',
      );
      return response.session != null;
    } on AuthException {
      // If sign in fails, could be because email doesn't exist
      // or password is wrong - we assume email might exist
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<AuthResponse> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('Supabase AuthException: ${e.message} (Status: ${e.statusCode})');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during signUp: $e');
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signInWithPhone(String phone, String password) async {
    return await _supabase.auth.signInWithPassword(
      phone: phone,
      password: password,
    );
  }

  Future<AuthResponse> signUpWithPhone(
    String phone,
    String password,
    String name,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        phone: phone,
        password: password,
        data: {'full_name': name},
      );
      return response;
    } on AuthException catch (e) {
      debugPrint('Supabase AuthException: ${e.message} (Status: ${e.statusCode})');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected error during signUpWithPhone: $e');
      rethrow;
    }
  }

  Future<AuthResponse> verifyOtp(String phone, String token) async {
    return await _supabase.auth.verifyOTP(
      type: OtpType.sms,
      token: token,
      phone: phone,
    );
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
}
