import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/premium_widgets.dart';

class ConfirmScreen extends StatefulWidget {
  final String orderId;
  const ConfirmScreen({super.key, required this.orderId});
  @override
  State<ConfirmScreen> createState() => _ConfirmScreenState();
}

class _ConfirmScreenState extends State<ConfirmScreen>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleCheck, _fadeContent, _scaleCard;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _scaleCheck = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.0, 0.5, curve: Curves.elasticOut)));
    _scaleCard = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.4, 0.9, curve: Curves.easeOutCubic)));
    _fadeContent = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl,
          curve: const Interval(0.5, 1.0, curve: Curves.easeOut)));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final shortId = widget.orderId.length >= 6
      ? widget.orderId.substring(0, 6).toUpperCase()
      : widget.orderId.toUpperCase();
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      body: SafeArea(child: Stack(children: [
        // Background décoratif
        Positioned(top: -80, right: -60,
          child: Container(width: 200, height: 200,
            decoration: BoxDecoration(
              color: FeezColors.red.withValues(alpha: 0.08),
              shape: BoxShape.circle))),
        Positioned(bottom: 120, left: -50,
          child: Container(width: 150, height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B00).withValues(alpha: 0.06),
              shape: BoxShape.circle))),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 60),

            // ── Check animé avec halo ──────────────────────
            ScaleTransition(
              scale: _scaleCheck,
              child: Stack(alignment: Alignment.center, children: [
                Container(width: 130, height: 130,
                  decoration: BoxDecoration(
                    color: FeezColors.red.withValues(alpha: 0.10),
                    shape: BoxShape.circle)),
                Container(width: 100, height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [FeezColors.red, Color(0xFFFF4D5E)]),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: FeezColors.red.withValues(alpha: 0.35),
                      blurRadius: 30, offset: const Offset(0, 12))]),
                  child: const Center(child: Icon(Icons.check_rounded,
                    color: Colors.white, size: 56))),
              ])),

            const SizedBox(height: 28),

            // ── Titre + sous-titre ─────────────────────────
            FadeTransition(opacity: _fadeContent,
              child: Column(children: [
                const Text('Commande confirmée !',
                  style: TextStyle(fontFamily: 'BarlowCondensed',
                    fontSize: 32, fontWeight: FontWeight.w900,
                    color: FeezColors.ink, letterSpacing: -0.02)),
                const SizedBox(height: 6),
                const Text('Ta commande est en cours de préparation',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5,
                    color: FeezColors.mid, height: 1.4)),
              ])),

            const SizedBox(height: 32),

            // ── Card récap animée ──────────────────────────
            ScaleTransition(scale: _scaleCard,
              child: FadeTransition(opacity: _fadeContent,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(
                      color: Color(0x10000000), blurRadius: 24,
                      offset: Offset(0, 8))],
                  ),
                  child: Column(children: [
                    Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F0),
                          borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.receipt_long,
                          color: FeezColors.red, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('N° de commande',
                            style: TextStyle(fontSize: 11,
                              color: FeezColors.low,
                              fontWeight: FontWeight.w600)),
                          Text('#$shortId',
                            style: const TextStyle(fontFamily: 'BarlowCondensed',
                              fontSize: 20, fontWeight: FontWeight.w900,
                              color: FeezColors.ink, letterSpacing: -0.01)),
                        ])),
                    ]),
                    const Padding(padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: Color(0xFFF0F0F0), height: 1)),
                    _line(Icons.location_on_outlined, 'Adresse', 'Cocody, Abidjan'),
                    const SizedBox(height: 12),
                    _line(Icons.access_time_rounded, 'Livraison estimée', '15 à 25 min',
                      valueColor: FeezColors.red),
                    const SizedBox(height: 12),
                    _line(Icons.bolt_rounded, 'Statut', 'En préparation',
                      valueColor: FeezColors.green),
                  ]))),
            ),

            const Spacer(),

            // ── Boutons ────────────────────────────────────
            FadeTransition(opacity: _fadeContent,
              child: Column(children: [
                PremiumButton(
                  label: 'Suivre ma commande',
                  leadingIcon: Icons.location_on_rounded,
                  trailingIcon: Icons.arrow_forward_rounded,
                  height: 56,
                  onTap: () => context.go('/tracking/${widget.orderId}')),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    height: 48, width: double.infinity,
                    alignment: Alignment.center,
                    child: const Text("Retour à l'accueil",
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: FeezColors.mid)))),
                const SizedBox(height: 8),
              ])),
          ]),
        ),
      ])),
    );
  }

  Widget _line(IconData icon, String label, String value, {Color? valueColor}) =>
    Row(children: [
      Icon(icon, size: 16, color: FeezColors.low),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(fontSize: 12,
        color: FeezColors.mid, fontWeight: FontWeight.w500)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 13,
        fontWeight: FontWeight.w800,
        color: valueColor ?? FeezColors.ink)),
    ]);
}
