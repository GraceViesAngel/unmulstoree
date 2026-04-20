import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../../core/theme/app_theme.dart';

Map<String, dynamic>? _profilesFromOrder(dynamic raw) {
  if (raw == null) return null;
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is List) {
    for (final e in raw) {
      if (e is Map<String, dynamic>) return e;
      if (e is Map) return Map<String, dynamic>.from(e);
    }
  }
  return null;
}

class KelolaPenyewaanScreen extends StatefulWidget {
  const KelolaPenyewaanScreen({super.key});

  @override
  State<KelolaPenyewaanScreen> createState() => _KelolaPenyewaanScreenState();
}

class _KelolaPenyewaanScreenState extends State<KelolaPenyewaanScreen> {
  static const String _rentalSeenKey = 'admin_last_seen_rental_pending_at';
  final AdminRepository _repo = AdminRepository();
  List<Map<String, dynamic>> _allPenyewaan = [];
  List<Map<String, dynamic>> _filteredPenyewaan = [];
  bool _isLoading = true;
  String? _loadError;

  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'Semua';

  final List<String> _statusFilters = [
    'Semua',
    'Menunggu Verifikasi',
    'DiKemas',
    'Siap Diambil',
    'Dalam Masa Sewa',
    'Selesai',
    'Dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _loadPenyewaan();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPenyewaan() async {
    setState(() {
      _loadError = null;
      _isLoading = true;
    });
    try {
      final penyewaan = await _repo.getAllPenyewaan();
      if (mounted) {
        setState(() {
          _allPenyewaan = penyewaan;
          _filteredPenyewaan = penyewaan;
          _isLoading = false;
          _loadError = null;
        });
        _applyFilters();
        _markPendingAsSeen(penyewaan);
      }
    } catch (e, st) {
      debugPrint('KelolaPenyewaan _loadPenyewaan error: $e\n$st');
      if (mounted) {
        setState(() {
          _allPenyewaan = [];
          _filteredPenyewaan = [];
          _isLoading = false;
          _loadError = e.toString();
        });
      }
    }
  }

  Future<void> _markPendingAsSeen(List<Map<String, dynamic>> orders) async {
    DateTime? latestPending;
    for (final order in orders) {
      final isRental = order['is_rental'] == true;
      final status = (order['status'] ?? '').toString().trim();
      if (!isRental || status != 'Menunggu Verifikasi') continue;
      final createdAt = DateTime.tryParse(
        (order['created_at'] ?? '').toString(),
      );
      if (createdAt == null) continue;
      if (latestPending == null || createdAt.isAfter(latestPending)) {
        latestPending = createdAt;
      }
    }

    if (latestPending != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rentalSeenKey, latestPending.toIso8601String());
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPenyewaan = _allPenyewaan.where((p) {
        bool matchesStatus = false;
        if (_selectedStatus == 'Semua') {
          matchesStatus = true;
        } else if (_selectedStatus == 'Terlambat') {
          if (p['return_deadline'] != null) {
            final deadline = DateTime.parse(p['return_deadline']);
            matchesStatus =
                deadline.isBefore(DateTime.now()) &&
                (p['status'] == 'Dalam Masa Sewa');
          }
        } else {
          matchesStatus = (p['status'] ?? '') == _selectedStatus;
        }

        final query = _searchController.text.toLowerCase();
        final profiles = _profilesFromOrder(p['profiles']);
        final name = (profiles?['full_name'] ?? '').toString().toLowerCase();
        final orderId = (p['order_id_display'] ?? '').toString().toLowerCase();

        return matchesStatus &&
            (name.contains(query) || orderId.contains(query));
      }).toList();
    });
  }

  int _calculateCurrentLateFine(Map<String, dynamic> order) {
    final returnDeadlineRaw = order['return_deadline'];
    if (returnDeadlineRaw == null) return 0;
    final deadline = DateTime.tryParse(returnDeadlineRaw.toString());
    if (deadline == null) return 0;
    final now = DateTime.now();
    if (!now.isAfter(deadline)) return 0;
    final daysLate =
        (now.difference(deadline).inSeconds / Duration.secondsPerDay).ceil();
    final lateFeeRaw = (order['late_fee'] ?? 0) as num;
    final lateFeePerDay = lateFeeRaw.toInt() > 0 ? lateFeeRaw.toInt() : 20000;
    return daysLate * lateFeePerDay;
  }

  Future<void> _updateStatus(
    String orderId,
    String status,
    String currentStatus, {
    bool isCancelApproved = false,
    String? rejectionReason,
    int? lateFineAmount,
  }) async {
    try {
      debugPrint(
        'DEBUG _updateStatus: orderId=$orderId, newStatus=$status, currentStatus=$currentStatus, isCancelApproved=$isCancelApproved',
      );

      // Handle pembatalan
      if (isCancelApproved) {
        await _repo.updateStatusPesanan(orderId, 'Dibatalkan');
      } else if (currentStatus == 'Menunggu Verifikasi' &&
          status != 'Ditolak') {
        await _repo.approveOrderAndReduceStock(orderId, status);
      } else if (status == 'Dalam Masa Sewa') {
        await _repo.mulaiSewa(orderId);
      } else if (status == 'Selesai') {
        if ((lateFineAmount ?? 0) > 0) {
          await _repo.validasiDenda(orderId, lateFineAmount!);
        }
        await _repo.konfirmasiDikembalikan(orderId);
      } else if (currentStatus == 'Menunggu Verifikasi' &&
          status == 'Ditolak') {
        final r = (rejectionReason ?? '').trim();
        if (r.length < 10) {
          throw Exception('Alasan penolakan minimal 10 karakter.');
        }
        await _repo.setDitolak(orderId, reason: r);
      } else {
        await _repo.updateStatusPesanan(orderId, status);
      }
      if (mounted) {
        _showSweetAlert(
          title: 'Berhasil!',
          message: 'Status sewa berhasil diperbarui ke $status',
        );
        _loadPenyewaan();
      }
    } catch (e) {
      if (mounted) {
        _showSweetAlert(
          title: 'Gagal',
          message: 'Gagal update status: $e',
          isError: true,
        );
      }
    }
  }

  Future<void> _showLateFeeConfirmDialog({
    required String orderId,
    required String currentStatus,
    required int denda,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Pembayaran Denda',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'Apakah pengguna telah membayar denda senilai Rp $denda?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Belum'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sudah'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _updateStatus(
        orderId,
        'Selesai',
        currentStatus,
        lateFineAmount: denda,
      );
    }
  }

  void _showRejectVerificationDialog({
    required String orderId,
    required String currentStatus,
  }) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            final ok = controller.text.trim().length >= 10;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Tolak verifikasi sewa',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alasan akan ditampilkan kepada penyewa. Wajib diisi (minimal 10 karakter).',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText:
                            'Contoh: Produk tidak tersedia untuk tanggal tersebut.',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        counterText: '',
                      ),
                      onChanged: (_) => setLocal(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.poppins(color: Colors.grey),
                  ),
                ),
                FilledButton(
                  onPressed: ok
                      ? () {
                          Navigator.pop(ctx);
                          _updateStatus(
                            orderId,
                            'Ditolak',
                            currentStatus,
                            rejectionReason: controller.text.trim(),
                          );
                        }
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                  ),
                  child: Text(
                    'Tolak penyewaan',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => controller.dispose());
  }

  void _showSweetAlert({
    required String title,
    required String message,
    bool isError = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Oke'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, String>? _getNextStatusInfo(Map<String, dynamic> pesanan) {
    final String currentStatus = (pesanan['status'] ?? '').toString().trim();

    debugPrint('DEBUG: currentStatus=$currentStatus');

    if (currentStatus == 'Selesai' ||
        currentStatus == 'Ditolak' ||
        currentStatus == 'Dibatalkan' ||
        currentStatus == 'Menunggu Pembatalan') {
      if (currentStatus == 'Menunggu Pembatalan') {
        return {'next': 'NEED_CANCEL_DIALOG', 'label': 'Proses Pembatalan'};
      }
      if (currentStatus == 'Ditolak') {
        return {'next': 'Dibatalkan', 'label': 'Batalkan'};
      }
      return null;
    }

    switch (currentStatus) {
      case 'Menunggu Verifikasi':
        return {'next': 'DiKemas', 'label': 'Verifikasi & Kemas'};
      case 'DiKemas':
      case 'Disetujui':
        return {'next': 'Siap Diambil', 'label': 'Siap Diambil'};
      case 'Siap Diambil':
        return {'next': 'Dalam Masa Sewa', 'label': 'Mulai Sewa'};
      case 'Dalam Masa Sewa':
        return {'next': 'Selesai', 'label': 'Konfirmasi Kembali'};
      case 'Selesai':
        return null;
      case 'Diterima':
        return {'next': 'Selesai', 'label': 'Selesaikan Sewa'};
      case 'Terlambat':
        return {'next': 'Selesai', 'label': 'Konfirmasi Kembali'};
      case 'Dibatalkan':
        return null;
      default:
        debugPrint('DEBUG: Status tidak dikenali - $currentStatus');
        return null;
    }
  }

  void _showCancelRequestDialog(
    Map<String, dynamic> pesanan,
    String cancelReason,
  ) {
    final String orderId = pesanan['id'];
    final String currentStatus = (pesanan['status'] ?? '').toString().trim();
    final String? previousStatus = pesanan['previous_status'] as String?;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFE6E6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Permintaan Pembatalan',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alasan Pembatalan:',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cancelReason,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF1B1B1B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    _updateStatus(
                      orderId,
                      'Dibatalkan',
                      currentStatus,
                      isCancelApproved: true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Terima Pembatalan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    _updateStatus(
                      orderId,
                      previousStatus ?? 'Menunggu Verifikasi',
                      currentStatus,
                      isCancelApproved: false,
                    );
                  },
                  child: Text(
                    'Tolak Pembatalan',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOrderDetailDialog(Map<String, dynamic> item) {
    final items = item['order_items'] as List? ?? [];
    final profiles = _profilesFromOrder(item['profiles']) ?? {};
    final status = item['status'] ?? 'Menunggu';
    final denda = _calculateCurrentLateFine(item);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Detail Sewa',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text('ID: ${item['order_id_display'] ?? '-'}'),
                Text('Status: $status'),
                Text('Penyewa: ${profiles['full_name'] ?? 'Guest'}'),
                if (item['return_deadline'] != null)
                  Text(
                    'Deadline: ${item['return_deadline'].toString().substring(0, 10)}',
                  ),
                Text('Denda Berjalan: Rp $denda'),
                const Divider(),
                ...items.map(
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('${i['product_title']} x ${i['quantity']}'),
                  ),
                ),
                const Divider(),
                Text(
                  'Total: Rp ${item['total_price']}',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    return Column(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(scrollbars: false),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, i) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final status = _statusFilters[index];
                final isSelected = _selectedStatus == status;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedStatus = status);
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFCC00)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFCC00)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF1B1B1B)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari nama penyewa / ID pesanan',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Menunggu Verifikasi':
        return Colors.orange;
      case 'Disetujui':
        return Colors.blue;
      case 'Dikemas':
        return Colors.purple;
      case 'Siap Diambil':
        return Colors.indigo;
      case 'Dalam Masa Sewa':
        return Colors.blueAccent;
      case 'Dikembalikan':
        return Colors.teal;
      case 'Diterima':
        return Colors.green;
      case 'Selesai':
        return Colors.green;
      case 'Dibatalkan':
        return Colors.red;
      case 'Ditolak':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCompactInfo(
    IconData icon,
    String value, {
    bool isPrice = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isPrice ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  void _showUpdateStatusDialog(Map<String, dynamic> pesanan) {
    final String orderId = pesanan['id'];
    final String currentStatus = (pesanan['status'] ?? 'Menunggu')
        .toString()
        .trim();
    final String? cancelReason = pesanan['cancellation_reason'] as String?;

    debugPrint(
      'DEBUG _showUpdateStatusDialog: orderId=$orderId, status=$currentStatus',
    );

    final info = _getNextStatusInfo(pesanan);
    debugPrint('DEBUG _getNextStatusInfo result: $info');

    if (info == null) {
      _showSweetAlert(
        title: 'Info',
        message:
            'Status penyewaan "$currentStatus" tidak dapat diupdate melalui tombol ini.',
      );
      return;
    }

    if (info['next'] == 'NEED_CANCEL_DIALOG') {
      _showCancelRequestDialog(pesanan, cancelReason ?? 'Tidak ada alasan');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7CC),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFFCC00), width: 4),
                ),
                child: const Icon(
                  Icons.edit_note_rounded,
                  color: Color(0xFF1B1B1B),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Update Status Sewa',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B1B1B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lanjut ke tahap berikutnya: $currentStatus ke ${info['next']}',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final navigator = Navigator.of(context);
                    navigator.pop();
                    if (currentStatus == 'Dalam Masa Sewa' &&
                        info['next'] == 'Selesai') {
                      final denda = _calculateCurrentLateFine(pesanan);
                      _showLateFeeConfirmDialog(
                        orderId: orderId,
                        currentStatus: currentStatus,
                        denda: denda,
                      );
                      return;
                    }
                    _updateStatus(orderId, info['next']!, currentStatus);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    info['label']!,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              if (currentStatus == 'Menunggu Verifikasi') ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TextButton(
                    onPressed: () {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      _showRejectVerificationDialog(
                        orderId: orderId,
                        currentStatus: currentStatus,
                      );
                    },
                    child: Text(
                      'Tolak Penyewaan',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyOrErrorBody() {
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_outlined, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat penyewaan',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Admin perlu policy RLS untuk orders & order_items — lihat '
                'supabase/migrations/20260419130000_admin_rls_orders_profiles.sql',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _loadPenyewaan,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: Text('Tidak ada penyewaan'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Kelola Penyewaan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchSection(),
                _buildFilterSection(),
                Expanded(
                  child: _filteredPenyewaan.isEmpty
                      ? _buildEmptyOrErrorBody()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          itemCount: _filteredPenyewaan.length,
                          itemBuilder: (context, index) {
                            final pesanan = _filteredPenyewaan[index];
                            final String status =
                                pesanan['status'] ?? 'Menunggu';
                            final Color statusColor = _getStatusColor(status);
                            final lateFine = _calculateCurrentLateFine(pesanan);
                            final items = pesanan['order_items'] as List? ?? [];
                            final String? firstImage = items.isNotEmpty
                                ? items[0]['image_path']
                                : null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Order ID',
                                                  style: GoogleFonts.poppins(
                                                    color: const Color(
                                                      0xFF94A3B8,
                                                    ),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                Text(
                                                  '#${pesanan['order_id_display'] ?? pesanan['id'].toString().substring(0, 8).toUpperCase()}',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: const Color(
                                                      0xFF1B1B1B,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: statusColor.withOpacity(
                                                  0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                status,
                                                style: GoogleFonts.poppins(
                                                  color: statusColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 20),
                                        Row(
                                          children: [
                                            Container(
                                              width: 60,
                                              height: 60,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                color: Colors.grey[100],
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFF1F5F9,
                                                  ),
                                                ),
                                              ),
                                              child: firstImage != null
                                                  ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      child: Image.network(
                                                        firstImage,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              c,
                                                              e,
                                                              s,
                                                            ) => const Icon(
                                                              Icons
                                                                  .broken_image,
                                                              size: 24,
                                                            ),
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.image_outlined,
                                                      size: 24,
                                                      color: Colors.grey,
                                                    ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _buildCompactInfo(
                                                    Icons.person_outline,
                                                    _profilesFromOrder(
                                                          pesanan['profiles'],
                                                        )?['full_name'] ??
                                                        'Guest',
                                                  ),
                                                  const SizedBox(height: 4),
                                                  _buildCompactInfo(
                                                    Icons.payments_outlined,
                                                    'Rp ${pesanan['total_price'] ?? 0}',
                                                    isPrice: true,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (lateFine > 0) ...[
                                          const SizedBox(height: 10),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEF2F2),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Terlambat - Denda berjalan Rp $lateFine',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: const Color(0xFFDC2626),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFF1F5F9),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextButton.icon(
                                            onPressed: () =>
                                                _showOrderDetailDialog(pesanan),
                                            icon: const Icon(
                                              Icons.visibility_outlined,
                                              size: 18,
                                            ),
                                            label: const Text('Detail'),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFF64748B,
                                              ),
                                              textStyle: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (status != 'Selesai' &&
                                            status != 'Dibatalkan' &&
                                            status != 'Diterima') ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            flex: 2,
                                            child: ElevatedButton(
                                              onPressed: () =>
                                                  _showUpdateStatusDialog(
                                                    pesanan,
                                                  ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    AppTheme.primaryColor,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: Text(
                                                'Update Status',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
