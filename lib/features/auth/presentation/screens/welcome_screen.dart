import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/deferred_navigation.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/secondary_button.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment(
              0,
              -0.2,
            ), // Membaur dengan putih lebih cepat (sekitar bagian atas-tengah)
            colors: [
              Color(0xFFFFF9E0), // Kuning super lembut / pale warm yellow
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                // Custom Illustration from Assets
                Expanded(
                  child: Image.asset(
                    'assets/images/welcome.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Selamat Datang\nDi Unmul Store',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF1B1B1B),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Login untuk menjelajahi dan memesan\nproduk Unmul Store dengan mudah.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF4B4B4B),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                PrimaryButton(
                  text: 'Masuk',
                  onPressed: () {
                    context.push('/login');
                  },
                ),
                const SizedBox(height: 16),
                SecondaryButton(
                  text: 'Daftar',
                  onPressed: () {
                    context.push('/register');
                  },
                ),
                const SizedBox(height: 32),
                Text.rich(
                  TextSpan(
                    text: 'By entering my phone number, I accept ',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                    children: [
                      TextSpan(
                        text: "Unmul Store's terms\n",
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      TextSpan(
                        text: 'and ',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      TextSpan(
                        text: 'personal data.',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
