import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/bootstrap/configure_url_strategy.dart';
import 'core/routing/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  NotificationService.instance.show(
    id: message.hashCode,
    title: message.notification?.title ?? 'Notifikasi',
    body: message.notification?.body ?? '',
  );
}

Future<void> _saveFcmToken() async {
  if (kIsWeb) return;
  try {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    debugPrint('Saving FCM Token: $token');
    await Supabase.instance.client
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', user.id);
  } catch (e) {
    debugPrint('Failed to save FCM token: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configureUrlStrategyForWeb();

  await dotenv.load(fileName: ".env");

  if (!kIsWeb) {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((message) {
      NotificationService.instance.show(
        id: message.hashCode,
        title: message.notification?.title ?? 'Notifikasi',
        body: message.notification?.body ?? '',
      );
    });
  }

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  await NotificationService.instance.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final StreamSubscription<AuthState> _authSub;
  bool _handledRecoveryRedirect = false;

  @override
  void initState() {
    super.initState();
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        _handledRecoveryRedirect = false;
        return;
      }

      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.tokenRefreshed) {
        _saveFcmToken();
      }

      if (data.event != AuthChangeEvent.passwordRecovery) return;
      if (_handledRecoveryRedirect) return;
      _handledRecoveryRedirect = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final currentPath =
            AppRouter.router.routeInformationProvider.value.uri.path;
        if (currentPath != '/reset-password') {
          AppRouter.router.go('/reset-password');
        }
      });
    });
  }

  @override
  void dispose() {
    _authSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Unmul Store',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        final content = child ?? const SizedBox.shrink();
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: content,
          ),
        );
      },
    );
  }
}
