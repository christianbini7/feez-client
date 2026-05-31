import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/premium_widgets.dart';

class VerifiedScreen extends StatefulWidget {
  const VerifiedScreen({super.key});
  @override
  State<VerifiedScreen> createState() => _VerifiedScreenState();
}

class _VerifiedScreenState extends State<VerifiedScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleCheck, _fadeContent;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 900));
    _scaleCheck = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl,
        curve: const Interval(0, 0.55, curve: Curves.elasticOut)));
    _fadeContent = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl,
        curve: const Interval(0.4, 1, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(children: [
        const Spacer(),
        ScaleTransition(scale: _scaleCheck,
          child: Stack(alignment: Alignment.center, children: [
            Container(width: 140, height: 140,
              decoration: BoxDecoration(
                color: FeezColors.green.withValues(alpha: 0.10),
                shape: BoxShape.circle)),
            Container(width: 100, height: 100,
              decoration: BoxDecoration(
                color: FeezColors.green,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                  color: FeezColors.green.withValues(alpha: 0.35),
                  blurRadius: 28, offset: const Offset(0, 12))]),
              child: const Center(child: Icon(Icons.check_rounded,
                color: Colors.white, size: 56))),
          ])),
        const SizedBox(height: 32),
        FadeTransition(opacity: _fadeContent,
          child: const Column(children: [
            Text('Numéro vérifié',
              style: TextStyle(fontFamily: 'BarlowCondensed',
                fontSize: 32, fontWeight: FontWeight.w900,
                color: FeezColors.ink, letterSpacing: -0.02)),
            SizedBox(height: 8),
            Text('Plus qu\'une étape pour profiter de Feez',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'DMSans',
                fontSize: 13.5, color: FeezColors.mid, height: 1.4)),
          ])),
        const Spacer(),
        FadeTransition(opacity: _fadeContent,
          child: PremiumButton(
            label: 'Continuer',
            trailingIcon: Icons.arrow_forward_rounded,
            height: 56,
            onTap: () => context.go('/auth/setup'))),
        const SizedBox(height: 28),
      ]),
    )));
}
