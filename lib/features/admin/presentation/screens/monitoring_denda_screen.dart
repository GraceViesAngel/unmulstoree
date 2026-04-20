import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/confirm_action_sheet.dart';

class MonitoringDendaScreen extends StatefulWidget {
  const MonitoringDendaScreen({super.key});

  @override
  State<MonitoringDendaScreen> createState() => _MonitoringDendaScreenState();
}

class _MonitoringDendaScreenState extends State<MonitoringDendaScreen> {
  final AdminRepository _repo = AdminRepository();
  List<Map<String, dynamic>> _denda = [];
  List<Map<String, dynamic>> _filteredDenda = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  String _formatPrice(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDenda();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDenda() async {
    try {
      final denda = await _repo.getDenda();
      if (mounted) {
        setState(() {
          _denda = denda;
          _filteredDenda = denda;
          _isLoading = false;
        });
        _applyFilters();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredDenda = _denda.where((item) {
        if (query.isEmpty) return true;
        final orderId = (item['order_id_display'] ?? item['id'] ?? '')
            .toString()
            .toLowerCase();
        final profileRaw = item['profiles'];
        String customerName = '';
        if (profileRaw is Map && profileRaw['full_name'] != null) {
          customerName = profileRaw['full_name'].toString().toLowerCase();
        } else if (profileRaw is List && profileRaw.isNotEmpty) {
          final first = profileRaw.first;
          if (first is Map && first['full_name'] != null) {
            customerName = first['full_name'].toString().toLowerCase();
          }
        }
        return orderId.contains(query) || customerName.contains(query);
      }).toList();
    });
  }

  Future<void> _validasiDenda(String orderId, int denda) async {
    final ok = await showConfirmActionSheet(
      context,
      variant: ConfirmActionVariant.custom,
      title: 'Validasi denda?',
      message:
          'Apakah Anda yakin ingin memvalidasi denda sebesar Rp ${denda.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} untuk pesanan ini?',
      confirmLabel: 'Validasi',
      icon: Icons.fact_check_rounded,
      iconBackgroundColor: const Color(0xFFE0F2FE),
      iconColor: const Color(0xFF0284C7),
      confirmBackgroundColor: const Color(0xFF0284C7),
    );
    if (ok != true || !mounted) return;

    try {
      await _repo.validasiDenda(orderId, denda);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Denda berhasil divalidasi')),
        );
        _loadDenda();
      }
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B1B1B)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Monitoring Denda',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1B1B1B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredDenda.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada keterlambatan',
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Cari order / nama pelanggan',
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
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredDenda.length,
                    itemBuilder: (context, index) {
                      final item = _filteredDenda[index];
                      final lateFeePerDay =
                          (item['late_fee'] as num?)?.toInt() ?? 0;
                      final profileRaw = item['profiles'];
                      String customerName = 'Pelanggan';
                      if (profileRaw is Map &&
                          profileRaw['full_name'] != null) {
                        customerName = profileRaw['full_name'].toString();
                      } else if (profileRaw is List && profileRaw.isNotEmpty) {
                        final first = profileRaw.first;
                        if (first is Map && first['full_name'] != null) {
                          customerName = first['full_name'].toString();
                        }
                      }
                      final orderItems = item['order_items'];
                      String productSummary = '-';
                      if (orderItems is List && orderItems.isNotEmpty) {
                        final first = orderItems.first;
                        if (first is Map) {
                          final title = (first['product_title'] ?? 'Produk')
                              .toString();
                          final qty = (first['quantity'] ?? 1).toString();
                          productSummary = '$title x $qty';
                        }
                      }
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order #${item['order_id_display'] ?? item['id'].toString().substring(0, 8)}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'Terlambat ${item['hari_terlambat']} hari',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              customerName,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF334155),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              productSummary,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Batas Pengembalian: ${item['return_deadline']?.toString().substring(0, 10) ?? '-'}',
                              style: GoogleFonts.poppins(fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Biaya keterlambatan: Rp ${_formatPrice(lateFeePerDay)} / hari',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Denda Berjalan: Rp ${_formatPrice((item['denda'] as num?)?.toInt() ?? 0)}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _validasiDenda(
                                  item['id'],
                                  item['denda'] ?? 0,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                ),
                                child: Text(
                                  'Validasi Denda',
                                  style: GoogleFonts.poppins(
                                    color: Colors.black,
                                  ),
                                ),
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
