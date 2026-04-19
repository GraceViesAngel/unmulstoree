import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../home/domain/repositories/home_banner_repository.dart';

class KelolaBannerScreen extends StatefulWidget {
  const KelolaBannerScreen({super.key});

  @override
  State<KelolaBannerScreen> createState() => _KelolaBannerScreenState();
}

class _KelolaBannerScreenState extends State<KelolaBannerScreen> {
  final HomeBannerRepository _repo = HomeBannerRepository();
  final ImagePicker _picker = ImagePicker();

  Map<int, String> _slotToUrl = {};
  bool _loading = true;
  int? _uploadingSlot;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final map = await _repo.fetchBannerSlots();
      if (mounted) {
        setState(() {
          _slotToUrl = map;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload(int slot) async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (x == null || !mounted) return;

    setState(() => _uploadingSlot = slot);
    try {
      final bytes = await x.readAsBytes();
      final name = x.name.toLowerCase();
      final isPng = name.endsWith('.png');
      await _repo.upsertBannerSlot(
        slot: slot,
        bytes: Uint8List.fromList(bytes),
        contentType: isPng ? 'image/png' : 'image/jpeg',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Banner slot $slot berhasil diperbarui.')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal upload: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingSlot = null);
    }
  }

  Future<void> _hapus(int slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Hapus banner?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Slot $slot akan dikosongkan.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _repo.removeBannerSlot(slot);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Banner slot $slot dihapus.')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Banner Beranda',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Maksimal 3 banner. Lebih dari satu gambar di beranda tampil sebagai carousel otomatis.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 20),
                for (int slot = 1; slot <= 3; slot++) _buildSlotCard(slot),
              ],
            ),
    );
  }

  Widget _buildSlotCard(int slot) {
    final url = _slotToUrl[slot];
    final busy = _uploadingSlot == slot;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slot $slot',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 16 / 7,
                child: url != null && url.isNotEmpty
                    ? Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                    : Container(
                        color: const Color(0xFFF1F5F9),
                        alignment: Alignment.center,
                        child: Text(
                          'Belum ada gambar',
                          style: GoogleFonts.poppins(color: Colors.grey),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : () => _pickAndUpload(slot),
                    icon: busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload, size: 20),
                    label: Text(busy ? 'Mengunggah...' : 'Pilih dan unggah'),
                  ),
                ),
                if (url != null && url.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: busy ? null : () => _hapus(slot),
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
