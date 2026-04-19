import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../shared/widgets/confirm_action_sheet.dart';
import '../../data/models/profile_model.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1B1B1B),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: FutureBuilder<ProfileModel?>(
        future: _profileRepository.getCurrentProfile(),
        builder: (context, snapshot) {
          final profile = snapshot.data;

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Profile Info Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: profile?.avatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  profile!.avatarUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      ),
                                ),
                              )
                            : Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[200],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile?.fullName ?? 'Ahmad Sepriza',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B1B1B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (profile?.phoneNumber?.isNotEmpty != true)
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 18,
                                color: Color(0xFFF59E0B),
                              ),
                            if (profile?.phoneNumber?.isNotEmpty != true)
                              const SizedBox(width: 4),
                            Text(
                              profile?.phoneNumber?.isNotEmpty == true
                                  ? profile!.phoneNumber!
                                  : 'nomor hp belum di isi',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight:
                                    profile?.phoneNumber?.isNotEmpty == true
                                    ? FontWeight.normal
                                    : FontWeight.w500,
                                color: profile?.phoneNumber?.isNotEmpty == true
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Edit Profile Button
                      ElevatedButton.icon(
                        onPressed: () => context.push('/edit-profile'),
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: Color(0xFF1B1B1B),
                        ),
                        label: Text(
                          'Edit profile',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1B1B1B),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFCC00),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Menu Utama Section
                _buildSectionHeader('Menu Utama'),
                _buildMenuItem(
                  icon: Icons.assignment_outlined,
                  title: 'Pesanan Saya',
                  onTap: () => context.push('/order-history?showBack=true'),
                ),
                _buildMenuItem(
                  icon: Icons.access_time_outlined,
                  title: 'Penyewaan Aktif',
                  onTap: () =>
                      context.push('/order-history?initialTab=1&showBack=true'),
                ),
                _buildMenuItem(
                  icon: Icons.history_outlined,
                  title: 'Riwayat Transaksi',
                  onTap: () => context.push('/order-history?showBack=true'),
                ),

                const SizedBox(height: 24),

                // Keluar Section
                _buildSectionHeader('Keluar'),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Keluar Akun',
                  iconColor: Colors.red,
                  textColor: Colors.red,
                  onTap: () async {
                    final confirm = await showConfirmActionSheet(
                      context,
                      variant: ConfirmActionVariant.logout,
                    );
                    if (confirm == true && mounted) {
                      await _profileRepository.signOut();
                      if (context.mounted) {
                        context.go('/');
                      }
                    }
                  },
                ),

                const SizedBox(height: 120), // Padding for bottom bar
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    String? iconPath,
    IconData? icon,
    required String title,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF1B1B1B),
    Color textColor = const Color(0xFF1B1B1B),
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: iconPath != null
          ? SvgPicture.asset(
              iconPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            )
          : Icon(icon, color: iconColor, size: 24),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
