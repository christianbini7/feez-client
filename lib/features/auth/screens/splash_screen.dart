import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late Animation<double> _logoScale, _logoFade;

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _logoCtrl.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() { _logoCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: FeezColors.red,
    body: Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        FadeTransition(opacity: _logoFade,
          child: ScaleTransition(scale: _logoScale,
            child: const Text('feez',
              style: TextStyle(
                fontFamily: 'BarlowCondensed',
                fontSize: 88, fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                color: Colors.white, height: 1,
                letterSpacing: -0.04)))),
        const SizedBox(height: 16),
        FadeTransition(opacity: _logoFade,
          child: Text('Tout en un clic',
            style: TextStyle(fontFamily: 'DMSans',
              fontSize: 14, fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.6))),
        const SizedBox(height: 80),
        SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(
            color: Colors.white.withValues(alpha: 0.85), strokeWidth: 2)),
      ])));
}
