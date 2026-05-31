import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/premium_widgets.dart';
import '../../widgets/product_image.dart';
import '../cart/providers/cart_provider.dart';
import '../orders/providers/order_provider.dart';
import '../../models/product_model.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});
  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _payIdx = 0;
  bool _loading = false;

  static String _fmt(int n) =>
    '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} F';

  final _methods = <Map<String, dynamic>>[
    {'icon':'🟠','bg':const Color(0xFFFFF3E0),'name':'Orange Money',
      'sub':'Paiement sécurisé instantané','value':'orange_money',
      'border':const Color(0xFFFF6B00)},
    {'icon':'💙','bg':const Color(0xFFE3F2FD),'name':'Wave',
      'sub':'Sans frais supplémentaires','value':'wave',
      'border':const Color(0xFF1E88E5)},
    {'icon':'📱','bg':const Color(0xFFFFFDE7),'name':'MTN Mobile Money',
      'sub':'Paiement mobile rapide','value':'mtn',
      'border':const Color(0xFFFFC107)},
    {'icon':'💳','bg':const Color(0xFFEDE7F6),'name':'Carte bancaire',
      'sub':'Visa, Mastercard','value':'card',
      'border':const Color(0xFF7E57C2)},
    {'icon':'💵','bg':const Color(0xFFE8F5E9),'name':'Cash à la livraison',
      'sub':'Préparez la monnaie exacte','value':'cash',
      'border':const Color(0xFF66BB6A)},
  ];

  Future<void> _confirm(Map<String,dynamic>? args) async {
    setState(() => _loading = true);
    try {
      final cart = args?['cart'] as Map<String,int>? ?? {};
      final products = args?['products'] as List? ?? [];
      final order = await ref.read(orderNotifierProvider.notifier).placeMarketOrder(
        cart: cart, products: products,
        deliveryAddress: 'Cocody, Abidjan', lat: 5.3600, lng: -3.9969, zone: 'cocody',
        paymentMethod: _methods[_payIdx]['value'] as String);
      if (order != null && mounted) {
        ref.read(marketCartProvider.notifier).clear();
        // Invalider la liste des commandes pour rafraîchir
        ref.invalidate(userOrdersProvider);
        context.go('/confirm', extra: order['id']?.toString() ?? '');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'), backgroundColor: FeezColors.red));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args     = GoRouterState.of(context).extra as Map<String,dynamic>?;
    final total    = (args?['total'] as int?) ?? 0;
    final subtotal = total - 200;
    final cart     = args?['cart'] as Map<String,int>? ?? {};
    final products = (args?['products'] as List?) ?? [];
    final productMap = {for (final p in products) (p as ProductModel).id: p};

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      body: SafeArea(child: Column(children: [
        // ── Custom header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            FeezBackButton(
              onTap: () => context.canPop() ? context.pop() : context.go('/home')),
            const SizedBox(width: 14),
            const Text('Paiement',
              style: TextStyle(
                fontFamily: 'BarlowCondensed', fontSize: 22,
                fontWeight: FontWeight.w900, color: Color(0xFF0D0D0D),
                letterSpacing: -0.02)),
          ])),
        Expanded(child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [

          // Adresse livraison
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x0F000000),
                blurRadius: 10, offset: Offset(0, 3))]),
            child: Row(children: [
              Container(width: 38, height: 38,
                decoration: BoxDecoration(
                  color: FeezColors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.location_on_outlined,
                  color: FeezColors.red, size: 18)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Livré à', style: TextStyle(fontSize: 11,
                    color: FeezColors.low, fontWeight: FontWeight.w600)),
                  Text('Cocody, Abidjan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                      color: FeezColors.ink)),
                  Text('Livraison estimée: 15-25 min',
                    style: TextStyle(fontSize: 11, color: FeezColors.mid)),
                ])),
              const Text('Modifier',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: FeezColors.red)),
            ])),

          const SizedBox(height: 18),

          // Méthode de paiement
          const Padding(padding: EdgeInsets.fromLTRB(4, 0, 0, 10),
            child: Text('MODE DE PAIEMENT', style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w800, color: FeezColors.low, letterSpacing: 0.08))),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x0F000000),
                blurRadius: 10, offset: Offset(0, 3))]),
            child: Column(children: List.generate(_methods.length, (i) {
              final m = _methods[i];
              final active = _payIdx == i;
              return Column(children: [
                GestureDetector(
                  onTap: () => setState(() => _payIdx = i),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    child: Row(children: [
                      Container(width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: m['bg'] as Color,
                          borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text(m['icon'] as String,
                          style: const TextStyle(fontSize: 20)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'] as String, style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w800,
                            color: FeezColors.ink)),
                          Text(m['sub'] as String, style: const TextStyle(
                            fontSize: 11, color: FeezColors.mid)),
                        ])),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22, height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active ? FeezColors.red : Colors.transparent,
                          border: Border.all(
                            color: active ? FeezColors.red : const Color(0xFFCCCCCC),
                            width: 2)),
                        child: active
                          ? const Icon(Icons.check, color: Colors.white, size: 13)
                          : null),
                    ]))),
                if (i < _methods.length - 1)
                  const Padding(padding: EdgeInsets.only(left: 64),
                    child: Divider(height: 0.5, color: Color(0xFFF0F0F0))),
              ]);
            }))),

          const SizedBox(height: 18),

          // Produits commande
          const Padding(padding: EdgeInsets.fromLTRB(4, 0, 0, 10),
            child: Text('TA COMMANDE', style: TextStyle(fontSize: 11,
              fontWeight: FontWeight.w800, color: FeezColors.low, letterSpacing: 0.08))),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x0F000000),
                blurRadius: 10, offset: Offset(0, 3))]),
            child: Column(children: cart.entries
              .where((e) => productMap.containsKey(e.key))
              .map((e) {
                final p = productMap[e.key] as ProductModel;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Container(width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(10)),
                      child: p.hasImage
                        ? ClipRRect(borderRadius: BorderRadius.circular(10),
                            child: ProductImage(url: p.primaryImage, size: 44,
                              borderRadius: BorderRadius.circular(10)))
                        : const Icon(Icons.image_outlined,
                            color: Color(0xFFCCCCCC), size: 20)),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5,
                            fontWeight: FontWeight.w700, color: FeezColors.ink)),
                        Text('${e.value}× · ${_fmt(p.price)}',
                          style: const TextStyle(fontSize: 11, color: FeezColors.mid)),
                      ])),
                    Text(_fmt(p.price * e.value),
                      style: const TextStyle(fontFamily: 'BarlowCondensed',
                        fontSize: 15, fontWeight: FontWeight.w900,
                        color: FeezColors.ink)),
                  ]));
              }).toList())),

          const SizedBox(height: 18),

          // Récap
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x0F000000),
                blurRadius: 10, offset: Offset(0, 3))]),
            child: Column(children: [
              _row('Sous-total', _fmt(subtotal)),
              _row('Frais de livraison', _fmt(200), color: FeezColors.green),
              const Divider(height: 22, color: Color(0xFFF0F0F0)),
              Row(children: [
                const Text('TOTAL',
                  style: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 18,
                    fontWeight: FontWeight.w900, color: FeezColors.ink)),
                const Spacer(),
                Text(_fmt(total),
                  style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 26,
                    fontWeight: FontWeight.w900, color: FeezColors.red)),
              ]),
            ])),
        ],
      )),
      ])),

      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
        decoration: const BoxDecoration(color: Colors.white,
          boxShadow: [BoxShadow(color: Color(0x10000000),
            blurRadius: 20, offset: Offset(0, -4))]),
        child: SafeArea(top: false,
          child: PremiumButton(
            label: 'Payer ${_fmt(total)}',
            trailingIcon: Icons.arrow_forward_rounded,
            height: 58,
            loading: _loading,
            onTap: _loading ? null : () => _confirm(args))),
      ),
    );
  }

  Widget _row(String l, String v, {Color? color}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(l, style: const TextStyle(fontSize: 13, color: FeezColors.mid)),
      const Spacer(),
      Text(v, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
        color: color ?? FeezColors.ink)),
    ]));
}
