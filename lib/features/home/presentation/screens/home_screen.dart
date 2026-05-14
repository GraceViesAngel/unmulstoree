import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/product_model.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/home_banner_repository.dart';
import '../widgets/home_promo_carousel.dart';
import '../widgets/product_card_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Semua';
  final ProductRepository _productRepository = ProductRepository();
  final HomeBannerRepository _bannerRepository = HomeBannerRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppTheme.textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder<List<ProductModel>>(
          future: _productRepository.getProductsFiltered(
            category: _selectedCategory == 'Semua' ? null : _selectedCategory,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          ),
          builder: (context, snapshot) {
            return CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // Combined White Background Container with Rounded Bottom
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Custom App Bar
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // UNMUL Logo (Left)
                              SizedBox(
                                width: 48,
                                height: 48,
                                child: Image.asset(
                                  'assets/icons/Universitas-Mulawarman.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.school,
                                      color: AppTheme.textColor,
                                      size: 28,
                                    );
                                  },
                                ),
                              ),

                              // Lokasi Title (Centered)
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Lokasi Store',
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.subtitleColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          color: Colors.red,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        GestureDetector(
                                          onTap: () async {
                                            final uri = Uri.parse(
                                                'https://share.google/ZJBQhbS8serWOm8Tt');
                                            if (await canLaunchUrl(uri)) {
                                              await launchUrl(uri,
                                                  mode:
                                                      LaunchMode.externalApplication);
                                            }
                                          },
                                          child: Text(
                                            'Universitas Mulawarman',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textColor,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // PAB Logo (Right)
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: SvgPicture.asset(
                                  'assets/icons/logo.svg',
                                  fit: BoxFit.contain,
                                  colorFilter: const ColorFilter.mode(
                                    AppTheme.primaryColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 1. Promo Banner (admin, max 3 — carousel jika > 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          child: FutureBuilder<List<String>>(
                            future: _bannerRepository.fetchBannerUrls(),
                            builder: (context, snap) {
                              return HomePromoCarousel(
                                imageUrls: snap.data ?? const [],
                              );
                            },
                          ),
                        ),

                        // 2. Search Bar (debounced 300ms)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Cari Produk',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF64748B).withValues(
                                  alpha: 0.55,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppTheme.textColor,
                                size: 20,
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 10,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: AppTheme.primaryColor,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 3. Category Chips
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          child: Row(
                            children: [
                              _buildCategoryChip('Semua'),
                              const SizedBox(width: 10),
                              _buildCategoryChip('Beli'),
                              const SizedBox(width: 10),
                              _buildCategoryChip('Sewa'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Product Grid with Loading/Error states
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  )
                else if (!snapshot.hasData || snapshot.data!.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('Tidak ada produk.')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.75,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return ProductCardWidget(
                          product: snapshot.data![index],
                        );
                      }, childCount: snapshot.data!.length),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }
}
