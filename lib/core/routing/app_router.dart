import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/phone_login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/verify_pending_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/reset_password_screen.dart';
import '../../features/home/presentation/screens/main_layout_screen.dart';
import '../../features/product/presentation/screens/product_detail_screen.dart';
import '../../features/home/data/models/product_model.dart';
import '../../features/order/presentation/screens/cart_screen.dart';
import '../../features/order/presentation/screens/checkout_screen.dart';
import '../../features/order/presentation/screens/order_status_screen.dart';
import '../../features/order/presentation/screens/order_history_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/order/data/models/cart_item_model.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/kelola_pesanan_screen.dart';
import '../../features/admin/presentation/screens/kelola_penyewaan_screen.dart';
import '../../features/admin/presentation/screens/monitoring_denda_screen.dart';
import '../../features/admin/presentation/screens/admin_notification_screen.dart';
import '../../features/admin/presentation/screens/kelola_banner_screen.dart';
import '../../features/admin/presentation/screens/superadmin/superadmin_main_screen.dart';
import '../../features/admin/presentation/screens/superadmin/tambah_produk_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final session = Supabase.instance.client.auth.currentSession;
      
      final bool isSuperadminRoute = state.matchedLocation.startsWith('/superadmin');
      final bool isAdminRoute = state.matchedLocation.startsWith('/admin');

      if (isSuperadminRoute || isAdminRoute) {
        if (session == null) return '/';
        
        final user = session.user;
        
        // Fetch role from profiles table for accurate role detection
        String? role;
        try {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select('role')
              .eq('id', user.id)
              .single();
          role = profileData['role']?.toString().toLowerCase();
        } catch (e) {
          debugPrint('Error fetching role from profiles: $e');
          // Fallback to user metadata if profiles query fails
          role = user.userMetadata?['role']?.toString().toLowerCase();
          role ??= user.appMetadata['role']?.toString().toLowerCase();
        }

        debugPrint('Navigating to ${state.matchedLocation}, detected role: $role');

        if (isSuperadminRoute && role != 'superadmin') {
          return '/admin-dashboard';
        }
        
        if (isAdminRoute && role != 'admin' && role != 'superadmin') {
          return '/';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainLayoutScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/product-detail',
        builder: (context, state) {
          final product = state.extra as ProductModel;
          return ProductDetailScreen(product: product);
        },
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phoneNumber = state.extra as String? ?? 'Unknown Number';
          return OtpScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: '/verify-pending',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return VerifyPendingScreen(
            email: extra['email'] as String? ?? '',
            name: extra['name'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          return CartScreen(from: from);
        },
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final from = state.uri.queryParameters['from'];

          if (extra == null) {
            return const MainLayoutScreen();
          }

          final items = extra['items'] as List<CartItemModel>?;
          final product = extra['product'] as ProductModel?;
          final quantity = extra['quantity'] as int? ?? 1;
          final variation = extra['variation'] as String?;
          final isRental = extra['isRental'] as bool? ?? false;

          if (items != null && items.isNotEmpty) {
            return CheckoutScreen(from: from, items: items);
          }

          if (product != null) {
            return CheckoutScreen(
              from: from,
              product: product,
              quantity: quantity,
              variation: variation,
              isRental: isRental,
            );
          }

          return const MainLayoutScreen();
        },
      ),
      GoRoute(
        path: '/order-status',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final orderId = extra?['orderId'] as String?;
          return OrderStatusScreen(orderId: orderId);
        },
      ),
      GoRoute(
        path: '/order-history',
        builder: (context, state) {
          final initialTab =
              int.tryParse(state.uri.queryParameters['initialTab'] ?? '0') ?? 0;
          final showBack = state.uri.queryParameters['showBack'] == 'true';
          final showNavBar = state.uri.queryParameters['showNavBar'] == 'true';
          return OrderHistoryScreen(
            initialTab: initialTab,
            showBackButton: showBack,
            showNavBar: showNavBar,
          );
        },
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/admin-dashboard',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AdminDashboardScreen(role: extra?['role'] as String?);
        },
      ),
      GoRoute(
        path: '/admin-pesanan',
        builder: (context, state) => const KelolaPesananScreen(),
      ),
      GoRoute(
        path: '/admin-penyewaan',
        builder: (context, state) => const KelolaPenyewaanScreen(),
      ),
      GoRoute(
        path: '/admin-denda',
        builder: (context, state) => const MonitoringDendaScreen(),
      ),
      GoRoute(
        path: '/admin-banners',
        builder: (context, state) => const KelolaBannerScreen(),
      ),
      GoRoute(
        path: '/admin-notifikasi',
        builder: (context, state) => const AdminNotificationScreen(),
      ),
      GoRoute(
        path: '/superadmin',
        builder: (context, state) => const SuperadminMainScreen(),
      ),
      GoRoute(
        path: '/superadmin-tambah-produk',
        builder: (context, state) {
          final product = state.extra as ProductModel?;
          return TambahProdukScreen(product: product);
        },
      ),
    ],
  );
}
