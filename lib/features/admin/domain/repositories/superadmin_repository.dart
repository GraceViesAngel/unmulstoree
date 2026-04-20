import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SuperAdminRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _extractError(dynamic data) {
    if (data is Map) {
      final dynamic error = data['error'];
      if (error != null) return error.toString();
      final dynamic message = data['message'];
      if (message != null) return message.toString();
    }
    return null;
  }

  // --- 1. GLOBAL SETTINGS ---

  // Default values jika tabel kosong atau key belum ada
  static const Map<String, num> _defaults = {
    'late_fee_per_day': 20000,
    'default_deposit': 50000,
    'default_rental_duration': 3,
  };

  Future<Map<String, dynamic>> getGlobalSettings() async {
    try {
      final response = await _supabase.from('global_settings').select();
      Map<String, dynamic> settings = {};
      for (var row in response) {
        settings[row['key']] = row['value'];
      }
      // Merge dengan defaults agar key yang belum ada tetap memiliki nilai
      for (var entry in _defaults.entries) {
        settings.putIfAbsent(entry.key, () => entry.value);
      }
      return settings;
    } catch (e) {
      debugPrint('Error fetching global settings: $e');
      // Return defaults saat terjadi error (misal tabel belum ada)
      return Map<String, dynamic>.from(_defaults);
    }
  }

  Future<void> updateGlobalSetting(String key, num value) async {
    try {
      await _supabase.from('global_settings').upsert({
        'key': key,
        'value': value,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');
    } catch (e) {
      debugPrint('Error updating global setting: $e');
      throw Exception('Gagal menyimpan pengaturan: $e');
    }
  }

  /// Ambil tarif denda per hari dari global_settings
  Future<int> getLateFeePerDay() async {
    try {
      final settings = await getGlobalSettings();
      return (settings['late_fee_per_day'] as num?)?.toInt() ?? 20000;
    } catch (e) {
      debugPrint('Error fetching late fee: $e');
      return 20000; // Fallback default
    }
  }

  // --- 2. ADMIN MANAGEMENT ---

  Future<List<Map<String, dynamic>>> getAdminsOnly() async {
    try {
      final profiles = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'admin')
          .order('updated_at', ascending: false);
      return List<Map<String, dynamic>>.from(profiles);
    } catch (e) {
      debugPrint('Error fetching admins: $e');
      return [];
    }
  }

  Future<void> updateAdmin(String id, String name, String phone) async {
    try {
      final response = await _supabase.functions.invoke(
        'update-admin-profile',
        body: {'id': id, 'name': name, 'phone': phone},
      );

      final errorMessage = _extractError(response.data);
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }

      if (response.status != 200) {
        throw Exception(errorMessage ?? 'Gagal mengubah data admin');
      }
    } catch (e) {
      if (e is FunctionException) {
        final details = e.details;
        if (details is Map && details['error'] != null) {
          throw Exception(details['error'].toString());
        }
        throw Exception('Gagal mengubah data admin (kode: ${e.status})');
      }
      debugPrint('Error updating admin: $e');
      throw Exception('Gagal mengubah data admin: $e');
    }
  }

  Future<void> createAdmin(String name, String email, String password) async {
    try {
      final response = await _supabase.functions.invoke(
        'create-admin',
        body: {'name': name, 'email': email, 'password': password},
      );

      final errorMessage = _extractError(response.data);
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }

      if (response.status != 200) {
        throw Exception(errorMessage ?? 'Gagal membuat admin');
      }
    } catch (e) {
      if (e is FunctionException) {
        final details = e.details;
        if (details is Map && details['error'] != null) {
          throw Exception(details['error'].toString());
        }
        if (e.status == 422) {
          throw Exception(
            'Email sudah terdaftar atau data admin tidak valid. Coba email lain.',
          );
        }
        throw Exception('Gagal membuat admin (kode: ${e.status})');
      }
      debugPrint('Error creating admin: $e');
      throw Exception('Gagal membuat admin: $e');
    }
  }

  Future<void> updateUserRole(String profileId, String role) async {
    try {
      await _supabase
          .from('profiles')
          .update({'role': role})
          .eq('id', profileId);
    } catch (e) {
      debugPrint('Error updating role: $e');
      throw Exception('Gagal mengubah role: $e');
    }
  }

  // --- 3. PRODUCT MANAGEMENT ---

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error fetching products: $e');
      return [];
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _supabase.from('products').delete().eq('id', id);
    } catch (e) {
      debugPrint('Error deleting product: $e');
      throw Exception('Gagal menghapus produk: $e');
    }
  }

  // To be implemented fully when storage is ready
  Future<void> saveProduct(Map<String, dynamic> productData) async {
    try {
      if (productData.containsKey('id') && productData['id'] != null) {
        await _supabase
            .from('products')
            .update(productData)
            .eq('id', productData['id']);
      } else {
        productData.remove('id');
        await _supabase.from('products').insert(productData);
      }
    } catch (e) {
      debugPrint('Error saving product: $e');
      throw Exception('Gagal menyimpan produk: $e');
    }
  }
}
