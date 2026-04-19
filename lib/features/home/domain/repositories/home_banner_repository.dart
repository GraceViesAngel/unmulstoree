import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class HomeBannerRepository {
  final SupabaseClient _c = Supabase.instance.client;

  Future<List<String>> fetchBannerUrls() async {
    try {
      final rows = await _c
          .from('home_banners')
          .select('slot,image_url')
          .order('slot', ascending: true);
      final list = rows as List<dynamic>;
      return list
          .map(
            (e) => Map<String, dynamic>.from(e as Map)['image_url'] as String,
          )
          .where((u) => u.trim().isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> upsertBannerSlot({
    required int slot,
    required Uint8List bytes,
    required String contentType,
  }) async {
    if (slot < 1 || slot > 3) {
      throw ArgumentError('slot must be 1..3');
    }
    final ext = contentType.contains('png') ? 'png' : 'jpg';
    final path = 'slot_${slot}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    await _c.storage
        .from('banners')
        .uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: false),
        );
    final url = _c.storage.from('banners').getPublicUrl(path);
    await _c.from('home_banners').upsert({
      'slot': slot,
      'image_url': url,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> removeBannerSlot(int slot) async {
    if (slot < 1 || slot > 3) return;
    await _c.from('home_banners').delete().eq('slot', slot);
  }

  Future<Map<int, String>> fetchBannerSlots() async {
    try {
      final rows = await _c
          .from('home_banners')
          .select('slot,image_url')
          .order('slot', ascending: true);
      final map = <int, String>{};
      for (final e in rows as List<dynamic>) {
        final m = e as Map<String, dynamic>;
        map[(m['slot'] as num).toInt()] = m['image_url'] as String;
      }
      return map;
    } catch (e) {
      return {};
    }
  }
}
