import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/confirm_action_sheet.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String? role;

  const AdminDashboardScreen({super.key, this.role});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminRepository _repo = AdminRepository();
  late String _userRole;
  DateTime _lastSeenPurchase = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSeenRental = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _userRole = widget.role ?? 'admin';
    _loadSeenState();
  }

  Future<void> _loadSeenState() async {
    final purchaseTs = await _repo.getGlobalPurchaseSeenTimestamp();
    final rentalTs = await _repo.getGlobalRentalSeenTimestamp();
    if (!mounted) return;
    setState(() {
      _lastSeenPurchase = purchaseTs ?? DateTime.fromMillisecondsSinceEpoch(0);
      _lastSeenRental = rentalTs ?? DateTime.fromMillisecondsSinceEpoch(0);
    });
  }

  Future<void> _markPurchaseSeen() async {
    await _repo.markPurchasePendingSeen();
    await _loadSeenState();
  }

  Future<void> _markRentalSeen() async {
    await _repo.markRentalPendingSeen();
    await _loadSeenState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _repo.watchOrdersRealtimeWithPolling(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Gagal memuat dashboard: ${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final orders = snapshot.data ?? const <Map<String, dynamic>>[];
          final stats = _computeStats(orders);
          final pendingPurchase = _countPendingByType(
            orders,
            isRental: false,
            lastSeen: _lastSeenPurchase,
          );
          final pendingRental = _countPendingByType(
            orders,
            isRental: true,
            lastSeen: _lastSeenRental,
          );
          // UX request: indikator cukup "1" / titik merah, tidak perlu angka besar.
          final indicatorPurchase = pendingPurchase > 0 ? 1 : 0;
          final indicatorRental = pendingRental > 0 ? 1 : 0;

          return SafeArea(
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // Modern Header with Grey Placeholder Profile
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Default Grey Placeholder Profile
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.grey[500],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Admin Dashboard',
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF1B1B1B),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  _userRole.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Logout Button with Red Icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.logout,
                              color: Colors.red,
                              size: 18,
                            ),
                            onPressed: () async {
                              final confirm = await showConfirmActionSheet(
                                context,
                                variant: ConfirmActionVariant.logout,
                              );
                              if (confirm == true && mounted) {
                                await Supabase.instance.client.auth.signOut();
                                if (mounted) context.go('/');
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Statistik Cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Statistik Toko',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1B1B1B),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (stats.isEmpty)
                          _buildEmptyStats()
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 1.6,
                                ),
                            itemCount: stats.length,
                            itemBuilder: (context, index) {
                              final stat = stats[index];
                              return _buildStatCard(stat);
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),

                // Management Menu
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manajemen Operasional',
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF1B1B1B),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProfessionalMenu(
                          icon: Icons.assignment_outlined,
                          title: 'Kelola Pembelian',
                          subtitle: 'Status pembelian & pembayaran',
                          color: Colors.blue,
                          notificationCount: indicatorPurchase,
                          onTap: () async {
                            await _markPurchaseSeen();
                            await context.push('/admin-pesanan');
                          },
                        ),
                        _buildProfessionalMenu(
                          icon: Icons.calendar_today_outlined,
                          title: 'Kelola Penyewaan',
                          subtitle: 'Logistik peminjaman produk',
                          color: Colors.orange,
                          notificationCount: indicatorRental,
                          onTap: () async {
                            await _markRentalSeen();
                            await context.push('/admin-penyewaan');
                          },
                        ),
                        _buildProfessionalMenu(
                          icon: Icons.photo_library_outlined,
                          title: 'Banner Beranda',
                          subtitle: 'Maks. 3 gambar promo (carousel)',
                          color: Colors.teal,
                          onTap: () => context.push('/admin-banners'),
                        ),
                        _buildProfessionalMenu(
                          icon: Icons.notifications_active_outlined,
                          title: 'Kirim Notifikasi',
                          subtitle: 'Push notification ke semua pengguna',
                          color: Colors.orange,
                          onTap: () => context.push('/admin-notifikasi'),
                        ),

                        if (_userRole == 'superadmin') ...[
                          const SizedBox(height: 32),
                          Text(
                            'Menu Super Admin',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1B1B1B),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildProfessionalMenu(
                            icon: Icons.admin_panel_settings,
                            title: 'Super Admin Panel',
                            subtitle: 'Kelola Admin & Produk',
                            color: Colors.indigo,
                            onTap: () => context.push('/superadmin'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _computeStats(List<Map<String, dynamic>> orders) {
    final totalPesanan = orders.length;

    final sewaAktif = orders.where((order) {
      final isRental = order['is_rental'] == true;
      if (!isRental) return false;
      final status = (order['status'] ?? '').toString().trim();
      return status != 'Selesai' &&
          status != 'Ditolak' &&
          status != 'Dibatalkan';
    }).length;

    final pesananSelesai = orders.where((order) {
      final status = (order['status'] ?? '').toString().trim();
      return status == 'Selesai' || status == 'Diterima';
    }).length;

    final pesananDibatalkan = orders.where((order) {
      final status = (order['status'] ?? '').toString().trim();
      return status == 'Ditolak' ||
          status == 'Dibatalkan' ||
          status == 'Menunggu Pembatalan';
    }).length;

    return [
      {'label': 'Total Pesanan', 'value': totalPesanan},
      {'label': 'Sewa Aktif', 'value': sewaAktif},
      {'label': 'Pesanan Selesai', 'value': pesananSelesai},
      {'label': 'Pesanan Dibatalkan', 'value': pesananDibatalkan},
    ];
  }

  int _countPendingByType(
    List<Map<String, dynamic>> orders, {
    required bool isRental,
    required DateTime lastSeen,
  }) {
    return orders.where((order) {
      final orderIsRental = order['is_rental'] == true;
      final status = (order['status'] ?? '').toString().trim();
      final createdAt = DateTime.tryParse(
        (order['created_at'] ?? '').toString(),
      );
      if (createdAt == null) return false;
      return orderIsRental == isRental &&
          status == 'Menunggu Verifikasi' &&
          createdAt.isAfter(lastSeen);
    }).length;
  }

  Widget _buildEmptyStats() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          'Gagal memuat data statistik',
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildStatCard(Map<String, dynamic> stat) {
    final String label = stat['label'] ?? '';
    final Color valueColor = _getStatColor(label);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${stat['value']}',
            style: GoogleFonts.poppins(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatColor(String label) {
    final l = label.toLowerCase();
    if (l.contains('selesai')) return Colors.green[700]!;
    if (l.contains('aktif')) return Colors.orange[700]!;
    if (l.contains('batal')) return Colors.red[700]!;
    return const Color(0xFF1B1B1B);
  }

  Widget _buildProfessionalMenu({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    int notificationCount = 0,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF1B1B1B),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notificationCount > 0)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFFCBD5E1),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
