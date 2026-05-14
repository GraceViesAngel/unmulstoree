import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../core/theme/app_theme.dart';

class VerifyPendingScreen extends StatefulWidget {
  final String email;
  final String name;

  const VerifyPendingScreen({
    super.key,
    required this.email,
    required this.name,
  });

  @override
  State<VerifyPendingScreen> createState() => _VerifyPendingScreenState();
}

class _VerifyPendingScreenState extends State<VerifyPendingScreen> {
  bool _isLoading = false;
  int _resendCooldown = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _checkVerificationStatus() {
    // Show message to user - they need to check their email
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Silakan klik link verifikasi di email Anda, lalu login dengan email dan password.',
        ),
      ),
    );
  }

  Future<void> _resendVerificationEmail() async {
    if (_resendCooldown > 0) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.email,
        email: widget.email,
        emailRedirectTo: kIsWeb ? null : 'io.supabase.pab://login-callback/',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email verifikasi telah dikirim ulang')),
        );
        setState(() => _resendCooldown = 60);
        _startCooldownTimer();
      }
    } on AuthException catch (e) {
      if (mounted) {
        String errorMessage = 'Gagal mengirim ulang';

        if (e.statusCode == '429' || e.message.contains('rate limit')) {
          errorMessage =
              'Terlalu banyak percobaan. Silakan tunggu beberapa detik lalu coba lagi.';
        } else if (e.message.contains('Email rate limit exceeded')) {
          errorMessage =
              'Batas pengiriman email tercapai. Tunggu sebentar lalu coba lagi.';
        } else {
          errorMessage = 'Gagal mengirim ulang: ${e.message}';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));

        setState(() => _resendCooldown = 60);
        _startCooldownTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengirim ulang: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCooldownTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown > 0) {
        setState(() => _resendCooldown--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textColor),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.email_outlined,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verifikasi Email Anda',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF1B1B1B),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kami telah mengirim link verifikasi ke email Anda.\nSilakan klik link tersebut untuk mengaktifkan akun.',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF4B4B4B),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.email,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1B1B1B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Coba Login',
                isLoading: _isLoading,
                onPressed: _checkVerificationStatus,
              ),
              const SizedBox(height: 16),
              if (_resendCooldown > 0)
                Text(
                  'Kirim ulang dalam 00:${_resendCooldown.toString().padLeft(2, '0')}',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                GestureDetector(
                  onTap: _resendVerificationEmail,
                  child: Text(
                    'Kirim Ulang Link Verifikasi',
                    style: GoogleFonts.poppins(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Text(
                  'Belum menerima email? Periksa folder spam Anda',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
