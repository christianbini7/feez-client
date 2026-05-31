import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/auth/screens/phone_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/verified_screen.dart';
import '../features/auth/screens/setup_profile_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/orders/screens/orders_screen.dart';
import '../features/orders/screens/confirm_screen.dart';
import '../features/orders/screens/tracking_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/payment/payment_screen.dart';
import '../features/product/screens/product_detail_screen.dart';
import '../features/restaurant/screens/resto_screen.dart';
import '../features/restaurant/screens/restaurants_list_screen.dart';
import '../features/home/screens/shortcut_category_screen.dart';
import '../features/search/search_screen.dart';
import '../models/product_model.dart';
import 'app_lifecycle.dart';
import 'nav_shell.dart';

CustomTransitionPage<T> _fadePage<T>({
  required LocalKey key,
  required Widget child,
  int duration = 220,
}) => CustomTransitionPage<T>(
  key: key, child: child,
  transitionDuration: Duration(milliseconds: duration),
  reverseTransitionDuration: Duration(milliseconds: duration - 40),
  transitionsBuilder: (_, anim, __, c) => FadeTransition(
    opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut), child: c),
);

CustomTransitionPage<T> _slideRightPage<T>({
  required LocalKey key, required Widget child,
}) => CustomTransitionPage<T>(
  key: key, child: child,
  transitionDuration: const Duration(milliseconds: 280),
  reverseTransitionDuration: const Duration(milliseconds: 240),
  transitionsBuilder: (_, anim, secAnim, c) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0), end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: anim,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic)),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero, end: const Offset(-0.25, 0),
        ).animate(CurvedAnimation(parent: secAnim, curve: Curves.easeOut)),
        child: c));
  },
);

final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    if (AppLifecycle.needsSplash && state.uri.toString() != '/splash') {
      AppLifecycle.needsSplash = false;
      return '/splash';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/splash',        pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: const SplashScreen())),
    GoRoute(path: '/onboarding',    pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: const OnboardingScreen())),
    GoRoute(path: '/auth/phone',    pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: const PhoneScreen())),
    GoRoute(path: '/auth/otp',      pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: OtpScreen(phone: s.extra as String? ?? ''))),
    GoRoute(path: '/auth/verified', pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: const VerifiedScreen())),
    GoRoute(path: '/auth/setup',    pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: const SetupProfileScreen())),
    GoRoute(path: '/cart',          pageBuilder: (c,s) => _slideRightPage(key: s.pageKey, child: const CartScreen())),
    GoRoute(path: '/payment',       pageBuilder: (c,s) => _slideRightPage(key: s.pageKey, child: const PaymentScreen())),
    GoRoute(path: '/confirm',       pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: ConfirmScreen(orderId: s.extra as String? ?? ''))),
    GoRoute(path: '/tracking/:id',  pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: TrackingScreen(orderId: s.pathParameters['id']!))),
    GoRoute(path: '/product/:id',   pageBuilder: (c,s) => _slideRightPage(key: s.pageKey, child: ProductDetailScreen(product: s.extra as ProductModel))),
    GoRoute(path: '/resto',         pageBuilder: (c,s) => _slideRightPage(key: s.pageKey, child: RestoScreen(resto: s.extra as Map<String,dynamic>))),
    GoRoute(path: '/search',   pageBuilder: (c,s) => _slideRightPage(key: s.pageKey, child: const SearchScreen())),
    GoRoute(path: '/shortcut',      pageBuilder: (c,s) => _slideRightPage(key: s.pageKey, child: ShortcutCategoryScreen(shortcut: s.extra as Map<String,dynamic>))),
    ShellRoute(
      builder: (c,s,child) => NavShell(child: child),
      routes: [
        GoRoute(path: '/home',       pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: const HomeScreen(), duration: 180)),
        GoRoute(path: '/restaurant', pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: const RestaurantsListScreen(), duration: 180)),
        GoRoute(path: '/orders',     pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: const OrdersScreen(), duration: 180)),
        GoRoute(path: '/profile',    pageBuilder: (c,s) => _fadePage(key: s.pageKey, child: const ProfileScreen(), duration: 180)),
      ],
    ),
  ],
);