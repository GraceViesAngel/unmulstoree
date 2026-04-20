import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pab/core/theme/app_theme.dart';
import 'kelola_admin_screen.dart';
import 'kelola_produk_screen.dart';

class SuperadminMainScreen extends StatelessWidget {
  const SuperadminMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Super Admin',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: const Color(0xFF94A3B8),
            indicatorColor: AppTheme.primaryColor,
            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
            tabs: const [
              Tab(text: 'Admin'),
              Tab(text: 'Produk'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            KelolaAdminScreen(),
            KelolaProdukScreen(),
          ],
        ),
      ),
    );
  }
}
