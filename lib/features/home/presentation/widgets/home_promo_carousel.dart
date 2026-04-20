import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class HomePromoCarousel extends StatefulWidget {
  final List<String> imageUrls;

  const HomePromoCarousel({super.key, required this.imageUrls});

  @override
  State<HomePromoCarousel> createState() => _HomePromoCarouselState();
}

class _HomePromoCarouselState extends State<HomePromoCarousel> {
  late PageController _pageController;
  Timer? _timer;
  int _virtualPage = 0;

  static const Duration _autoInterval = Duration(seconds: 5);
  static const Duration _pageDuration = Duration(milliseconds: 450);
  static const Curve _pageCurve = Curves.easeInOutCubic;
  static const int _infiniteMultiplier = 1000;

  List<String> get _urls =>
      widget.imageUrls.where((e) => e.trim().isNotEmpty).toList();
  int get _visibleIndex => _urls.isEmpty ? 0 : _virtualPage % _urls.length;
  int _initialInfinitePage(int length) => length * _infiniteMultiplier;

  @override
  void initState() {
    super.initState();
    final urls = _urls;
    _virtualPage = urls.length > 1 ? _initialInfinitePage(urls.length) : 0;
    _pageController = PageController(initialPage: _virtualPage);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    if (_urls.length <= 1) return;
    _timer = Timer.periodic(_autoInterval, (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = _virtualPage + 1;
      _pageController.animateToPage(
        next,
        duration: _pageDuration,
        curve: _pageCurve,
      );
    });
  }

  @override
  void didUpdateWidget(covariant HomePromoCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrls != widget.imageUrls) {
      final urls = _urls;
      _virtualPage = urls.length > 1 ? _initialInfinitePage(urls.length) : 0;
      _pageController.dispose();
      _pageController = PageController(initialPage: _virtualPage);
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;

    if (urls.isEmpty) {
      return _fallbackAsset();
    }

    if (urls.length == 1) {
      return _buildCarouselFrame(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: _networkBanner(urls.first, fillHeight: true),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 160,
          child: _buildCarouselFrame(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: PageView.builder(
                controller: _pageController,
                itemCount: null,
                onPageChanged: (i) => setState(() => _virtualPage = i),
                itemBuilder: (context, i) =>
                    _networkBanner(urls[i % urls.length], fillHeight: true),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(urls.length, (i) {
            final active = i == _visibleIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _fallbackAsset() {
    return _buildCarouselFrame(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.asset(
          'assets/images/promo.png',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.primaryColor.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'PROMO BANNER',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCarouselFrame({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F0F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _networkBanner(String url, {bool fillHeight = false}) {
    return Image.network(
      url,
      width: double.infinity,
      height: fillHeight ? 160 : null,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return SizedBox(
          height: fillHeight ? 160 : 140,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      },
      errorBuilder: (context, error, stackTrace) => _fallbackAsset(),
    );
  }
}
