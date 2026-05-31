import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/premium_widgets.dart';
import '../../../widgets/product_image.dart';
import '../../home/providers/home_provider.dart';
import '../providers/order_provider.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});
  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;

  int _eta = 18;
  Timer? _etaTimer;

  static const _statusLabel = {
    'pending':'Commande reçue','accepted':'Commande acceptée','preparing':'En préparation',
    'ready':'Prête à partir','in_transit':'En route','delivered':'Livrée',
  };

  static String _fmt(int n) =>
    '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} F';

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this,
      duration: const Duration(seconds: 2))..repeat();
    _etaTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _eta > 1) setState(() => _eta--);
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _etaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(userOrdersProvider);
    final productsAsync = ref.watch(productsProvider);
    final products = productsAsync.asData?.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(
          color: FeezColors.red, strokeWidth: 2)),
        error: (e, _) => Center(child: Text('$e')),
        data: (orders) {
          Map<String, dynamic>? order;
          try {
            order = orders.firstWhere((o) => o['id'].toString() == widget.orderId);
          } catch (_) { order = orders.isNotEmpty ? orders.first : null; }
          if (order == null) return const Center(child: Text('Commande introuvable'));

          final status = order['status'] as String? ?? 'pending';
          final items = (order['items'] as List?) ?? [];
          final subtotal = (order['subtotal'] as num?)?.toInt() ?? 0;
          final fee = (order['delivery_fee'] as num?)?.toInt() ?? 200;
          final total = (order['total'] as num?)?.toInt() ?? subtotal + fee;
          final addr = order['delivery_address'] ?? 'Adresse non précisée';
          final phone = order['phone'] ?? '';

          return SafeArea(child: Column(children: [

            // ── Header ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
              child: Row(children: [
                FeezBackButton(
                  onTap: () => context.canPop() ? context.pop() : context.go('/orders')),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Commande #${widget.orderId.substring(0, 6).toUpperCase()}',
                    style: const TextStyle(fontFamily: 'BarlowCondensed',
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: FeezColors.ink, letterSpacing: -0.02)),
                  Text(_statusLabel[status] ?? '',
                    style: const TextStyle(fontSize: 12,
                      fontWeight: FontWeight.w600, color: FeezColors.red)),
                ])),
              ])),

            // ── Scrollable ────────────────────────────────────
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              children: [

                // ══ MAP de suivi améliorée ════════════════════
                Container(
                  height: 260,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Color(0x18000000),
                      blurRadius: 20, offset: Offset(0, 8))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (context, _) => Stack(children: [
                        // Fond carte stylisé
                        Positioned.fill(child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft, end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFE3EEF5),
                                Color(0xFFEDF4E8),
                                Color(0xFFF5EFE3),
                              ])),
                          child: CustomPaint(painter: _MapGridPainter()))),

                        // Bâtiments / blocs décoratifs
                        Positioned(left: 20, top: 30,
                          child: _block(40, 30, const Color(0xFFD6E4ED))),
                        Positioned(left: 90, top: 50,
                          child: _block(60, 40, const Color(0xFFDEE7D2))),
                        Positioned(right: 30, top: 30,
                          child: _block(50, 35, const Color(0xFFE5DED2))),
                        Positioned(left: 60, bottom: 60,
                          child: _block(70, 50, const Color(0xFFDFE5D6))),
                        Positioned(right: 50, bottom: 80,
                          child: _block(45, 40, const Color(0xFFE6DCCC))),

                        // Route principale
                        Positioned.fill(child: CustomPaint(
                          painter: _RoutePainter(progress: _pulseCtrl.value))),

                        // Marker boutique (départ)
                        const Positioned(left: 24, top: 36,
                          child: _MapMarker(icon: Icons.storefront_rounded,
                            color: Color(0xFF1976D2), label: 'Boutique')),

                        // Livreur (position animée selon statut)
                        Positioned(
                          left: 60 + (_pulseCtrl.value * 160),
                          top: 110 + (_pulseCtrl.value * 40),
                          child: Stack(alignment: Alignment.center, children: [
                            Container(
                              width: 60 + (_pulseCtrl.value * 40),
                              height: 60 + (_pulseCtrl.value * 40),
                              decoration: BoxDecoration(
                                color: FeezColors.red.withValues(
                                  alpha: 0.25 - (_pulseCtrl.value * 0.25)),
                                shape: BoxShape.circle)),
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: FeezColors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(
                                  color: FeezColors.red.withValues(alpha: 0.5),
                                  blurRadius: 16, offset: const Offset(0, 4))]),
                              child: const Icon(Icons.motorcycle_rounded,
                                color: Colors.white, size: 22)),
                          ])),

                        // Marker destination (toi)
                        const Positioned(right: 24, bottom: 30,
                          child: _MapMarker(icon: Icons.home_rounded,
                            color: Color(0xFF388E3C), label: 'Toi')),

                        // Badge ETA en bas
                        Positioned(bottom: 12, left: 12, right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [BoxShadow(
                                color: Color(0x18000000), blurRadius: 8,
                                offset: Offset(0, 2))]),
                            child: Row(children: [
                              Container(width: 32, height: 32,
                                decoration: BoxDecoration(
                                  color: FeezColors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.delivery_dining_rounded,
                                  size: 18, color: FeezColors.red)),
                              const SizedBox(width: 10),
                              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Ton livreur',
                                    style: TextStyle(fontSize: 10,
                                      color: FeezColors.low,
                                      fontWeight: FontWeight.w600)),
                                  Text('À 5 min de toi',
                                    style: TextStyle(fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: FeezColors.ink)),
                                ])),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: FeezColors.red,
                                  borderRadius: BorderRadius.circular(20)),
                                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                  Icon(Icons.phone, color: Colors.white, size: 12),
                                  SizedBox(width: 4),
                                  Text('Appeler', style: TextStyle(fontSize: 11,
                                    fontWeight: FontWeight.w700, color: Colors.white)),
                                ])),
                            ]))),
                      ]),
                    )),
                  ),

                // ETA Card premium
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                      colors: [Color(0xFFE8192C), Color(0xFFFF4D5E)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: FeezColors.red.withValues(alpha: 0.30),
                      blurRadius: 18, offset: const Offset(0, 6))],
                  ),
                  child: Row(children: [
                    AnimatedBuilder(
                      animation: _pulseCtrl,
                      builder: (_, __) => Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15 + _pulseCtrl.value * 0.10),
                          shape: BoxShape.circle),
                        child: const Center(child: Icon(
                          Icons.motorcycle_rounded, color: Colors.white, size: 28)))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Arrivée dans',
                        style: TextStyle(fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600, letterSpacing: 0.05)),
                      const SizedBox(height: 2),
                      Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic, children: [
                          Text('$_eta', style: const TextStyle(
                            fontFamily: 'BarlowCondensed', fontSize: 38,
                            fontWeight: FontWeight.w900, color: Colors.white,
                            height: 1)),
                          const SizedBox(width: 6),
                          const Text('min', style: TextStyle(fontSize: 14,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                        ]),
                    ])),
                  ])),

                const SizedBox(height: 18),

                // Timeline
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x0F000000),
                      blurRadius: 10, offset: Offset(0, 3))]),
                  child: Column(children: _timelineSteps(status)),
                ),

                const SizedBox(height: 14),

                // ── Produits avec photos ════════════════════════
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x0F000000),
                      blurRadius: 10, offset: Offset(0, 3))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: FeezColors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.shopping_bag_outlined,
                          size: 15, color: FeezColors.red)),
                      const SizedBox(width: 10),
                      Text('Ma commande · ${items.length} article${items.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w800, color: FeezColors.ink)),
                    ]),
                    const SizedBox(height: 12),
                    ...items.map((item) {
                      final m = item is Map<String, dynamic>
                        ? item : Map<String, dynamic>.from(item as Map);
                      // 1. Essayer image_url stocké
                      String? url = m['image_url']?.toString();
                      // 2. Sinon, chercher dans products via product_id
                      if (url == null || url.isEmpty) {
                        final pid = m['product_id']?.toString();
                        if (pid != null) {
                          try {
                            final p = products.firstWhere((p) => p.id == pid);
                            url = p.primaryImage as String?;
                          } catch (_) {}
                        }
                      }
                      final emoji = m['emoji']?.toString() ?? '📦';
                      final price = (m['price'] as num?)?.toInt() ?? 0;
                      final q = (m['quantity'] as num?)?.toInt() ?? (m['qty'] as num?)?.toInt() ?? 1;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(children: [
                          Container(width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10)),
                            child: url != null && url.isNotEmpty
                              ? ClipRRect(borderRadius: BorderRadius.circular(10),
                                  child: ProductImage(url: url, size: 50,
                                    borderRadius: BorderRadius.circular(10)))
                              : Center(child: Text(emoji,
                                  style: const TextStyle(fontSize: 26)))),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m['name']?.toString() ?? 'Produit',
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w700, color: FeezColors.ink)),
                              Text(m['unit']?.toString() ?? '',
                                style: const TextStyle(fontSize: 10.5, color: FeezColors.low)),
                              const SizedBox(height: 3),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(4)),
                                  child: Text('×$q',
                                    style: const TextStyle(fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: FeezColors.red))),
                                const SizedBox(width: 6),
                                Text(_fmt(price),
                                  style: const TextStyle(fontSize: 11, color: FeezColors.mid)),
                              ]),
                            ])),
                          Text(_fmt(price * q),
                            style: const TextStyle(fontFamily: 'BarlowCondensed',
                              fontSize: 16, fontWeight: FontWeight.w900,
                              color: FeezColors.ink)),
                        ]));
                    }),
                  ])),

                const SizedBox(height: 14),

                // ── Livraison ════════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x0F000000),
                      blurRadius: 10, offset: Offset(0, 3))]),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: FeezColors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.location_on_outlined,
                          size: 15, color: FeezColors.red)),
                      const SizedBox(width: 10),
                      const Text('Adresse de livraison',
                        style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w800, color: FeezColors.ink)),
                    ]),
                    const SizedBox(height: 8),
                    Text(addr.toString(), style: const TextStyle(
                      fontSize: 13, color: FeezColors.mid, height: 1.4)),
                    if (phone.toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.phone_outlined,
                          size: 13, color: FeezColors.low),
                        const SizedBox(width: 6),
                        Text(phone.toString(),
                          style: const TextStyle(fontSize: 12, color: FeezColors.mid)),
                      ]),
                    ],
                  ])),

                const SizedBox(height: 14),

                // ── Total ════════════════════════════════════════
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Color(0x0F000000),
                      blurRadius: 10, offset: Offset(0, 3))]),
                  child: Column(children: [
                    _row('Sous-total', _fmt(subtotal)),
                    _row('Frais livraison', _fmt(fee), color: FeezColors.green),
                    const Divider(height: 22, color: Color(0xFFF0F0F0)),
                    Row(children: [
                      const Text('Total payé',
                        style: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 18,
                          fontWeight: FontWeight.w900, color: FeezColors.ink)),
                      const Spacer(),
                      Text(_fmt(total),
                        style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 24,
                          fontWeight: FontWeight.w900, color: FeezColors.red)),
                    ]),
                  ])),

                const SizedBox(height: 14),

                // Aide / Contact
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F0),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFFFE4B5))),
                    child: Row(children: [
                      const Icon(Icons.support_agent_rounded,
                        color: Color(0xFFFF6B00), size: 22),
                      const SizedBox(width: 12),
                      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Un problème avec ta commande ?',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: FeezColors.ink)),
                          Text('Contacte le support',
                            style: TextStyle(fontSize: 11, color: FeezColors.mid)),
                        ])),
                      const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
                    ]))),
              ])),
          ]));
        }),
    );
  }

  List<Widget> _timelineSteps(String currentStatus) {
    const steps = ['pending', 'accepted', 'preparing', 'ready', 'in_transit', 'delivered'];
    const labels = ['Commande reçue', 'Acceptée', 'En préparation', 'Prête', 'En route', 'Livrée'];
    const icons = [Icons.receipt_long, Icons.check_circle_outline,
      Icons.restaurant_menu_outlined, Icons.shopping_bag_outlined,
      Icons.motorcycle_rounded, Icons.home_outlined];
    final currentIdx = steps.indexOf(currentStatus);

    return List.generate(steps.length, (i) {
      final done = i <= currentIdx;
      final isLast = i == steps.length - 1;
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(width: 32, height: 32,
            decoration: BoxDecoration(
              color: done ? FeezColors.red : const Color(0xFFEEEEEE),
              shape: BoxShape.circle,
              boxShadow: done ? [BoxShadow(
                color: FeezColors.red.withValues(alpha: 0.2),
                blurRadius: 6, offset: const Offset(0, 2))] : null),
            child: Icon(done ? Icons.check : icons[i],
              color: done ? Colors.white : const Color(0xFFAAAAAA), size: 16)),
          if (!isLast)
            Container(width: 2, height: 26,
              color: i < currentIdx ? FeezColors.red : const Color(0xFFEEEEEE)),
        ]),
        const SizedBox(width: 12),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(labels[i], style: TextStyle(fontSize: 13,
              fontWeight: done ? FontWeight.w800 : FontWeight.w500,
              color: done ? FeezColors.ink : FeezColors.low)),
            if (i == currentIdx)
              const Padding(padding: EdgeInsets.only(top: 2),
                child: Text('En cours…', style: TextStyle(fontSize: 10.5,
                  fontWeight: FontWeight.w600, color: FeezColors.red))),
          ]))),
      ]);
    });
  }

  Widget _row(String l, String v, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(l, style: const TextStyle(fontSize: 13, color: FeezColors.mid)),
      const Spacer(),
      Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: color ?? FeezColors.ink)),
    ]));

  Widget _block(double w, double h, Color color) => Container(
    width: w, height: h,
    decoration: BoxDecoration(color: color,
      borderRadius: BorderRadius.circular(6)));
}

// ── Map marker ────────────────────────────────────────────────
class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  const _MapMarker({required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          boxShadow: const [BoxShadow(color: Color(0x20000000),
            blurRadius: 4, offset: Offset(0, 1))]),
        child: Text(label, style: const TextStyle(fontSize: 9,
          fontWeight: FontWeight.w700, color: Color(0xFF333333)))),
      const SizedBox(height: 3),
      Container(width: 30, height: 30,
        decoration: BoxDecoration(
          color: color, shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6, offset: const Offset(0, 2))]),
        child: Icon(icon, color: Colors.white, size: 14)),
    ]);
}

// ── Painter pour grille de carte ──────────────────────────────
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 0.5;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ── Painter pour route pointillée animée ──────────────────────
class _RoutePainter extends CustomPainter {
  final double progress;
  _RoutePainter({this.progress = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE8192C).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(45, 60)
      ..quadraticBezierTo(size.width * 0.35, 50, size.width * 0.45, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.65, size.width - 45, size.height - 55);

    // Trait pointillé animé
    const dash = 9.0;
    const gap = 7.0;
    final offset = progress * (dash + gap);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double d = -offset;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d.clamp(0, metric.length), (d + dash).clamp(0, metric.length)), paint);
        d += dash + gap;
      }
    }
  }
  @override bool shouldRepaint(_RoutePainter old) => old.progress != progress;
}
