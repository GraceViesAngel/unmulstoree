import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() =>
      _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan pesan wajib diisi.')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      final res = await Supabase.instance.client.functions.invoke(
        'send-notification',
        body: {'title': title, 'body': body},
      );

      if (mounted) {
        final data = res.data as Map<String, dynamic>?;
        final success = data?['success'] as int? ?? 0;
        final failed = data?['failed'] as int? ?? 0;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failed > 0
                  ? 'Terkirim ke $success perangkat, $failed gagal.'
                  : 'Notifikasi terkirim ke $success perangkat.',
            ),
          ),
        );

        if (failed > 0) {
          final errors = (data?['errors'] as List?)?.cast<String>() ?? [];
          if (errors.isNotEmpty && mounted) {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(
                  'Gagal Dikirim',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: errors.length,
                    itemBuilder: (_, i) => Padding(
                      padding: EdgeInsets.only(bottom: i < errors.length - 1 ? 8 : 0),
                      child: Text(
                        errors[i],
                        style: GoogleFonts.poppins(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          }
        }

        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('not deployed') || msg.contains('404')) {
        if (mounted) {
          _showDeployInstructions();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal: $e')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showDeployInstructions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Deploy Edge Function',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Fungsi backend belum di-deploy. Ikuti langkah berikut:',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 12),
              _step('1. Buka console.firebase.google.com'),
              _step(
                '2. Project Settings → Service Accounts → Generate New Private Key → Download JSON',
              ),
              _step('3. Buka supabase.com → Dashboard → Edge Functions'),
              _step('4. Set secrets:'),
              _step('   FCM_PROJECT_ID = project_id dari JSON'),
              _step('   FCM_CLIENT_EMAIL = client_email dari JSON'),
              _step('   FCM_PRIVATE_KEY = private_key dari JSON'),
              _step('5. Install Supabase CLI: npm install -g supabase'),
              _step('6. Di terminal: supabase login'),
              _step(
                '7. supabase link --project-ref <project-id>',
              ),
              _step('8. supabase functions deploy send-notification'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _step(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.poppins(fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1B1B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Kirim Notifikasi',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1B1B1B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Judul Notifikasi',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B1B1B),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF1B1B1B),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Contoh: Promo Spesial',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF64748B).withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFCC00),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Pesan',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B1B1B),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              maxLines: 4,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF1B1B1B),
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Isi pesan notifikasi...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF64748B).withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.all(16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFFFCC00),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _sending ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFCC00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _sending
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF1B1B1B),
                        ),
                      )
                    : Text(
                        'Kirim Notifikasi ke Semua Pengguna',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1B1B1B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
