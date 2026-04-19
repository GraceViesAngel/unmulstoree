import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/cities.dart';
import '../../../home/data/models/product_model.dart';
import '../../../profile/data/models/profile_model.dart';
import '../../../profile/domain/repositories/profile_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../data/models/cart_item_model.dart';
import '../../../../shared/widgets/confirm_action_sheet.dart';

class CheckoutScreen extends StatefulWidget {
  final String? from;
  final ProductModel? product;
  final int quantity;
  final List<CartItemModel>? items;
  final String? variation;
  final bool isRental;

  const CheckoutScreen({
    super.key,
    this.from,
    this.product,
    this.quantity = 1,
    this.items,
    this.variation,
    this.isRental = false,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _selectedPaymentIndex = 0;
  final OrderRepository _orderRepository = OrderRepository();
  final CartRepository _cartRepository = CartRepository();
  final ProfileRepository _profileRepo = ProfileRepository();
  bool _isLoading = false;
  int _shippingCost = 0;
  ProfileModel? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profileRepo.getCurrentProfile();
    if (profile != null) {
      setState(() {
        _profile = profile;
        _shippingCost = Cities.getShippingCost(profile.city);
      });
    }
  }

  bool get _isFromCart => widget.items != null && widget.items!.isNotEmpty;

  List<CartItemModel> get _cartItems => widget.items ?? [];

  ProductModel? get _singleProduct => widget.product;

  int get _totalPrice {
    if (_isFromCart) {
      return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
    }
    return (_singleProduct?.price ?? 0) * widget.quantity;
  }

  int get _itemCount {
    if (_isFromCart) {
      return _cartItems.length;
    }
    return 1;
  }

  int get _totalDeposit {
    if (_isFromCart) {
      return _cartItems
          .where((item) => item.isRental)
          .fold(0, (sum, item) => sum + (item.product?.deposit ?? 0));
    }
    return _orderIsRental ? (_singleProduct?.deposit ?? 0) : 0;
  }

  int get _totalRentalDuration {
    if (_isFromCart) {
      final rentalItems = _cartItems.where((item) => item.isRental);
      if (rentalItems.isEmpty) return 0;
      return rentalItems
          .map((e) => e.product?.rentalDuration ?? 0)
          .reduce((a, b) => a > b ? a : b);
    }
    return _orderIsRental ? (_singleProduct?.rentalDuration ?? 0) : 0;
  }

  int get _totalLateFee {
    if (_isFromCart) {
      return _cartItems
          .where((item) => item.isRental)
          .fold(0, (sum, item) => sum + (item.product?.lateFee ?? 0));
    }
    return _orderIsRental ? (_singleProduct?.lateFee ?? 0) : 0;
  }

  int get _finalTotalPrice => _totalPrice + _totalDeposit + _shippingCost;

  /// True only when the user actually chose rental (line items / checkout flag),
  /// not merely because the product supports rent.
  bool get _orderIsRental {
    if (_isFromCart) {
      return _cartItems.any((item) => item.isRental);
    }
    return widget.isRental;
  }

  String _formatPrice(int price) {
    var str = price.toString();
    var result = '';
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) result += '.';
      result += str[i];
    }
    return 'Rp$result';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Checkout',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Alamat Pengiriman'),
            _buildAddressCard(),
            _buildSectionHeader('Produk'),
            if (_isFromCart) _buildCartItemsList() else _buildProductCard(),
            _buildSectionHeader(
              'Metode Pembayaran',
              trailing: _buildCashOnlyBadge(),
            ),
            _buildPaymentMethods(),
            _buildSectionHeader('Rincian Pembayaran'),
            _buildPaymentDetails(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildCashOnlyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'CASH ONLY',
        style: GoogleFonts.poppins(
          color: const Color(0xFFEF4444),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAddressCard() {
    final ProfileRepository profileRepo = ProfileRepository();
    return FutureBuilder<ProfileModel?>(
      future: profileRepo.getCurrentProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const CircularProgressIndicator();
        final profile = snapshot.data;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Color(0xFFFFCC00), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            profile?.fullName ?? 'Belum ada nama',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            await context.push('/edit-profile');
                            setState(() {});
                          },
                          child: Text(
                            'Edit',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFFFCC00),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      profile?.fullAddress.isNotEmpty == true
                          ? profile!.fullAddress
                          : 'Alamat belum diatur',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF334155),
                        fontSize: 12,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCartItemsList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < _cartItems.length; i++) ...[
            _buildCartItemCard(_cartItems[i]),
            if (i < _cartItems.length - 1)
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItemModel item) {
    final product = item.product;
    if (product == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.imagePath.startsWith('http')
                ? Image.network(
                    product.imagePath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    product.imagePath,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xFF1B1B1B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.variation ?? '',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(product.price),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFFCC00),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${item.quantity}x',
            style: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard() {
    final product = _singleProduct!;
    final variation = widget.variation ?? 'Size L';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: product.imagePath.startsWith('http')
                ? Image.network(
                    product.imagePath,
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    product.imagePath,
                    width: 75,
                    height: 75,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: const Color(0xFF1B1B1B),
                  ),
                ),
                Text(
                  variation,
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatPrice(product.price),
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFFFCC00),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${widget.quantity}x',
            style: GoogleFonts.poppins(
              color: const Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
    if (_orderIsRental) {
      // Force 'Bayar di Toko' for rental
      _selectedPaymentIndex = 1;
      return Column(
        children: [
          _buildPaymentOption(
            1,
            'Bayar di Toko',
            'Ambil dan bayar deposit di UNMUL STORE',
            Icons.storefront_outlined,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildPaymentOption(
          0,
          'COD (Cash on Delivery)',
          'Bayar tunai saat barang tiba.',
          Icons.payments_outlined,
        ),
        const SizedBox(height: 12),
        _buildPaymentOption(
          1,
          'Bayar di Toko',
          'Ambil dan bayar di UNMUL STORE',
          Icons.storefront_outlined,
        ),
      ],
    );
  }

  Widget _buildPaymentOption(
    int index,
    String title,
    String sub,
    IconData icon,
  ) {
    bool isSelected = _selectedPaymentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFFFCC00)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFCC00)
                      : const Color(0xFFCBD5E1),
                  width: isSelected ? 6 : 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
                  Text(
                    sub,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: const Color(0xFFCBD5E1), size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            'Harga Produk ($_itemCount item)',
            _formatPrice(_totalPrice),
          ),
          if (_orderIsRental) ...[
            const SizedBox(height: 12),
            _buildDetailRow(
              'Biaya Jaminan (Deposit)',
              _formatPrice(_totalDeposit),
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Batas Sewa',
              '${_totalRentalDuration} Hari',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              'Biaya Keterlambatan',
              '${_formatPrice(_totalLateFee)} / Hari',
            ),
          ],
          if (_selectedPaymentIndex == 0 && _shippingCost > 0) ...[
            const SizedBox(height: 12),
            _buildDetailRow('Biaya Pengiriman', _formatPrice(_shippingCost)),
          ],
          const SizedBox(height: 16),
          _buildDashedLine(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Text(
                _formatPrice(_finalTotalPrice),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          if (_orderIsRental) ...[
            const SizedBox(height: 12),
            Text(
              '*Biaya jaminan akan dikembalikan setelah barang kembali dalam kondisi baik.\n*Keterlambatan pengembalian akan dikenakan denda sesuai biaya keterlambatan per hari.',
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF64748B),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: const Color(0xFF64748B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF1B1B1B),
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return Row(
      children: List.generate(40, (index) {
        return Expanded(
          child: Container(
            height: 1,
            color: index % 2 == 0
                ? const Color(0xFFE2E8F0)
                : Colors.transparent,
          ),
        );
      }),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: const BoxDecoration(color: Color(0xFFFFCC00)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleBayarSekarang,
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF1B1B1B),
                    ),
                  )
                : Text(
                    'BAYAR SEKARANG ${_formatPrice(_finalTotalPrice)}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF1B1B1B),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleBayarSekarang() async {
    final profileRepo = ProfileRepository();
    final profile = await profileRepo.getCurrentProfile();
    if (!mounted) return;
    if (profile == null ||
        (profile.fullName ?? '').trim().isEmpty ||
        (profile.phoneNumber ?? '').trim().isEmpty ||
        (profile.city ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lengkapan Profil: Nama, Nomor HP, dan Kota wajib diisi.',
          ),
        ),
      );
      return;
    }

    final confirm = await showConfirmActionSheet(
      context,
      variant: ConfirmActionVariant.checkout,
    );
    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);

    final String paymentMethod = _selectedPaymentIndex == 0
        ? 'COD'
        : 'Bayar di Toko';

    try {
      String? orderId;

      if (_isFromCart) {
        final order = await _orderRepository.createOrderFromCart(
          items: _cartItems,
          isRental: _orderIsRental,
          paymentMethod: paymentMethod,
          deposit: _totalDeposit,
          rentalDuration: _totalRentalDuration,
          lateFee: _totalLateFee,
          shippingCost: _shippingCost,
        );
        orderId = order.id;
        final itemIds = _cartItems.map((e) => e.id).toList();
        await _cartRepository.removeMultipleFromCart(itemIds);
      } else {
        final order = await _orderRepository.createOrder(
          productId: _singleProduct!.id ?? '',
          productTitle: _singleProduct!.title,
          imagePath: _singleProduct!.imagePath,
          quantity: widget.quantity,
          price: _singleProduct!.price,
          isRental: widget.isRental,
          variation: widget.variation ?? 'Size L',
          paymentMethod: paymentMethod,
          deposit: _totalDeposit,
          rentalDuration: _totalRentalDuration,
          lateFee: _totalLateFee,
          shippingCost: _shippingCost,
        );
        orderId = order.id;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pesanan Berhasil Dibuat!')),
        );

        context.go(
          '/order-status',
          extra: {
            'orderId': orderId,
            'isRental': _orderIsRental,
            'totalPrice': _finalTotalPrice,
            'itemCount': _itemCount,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal membuat pesanan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
