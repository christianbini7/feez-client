import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../models/product_model.dart';
import '../../../widgets/product_image.dart';
import '../../home/providers/home_provider.dart';
import '../providers/cart_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});
  @override ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _promoCtrl = TextEditingController();
  bool _promoApplied = false;

  @override
  void dispose() { _promoCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final cart      = ref.watch(marketCartProvider);
    final products  = ref.watch(productsProvider);
    final cartItems = products.when(
      data: (list) => list
        .where((p) => cart.containsKey(p.id) && (cart[p.id] ?? 0) > 0)
        .toList(),
      loading: () => <ProductModel>[],
      error: (_, __) => <ProductModel>[],
    );
    final subTotal = cartItems.fold<int>(
      0, (sum, p) => sum + (p.price * (cart[p.id] ?? 0)));
    const delivery = 500;
    final total    = subTotal + (_promoApplied ? 0 : delivery);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/home'),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: Color(0xFF0D0D0D))),
        title: Column(children: [
          const Text('Mon Panier',
            style: TextStyle(fontFamily: 'BarlowCondensed',
              fontSize: 22, fontWeight: FontWeight.w900,
              color: Color(0xFF0D0D0D))),
          if (cartItems.isNotEmpty)
            Text('${cartItems.length} article${cartItems.length > 1 ? 's' : ''}',
              style: const TextStyle(fontFamily: 'DMSans',
                fontSize: 11, color: Color(0xFF888888))),
        ]),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10)),
            child: const Center(child: Icon(Icons.shopping_cart_outlined,
              size: 18, color: Color(0xFF0D0D0D)))),
        ]),

      body: cartItems.isEmpty
        ? _emptyState(context)
        : Column(children: [
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              itemCount: cartItems.length,
              itemBuilder: (_, i) {
                final p   = cartItems[i];
                final qty = cart[p.id] ?? 0;
                return _CartItem(
                  product: p, qty: qty,
                  onAdd: () {
                    HapticFeedback.lightImpact();
                    ref.read(marketCartProvider.notifier).add(p.id);
                  },
                  onRemove: () {
                    HapticFeedback.lightImpact();
                    ref.read(marketCartProvider.notifier).remove(p.id);
                  },
                  onDelete: () {
                    HapticFeedback.mediumImpact();
                    ref.read(marketCartProvider.notifier).removeAll(p.id);
                  });
              })),

            // ── Summary bottom ──────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 20, offset: const Offset(0, -6))]),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(children: [

                    // Promo code
                    Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEEEEEE))),
                      child: Row(children: [
                        const SizedBox(width: 12),
                        const Icon(Icons.local_offer_outlined,
                          size: 16, color: Color(0xFFAAAAAA)),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(
                          controller: _promoCtrl,
                          style: const TextStyle(fontFamily: 'DMSans',
                            fontSize: 13.5, color: Color(0xFF0D0D0D)),
                          decoration: const InputDecoration(
                            hintText: 'Code promo',
                            hintStyle: TextStyle(color: Color(0xFFAAAAAA)),
                            border: InputBorder.none, isDense: true))),
                        GestureDetector(
                          onTap: () {
                            if (_promoCtrl.text.trim().toUpperCase() == 'FEEZ10') {
                              setState(() => _promoApplied = true);
                              FocusScope.of(context).unfocus();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code promo appliqué ! Livraison offerte 🎉'),
                                  backgroundColor: Color(0xFF1A5C38)));
                            } else if (_promoCtrl.text.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Code invalide'),
                                  backgroundColor: Colors.red));
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A5C38),
                              borderRadius: BorderRadius.circular(10)),
                            child: const Text('Appliquer',
                              style: TextStyle(fontFamily: 'DMSans',
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: Colors.white)))),
                      ])),

                    const SizedBox(height: 14),

                    // Order Summary
                    const Row(children: [
                      Text('Résumé de commande',
                        style: TextStyle(fontFamily: 'BarlowCondensed',
                          fontSize: 18, fontWeight: FontWeight.w900,
                          color: Color(0xFF0D0D0D))),
                    ]),
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'Sous-total',
                      value: '$subTotal F'),
                    const SizedBox(height: 4),
                    _SummaryRow(
                      label: 'Livraison',
                      value: _promoApplied ? 'Offerte 🎉' : '$delivery F',
                      valueColor: _promoApplied
                        ? const Color(0xFF1A5C38) : null),
                    if (_promoApplied) ...[
                      const SizedBox(height: 4),
                      _SummaryRow(label: 'Réduction',
                        value: '-$delivery F',
                        valueColor: FeezColors.red),
                    ],
                    const SizedBox(height: 8),
                    const Divider(height: 1, color: Color(0xFFF0F0F0)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Text('Total',
                        style: TextStyle(fontFamily: 'BarlowCondensed',
                          fontSize: 18, fontWeight: FontWeight.w900,
                          color: Color(0xFF0D0D0D))),
                      const Spacer(),
                      Text('$total F',
                        style: const TextStyle(
                          fontFamily: 'BarlowCondensed',
                          fontSize: 22, fontWeight: FontWeight.w900,
                          color: Color(0xFF0D0D0D))),
                    ]),

                    const SizedBox(height: 12),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => context.push('/checkout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A5C38),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                          elevation: 0),
                        child: const Text('Passer au paiement',
                          style: TextStyle(
                            fontFamily: 'BarlowCondensed',
                            fontSize: 18, fontWeight: FontWeight.w900,
                            letterSpacing: 0.02)))),
                  ]))),
            ),
          ]),
    );
  }

  Widget _emptyState(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          shape: BoxShape.circle),
        child: const Icon(Icons.shopping_cart_outlined,
          size: 44, color: Color(0xFFCCCCCC))),
      const SizedBox(height: 16),
      const Text('Ton panier est vide',
        style: TextStyle(fontFamily: 'BarlowCondensed',
          fontSize: 22, fontWeight: FontWeight.w900,
          color: Color(0xFF0D0D0D))),
      const SizedBox(height: 6),
      const Text('Ajoute des produits pour commander',
        style: TextStyle(fontFamily: 'DMSans', fontSize: 13,
          color: Color(0xFF888888))),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () => context.go('/home'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A5C38),
            borderRadius: BorderRadius.circular(20)),
          child: const Text('Parcourir les produits',
            style: TextStyle(fontFamily: 'BarlowCondensed',
              fontSize: 16, fontWeight: FontWeight.w900,
              color: Colors.white)))),
    ]));
}

// ── Cart Item ─────────────────────────────────────────────────
class _CartItem extends StatelessWidget {
  final ProductModel product;
  final int qty;
  final VoidCallback onAdd, onRemove, onDelete;
  const _CartItem({required this.product, required this.qty,
    required this.onAdd, required this.onRemove, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final p = product;
    return Dismissible(
      key: ValueKey(p.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFECEC),
          borderRadius: BorderRadius.circular(16)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded,
          color: Color(0xFFE53935), size: 26)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8, offset: Offset(0, 2))]),
        child: Row(children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 80, height: 80,
              color: _catBg(p.category),
              child: p.hasImage
                ? ProductImage(
                    url: p.primaryImage!, size: 80,
                    borderRadius: BorderRadius.circular(12),
                    fit: BoxFit.cover)
                : Center(child: Text(p.emoji,
                    style: const TextStyle(fontSize: 36))))),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontFamily: 'DMSans',
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: Color(0xFF0D0D0D), height: 1.3)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.access_time_rounded,
                  size: 11, color: Color(0xFF1A5C38)),
                const SizedBox(width: 3),
                const Text('15 MINS',
                  style: TextStyle(fontFamily: 'DMSans', fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A5C38))),
              ]),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Prix
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(p.formattedPrice,
                        style: const TextStyle(
                          fontFamily: 'BarlowCondensed', fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0D0D0D), height: 1)),
                      if (p.formattedOldPrice != null) ...[
                        const SizedBox(width: 5),
                        Text(p.formattedOldPrice!,
                          style: const TextStyle(
                            fontFamily: 'DMSans', fontSize: 11,
                            color: Color(0xFFAAAAAA),
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Color(0xFFAAAAAA))),
                      ],
                    ]),
                  // Qty controls
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE0E0E0), width: 1.5),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      GestureDetector(
                        onTap: qty == 1 ? onDelete : onRemove,
                        child: SizedBox(
                          width: 32, height: 32,
                          child: Center(child: Icon(
                            qty == 1
                              ? Icons.delete_outline_rounded
                              : Icons.remove_rounded,
                            color: const Color(0xFF1A5C38), size: 16)))),
                      Text('0$qty',
                        style: const TextStyle(fontFamily: 'DMSans',
                          fontSize: 13, fontWeight: FontWeight.w800,
                          color: Color(0xFF0D0D0D))),
                      GestureDetector(
                        onTap: onAdd,
                        child: Container(
                          width: 32, height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1A5C38),
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(8),
                              bottomRight: Radius.circular(8))),
                          child: const Center(child: Icon(
                            Icons.add_rounded,
                            color: Colors.white, size: 16)))),
                    ])),
                ]),
            ])),
        ])));
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

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final Color? valueColor;
  const _SummaryRow({required this.label, required this.value, this.valueColor});
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(label, style: const TextStyle(fontFamily: 'DMSans',
      fontSize: 13, color: Color(0xFF666666))),
    const Spacer(),
    Text(value, style: TextStyle(fontFamily: 'DMSans',
      fontSize: 13, fontWeight: FontWeight.w700,
      color: valueColor ?? const Color(0xFF0D0D0D))),
  ]);
}