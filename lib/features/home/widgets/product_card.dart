import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/product_model.dart';
import '../../../core/theme.dart';
import '../../../widgets/product_image.dart';
import '../../favorites/providers/favorites_provider.dart';

class ProductCard extends ConsumerStatefulWidget {
  final ProductModel product;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, required this.qty,
    required this.onAdd, required this.onRemove, this.onTap});

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  final _pageCtrl = PageController();
  int _imgIdx = 0;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  void _add()    { HapticFeedback.lightImpact(); _ctrl.forward().then((_) => _ctrl.reverse()); widget.onAdd(); }
  void _remove() { HapticFeedback.lightImpact(); widget.onRemove(); }

  @override
  Widget build(BuildContext context) {
    final p    = widget.product;
    final pct  = p.discountPct;
    final imgs = p.images.isNotEmpty ? p.images : <String>[];
    final isFav = ref.watch(favoritesProvider).contains(p.id);

    return _TappableScale(
      onTap: widget.onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // ── Carte 3D ─────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                // Tranche basse (couche la plus profonde)
                BoxShadow(
                  color: Color(0xFFBBBBBB),
                  blurRadius: 0,
                  offset: Offset(4, 8),
                ),
                // Tranche intermédiaire
                BoxShadow(
                  color: Color(0xFFD0D0D0),
                  blurRadius: 0,
                  offset: Offset(2, 5),
                ),
                // Halo doux ambiant
                BoxShadow(
                  color: Color(0x14000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                  spreadRadius: -4,
                ),
                // Contact shadow
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                clipBehavior: Clip.none,
                children: [

                  // Contenu carte
                  Column(children: [

                    // Image
                    SizedBox(
                      height: 118, width: double.infinity,
                      child: Stack(children: [
                        Positioned.fill(child: Container(
                          color: _catBg(p.category),
                          child: imgs.isEmpty
                            ? const Center(child: Icon(
                                Icons.image_outlined,
                                color: Color(0xFFD0D0D0), size: 40))
                            : PageView.builder(
                                controller: _pageCtrl,
                                itemCount: imgs.length,
                                onPageChanged: (i) =>
                                  setState(() => _imgIdx = i),
                                itemBuilder: (_, i) => _ImageWithSkeleton(
                                  url: imgs[i],
                                  bg: _catBg(p.category))))),

                        // Dots pagination
                        if (imgs.length > 1)
                          Positioned(bottom: 6, left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(10)),
                              child: Row(mainAxisSize: MainAxisSize.min,
                                children: List.generate(imgs.length, (i) =>
                                  AnimatedContainer(
                                    duration:
                                      const Duration(milliseconds: 200),
                                    width: i == _imgIdx ? 12 : 4,
                                    height: 4,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 1.5),
                                    decoration: BoxDecoration(
                                      color: i == _imgIdx
                                        ? FeezColors.red
                                        : FeezColors.red.withValues(
                                            alpha: 0.30),
                                      borderRadius:
                                        BorderRadius.circular(2))))))),

                        // Badge promo
                        if (pct != null)
                          Positioned(top: 0, left: 0,
                            child: Container(
                              padding:
                                const EdgeInsets.fromLTRB(8, 4, 9, 4),
                              decoration: const BoxDecoration(
                                color: FeezColors.red,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(9))),
                              child: Text('-$pct%',
                                style: const TextStyle(fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white)))),

                        // Heart
                        Positioned(top: 6, right: 6,
                          child: GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ref.read(favoritesProvider.notifier)
                                .toggle(p.id);
                            },
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                shape: BoxShape.circle,
                                boxShadow: const [BoxShadow(
                                  color: Color(0x18000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 1))]),
                              child: Icon(
                                isFav ? Icons.favorite
                                      : Icons.favorite_border,
                                size: 15,
                                color: isFav
                                  ? FeezColors.red
                                  : const Color(0xFF999999))))),

                        // Rupture
                        if (!p.isAvailable)
                          Positioned.fill(child: Container(
                            color: Colors.white.withValues(alpha: 0.65),
                            child: const Center(child: Text('Rupture',
                              style: TextStyle(fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF888888)))))),
                      ]),
                    ),

                    // Prix
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFAFAFA), Color(0xFFEFEFEF)]),
                        border: Border(top: BorderSide(
                          color: Color(0xFFDDDDDD), width: 1.0))),
                      padding: const EdgeInsets.fromLTRB(9, 7, 9, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.unit,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF999999))),
                          const SizedBox(height: 1),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(p.formattedPrice,
                                style: const TextStyle(
                                  fontFamily: 'BarlowCondensed',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0D0D0D),
                                  height: 1.0)),
                              if (p.formattedOldPrice != null) ...[
                                const SizedBox(width: 4),
                                Text(p.formattedOldPrice!,
                                  style: const TextStyle(fontSize: 9,
                                    color: Color(0xFFBBBBBB),
                                    decoration:
                                      TextDecoration.lineThrough)),
                              ],
                            ]),
                        ],
                      ),
                    ),
                  ]), // Column

                  // FAB à la jointure image/prix
                  Positioned(top: 118 - 19, right: 8,
                    child: ScaleTransition(scale: _scale,
                      child: p.isAvailable
                        ? widget.qty == 0
                          ? _Fab(onTap: _add)
                          : _FabQty(qty: widget.qty,
                              onAdd: _add, onRemove: _remove)
                        : const _FabDisabled())),

                ], // Stack children
              ), // Stack
            ), // ClipRRect
          ), // Container 3D

          // ── Nom produit ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 10, 2, 0),
            child: Text(p.name,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'DMSans', fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2A2A2A),
                height: 1.3, letterSpacing: -0.1)),
          ),
        ], // Column children
      ), // Column
    ); // _TappableScale
  }

  Color _catBg(String cat) => const {
    'epicerie':    Color(0xFFF0F9F4),
    'pharmacie':   Color(0xFFEEF6FF),
    'beaute':      Color(0xFFFFF0F6),
    'boissons':    Color(0xFFEEF4FF),
    'boucherie':   Color(0xFFFFF4EE),
    'boulangerie': Color(0xFFFFF9EE),
  }[cat] ?? const Color(0xFFF5F5F5);
}

// ── Image avec skeleton pendant le chargement ──────────────────
class _ImageWithSkeleton extends StatelessWidget {
  final String url;
  final Color bg;
  const _ImageWithSkeleton({required this.url, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      width: double.infinity,
      height: 118,
      fit: BoxFit.cover,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) return child;
        return _Skeleton(bg: bg);
      },
      errorBuilder: (_, __, ___) => Container(
        color: bg,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
            color: Color(0xFFCCCCCC), size: 32)),
      ),
    );
  }
}

// ── Skeleton shimmer ───────────────────────────────────────────
class _Skeleton extends StatelessWidget {
  final Color bg;
  const _Skeleton({required this.bg});

  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: Color.lerp(bg, const Color(0xFFE0E0E0), 0.5)!,
    highlightColor: Color.lerp(bg, Colors.white, 0.85)!,
    period: const Duration(milliseconds: 1200),
    child: Container(
      width: double.infinity,
      height: 118,
      color: Colors.white,
    ),
  );
}

// ── FAB + ────────────────────────────────────────────────────────
class _Fab extends StatefulWidget {
  final VoidCallback onTap;
  const _Fab({required this.onTap});
  @override State<_Fab> createState() => _FabState();
}
class _FabState extends State<_Fab> {
  bool _p = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => setState(() => _p = true),
    onTapUp:     (_) { setState(() => _p = false); widget.onTap(); },
    onTapCancel: ()  => setState(() => _p = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 130),
      width: 38, height: 38,
      transform: Matrix4.translationValues(0, _p ? 1 : 0, 0),
      decoration: BoxDecoration(
        gradient: _p
          ? const LinearGradient(begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD41525), Color(0xFFB81020)])
          : const LinearGradient(begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFFAFAFA)]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _p ? const Color(0xFFB81020) : FeezColors.red,
          width: 1.6),
        boxShadow: _p
          ? [const BoxShadow(color: Color(0x33000000),
              blurRadius: 2, offset: Offset(0, 1))]
          : const [
              BoxShadow(color: Color(0x1F000000),
                blurRadius: 6, offset: Offset(0, 2)),
              BoxShadow(color: Color(0x08000000),
                blurRadius: 1, offset: Offset(0, 1)),
            ]),
      child: Center(child: Icon(Icons.add_rounded,
        color: _p ? Colors.white : FeezColors.red, size: 22))));
}

// ── FAB qty ──────────────────────────────────────────────────────
class _FabQty extends StatelessWidget {
  final int qty;
  final VoidCallback onAdd, onRemove;
  const _FabQty({required this.qty, required this.onAdd, required this.onRemove});
  @override
  Widget build(BuildContext context) => Container(
    height: 38,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFFEE2738), Color(0xFFCF1422)]),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFB81020), width: 0.5),
      boxShadow: const [
        BoxShadow(color: Color(0x29000000),
          blurRadius: 8, offset: Offset(0, 3)),
        BoxShadow(color: Color(0x0F000000),
          blurRadius: 2, offset: Offset(0, 1)),
      ]),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(onTap: onRemove,
        child: const SizedBox(width: 28, height: 38,
          child: Center(child: Icon(Icons.remove_rounded,
            color: Colors.white, size: 15)))),
      Text('$qty', style: const TextStyle(fontFamily: 'BarlowCondensed',
        fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
      GestureDetector(onTap: onAdd,
        child: const SizedBox(width: 28, height: 38,
          child: Center(child: Icon(Icons.add_rounded,
            color: Colors.white, size: 15)))),
    ]));
}

// ── FAB disabled ──────────────────────────────────────────────────
class _FabDisabled extends StatelessWidget {
  const _FabDisabled();
  @override
  Widget build(BuildContext context) => Container(
    width: 38, height: 38,
    decoration: BoxDecoration(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(12)),
    child: const Center(child: Text('–',
      style: TextStyle(fontSize: 16, color: Color(0xFFBBBBBB)))));
}

// ── Scale on tap ──────────────────────────────────────────────────
class _TappableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _TappableScale({required this.child, this.onTap});
  @override State<_TappableScale> createState() => _TappableScaleState();
}
class _TappableScaleState extends State<_TappableScale>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;
  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
      duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap:       widget.onTap,
    onTapDown:   (_) => _ctrl.forward(),
    onTapUp:     (_) => _ctrl.reverse(),
    onTapCancel: ()  => _ctrl.reverse(),
    child: ScaleTransition(scale: _scale, child: widget.child));
}