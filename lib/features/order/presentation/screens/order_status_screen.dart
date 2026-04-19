import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../shared/widgets/confirm_action_sheet.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';

class OrderStatusScreen extends StatefulWidget {
  final String? orderId;

  const OrderStatusScreen({super.key, this.orderId});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  final OrderRepository _orderRepository = OrderRepository();
  OrderModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    if (widget.orderId == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final order = await _orderRepository.getOrderById(widget.orderId!);
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _formatPrice(int price) {
    return 'Rp${price.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}';
  }

  int _getStatusIndex(String status) {
    switch (status) {
      case 'Menunggu Verifikasi':
        return 0;
      case 'DiKemas':
        return 1;
      case 'Siap Diambil':
        return 2;
      case 'Dikirim':
        return 3;
      case 'Diterima':
        return 4;
      case 'Dalam Masa Sewa':
        return 5;
      case 'Dikembalikan':
        return 6;
      case 'Selesai':
        return 7;
      default:
        if (status == 'Dalam Masa Sewa') return 2;
        if (status == 'Dikembalikan') return 3;
        if (status == 'Selesai') return 4;
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Color(0xFF1B1B1B),
              size: 20,
            ),
            onPressed: () => context.go('/home'),
          ),
          title: Text(
            'Status Pesanan',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1B1B1B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        body: const Center(child: Text('Pesanan tidak ditemukan')),
      );
    }

    final isRental = _order!.isRental;
    final statusIndex = _getStatusIndex(_order!.status);
    final firstItem = _order!.items?.isNotEmpty == true
        ? _order!.items!.first
        : null;
    final itemCount = _order!.items?.length ?? 1;
    final paymentMethod = _order!.paymentMethod;
    final isCod = paymentMethod == 'COD';
    final isRejected = _order!.status == 'Ditolak';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF1B1B1B),
            size: 20,
          ),
          onPressed: () => context.go('/home'),
        ),
        title: Text(
          isRental ? 'Status Sewa' : 'Status Pesanan',
          style: GoogleFonts.poppins(
            color: const Color(0xFF1B1B1B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isRejected) _buildVerificationRejectedBanner(),
            if (!isRejected && isRental && _order!.status == 'Dalam Masa Sewa')
              ..._buildActiveRentalCards()
            else if (!isRejected)
              _buildTimelineSection(isCod, isRental, statusIndex),
            const SizedBox(height: 32),
            _buildOrderDetailCard(
              context,
              isCod,
              isRental,
              paymentMethod,
              firstItem,
              itemCount,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActiveRentalCards() {
    if (_order!.items == null ||
        _order!.items!.isEmpty ||
        _order!.returnDeadline == null) {
      return [];
    }

    return _order!.items!.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ActiveRentalCard(item: item, deadline: _order!.returnDeadline!),
      );
    }).toList();
  }

  Widget _buildVerificationRejectedBanner() {
    final reason = (_order!.rejectionReason ?? '').trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verifikasi ditolak',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: const Color(0xFF991B1B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Toko tidak dapat memproses pesanan ini. Alasan:',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reason.isNotEmpty
                ? reason
                : 'Tidak ada detail tambahan dari toko.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1B1B1B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // removed old _buildRentalTimerCard and _buildTimeUnit

  Widget _buildTimelineSection(bool isCod, bool isRental, int statusIndex) {
    if (isRental) {
      return Column(
        children: [
          _buildTimelineItem(
            'Menunggu Verifikasi',
            _order!.createdAt.toString().substring(0, 16),
            isCompleted: statusIndex >= 0,
            isPending: statusIndex == 0,
            isLast: false,
            icon: Icons.check,
          ),
          _buildTimelineItem(
            'Siap Diambil',
            'Silakan ambil di UNMUL STORE',
            isCompleted: statusIndex >= 1,
            isPending: statusIndex == 1,
            isLast: false,
            icon: Icons.storefront,
          ),
          _buildTimelineItem(
            'Masa Sewa Aktif',
            _order!.deliveredAt != null
                ? 'Dimulai sejak ${_order!.deliveredAt!.toString().substring(0, 10)}'
                : 'Menunggu barang sampai',
            isCompleted: statusIndex >= 2,
            isPending: statusIndex == 2,
            isLast: false,
            icon: Icons.timer_outlined,
          ),
          _buildTimelineItem(
            'Dikembalikan',
            'Barang telah dikembalikan',
            isCompleted: statusIndex >= 3,
            isPending: statusIndex == 3,
            isLast: false,
            icon: Icons.assignment_return_outlined,
          ),
          _buildTimelineItem(
            'Selesai',
            'Deposit telah dikembalikan',
            isCompleted: statusIndex >= 4,
            isPending: statusIndex == 4,
            isLast: true,
            icon: Icons.done_all,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildTimelineItem(
          'Menunggu Verifikasi',
          _order!.createdAt.toString().substring(0, 16),
          isCompleted: statusIndex >= 0,
          isPending: statusIndex == 0,
          isLast: false,
          icon: Icons.check,
        ),
        _buildTimelineItem(
          'DiKemas',
          'Barang sedang disiapkan',
          isCompleted: statusIndex >= 1,
          isPending: statusIndex == 1,
          isLast: false,
          icon: Icons.inventory_2_outlined,
        ),
        if (isCod)
          _buildTimelineItem(
            'Dikirim',
            'Kurir sedang dalam perjalanan',
            isCompleted: statusIndex >= 3,
            isPending: statusIndex == 3,
            isLast: false,
            icon: Icons.local_shipping_outlined,
          )
        else
          _buildTimelineItem(
            'Siap Diambil',
            'Silakan ambil di UNMUL STORE',
            isCompleted: statusIndex >= 2,
            isPending: statusIndex == 2,
            isLast: false,
            icon: Icons.storefront,
          ),
        _buildTimelineItem(
          'Selesai',
          isCod ? 'Barang telah diterima.' : 'Terima kasih telah berbelanja.',
          isCompleted: statusIndex >= 7,
          isPending: statusIndex == 7,
          isLast: true,
          icon: Icons.check,
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle, {
    required bool isCompleted,
    required bool isPending,
    required bool isLast,
    required IconData icon,
    String? description,
    bool isYellowDescription = false,
  }) {
    final Color completedColor = const Color(0xFF10B981);
    final Color pendingColor = const Color(0xFFE2E8F0);
    final Color currentColor = const Color(0xFFFFCC00);

    Color bgColor;
    Color iconColor;

    if (isCompleted) {
      bgColor = completedColor;
      iconColor = Colors.white;
    } else if (isPending) {
      bgColor = currentColor;
      iconColor = Colors.white;
    } else {
      bgColor = pendingColor;
      iconColor = const Color(0xFFCBD5E1);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isCompleted
                        ? completedColor.withValues(alpha: 0.3)
                        : pendingColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isCompleted || isPending
                          ? const Color(0xFF1B1B1B)
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                      height: 1.4,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isYellowDescription
                            ? const Color(0xFFFFCC00)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailCard(
    BuildContext context,
    bool isCod,
    bool isRental,
    String paymentMethod,
    OrderItemModel? firstItem,
    int itemCount,
  ) {
    final imagePath = firstItem?.imagePath ?? 'assets/images/workshirt.jpeg';
    final productTitle = firstItem?.productTitle ?? 'Produk';
    final productQuantity = firstItem?.quantity ?? 1;
    final variation = firstItem?.variation ?? 'Size: L';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imagePath.startsWith('http')
                    ? Image.network(
                        imagePath,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        imagePath,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            productTitle,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (itemCount > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '+$itemCount items',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      '$variation - Qty $productQuantity',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF334155),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatPrice(_order!.totalPrice),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: _DottedDivider(),
          ),
          if (paymentMethod != 'Bayar di Toko' && _order!.shippingCost > 0) ...[
            _buildDetailRow('Biaya Pengiriman', _formatPrice(_order!.shippingCost)),
            const SizedBox(height: 12),
          ],
          _buildDetailRow('Metode Pembayaran', paymentMethod),          if (isRental) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Durasi Sewa', '${_order!.rentalDuration} hari'),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Biaya Jaminan (Deposit)',
              _formatPrice(_order!.deposit),
            ),
            if (_order!.lateFee > 0) ...[
              const SizedBox(height: 12),
              _buildDetailRow(
                'Denda Keterlambatan',
                _formatPrice(_order!.lateFee),
                valueColor: const Color(0xFFEF4444),
              ),
            ],
          ],
          if (isCod || isRental) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Resi POS', _order!.resi ?? 'Belum Tersedia'),
          ],
          if (isRental && _order!.returnResi != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Resi Pengembalian', _order!.returnResi!),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jumlah Pembayaran',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
              Text(
                _formatPrice(_order!.totalPrice + _order!.lateFee),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: const Color(0xFFFFCC00),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isRental && _order!.status == 'Dalam Masa Sewa') ...[
            PrimaryButton(
              text: 'Kirim Balik & Input Resi',
              fontWeight: FontWeight.w900,
              onPressed: () => _showInputResiBalikDialog(context),
              prefixIcon: Icons.assignment_return_outlined,
            ),
          ] else if (isLacakButtonVisible(_order!.status, paymentMethod)) ...[
            PrimaryButton(
              text: paymentMethod == 'Bayar di Toko'
                  ? 'Lihat Lokasi'
                  : 'Lacak Pengiriman',
              fontWeight: FontWeight.w900,
              onPressed: () async {
                if (paymentMethod == 'Bayar di Toko') {
                  context.push('/order-status', extra: {'orderId': _order!.id});
                } else {
                  final uri = Uri.parse(
                    'https://www.posindonesia.co.id/id/tracking',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              prefixIcon: paymentMethod == 'Bayar di Toko'
                  ? Icons.location_on
                  : Icons.local_shipping,
            ),
          ],
          const SizedBox(height: 12),
          if (_order!.status == 'Menunggu Verifikasi') ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showCancellationDialog(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Ajukan Pembatalan',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  bool isLacakButtonVisible(String status, String paymentMethod) {
    if (paymentMethod == 'Bayar di Toko') {
      return status == 'Siap Diambil';
    }
    return status == 'Dikirim';
  }

  void _showInputResiBalikDialog(BuildContext context) {
    final TextEditingController resiController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Input Resi Pengembalian',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Masukkan nomor resi POS pengembalian barang Anda.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: resiController,
                decoration: InputDecoration(
                  hintText: 'Nomor Resi POS',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Resi wajib diisi' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final ok = await showConfirmActionSheet(
                context,
                variant: ConfirmActionVariant.save,
                title: 'Simpan resi pengembalian?',
                message:
                    'Apakah Anda yakin nomor resi yang dimasukkan sudah benar?',
              );
              if (ok != true || !context.mounted) return;
              Navigator.pop(context);
              await _submitReturnResi(resiController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
            ),
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitReturnResi(String resi) async {
    setState(() => _isLoading = true);
    try {
      await _orderRepository.submitReturnResi(_order!.id, resi);

      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Resi pengembalian berhasil disimpan')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan resi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCancellationDialog(BuildContext context) {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: SafeArea(
            top: false,
            child: Form(
              key: formKey,
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
                      color: const Color(0xFFFEF2F2),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFEE2E2), width: 4),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFEF4444),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ajukan Pembatalan',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Berikan alasan detail (min. 20 karakter) agar pesanan Anda dapat segera kami proses.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: reasonController,
                    maxLines: 3,
                    autofocus: true,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tuliskan alasan pembatalan Anda...',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFFFCC00),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length < 20) {
                        return 'Alasan harus minimal 20 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final ok = await showConfirmActionSheet(
                          context,
                          variant: ConfirmActionVariant.cancelOrder,
                          title: 'Kirim pengajuan?',
                          message:
                              'Yakin ingin membatalkan pesanan ini? Aksi ini tidak dapat diurungkan.',
                          confirmLabel: 'Ya, Ajukan',
                        );
                        if (ok == true && context.mounted) {
                          Navigator.pop(context);
                          await _requestCancellation(reasonController.text);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Kirim Pengajuan',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _requestCancellation(String reason) async {
    try {
      await _orderRepository.requestCancellation(_order!.id, reason: reason);
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengajuan pembatalan berhasil dikirim'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengajukan pembatalan: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color valueColor = Colors.black,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF334155),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int dashCount = (constraints.constrainWidth() / 7).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => const SizedBox(
              width: 3,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ActiveRentalCard extends StatefulWidget {
  final OrderItemModel item;
  final DateTime deadline;

  const ActiveRentalCard({
    super.key,
    required this.item,
    required this.deadline,
  });

  @override
  State<ActiveRentalCard> createState() => _ActiveRentalCardState();
}

class _ActiveRentalCardState extends State<ActiveRentalCard> {
  late Timer _timer;
  Duration _timeLeft = Duration.zero;
  bool _isOverdue = false;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    final now = DateTime.now();
    final difference = widget.deadline.difference(now);

    if (mounted) {
      setState(() {
        if (difference.isNegative) {
          _isOverdue = true;
          _timeLeft = difference.abs();
        } else {
          _isOverdue = false;
          _timeLeft = difference;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child:
                    widget.item.imagePath != null &&
                        widget.item.imagePath!.startsWith('http')
                    ? Image.network(
                        widget.item.imagePath!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        widget.item.imagePath ??
                            'assets/images/placeholder.png',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 70,
                          height: 70,
                          color: const Color(0xFFF1F5F9),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.productTitle,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: const Color(0xFF1B1B1B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.item.variation ?? 'Size: All'} - Qty ${widget.item.quantity}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _isOverdue
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFCCFBF1), // Light Teal
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isOverdue ? 'Telat' : 'Sewa Aktif',
                        style: GoogleFonts.poppins(
                          color: _isOverdue
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0D9488), // Teal 700
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTimeUnit(hours, 'HOURS'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
                _buildTimeUnit(minutes, 'MINS'),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  child: Text(
                    ':',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
                _buildTimeUnit(seconds, 'SECS'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 28,
            color: const Color(0xFFB91C1C),
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFEF4444),
          ),
        ),
      ],
    );
  }
}

