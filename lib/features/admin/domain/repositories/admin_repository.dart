import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/admin_model.dart';
import 'package:flutter/foundation.dart';


class AdminRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AdminModel?> adminLogin(String email, String password) async {
    try {
      debugPrint('Attempting admin login with email: $email');

      // Login menggunakan Supabase Auth
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      debugPrint('Auth response: ${response.user}');

      if (response.user != null) {
        final user = response.user!;

        // Fungsi pembantu untuk cek role secara aman
        bool isAdminRole(String? r) {
          if (r == null) return false;
          final lowRole = r.toLowerCase().trim();
          return lowRole == 'admin' || lowRole == 'superadmin';
        }

        // 1. Coba ambil role dari user metadata
        String? role = user.userMetadata?['role'] as String?;
        debugPrint('User role from metadata: $role');

        // 2. Coba ambil dari auth role (kolom role di auth.users)
        if (!isAdminRole(role)) {
          if (user.role != null && user.role != 'authenticated') {
            role = user.role;
            debugPrint('User role from auth.role column: $role');
          }
        }

        // 3. Jika masih bukan admin, coba ambil dari tabel profiles
        if (!isAdminRole(role)) {
          try {
            final profileData = await _supabase
                .from('profiles')
                .select() // Ambil semua kolom yang ada saja
                .eq('id', user.id)
                .single();
            role = profileData['role'] as String?;
            debugPrint('User role from profiles table: $role');
          } catch (e) {
            debugPrint(
              'Note: Role column might be missing in profiles table or other error: $e',
            );
          }
        }

        // Cek final apakah user adalah admin atau superadmin
        if (isAdminRole(role)) {
          final admin = AdminModel(
            id: user.id.toString(),
            email: user.email ?? email,
            password: '',
            fullName: user.userMetadata?['full_name'] as String? ?? 'Admin',
            role: role!.toLowerCase().trim(),
            createdAt: DateTime.now(),
            lastLogin: DateTime.now(),
          );
          debugPrint(
            'Admin login successful: ${admin.email} - role: ${admin.role}',
          );
          return admin;
        } else {
          // User bukan admin - logout dan return null
          debugPrint('User is not admin, role: $role');
          await _supabase.auth.signOut();
          return null;
        }
      }

      debugPrint('No user returned from auth');
      return null;
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      if (e.message.contains('Invalid login') || e.statusCode == '400') {
        return null;
      }
      rethrow;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllPesanan() async {
    // Pembelian: false atau null (data lama / migrasi).
    const purchaseFilter = 'is_rental.is.null,is_rental.eq.false';
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*), profiles(*)')
          .or(purchaseFilter)
          .order('created_at', ascending: false);
      return _castOrderRows(response);
    } catch (e) {
      debugPrint('getAllPesanan (with profiles): $e — retry without embed');
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .or(purchaseFilter)
          .order('created_at', ascending: false);
      return _castOrderRows(response);
    }
  }

  List<Map<String, dynamic>> _castOrderRows(dynamic response) {
    final list = response as List<dynamic>;
    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> updateStatusPesanan(String orderId, String status) async {
    await _supabase.from('orders').update({'status': status}).eq('id', orderId);
  }

  Future<void> setDisetujui(String orderId) async {
    await _supabase
        .from('orders')
        .update({'status': 'Disetujui'})
        .eq('id', orderId);
  }

  Future<void> setDitolak(String orderId, {required String reason}) async {
    await _supabase.from('orders').update({
      'status': 'Ditolak',
      'rejection_reason': reason.trim(),
    }).eq('id', orderId);
  }

  Future<void> setDikemas(String orderId) async {
    await _supabase
        .from('orders')
        .update({'status': 'DiKemas'})
        .eq('id', orderId);
  }

  Future<void> setSiapDiambil(String orderId) async {
    await _supabase
        .from('orders')
        .update({'status': 'Siap Diambil'})
        .eq('id', orderId);
  }

  Future<void> setDikirim(String orderId) async {
    await _supabase
        .from('orders')
        .update({'status': 'Dikirim'})
        .eq('id', orderId);
  }

  Future<void> setSelesai(String orderId) async {
    await _supabase
        .from('orders')
        .update({'status': 'Selesai'})
        .eq('id', orderId);
  }

  Future<void> setMasaSewaAktif(String orderId) async {
    final orderData = await _supabase
        .from('orders')
        .select('rental_duration')
        .eq('id', orderId)
        .single();
    final int duration = orderData['rental_duration'] ?? 3;

    final now = DateTime.now();
    final deadline = now.add(Duration(days: duration));

    await _supabase
        .from('orders')
        .update({
          'status': 'Dalam Masa Sewa',
          'delivered_at': now.toIso8601String(),
          'return_deadline': deadline.toIso8601String(),
        })
        .eq('id', orderId);
  }

  Future<void> setDikembalikan(String orderId) async {
    await _supabase
        .from('orders')
        .update({'status': 'Dikembalikan'})
        .eq('id', orderId);
  }

  Future<List<Map<String, dynamic>>> getAllPenyewaan() async {
    try {
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*), profiles(*)')
          .eq('is_rental', true)
          .order('created_at', ascending: false);
      return _castOrderRows(response);
    } catch (e) {
      debugPrint('getAllPenyewaan (with profiles): $e — retry without embed');
      final response = await _supabase
          .from('orders')
          .select('*, order_items(*)')
          .eq('is_rental', true)
          .order('created_at', ascending: false);
      return _castOrderRows(response);
    }
  }

  Future<void> updateDurasiSewa(String orderId, int durasi) async {
    await _supabase
        .from('orders')
        .update({'rental_duration': durasi})
        .eq('id', orderId);
  }

  Future<void> mulaiSewa(String orderId) async {
    // Get the current order to find its duration
    final orderData = await _supabase
        .from('orders')
        .select('rental_duration')
        .eq('id', orderId)
        .single();
    final int duration = orderData['rental_duration'] ?? 3;

    final now = DateTime.now();
    final deadline = now.add(Duration(days: duration));

    await _supabase
        .from('orders')
        .update({
          'status': 'Dalam Masa Sewa',
          'delivered_at': now.toIso8601String(),
          'return_deadline': deadline.toIso8601String(),
        })
        .eq('id', orderId);
  }

  Future<void> konfirmasiDikembalikan(String orderId) async {
    await _supabase
        .from('orders')
        .update({
          'status': 'Dikembalikan',
          'return_date': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId);
  }

  Future<void> setDiterima(String orderId) async {
    await _supabase
        .from('orders')
        .update({'status': 'Diterima'})
        .eq('id', orderId);
  }

  Future<List<Map<String, dynamic>>> getDenda() async {
    final now = DateTime.now();

    final orders = await _supabase
        .from('orders')
        .select()
        .eq('status', 'Dalam Masa Sewa');

    List<Map<String, dynamic>> keterlambatan = [];
    for (var order in orders) {
      final returnDeadline = order['return_deadline'];
      if (returnDeadline != null) {
        final deadline = DateTime.parse(returnDeadline);

        if (now.isAfter(deadline)) {
          final hariTerlambat = now.difference(deadline).inDays;
          // Gunakan late_fee dari pesanan, default 20000 jika belum ada
          final int orderLateFee = order['late_fee'] != null 
              ? (order['late_fee'] as num).toInt() 
              : 20000;
          
          final denda = hariTerlambat * orderLateFee;
          keterlambatan.add({
            ...order,
            'hari_terlambat': hariTerlambat,
            'denda': denda,
          });
        }
      }
    }
    return keterlambatan;
  }

  Future<void> validasiDenda(String orderId, int denda) async {
    await _supabase.from('orders').update({'denda': denda}).eq('id', orderId);
  }

  Future<void> setSelesaiSewa(String orderId) async {
    final now = DateTime.now();
    await _supabase
        .from('orders')
        .update({'status': 'Selesai', 'return_date': now.toIso8601String()})
        .eq('id', orderId);
  }

  Future<void> inputKurir(String orderId, String kurir) async {
    await _supabase.from('orders').update({'kurir': kurir}).eq('id', orderId);
  }

  Future<void> inputNomorResi(String orderId, String resi) async {
    await _supabase
        .from('orders')
        .update({'resi': resi, 'status': 'Dikirim'})
        .eq('id', orderId);
  }

  Future<List<Map<String, dynamic>>> getStatistik() async {
    final totalPesanan = await _supabase.from('orders').select();

    final pesananSelesai = await _supabase
        .from('orders')
        .select()
        .eq('status', 'Selesai');

    final pesananAktif = await _supabase
        .from('orders')
        .select()
        .or(
          'status.eq.DiKemas,status.eq.Dikirim,status.eq.Dalam Masa Sewa,status.eq.Siap Diambil',
        );

    final pesananBatal = await _supabase
        .from('orders')
        .select()
        .eq('status', 'Ditolak');

    return [
      {'label': 'Total Pesanan', 'value': totalPesanan.length},
      {'label': 'Pesanan Selesai', 'value': pesananSelesai.length},
      {'label': 'Pesanan Aktif', 'value': pesananAktif.length},
      {'label': 'Pesanan Ditolak', 'value': pesananBatal.length},
    ];
  }
}
