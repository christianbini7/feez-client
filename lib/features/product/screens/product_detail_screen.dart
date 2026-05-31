import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../models/product_model.dart';
import '../../../widgets/product_image.dart';
import '../../cart/providers/cart_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../home/widgets/product_card.dart';
import '../../favorites/providers/favorites_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _imgIdx = 0;
  late PageController _pageCtrl;
  bool _descExpanded = false;
  bool _nameExpanded = false;

  @override
  void initState() { super.initState(); _pageCtrl = PageController(); }
  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  void _add()    { HapticFeedback.mediumImpact(); ref.read(marketCartProvider.notifier).add(widget.product.id); }
  void _remove() { HapticFeedback.lightImpact();  ref.read(marketCartProvider.notifier).remove(widget.product.id); }

  @override
  Widget build(BuildContext context) {
    final p         = widget.product;
    final imgs      = p.images.isNotEmpty ? p.images : <String>[];
    final qty       = ref.watch(marketCartProvider)[p.id] ?? 0;
    final cartTotal = ref.watch(marketTotalItemsProvider);
    final isFav     = ref.watch(favoritesProvider).contains(p.id);
    final prods     = ref.watch(productsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(children: [

        // ── Contenu scrollable ────────────────────────
        CustomScrollView(slivers: [

          // ── IMAGE PLEIN CADRE ─────────────────────
          SliverToBoxAdapter(
            child: SizedBox(
              height: 340,
              child: Stack(children: [
                // Images plein cadre (cover)
                if (imgs.isNotEmpty)
                  PageView.builder(
                    controller: _pageCtrl,
                    itemCount: imgs.length,
                    onPageChanged: (i) => setState(() => _imgIdx = i),
                    itemBuilder: (_, i) => ProductImage(
                      url: imgs[i], size: 340,
                      borderRadius: BorderRadius.zero,
                      fit: BoxFit.cover))
                else
                  Container(
                    color: _catBg(p.category),
                    child: Center(child: Text(p.emoji,
                      style: const TextStyle(fontSize: 100)))),

                // Gradient bas → fondu vers le blanc
                Positioned(bottom: 0, left: 0, right: 0,
                  child: Container(height: 80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.white, Colors.transparent])))),

                // Dots pagination
                if (imgs.length > 1)
                  Positioned(bottom: 16, left: 0, right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(imgs.length, (i) =>
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _imgIdx ? 18 : 6, height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == _imgIdx
                              ? FeezColors.red
                              : Colors.white.withValues(alpha: 0.60),
                            borderRadius: BorderRadius.circular(3)))))),

                // Badge promo
                if (p.discountPct != null)
                  Positioned(top: 80, left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: FeezColors.red,
                        borderRadius: BorderRadius.circular(8)),
                      child: Text('-${p.discountPct}%',
                        style: const TextStyle(
                          fontFamily: 'DMSans', fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white)))),
              ])),
          ),

          // ── CONTENU (arrondi haut) ─────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24))),
              // Chevauchement sur l'image
              transform: Matrix4.translationValues(0, -24, 0),
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Badge livraison
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F0),
                        borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.bolt_rounded,
                          size: 12, color: FeezColors.red),
                        const SizedBox(width: 4),
                        const Text('15 MIN · EXPRESS',
                          style: TextStyle(fontFamily: 'DMSans',
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: FeezColors.red)),
                      ])),
                    const Spacer(),
                    // Unité
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFEEEEEE))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(p.unit,
                          style: const TextStyle(fontFamily: 'DMSans',
                            fontSize: 11, fontWeight: FontWeight.w600,
                            color: FeezColors.ink)),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 14, color: FeezColors.mid),
                      ])),
                  ]),

                  const SizedBox(height: 12),

                  // Nom produit (expandable si long)
                  LayoutBuilder(builder: (ctx, constraints) {
                    final span = TextSpan(
                      text: p.name,
                      style: const TextStyle(
                        fontFamily: 'DMSans', fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: FeezColors.ink, height: 1.2));
                    final tp = TextPainter(
                      text: span,
                      maxLines: 2,
                      textDirection: TextDirection.ltr)
                      ..layout(maxWidth: constraints.maxWidth);
                    final isLong = tp.didExceedMaxLines;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name,
                          maxLines: _nameExpanded ? null : 2,
                          overflow: _nameExpanded
                            ? null : TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DMSans', fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: FeezColors.ink, height: 1.2)),
                        if (isLong) ...[
                          const SizedBox(height: 2),
                          GestureDetector(
                            onTap: () => setState(
                              () => _nameExpanded = !_nameExpanded),
                            child: Text(
                              _nameExpanded ? 'Réduire' : 'Voir plus',
                              style: const TextStyle(
                                fontFamily: 'DMSans', fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: FeezColors.red))),
                        ],
                      ]);
                  }),

                  const SizedBox(height: 10),

                  // Prix
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(p.formattedPrice,
                        style: const TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontSize: 32, fontWeight: FontWeight.w900,
                          color: FeezColors.ink, height: 1)),
                      if (p.formattedOldPrice != null) ...[
                        const SizedBox(width: 10),
                        Text('MRP ${p.formattedOldPrice}',
                          style: const TextStyle(
                            fontFamily: 'DMSans', fontSize: 13,
                            color: FeezColors.low,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: FeezColors.low)),
                      ],
                    ]),

                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFF2F2F2)),
                  const SizedBox(height: 18),

                  // Description (expandable si longue)
                  const Text('Description',
                    style: TextStyle(fontFamily: 'BarlowCondensed',
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: FeezColors.ink)),
                  const SizedBox(height: 8),
                  LayoutBuilder(builder: (ctx, constraints) {
                    final desc = p.description?.isNotEmpty == true
                      ? p.description!
                      : 'Produit sélectionné avec soin par notre équipe. '
                        'Qualité garantie par Feez Market. '
                        'Livré rapidement à votre porte dans les meilleures conditions.';

                    final span = TextSpan(
                      text: desc,
                      style: const TextStyle(fontFamily: 'DMSans',
                        fontSize: 13.5, height: 1.6));
                    final tp = TextPainter(
                      text: span, maxLines: 3,
                      textDirection: TextDirection.ltr)
                      ..layout(maxWidth: constraints.maxWidth);
                    final isLong = tp.didExceedMaxLines;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(desc,
                          maxLines: _descExpanded ? null : 3,
                          overflow: _descExpanded
                            ? null : TextOverflow.ellipsis,
                          style: const TextStyle(fontFamily: 'DMSans',
                            fontSize: 13.5, color: FeezColors.mid,
                            height: 1.6)),
                        if (isLong) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => setState(
                              () => _descExpanded = !_descExpanded),
                            child: Text(
                              _descExpanded ? 'Voir moins' : 'Voir plus',
                              style: const TextStyle(
                                fontFamily: 'DMSans', fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: FeezColors.red))),
                        ],
                      ]);
                  }),

                  const SizedBox(height: 20),
                  const Divider(height: 1, color: Color(0xFFF2F2F2)),
                  const SizedBox(height: 20),

                  // Produits similaires
                  const Text('Tu pourrais aussi aimer',
                    style: TextStyle(fontFamily: 'BarlowCondensed',
                      fontSize: 20, fontWeight: FontWeight.w900,
                      color: FeezColors.ink)),
                  const SizedBox(height: 12),

                  prods.when(
                    loading: () => const SizedBox(height: 200,
                      child: Center(child: CircularProgressIndicator(
                        color: FeezColors.red, strokeWidth: 2))),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) {
                      final similar = list
                        .where((s) =>
                          s.id != p.id && s.category == p.category)
                        .take(6).toList();
                      if (similar.isEmpty) return const SizedBox.shrink();
                      return SizedBox(
                        height: 290,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: similar.length,
                          itemBuilder: (ctx, i) => SizedBox(
                            width: 150,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: ProductCard(
                                product: similar[i],
                                qty: ref.watch(marketCartProvider)[similar[i].id] ?? 0,
                                onAdd: () => ref.read(marketCartProvider.notifier).add(similar[i].id),
                                onRemove: () => ref.read(marketCartProvider.notifier).remove(similar[i].id),
                                onTap: () => ctx.push('/product/${similar[i].id}', extra: similar[i]))))));
                    }),

                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        ]),

        // ── HEADER FLOTTANT ────────────────────────
        Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavBtn(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => context.canPop()
                      ? context.pop() : context.go('/home')),
                  _NavBtn(
                    icon: isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                    color: isFav ? FeezColors.red : null,
                    onTap: () => ref
                      .read(favoritesProvider.notifier)
                      .toggle(p.id)),
                ])))),

        // ── CTA BAS ─────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16, offset: const Offset(0, -4))]),
            child: SafeArea(
              top: false,
              child: qty == 0
                ? SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _add,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FeezColors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                        elevation: 0),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_shopping_cart_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Ajouter au panier',
                            style: TextStyle(
                              fontFamily: 'BarlowCondensed',
                              fontSize: 18, fontWeight: FontWeight.w900,
                              letterSpacing: 0.02)),
                        ])))
                : Row(children: [
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFFEEEEEE), width: 1.5),
                        borderRadius: BorderRadius.circular(14)),
                      child: Row(children: [
                        GestureDetector(
                          onTap: _remove,
                          child: const SizedBox(width: 44, height: 52,
                            child: Center(child: Icon(
                              Icons.remove_rounded,
                              color: FeezColors.red, size: 22)))),
                        Text('$qty',
                          style: const TextStyle(
                            fontFamily: 'BarlowCondensed',
                            fontSize: 22, fontWeight: FontWeight.w900,
                            color: FeezColors.ink)),
                        GestureDetector(
                          onTap: _add,
                          child: const SizedBox(width: 44, height: 52,
                            child: Center(child: Icon(
                              Icons.add_rounded,
                              color: FeezColors.red, size: 22)))),
                      ])),
                    const SizedBox(width: 10),
                    Expanded(child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.push('/cart'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FeezColors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                          elevation: 0),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('Voir le panier',
                              style: TextStyle(
                                fontFamily: 'BarlowCondensed',
                                fontSize: 17,
                                fontWeight: FontWeight.w900)),
                          ])))),
                  ])),
          )),
      ]));
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

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(
          color: Color(0x18000000),
          blurRadius: 8, offset: Offset(0, 2))]),
      child: Center(child: Icon(icon,
        size: 17, color: color ?? const Color(0xFF0D0D0D)))));
}