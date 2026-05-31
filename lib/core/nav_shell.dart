import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'theme.dart';
import '../widgets/product_image.dart';
import '../features/cart/providers/cart_provider.dart';
import '../features/home/providers/home_provider.dart';
import '../models/product_model.dart';

class NavShell extends ConsumerWidget {
  final Widget child;
  const NavShell({super.key, required this.child});

  int _idx(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/restaurant')) return 1;
    if (loc.startsWith('/orders'))     return 2;
    if (loc.startsWith('/profile'))    return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idx       = _idx(context);
    final isHome    = idx == 0;
    final mode      = ref.watch(modeProvider);
    final marketQty = ref.watch(marketTotalItemsProvider);
    final cart      = ref.watch(marketCartProvider);
    final prodsAsync = ref.watch(productsProvider);

    final showBasket = isHome && mode == AppMode.market && marketQty > 0;

    // Récupérer les 3 DERNIERS produits ajoutés (par ordre d'insertion)
    List<ProductModel> cartProducts = [];
    if (prodsAsync.asData != null) {
      final prodMap = {for (final p in prodsAsync.asData!.value) p.id: p};
      final allKeys = cart.keys
          .where((id) => prodMap.containsKey(id))
          .toList();
      // Garder les 3 derniers en ordre chronologique
      final lastKeys = allKeys.length > 3
          ? allKeys.sublist(allKeys.length - 3)
          : allKeys;
      cartProducts = lastKeys.map((id) => prodMap[id]!).toList();
    }

    return Scaffold(
      body: Stack(children: [
        Positioned.fill(child: child),
        // Basket bar au-dessus de la nav bar
        if (showBasket)
          Positioned(
            left: 0, right: 0, bottom: 10,
            child: Center(
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutBack,
                offset: Offset.zero,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: 1.0,
                  child: _BasketBar(qty: marketQty, products: cartProducts))))),
      ]),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
          boxShadow: [
            BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  index: 0, current: idx,
                  label: 'Market',
                  path: '/home',
                  iconOff: _FeezIcons.homeOff,
                  iconOn:  _FeezIcons.homeOn,
                ),
                _NavItem(
                  index: 1, current: idx,
                  label: 'Restaurant',
                  path: '/restaurant',
                  iconOff: _FeezIcons.restaurantOff,
                  iconOn:  _FeezIcons.restaurantOn,
                ),
                _NavItem(
                  index: 2, current: idx,
                  label: 'Commandes',
                  path: '/orders',
                  iconOff: _FeezIcons.ordersOff,
                  iconOn:  _FeezIcons.ordersOn,
                ),
                _NavItem(
                  index: 3, current: idx,
                  label: 'Profil',
                  path: '/profile',
                  iconOff: _FeezIcons.profileOff,
                  iconOn:  _FeezIcons.profileOn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Méthode legacy supprimée — voir _NavItem ci-dessous
}

// ══ Nav Item premium ════════════════════════════════════════════
class _NavItem extends StatelessWidget {
  final int index, current;
  final String label, path;
  final Widget iconOff, iconOn;
  const _NavItem({required this.index, required this.current,
    required this.label, required this.path,
    required this.iconOff, required this.iconOn});

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => context.go(path),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(width: 80,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween<double>(begin: 0.75, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
              child: child),
            child: active
              ? SizedBox(key: const ValueKey('on'),  width: 26, height: 26, child: iconOn)
              : SizedBox(key: const ValueKey('off'), width: 26, height: 26, child: iconOff),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? FeezColors.red : const Color(0xFFBBBBBB))),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: active ? 16 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: active ? FeezColors.red : Colors.transparent,
              borderRadius: BorderRadius.circular(2))),
        ])),
    );
  }
}

// ══ Icônes SVG custom dessinées — identité Feez ════════════════
class _FeezIcons {
  static Widget homeOff       = const _HomeIcon(active: false);
  static Widget homeOn        = const _HomeIcon(active: true);
  static Widget restaurantOff = const _RestaurantIcon(active: false);
  static Widget restaurantOn  = const _RestaurantIcon(active: true);
  static Widget ordersOff     = const _OrdersIcon(active: false);
  static Widget ordersOn      = const _OrdersIcon(active: true);
  static Widget profileOff    = const _ProfileIcon(active: false);
  static Widget profileOn     = const _ProfileIcon(active: true);
}

// ── Restaurant ──────────────────────────────────────────────────
class _RestaurantIcon extends StatelessWidget {
  final bool active;
  const _RestaurantIcon({required this.active});
  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE8192C);
    const grey  = Color(0xFFBBBBBB);
    return Icon(active ? Icons.restaurant_rounded : Icons.restaurant_outlined,
      size: 22, color: active ? color : grey);
  }
}

// ── Maison ─────────────────────────────────────────────────────
class _HomeIcon extends StatelessWidget {
  final bool active;
  const _HomeIcon({required this.active});
  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE8192C);
    const grey  = Color(0xFFBBBBBB);
    return Icon(
      active ? Icons.storefront_rounded : Icons.storefront_outlined,
      size: 24, color: active ? color : grey);
  }
}

class _HomePainter extends CustomPainter {
  final Color color;
  final bool filled;
  const _HomePainter(this.color, this.filled);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final s = size.width;
    final path = Path();
    // Toit
    path.moveTo(s * 0.12, s * 0.46);
    path.lineTo(s * 0.50, s * 0.12);
    path.lineTo(s * 0.88, s * 0.46);
    path.lineTo(s * 0.88, s * 0.88);
    path.lineTo(s * 0.62, s * 0.88);
    path.lineTo(s * 0.62, s * 0.65);
    path.lineTo(s * 0.38, s * 0.65);
    path.lineTo(s * 0.38, s * 0.88);
    path.lineTo(s * 0.12, s * 0.88);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override bool shouldRepaint(_HomePainter o) => o.color != color || o.filled != filled;
}

// ── Commandes (reçu) ───────────────────────────────────────────
class _OrdersIcon extends StatelessWidget {
  final bool active;
  const _OrdersIcon({required this.active});
  @override
  Widget build(BuildContext context) => SizedBox(width: 26, height: 26,
    child: CustomPaint(painter: _OrdersPainter(
      active ? const Color(0xFFE8192C) : const Color(0xFFBBBBBB), active)));
}

class _OrdersPainter extends CustomPainter {
  final Color color;
  final bool filled;
  const _OrdersPainter(this.color, this.filled);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = color..style = PaintingStyle.stroke
      ..strokeWidth = 1.7..strokeCap = StrokeCap.round;

    // Fond rect
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(s*0.16, s*0.08, s*0.68, s*0.84),
      const Radius.circular(4));

    if (filled) {
      canvas.drawRRect(rect, fillPaint);
      final linePaint = Paint()..color = Colors.white
        ..strokeWidth = 1.7..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(s*0.32, s*0.36), Offset(s*0.68, s*0.36), linePaint);
      canvas.drawLine(Offset(s*0.32, s*0.52), Offset(s*0.68, s*0.52), linePaint);
      canvas.drawLine(Offset(s*0.32, s*0.68), Offset(s*0.56, s*0.68), linePaint);
    } else {
      canvas.drawRRect(rect, strokePaint);
      canvas.drawLine(Offset(s*0.32, s*0.36), Offset(s*0.68, s*0.36), strokePaint);
      canvas.drawLine(Offset(s*0.32, s*0.52), Offset(s*0.68, s*0.52), strokePaint);
      canvas.drawLine(Offset(s*0.32, s*0.68), Offset(s*0.56, s*0.68), strokePaint);
    }
  }

  @override bool shouldRepaint(_OrdersPainter o) => o.color != color || o.filled != filled;
}

// ── Profil (personne) ──────────────────────────────────────────
class _ProfileIcon extends StatelessWidget {
  final bool active;
  const _ProfileIcon({required this.active});
  @override
  Widget build(BuildContext context) => SizedBox(width: 26, height: 26,
    child: CustomPaint(painter: _ProfilePainter(
      active ? const Color(0xFFE8192C) : const Color(0xFFBBBBBB), active)));
}

class _ProfilePainter extends CustomPainter {
  final Color color;
  final bool filled;
  const _ProfilePainter(this.color, this.filled);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    // Tête
    canvas.drawCircle(Offset(s * 0.5, s * 0.32), s * 0.17, paint);

    // Corps (arc)
    final bodyPath = Path();
    bodyPath.moveTo(s * 0.1, s * 0.88);
    bodyPath.quadraticBezierTo(s * 0.1, s * 0.60, s * 0.5, s * 0.60);
    bodyPath.quadraticBezierTo(s * 0.9, s * 0.60, s * 0.9, s * 0.88);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(bodyPath, strokePaint);

    if (filled) {
      // Remplir le demi-ovale corps
      final bodyFill = Path();
      bodyFill.moveTo(s*0.1, s*0.88);
      bodyFill.quadraticBezierTo(s*0.1, s*0.60, s*0.5, s*0.60);
      bodyFill.quadraticBezierTo(s*0.9, s*0.60, s*0.9, s*0.88);
      bodyFill.close();
      final fillPaint = Paint()..color = color..style = PaintingStyle.fill;
      canvas.drawPath(bodyFill, fillPaint);
    }
  }

  @override bool shouldRepaint(_ProfilePainter o) => o.color != color || o.filled != filled;
}

// ══ Renderer SVG placeholder (non utilisé) ════════════════════
class _SvgPainter extends CustomPainter {
  final String svg;
  const _SvgPainter(this.svg);
  @override void paint(Canvas canvas, Size size) {}
  @override bool shouldRepaint(_) => false;
}

// ── Basket Bar ─────────────────────────────────────────────────
class _BasketBar extends StatelessWidget {
  final int qty;
  final List<ProductModel> products;
  const _BasketBar({required this.qty, required this.products});

  Widget _thumbs() {
    const size    = 36.0;
    const overlap = 10.0;
    return SizedBox(
      width: products.length * (size - overlap) + overlap,
      height: size,
      child: Stack(
        children: List.generate(products.length, (i) {
          return Positioned(
            left: i * (size - overlap),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1C1C1C), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ProductImage(
                  url: products[i].primaryImage,
                  size: size,
                  borderRadius: BorderRadius.circular(8),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: () => context.push('/cart'),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1C1C1C), Color(0xFF0A0A0A)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: const Border(
              top: BorderSide(color: FeezColors.red, width: 2.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: FeezColors.red.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Thumbnails ou icône
                products.isNotEmpty
                    ? _thumbs()
                    : Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: FeezColors.red,
                          borderRadius: BorderRadius.circular(11),
                          boxShadow: [
                            BoxShadow(
                              color: FeezColors.red.withValues(alpha: 0.40),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),

                const SizedBox(width: 14),

                // Texte
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$qty article${qty > 1 ? "s" : ""}',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Voir mon panier',
                        style: TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.0,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                // CTA
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 9, 10, 9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFE8192C), Color(0xFFBF0F1F)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    boxShadow: [
                      BoxShadow(
                        color: FeezColors.red.withValues(alpha: 0.40),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Commander',
                        style: TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.02,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}