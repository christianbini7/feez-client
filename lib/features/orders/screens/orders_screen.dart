import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';
import '../../../core/premium_widgets.dart';
import '../../../widgets/product_image.dart';
import '../../home/providers/home_provider.dart';
import '../providers/order_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});
  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _showHistory = false;

  static const _statusLabel = {
    'pending':'En attente','accepted':'Accepté','preparing':'En préparation',
    'ready':'Prêt','in_transit':'En route','delivered':'Livré',
    'cancelled':'Annulé','rejected':'Refusé',
  };
  static const _statusColors = <String, Color>{
    'pending':FeezColors.red,'accepted':FeezColors.red,
    'preparing':FeezColors.red,'ready':FeezColors.red,
    'in_transit':FeezColors.red,'delivered':Color(0xFF66BB6A),
    'cancelled':Color(0xFF9E9E9E),'rejected':Color(0xFFEF5350),
  };

  static const _activeStatuses = ['pending','accepted','preparing','ready','in_transit'];

  // Récupère l'URL image avec fallback : items[image_url] → productsProvider → null
  String? _getItemImageUrl(Map<String, dynamic> item, List products) {
    // 1. Essayer item.image_url
    final saved = item['image_url']?.toString();
    if (saved != null && saved.isNotEmpty) return saved;
    // 2. Chercher dans productsProvider via product_id
    final pid = item['product_id']?.toString();
    if (pid != null) {
      try {
        final product = products.firstWhere((p) => p.id == pid);
        return product.primaryImage as String?;
      } catch (_) {}
    }
    return null;
  }

  static String _fmt(int n) =>
    '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} F';

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      body: SafeArea(child: Column(children: [
        // ── Header propre
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(children: [
            const Text('Mes commandes',
              style: TextStyle(
                fontFamily: 'BarlowCondensed', fontSize: 26,
                fontWeight: FontWeight.w900, color: Color(0xFF0D0D0D),
                letterSpacing: -0.02)),
            const Spacer(),
            // Compteur
            ordersAsync.when(
              loading: () => const SizedBox(),
              error: (_, __) => const SizedBox(),
              data: (orders) {
                final activeCount = orders.where((o) =>
                  _activeStatuses.contains(o['status'])).length;
                if (activeCount == 0) return const SizedBox();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: FeezColors.red,
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text('$activeCount en cours',
                      style: const TextStyle(fontFamily: 'DMSans',
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: Colors.white)),
                  ]));
              }),
          ])),
        const SizedBox(height: 14),
        // ── Tabs segmented
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1F3),
              borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              _tabBtn('En cours', !_showHistory, () => setState(() => _showHistory = false)),
              _tabBtn('Historique', _showHistory, () => setState(() => _showHistory = true)),
            ]))),
        const SizedBox(height: 10),
        Expanded(child: ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(
            color: FeezColors.red, strokeWidth: 2)),
          error: (e, _) => Center(child: Text('Erreur: $e',
            style: const TextStyle(color: FeezColors.red))),
          data: (orders) {
            final filtered = orders.where((o) {
              final s = o['status'] as String? ?? '';
              return _showHistory ? !_activeStatuses.contains(s) : _activeStatuses.contains(s);
            }).toList();

            if (filtered.isEmpty) return _emptyState();

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final products = ref.watch(productsProvider).asData?.value ?? [];
                return _OrderCard(
                  order: filtered[i],
                  products: products,
                  statusLabel: _statusLabel[filtered[i]['status']] ?? 'Inconnu',
                  statusColor: _statusColors[filtered[i]['status']] ?? Colors.grey,
                  onTap: () => _showOrderDetails(filtered[i]),
                  isActive: !_showHistory);
              });
          })),
      ])),
    );
  }

  Widget _tabBtn(String label, bool active, VoidCallback onTap) =>
    Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active ? const [BoxShadow(
            color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))] : null),
        child: Center(child: Text(label,
          style: TextStyle(fontFamily: 'BarlowCondensed', fontSize: 13,
            fontWeight: FontWeight.w900,
            color: active ? const Color(0xFF0D0D0D) : const Color(0xFFAAAAAA)))))));

  Widget _emptyState() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 120, height: 120,
        decoration: BoxDecoration(
          color: FeezColors.red.withValues(alpha: 0.08),
          shape: BoxShape.circle),
        child: Icon(Icons.receipt_long_outlined,
          size: 54, color: FeezColors.red.withValues(alpha: 0.7))),
      const SizedBox(height: 24),
      Text(_showHistory ? 'Aucune commande passée' : 'Aucune commande en cours',
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 22,
          fontWeight: FontWeight.w900, color: FeezColors.ink)),
      const SizedBox(height: 8),
      const Text('Tes commandes apparaîtront ici',
        style: TextStyle(fontSize: 13, color: FeezColors.mid)),
      const SizedBox(height: 24),
      PremiumButton(
        label: 'Commander maintenant',
        leadingIcon: Icons.shopping_bag_outlined,
        height: 50, fontSize: 15,
        onTap: () => context.go('/home')),
      const SizedBox(height: 4),
    ])));

  void _showOrderDetails(Map<String, dynamic> order) {
    final products = ref.read(productsProvider).asData?.value ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(children: [
            // Drag handle
            Container(width: 36, height: 4, margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2))),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Commande #${(order['id'] ?? '').toString().substring(0, 6).toUpperCase()}',
                    style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 22,
                      fontWeight: FontWeight.w900, color: FeezColors.ink,
                      letterSpacing: -0.02)),
                  Text(_statusLabel[order['status']] ?? 'Inconnu',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: _statusColors[order['status']] ?? Colors.grey)),
                ])),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5), shape: BoxShape.circle),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF666666)))),
              ])),
            Container(height: 0.5, color: const Color(0xFFEEEEEE)),
            // Contenu scrollable
            Expanded(child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                if (_activeStatuses.contains(order['status']))
                  _trackingStrip(order['status'] as String? ?? ''),
                const SizedBox(height: 16),
                // Produits avec photos
                const Text('PRODUITS', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w800, color: FeezColors.low, letterSpacing: 0.08)),
                const SizedBox(height: 10),
                ..._orderItems(order, products),
                const SizedBox(height: 18),
                // Adresse
                const Text('LIVRAISON', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w800, color: FeezColors.low, letterSpacing: 0.08)),
                const SizedBox(height: 10),
                _detailRow(Icons.location_on_outlined,
                  order['delivery_address'] ?? 'Adresse non précisée'),
                _detailRow(Icons.phone_outlined,
                  order['phone'] ?? 'Non renseigné'),
                _detailRow(Icons.access_time, 'Livraison estimée: 25-35 min'),
                const SizedBox(height: 18),
                // Total
                const Text('PAIEMENT', style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w800, color: FeezColors.low, letterSpacing: 0.08)),
                const SizedBox(height: 10),
                _totalRow('Sous-total', _fmt(order['subtotal'] ?? 0)),
                _totalRow('Livraison', _fmt(order['delivery_fee'] ?? 0)),
                const SizedBox(height: 8),
                Container(height: 0.5, color: const Color(0xFFEEEEEE)),
                const SizedBox(height: 12),
                Row(children: [
                  const Text('TOTAL', style: TextStyle(fontFamily: 'BarlowCondensed',
                    fontSize: 18, fontWeight: FontWeight.w900, color: FeezColors.ink)),
                  const Spacer(),
                  Text(_fmt(order['total'] ?? 0),
                    style: const TextStyle(fontFamily: 'BarlowCondensed',
                      fontSize: 24, fontWeight: FontWeight.w900, color: FeezColors.red)),
                ]),
              ])),
            // Action button
            if (_activeStatuses.contains(order['status']))
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: GestureDetector(
                  onTap: () { Navigator.pop(context); context.push('/tracking/${order['id']}'); },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: FeezColors.red,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: FeezColors.red.withValues(alpha: 0.25),
                        blurRadius: 12, offset: const Offset(0, 4))]),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.location_on, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('Suivre ma commande', style: TextStyle(
                        fontFamily: 'BarlowCondensed', fontSize: 16,
                        fontWeight: FontWeight.w900, color: Colors.white)),
                    ])))),
          ]))));
  }

  List<Widget> _orderItems(Map<String, dynamic> order, List products) {
    final items = (order['items'] as List?) ?? [];
    return items.map((item) {
      final m = item is Map<String, dynamic>
        ? item
        : Map<String, dynamic>.from(item as Map);
      final url = _getItemImageUrl(m, products);
      final emoji = m['emoji']?.toString() ?? '📦';
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: url != null && url.isNotEmpty
                ? ClipRRect(borderRadius: BorderRadius.circular(10),
                    child: ProductImage(url: url, size: 48,
                      borderRadius: BorderRadius.circular(10)))
                : Center(child: Text(emoji, style: const TextStyle(fontSize: 24)))),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['name']?.toString() ?? 'Produit',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: Color(0xFF0D0D0D))),
              Text('${m['quantity'] ?? m['qty'] ?? 1}× · ${_fmt(((m['price'] as num?)?.toInt() ?? 0))}',
                style: const TextStyle(fontSize: 11, color: FeezColors.mid)),
            ])),
            Text(_fmt(((m['price'] as num?)?.toInt() ?? 0) * ((m['quantity'] as num?)?.toInt() ?? (m['qty'] as num?)?.toInt() ?? 1)),
              style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 15,
                fontWeight: FontWeight.w900, color: FeezColors.ink)),
          ])));
    }).toList();
  }

  Widget _trackingStrip(String status) {
    final steps = ['pending', 'accepted', 'preparing', 'ready', 'in_transit', 'delivered'];
    final stepsLabels = ['Reçue', 'Acceptée', 'Préparation', 'Prête', 'En route', 'Livrée'];
    final currentIdx = steps.indexOf(status);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFFF5F5), Color(0xFFFFFFFF)]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FeezColors.red.withValues(alpha: 0.15))),
      child: Column(children: [
        Row(children: List.generate(steps.length, (i) {
          final done = i <= currentIdx;
          return Expanded(child: Row(children: [
            Container(width: 22, height: 22,
              decoration: BoxDecoration(
                color: done ? FeezColors.red : const Color(0xFFEEEEEE),
                shape: BoxShape.circle),
              child: done
                ? const Center(child: Icon(Icons.check, color: Colors.white, size: 13))
                : null),
            if (i < steps.length - 1)
              Expanded(child: Container(height: 2,
                color: i < currentIdx ? FeezColors.red : const Color(0xFFEEEEEE))),
          ]));
        })),
        const SizedBox(height: 10),
        Text(stepsLabels[currentIdx >= 0 ? currentIdx : 0],
          style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 14,
            fontWeight: FontWeight.w900, color: FeezColors.red)),
      ]));
  }

  Widget _detailRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: FeezColors.mid),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(
        fontSize: 13, color: FeezColors.ink))),
    ]));

  Widget _totalRow(String l, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Text(l, style: const TextStyle(fontSize: 13, color: FeezColors.mid)),
      const Spacer(),
      Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
        color: FeezColors.ink)),
    ]));
}

// ── Carte commande ─────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final List products;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;
  final bool isActive;
  const _OrderCard({required this.order, required this.products,
    required this.statusLabel, required this.statusColor,
    required this.onTap, required this.isActive});

  static String _fmt(int n) =>
    '${n.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]} ')} F';

  String? _imageFor(Map<String, dynamic> item) {
    final saved = item['image_url']?.toString();
    if (saved != null && saved.isNotEmpty) return saved;
    final pid = item['product_id']?.toString();
    if (pid != null) {
      try {
        final p = products.firstWhere((p) => p.id == pid);
        return p.primaryImage as String?;
      } catch (_) {}
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(
            color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 3))]),
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Commande #${(order['id'] ?? '').toString().substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800,
                    color: FeezColors.ink)),
                Text(statusLabel, style: TextStyle(fontSize: 11,
                  fontWeight: FontWeight.w600, color: statusColor)),
              ])),
              Text(_fmt(order['total'] ?? 0),
                style: const TextStyle(fontFamily: 'BarlowCondensed', fontSize: 18,
                  fontWeight: FontWeight.w900, color: FeezColors.ink)),
            ])),
          if (items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(children: [
                SizedBox(
                  width: items.length.clamp(1, 4) * 28.0 + 10,
                  height: 36,
                  child: Stack(clipBehavior: Clip.none,
                    children: List.generate(items.length.clamp(0, 4), (i) {
                      final raw = items[i];
                      final m = raw is Map<String, dynamic>
                        ? raw : Map<String, dynamic>.from(raw as Map);
                      final url = _imageFor(m);
                      final emoji = m['emoji']?.toString() ?? '📦';
                      return Positioned(left: i * 24.0,
                        child: Container(width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.2),
                            boxShadow: const [BoxShadow(
                              color: Color(0x14000000), blurRadius: 4)]),
                          child: url != null && url.isNotEmpty
                            ? ClipOval(child: ProductImage(url: url, size: 36,
                                borderRadius: BorderRadius.circular(100)))
                            : Center(child: Text(emoji,
                                style: const TextStyle(fontSize: 18)))));
                    }))),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  '${items.length} article${items.length > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: FeezColors.mid))),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: FeezColors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Voir détails',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: FeezColors.red)),
                      SizedBox(width: 3),
                      Icon(Icons.chevron_right_rounded,
                        size: 14, color: FeezColors.red),
                    ]))
                else
                  const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
              ])),
        ])));
  }
}
