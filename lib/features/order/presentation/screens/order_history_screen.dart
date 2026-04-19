import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/models/order_model.dart';
import '../../domain/repositories/order_repository.dart';

class OrderHistoryScreen extends StatefulWidget {
  final bool showNavBar;
  final VoidCallback? onBack;
  final int initialTab;
  final bool showBackButton;

  const OrderHistoryScreen({
    super.key,
    this.showNavBar = false,
    this.onBack,
    this.initialTab = 0,
    this.showBackButton = false,
  });

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedFilter = 'Semua';

  final List<String> _filters = [
    'Semua',
    'Menunggu',
    'Disetujui',
    'Aktif',
    'Dikirim',
    'Selesai',
    'Ditolak',
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: widget.showBackButton
              ? IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF1B1B1B),
                    size: 24,
                  ),
                  onPressed: () {
                    if (widget.onBack != null) {
                      widget.onBack!();
                    } else if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                )
              : null,
          title: Text(
            'Pesanan',
            style: GoogleFonts.poppins(
              color: const Color(0xFF1B1B1B),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(90),
            child: Column(
              children: [
                TabBar(
                  indicatorColor: Colors.transparent,
                  labelColor: const Color(0xFFFFCC00),
                  unselectedLabelColor: const Color(0xFF94A3B8),
                  labelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(text: 'Pembelian'),
                    Tab(text: 'Penyewaan'),
                  ],
                ),
                _buildFilterChips(),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _OrderListContent(
              key: ValueKey('order-list-0-$_selectedFilter'),
              isRental: false,
              selectedFilter: _selectedFilter,
            ),
            _OrderListContent(
              key: ValueKey('order-list-1-$_selectedFilter'),
              isRental: true,
              selectedFilter: _selectedFilter,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          physics: const BouncingScrollPhysics(),
          itemCount: _filters.length,
          separatorBuilder: (_, i) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final isSelected = _selectedFilter == filter;
            return GestureDetector(
              onTap: () {
                setState(() => _selectedFilter = filter);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFFCC00) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFCC00)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    );
  }
}

class _OrderListContent extends StatefulWidget {
  final bool isRental;
  final String selectedFilter;

  const _OrderListContent({
    required Key key,
    required this.isRental,
    required this.selectedFilter,
  }) : super(key: key);

  @override
  State<_OrderListContent> createState() => _OrderListContentState();
}

class _OrderListContentState extends State<_OrderListContent> {
  final OrderRepository _orderRepository = OrderRepository();
  late Future<List<OrderModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchOrders();
  }

  @override
  void didUpdateWidget(_OrderListContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFilter != widget.selectedFilter ||
        oldWidget.isRental != widget.isRental) {
      _future = _fetchOrders();
    }
  }

  String _mapFilterToStatus(String filter) {
    switch (filter) {
      case 'Menunggu':
        return 'Menunggu Verifikasi';
      case 'Disetujui':
        return 'Disetujui';
      case 'Aktif':
        return 'Dalam Masa Sewa';
      case 'Dikirim':
        return 'Dikirim';
      case 'Selesai':
        return 'Selesai';
      case 'Ditolak':
        return 'Ditolak_Gabungan'; // Marker untuk filter gabungan
      default:
        return filter;
    }
  }

  Future<List<OrderModel>> _fetchOrders() async {
    String? statusToSend;
    if (widget.selectedFilter != 'Semua') {
      statusToSend = _mapFilterToStatus(widget.selectedFilter);
    }
    return _orderRepository.getUserOrders(
      isRental: widget.isRental,
      status: statusToSend,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<OrderModel>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyMessage(),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF64748B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final orders = snapshot.data!;
        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _future = _fetchOrders();
            });
          },
          child: ListView.builder(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildOrderCard(context, order),
              );
            },
          ),
        );
      },
    );
  }

  String _getEmptyMessage() {
    final parentState = context
        .findAncestorStateOfType<_OrderHistoryScreenState>();
    if (parentState != null) {
      if (parentState._selectedFilter != 'Semua') {
        return 'Tidak ada pesanan dengan status "${parentState._selectedFilter}"';
      }
      return widget.isRental ? 'Belum ada penyewaan' : 'Belum ada pembelian';
    }
    return widget.isRental ? 'Belum ada penyewaan' : 'Belum ada pembelian';
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    final firstItem = order.items?.isNotEmpty == true
        ? order.items!.first
        : null;
    final itemCount = order.items?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/icons/ikonpesan.svg',
                colorFilter: const ColorFilter.mode(
                  Color(0xFFFFCC00),
                  BlendMode.srcIn,
                ),
                width: 20,
                height: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${order.orderIdDisplay} • ${DateFormat('dd MMMM yyyy').format(order.createdAt)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: order.status == 'Selesai'
                      ? const Color(0xFFD1FAE5)
                      : order.status == 'Ditolak'
                          ? const Color(0xFFFEE2E2)
                          : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  order.status,
                  style: GoogleFonts.poppins(
                    color: order.status == 'Selesai'
                        ? const Color(0xFF10B981)
                        : order.status == 'Ditolak'
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF3B82F6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (order.status == 'Ditolak') ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alasan penolakan:',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (order.rejectionReason ?? '').trim().isNotEmpty
                        ? order.rejectionReason!.trim()
                        : 'Tidak ada detail dari toko.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF1B1B1B),
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (firstItem != null)
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child:
                      firstItem.imagePath != null &&
                          firstItem.imagePath!.startsWith('http')
                      ? Image.network(
                          firstItem.imagePath!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          firstItem.imagePath ??
                              'assets/images/placeholder.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        firstItem.productTitle,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${firstItem.variation ?? ''} • ${firstItem.quantity} Qty${itemCount > 1 ? ' (+${itemCount - 1} item lain)' : ''}',
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF334155),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp${order.totalPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => "${m[1]}.")}',
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
          const SizedBox(height: 16),
          // Timer sewa aktif
          if (order.isRental &&
              order.status == 'Dalam Masa Sewa' &&
              order.returnDeadline != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RentalCountdownTimer(deadline: order.returnDeadline!),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (order.status == 'Selesai')
                _buildActionBtn('Beli Lagi', isPrimary: true, onTap: () {})
              else if (_shouldShowLacakButton(order.status, order.paymentMethod))
                _buildActionBtn(
                  order.paymentMethod == 'Bayar di Toko'
                      ? 'Lihat Lokasi'
                      : 'Lacak',
                  isPrimary: true,
                  onTap: () => _handleLacak(context, order),
                ),
              _buildActionBtn(
                'Detail',
                isPrimary: false,
                onTap: () =>
                    context.push('/order-status', extra: {'orderId': order.id}),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(
    String text, {
    required bool isPrimary,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPrimary
                ? const Color(0xFFFFCC00)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            color: isPrimary
                ? const Color(0xFFFFCC00)
                : const Color(0xFF1B1B1B),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  bool _shouldShowLacakButton(String status, String paymentMethod) {
    if (paymentMethod == 'Bayar di Toko') {
      return status == 'Siap Diambil';
    }
    return status == 'Dikirim';
  }

  void _handleLacak(BuildContext context, OrderModel order) async {
    if (order.paymentMethod == 'Bayar di Toko') {
      context.push('/order-status', extra: {'orderId': order.id});
    } else {
      final uri = Uri.parse('https://www.posindonesia.co.id/id/tracking');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }
}

/// Widget timer countdown untuk sewa aktif di order card
class _RentalCountdownTimer extends StatefulWidget {
  final DateTime deadline;

  const _RentalCountdownTimer({required this.deadline});

  @override
  State<_RentalCountdownTimer> createState() => _RentalCountdownTimerState();
}

class _RentalCountdownTimerState extends State<_RentalCountdownTimer> {
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
    final days = _timeLeft.inDays;
    final hours = (_timeLeft.inHours % 24).toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    final timerColor = _isOverdue ? const Color(0xFFEF4444) : const Color(0xFF0D9488);
    final bgColor = _isOverdue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDFA);
    final labelColor = _isOverdue ? const Color(0xFFB91C1C) : const Color(0xFF0F766E);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: timerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isOverdue ? Icons.warning_amber_rounded : Icons.timer_outlined,
                size: 16,
                color: labelColor,
              ),
              const SizedBox(width: 6),
              Text(
                _isOverdue ? 'Terlambat' : 'Sisa Waktu Sewa',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildUnit('$days', 'HARI', timerColor),
              _buildSeparator(timerColor),
              _buildUnit(hours, 'JAM', timerColor),
              _buildSeparator(timerColor),
              _buildUnit(minutes, 'MNT', timerColor),
              _buildSeparator(timerColor),
              _buildUnit(seconds, 'DTK', timerColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnit(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: color,
            height: 1.1,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        ':',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
